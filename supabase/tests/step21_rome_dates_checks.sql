-- HAPOSTO — Verifica automatica della migration 0017: "oggi" in ora italiana nelle pulizie e nel
-- pannello admin, fonte e scadenza del piano nella scheda del locale.
--
-- Tutto avviene in una transazione annullata alla fine: non lascia tracce.
-- Prerequisiti: migration 0001–0017, seed 900 caricato (in locale gli utenti di prova si creano da sé).
--
-- Esito atteso: righe "ok: …" e, in fondo, "CONTROLLI DATE ITALIANE SUPERATI".

begin;

create function pg_temp.act_as(p_email text, p_aal text default 'aal2')
returns void language plpgsql as $$
declare
    v_id uuid;
begin
    if p_email = 'postgres' then
        execute 'reset role';
        perform set_config('request.jwt.claim.sub', '', true);
        perform set_config('request.jwt.claims', '', true);
    elsif p_email is null then
        perform set_config('request.jwt.claim.sub', '', true);
        perform set_config('request.jwt.claims', '{"role": "anon"}', true);
        execute 'set local role anon';
    elsif p_email = 'service_role' then
        perform set_config('request.jwt.claim.sub', '', true);
        perform set_config('request.jwt.claims', '{"role": "service_role"}', true);
        execute 'set local role service_role';
    else
        execute 'reset role';
        select id into v_id from auth.users where email = p_email;
        perform set_config('request.jwt.claim.sub', v_id::text, true);
        perform set_config('request.jwt.claims',
            json_build_object('sub', v_id, 'role', 'authenticated', 'aal', p_aal,
                              'session_id', 'sessione-di-prova-' || v_id)::text, true);
        execute 'set local role authenticated';
    end if;
end;
$$;

create function pg_temp.uid(p_email text) returns uuid language sql security definer as $$
    select id from auth.users where email = p_email
$$;

create function pg_temp.expect(p_ok boolean, p_what text) returns void language plpgsql as $$
begin
    if p_ok is distinct from true then
        raise exception 'FAIL: %', p_what;
    end if;
    raise notice 'ok: %', p_what;
end;
$$;

create function pg_temp.expect_error(p_sql text, p_error text, p_what text) returns void language plpgsql as $$
begin
    begin
        execute p_sql;
    exception when others then
        if p_error is not null and position(p_error in sqlerrm) = 0 then
            raise exception 'FAIL: % (errore inatteso: %)', p_what, sqlerrm;
        end if;
        raise notice 'ok: % (rifiutato: %)', p_what, sqlerrm;
        return;
    end;
    raise exception 'FAIL: % (doveva essere rifiutato)', p_what;
end;
$$;

create temporary table test_values (key text primary key, value text) on commit drop;
grant all on test_values to anon, authenticated, service_role;

do $$
begin
    if not exists (select 1 from auth.users where email = 'test-admin@haposto.test') then
        insert into auth.users (id, email, raw_user_meta_data)
        values (gen_random_uuid(), 'test-admin@haposto.test', '{"full_name": "test-admin"}');
    end if;
end;
$$;
insert into public.profiles (id) select id from auth.users where email = 'test-admin@haposto.test'
on conflict (id) do nothing;
select public.admin_set_credentials('test-admin@haposto.test', 'test.admin', 'password-di-prova-123');

-- ---------------------------------------------------------------------------
-- 1. Il giorno di oggi è quello italiano.
-- ---------------------------------------------------------------------------
select pg_temp.expect(public.today_rome() = (now() at time zone 'Europe/Rome')::date,
    'oggi: la data italiana, non quella UTC');
select pg_temp.act_as(null);
select pg_temp.expect_error($q$select public.today_rome()$q$, 'permission denied', 'anon: funzione solo per il database');

-- ---------------------------------------------------------------------------
-- 2. Pulizia delle prenotazioni: via quelle più vecchie di 30 giorni italiani, il resto resta.
-- ---------------------------------------------------------------------------
select pg_temp.act_as('postgres');
delete from public.reservations where restaurant_id = '10000000-0000-0000-0000-000000000006';
insert into public.reservations (restaurant_id, client_id, reservation_date, party_size, customer_name) values
    ('10000000-0000-0000-0000-000000000006', gen_random_uuid(), public.today_rome() - 31, 2, 'Vecchia'),
    ('10000000-0000-0000-0000-000000000006', gen_random_uuid(), public.today_rome() - 30, 2, 'Al limite'),
    ('10000000-0000-0000-0000-000000000006', gen_random_uuid(), public.today_rome(), 2, 'Di oggi');
select public.purge_old_reservations(30);
select pg_temp.expect((select string_agg(customer_name, ',' order by customer_name) from public.reservations
                       where restaurant_id = '10000000-0000-0000-0000-000000000006') = 'Al limite,Di oggi',
    'pulizia prenotazioni: tolte solo quelle oltre i 30 giorni');
select pg_temp.expect((public.purge_operational_data() ? 'daily_stats'), 'pulizia dati operativi: funziona');

-- ---------------------------------------------------------------------------
-- 3. Pannello admin: piano del locale con fonte, scadenza e inizio partner.
-- ---------------------------------------------------------------------------
update public.app_config set value = '{"restaurants_all_pro_until": "2099-01-01T00:00:00Z"}' where key = 'beta';
update public.restaurants set partnership_status = 'ACTIVE_PARTNER' where id = '10000000-0000-0000-0000-000000000006';
select pg_temp.act_as('test-admin@haposto.test');
select public.admin_unlock('test.admin', 'password-di-prova-123');
insert into test_values
select 'detail', public.admin_restaurant_detail('10000000-0000-0000-0000-000000000006')::text;
select pg_temp.expect((select value::jsonb ->> 'plan_source' from test_values where key = 'detail') = 'BETA',
    'pannello: fonte del piano (beta)');
select pg_temp.expect((select (value::jsonb ->> 'plan_valid_until') is not null and (value::jsonb ->> 'partner_since') is not null
                       from test_values where key = 'detail'),
    'pannello: scadenza del piano e inizio partner');
select pg_temp.expect((select value::jsonb -> 'stats_30_days' ? 'live_updates' from test_values where key = 'detail'),
    'pannello: statistiche degli ultimi 30 giorni');

select pg_temp.act_as('postgres');
do $$ begin raise notice 'CONTROLLI DATE ITALIANE SUPERATI'; end $$;
select 'CONTROLLI DATE ITALIANE SUPERATI' as esito;

rollback;
