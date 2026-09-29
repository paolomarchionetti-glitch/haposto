-- HAPOSTO — STRUMENTI SOLO PER IL PROGETTO SUPABASE DEV. MAI IN PRODUZIONE.
--
-- Esegui DOPO le migration e il seed 910. Rieseguibile (per aggiornarlo basta rieseguirlo).
-- Cosa aggiunge:
--   1. dev_publish_live_status(): l'app (anche senza login) può pubblicare lo stato dei SOLI locali
--      di test (data_source = 'DEV_SEED'). Così due telefoni vedono la stessa cosa: su uno fai il
--      ristoratore, sull'altro il cliente. Si spegne con dev_tools_enabled = false.
--   2. dev_simulate_live_activity(): fa "vivere" i locali di test come in una serata vera.
--   3. Pianificazione automatica del simulatore ogni 5 minuti con pg_cron (se attivo).
-- Per togliere tutto: supabase/dev/dev_purge.sql

update public.app_config set value = 'true', updated_at = now() where key = 'dev_tools_enabled';

create or replace function public.dev_tools_enabled()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select coalesce((select c.value = 'true'::jsonb from public.app_config c where c.key = 'dev_tools_enabled'), false);
$$;

-- ---------------------------------------------------------------------------
-- 1) Pubblicazione dall'app per i locali di test (sostituisce l'overlay in RAM dello Step 7).
-- ---------------------------------------------------------------------------
create or replace function public.dev_publish_live_status(
    p_restaurant_id uuid,
    p_status public.live_status,
    p_available_tables smallint default null,
    p_estimated_wait_minutes smallint default null,
    p_note varchar(80) default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_now timestamptz := now();
    v_tables smallint := case when p_status = 'FULL' then null else p_available_tables end;
begin
    if not public.dev_tools_enabled() then
        raise exception 'DEV_TOOLS_DISABLED';
    end if;
    -- Un locale di test rivendicato da un account vero lo aggiorna solo chi lo gestisce.
    if not exists (
        select 1 from public.restaurants r
        where r.id = p_restaurant_id
          and r.data_source = 'DEV_SEED'
          and r.partnership_status = 'ACTIVE_PARTNER'
          and not exists (select 1 from public.restaurant_users ru where ru.restaurant_id = r.id)
    ) then
        raise exception 'NOT_A_DEV_PARTNER';
    end if;
    if v_tables is not null and v_tables not between 0 and 99 then
        raise exception 'available_tables must be between 0 and 99';
    end if;
    if p_estimated_wait_minutes is not null and p_estimated_wait_minutes not between 0 and 240 then
        raise exception 'estimated_wait_minutes must be between 0 and 240';
    end if;

    insert into public.restaurant_live_status (
        restaurant_id, status, available_tables, estimated_wait_minutes, note, updated_at, valid_until, updated_via
    ) values (
        p_restaurant_id, p_status, v_tables, p_estimated_wait_minutes, nullif(trim(p_note), ''),
        v_now, v_now + interval '30 minutes', 'DEV_APP'
    )
    on conflict (restaurant_id) do update set
        status = excluded.status,
        available_tables = excluded.available_tables,
        estimated_wait_minutes = excluded.estimated_wait_minutes,
        note = excluded.note,
        updated_at = excluded.updated_at,
        valid_until = excluded.valid_until,
        updated_via = excluded.updated_via;

    insert into public.status_history (
        restaurant_id, status, available_tables, estimated_wait_minutes, note, updated_at, valid_until, updated_via
    ) values (
        p_restaurant_id, p_status, v_tables, p_estimated_wait_minutes, nullif(trim(p_note), ''),
        v_now, v_now + interval '30 minutes', 'DEV_APP'
    );
end;
$$;

-- ---------------------------------------------------------------------------
-- 2) Simulatore: una "serata vera" per i locali di test.
--    - pranzo (11:30–14:45) e cena (18:45–23:00, ora italiana) più affollati; venerdì e sabato di più;
--    - circa 1 locale su 5 è "pigro" e lascia scadere lo stato (così si vede "Da aggiornare");
--    - di notte nessun aggiornamento: gli stati scadono da soli, come nella realtà;
--    - non tocca per 3 ore un locale aggiornato a mano dall'app (DEV_APP);
--    - non tocca mai un locale che ha un titolare o uno staff vero (rivendicato nelle prove).
-- ---------------------------------------------------------------------------
create or replace function public.dev_simulate_live_activity()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_now timestamptz := now();
    v_local time := (now() at time zone 'Europe/Rome')::time;
    v_weekend boolean := extract(isodow from (now() at time zone 'Europe/Rome')) in (5, 6);
    v_phase text;
    v_roll double precision;
    v_status public.live_status;
    v_tables smallint;
    v_wait smallint;
    v_note text;
    v_count integer := 0;
    r record;
begin
    if not public.dev_tools_enabled() then
        return 0;
    end if;

    v_phase := case
        when v_local >= time '11:30' and v_local < time '14:45' then 'LUNCH'
        when v_local >= time '18:45' and v_local < time '23:00' then 'DINNER'
        when v_local >= time '23:00' or v_local < time '10:30' then 'NIGHT'
        else 'QUIET'
    end;
    if v_phase = 'NIGHT' then
        return 0;
    end if;

    for r in
        select rest.id, s.valid_until, s.updated_via, s.updated_at,
               abs(hashtext(rest.id::text)) % 5 = 0 as lazy
        from public.restaurants rest
        left join public.restaurant_live_status s on s.restaurant_id = rest.id
        where rest.data_source = 'DEV_SEED'
          and rest.partnership_status = 'ACTIVE_PARTNER'
          -- I locali per le prove sul campo con un ristoratore vero li aggiorna solo lui dall'app.
          and coalesce(rest.source_ref, '') not like 'field-test:%'
          -- ...e nemmeno quelli rivendicati da un account vero (titolare o staff).
          and not exists (select 1 from public.restaurant_users ru where ru.restaurant_id = rest.id)
    loop
        continue when r.updated_via = 'DEV_APP' and r.updated_at > v_now - interval '3 hours';
        continue when r.lazy and random() < 0.85;
        -- Aggiorna soprattutto quando lo stato è scaduto o sta per scadere; a volte cambia prima.
        continue when r.valid_until is not null
                  and r.valid_until > v_now + interval '8 minutes'
                  and random() > 0.15;

        v_roll := random();
        v_status := case v_phase
            when 'DINNER' then
                case when v_roll < (case when v_weekend then 0.25 else 0.45 end) then 'AVAILABLE'
                     when v_roll < (case when v_weekend then 0.60 else 0.78 end) then 'LIMITED'
                     else 'FULL' end
            when 'LUNCH' then
                case when v_roll < 0.55 then 'AVAILABLE' when v_roll < 0.85 then 'LIMITED' else 'FULL' end
            else
                case when v_roll < 0.80 then 'AVAILABLE' else 'LIMITED' end
        end::public.live_status;

        v_tables := case v_status
            when 'AVAILABLE' then 2 + floor(random() * 7)::smallint
            when 'LIMITED' then 1 + floor(random() * 2)::smallint
            else null
        end;
        v_wait := case v_status
            when 'AVAILABLE' then (array[null, 0, 0, 5])[1 + floor(random() * 4)::int]
            when 'LIMITED' then (array[5, 10, 15, 20])[1 + floor(random() * 4)::int]
            else (array[20, 30, 45, null])[1 + floor(random() * 4)::int]
        end;
        v_note := case v_status
            when 'AVAILABLE' then (array[null, null, 'Tavoli anche all''aperto', 'Sala interna libera', 'Posti al bancone'])[1 + floor(random() * 5)::int]
            when 'LIMITED' then (array[null, 'Ultimi tavoli per 2', 'Solo al bancone', 'Attesa breve'])[1 + floor(random() * 4)::int]
            else (array[null, 'Pieno fino alle 21:30', 'Solo asporto', 'Riprova tra mezz''ora'])[1 + floor(random() * 4)::int]
        end;

        insert into public.restaurant_live_status (
            restaurant_id, status, available_tables, estimated_wait_minutes, note, updated_at, valid_until, updated_via
        ) values (
            r.id, v_status, v_tables, v_wait, v_note, v_now, v_now + interval '30 minutes', 'DEV_SIMULATOR'
        )
        on conflict (restaurant_id) do update set
            status = excluded.status,
            available_tables = excluded.available_tables,
            estimated_wait_minutes = excluded.estimated_wait_minutes,
            note = excluded.note,
            updated_at = excluded.updated_at,
            valid_until = excluded.valid_until,
            updated_via = excluded.updated_via;

        insert into public.status_history (
            restaurant_id, status, available_tables, estimated_wait_minutes, note, updated_at, valid_until, updated_via
        ) values (
            r.id, v_status, v_tables, v_wait, v_note, v_now, v_now + interval '30 minutes', 'DEV_SIMULATOR'
        );
        v_count := v_count + 1;
    end loop;

    return v_count;
end;
$$;

revoke execute on function public.dev_tools_enabled() from public;
revoke execute on function public.dev_publish_live_status(uuid, public.live_status, smallint, smallint, varchar) from public;
revoke execute on function public.dev_simulate_live_activity() from public, anon, authenticated;
grant execute on function public.dev_tools_enabled() to anon, authenticated;
grant execute on function public.dev_publish_live_status(uuid, public.live_status, smallint, smallint, varchar) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3) Pianificazione ogni 5 minuti (serve l'estensione pg_cron:
--    Dashboard → Database → Extensions → cerca "pg_cron" → Enable).
-- ---------------------------------------------------------------------------
do $$
begin
    if exists (select 1 from pg_extension where extname = 'pg_cron') then
        execute $cron$select cron.schedule('haposto-dev-simulator', '*/5 * * * *', 'select public.dev_simulate_live_activity()')$cron$;
        raise notice 'Simulatore pianificato ogni 5 minuti (job haposto-dev-simulator).';
    else
        raise notice 'pg_cron non attivo: abilitalo e riesegui questo file, oppure lancia a mano: select public.dev_simulate_live_activity();';
    end if;
end;
$$;

-- Primo giro subito, così non si aspetta il cron.
select public.dev_simulate_live_activity() as locali_aggiornati_ora;
