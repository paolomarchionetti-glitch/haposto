-- HAPOSTO — Note pronte, link e file del locale, offerta della serata.
--
-- Esegui DOPO 0014. Rieseguibile. Se riesegui una migration precedente, riesegui poi anche questa
-- (questa ridefinisce funzioni create da 0003, 0011, 0012, 0013).
-- Le app già installate continuano a funzionare (ignorano i campi nuovi); le novità si vedono con
-- l'app aggiornata.
--
-- Cosa aggiunge:
--   1. Note pronte del locale (al massimo 8, 80 caratteri): le vedono titolare e staff.
--   2. Due link pubblici (sito e menù) e UN file facoltativo (foto o PDF piccolo), anche "solo per
--      oggi" (si cancella la notte dopo). I file li carica solo la Edge Function restaurant-file,
--      che controlla davvero tipo e dimensione; nel database restano solo nome, tipo e peso.
--   3. Controllo dell'admin dopo la pubblicazione: elenco "da controllare", Visto / Rimuovi.
--   4. Offerta della serata (60 caratteri, facoltativa) pubblicata con lo stato e che scade con lo
--      stato; solo con "C'è posto" o "Pochi posti".
--   5. Pulizia notturna dei file scaduti o non più usati (Edge Function + pg_cron, guida 6.3).

-- ---------------------------------------------------------------------------
-- 1) Regole dei dati.
-- ---------------------------------------------------------------------------
create or replace function public.valid_quick_notes(p_notes text[])
returns boolean
language sql
immutable
set search_path = ''
as $$
    select coalesce(cardinality(p_notes), 0) <= 8
       and not exists (
           select 1 from unnest(coalesce(p_notes, '{}'::text[])) as n
           where n is null or char_length(btrim(n)) not between 1 and 80
       );
$$;

create or replace function public.valid_public_link(p_url text)
returns boolean
language sql
immutable
set search_path = ''
as $$
    select p_url is null
        or (char_length(p_url) <= 300
            and p_url ~ '^https?://[A-Za-z0-9.-]+\.[A-Za-z]{2,}(:[0-9]{2,5})?(/[^[:space:]]*)?$');
$$;

alter table public.restaurants
    add column if not exists quick_notes text[] not null default '{}'::text[],
    add column if not exists website_url text,
    add column if not exists menu_url text,
    add column if not exists file_path text,
    add column if not exists file_mime text,
    add column if not exists file_bytes integer,
    add column if not exists file_expires_at timestamptz,
    add column if not exists extras_changed_at timestamptz,
    add column if not exists extras_reviewed_at timestamptz;

alter table public.restaurants drop constraint if exists restaurants_quick_notes_check;
alter table public.restaurants add constraint restaurants_quick_notes_check
    check (public.valid_quick_notes(quick_notes));
alter table public.restaurants drop constraint if exists restaurants_links_check;
alter table public.restaurants add constraint restaurants_links_check
    check (public.valid_public_link(website_url) and public.valid_public_link(menu_url));
-- Immagini al massimo 1 MB (l'app le riduce a ~300–500 KB), PDF al massimo 2 MB.
alter table public.restaurants drop constraint if exists restaurants_file_check;
alter table public.restaurants add constraint restaurants_file_check check (
    (file_path is null and file_mime is null and file_bytes is null and file_expires_at is null)
    or (file_path ~ '^[0-9a-f-]{36}/[A-Za-z0-9_.-]{1,80}$'
        and ((file_mime in ('image/jpeg', 'image/webp') and file_bytes between 1 and 1048576)
             or (file_mime = 'application/pdf' and file_bytes between 1 and 2097152)))
);

alter table public.restaurant_live_status add column if not exists offer varchar(60);
alter table public.status_history add column if not exists offer varchar(60);

-- Contenitore dei file (pubblico in lettura; si scrive solo con la chiave del server).
-- In un Postgres senza Supabase (CI) lo schema storage non c'è: si salta.
do $$
begin
    if to_regclass('storage.buckets') is not null then
        insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
        values ('restaurant-files', 'restaurant-files', true, 2097152,
                array['image/jpeg', 'image/webp', 'application/pdf'])
        on conflict (id) do update set
            public = excluded.public,
            file_size_limit = excluded.file_size_limit,
            allowed_mime_types = excluded.allowed_mime_types;
    end if;
end;
$$;

-- Quando un locale non ha più titolare (account cancellato, rivendicazione revocata) torna "solo
-- directory": via note, link e file messi da chi lo gestiva (il file lo cancella la pulizia).
create or replace function public.clear_extras_when_unclaimed()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    if new.partnership_status = 'DIRECTORY_ONLY' and old.partnership_status is distinct from 'DIRECTORY_ONLY' then
        new.quick_notes := '{}'::text[];
        new.website_url := null;
        new.menu_url := null;
        new.file_path := null;
        new.file_mime := null;
        new.file_bytes := null;
        new.file_expires_at := null;
        new.extras_changed_at := null;
        new.extras_reviewed_at := null;
    end if;
    return new;
end;
$$;

drop trigger if exists restaurants_clear_extras_when_unclaimed on public.restaurants;
create trigger restaurants_clear_extras_when_unclaimed
    before update of partnership_status on public.restaurants
    for each row execute function public.clear_extras_when_unclaimed();

-- ---------------------------------------------------------------------------
-- 2) Pubblicazione dello stato con l'offerta della serata.
--    La versione nuova ha 6 parametri, tutti obbligatori (l'app li manda sempre); quella di 0012
--    con 5 parametri resta per le app più vecchie e i test, e passa la mano alla nuova.
-- ---------------------------------------------------------------------------
create or replace function public.set_restaurant_live_status(
    p_restaurant_id uuid,
    p_status public.live_status,
    p_available_tables smallint,
    p_estimated_wait_minutes smallint,
    p_note varchar(80),
    p_offer varchar(60)
)
returns public.restaurant_live_status
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_now timestamptz := now();
    v_role public.restaurant_user_role;
    v_details boolean;
    v_partnership public.partnership_status;
    v_available_tables smallint;
    v_wait smallint;
    v_note varchar(80);
    v_offer text;
    v_via text;
    v_limit integer := coalesce(public.config_value('security', 'max_publish_per_10min')::integer, 30);
    v_row public.restaurant_live_status;
begin
    perform public.assert_active_user();
    v_role := public.restaurant_role(p_restaurant_id);
    if v_role is null then
        raise exception 'Not authorized for this restaurant';
    end if;
    perform public.assert_restaurant_mfa();
    v_via := case when v_role = 'STAFF' then 'STAFF' else 'OWNER' end;

    select r.partnership_status into v_partnership from public.restaurants r where r.id = p_restaurant_id;
    if v_partnership = 'SUSPENDED' then
        raise exception 'RESTAURANT_SUSPENDED';
    end if;
    if v_partnership is distinct from 'ACTIVE_PARTNER' then
        raise exception 'Restaurant is not an active partner';
    end if;

    if (select count(*) from public.status_history h
        where h.restaurant_id = p_restaurant_id and h.updated_at > v_now - interval '10 minutes') >= v_limit then
        raise exception 'RATE_LIMITED';
    end if;

    v_details := public.restaurant_has_feature(p_restaurant_id, 'LIVE_DETAILS');
    v_available_tables := case when p_status = 'FULL' or not v_details then null else p_available_tables end;
    v_wait := case when v_details then p_estimated_wait_minutes end;
    v_note := case when v_details then nullif(trim(p_note), '') end;
    -- L'offerta ha senso solo se c'è posto; scade con lo stato (la riga si riscrive a ogni pubblicazione).
    v_offer := case when v_details and p_status <> 'FULL' then nullif(btrim(p_offer), '') end;

    if v_available_tables is not null and v_available_tables not between 0 and 99 then
        raise exception 'available_tables must be between 0 and 99';
    end if;
    if v_wait is not null and v_wait not between 0 and 240 then
        raise exception 'estimated_wait_minutes must be between 0 and 240';
    end if;
    if v_offer is not null and char_length(v_offer) > 60 then
        raise exception 'OFFER_TOO_LONG';
    end if;

    insert into public.restaurant_live_status (
        restaurant_id, status, available_tables, estimated_wait_minutes, note, offer,
        updated_at, valid_until, updated_via
    ) values (
        p_restaurant_id, p_status, v_available_tables, v_wait, v_note, v_offer,
        v_now, v_now + interval '30 minutes', v_via
    )
    on conflict (restaurant_id) do update set
        status = excluded.status,
        available_tables = excluded.available_tables,
        estimated_wait_minutes = excluded.estimated_wait_minutes,
        note = excluded.note,
        offer = excluded.offer,
        updated_at = excluded.updated_at,
        valid_until = excluded.valid_until,
        updated_via = excluded.updated_via
    returning * into v_row;

    insert into public.status_history (
        restaurant_id, status, available_tables, estimated_wait_minutes, note, offer,
        updated_at, valid_until, updated_by, updated_via
    ) values (
        v_row.restaurant_id, v_row.status, v_row.available_tables, v_row.estimated_wait_minutes,
        v_row.note, v_row.offer, v_row.updated_at, v_row.valid_until, auth.uid(), v_row.updated_via
    );

    return v_row;
end;
$$;

create or replace function public.set_restaurant_live_status(
    p_restaurant_id uuid,
    p_status public.live_status,
    p_available_tables smallint default null,
    p_estimated_wait_minutes smallint default null,
    p_note varchar(80) default null
)
returns public.restaurant_live_status
language sql
security definer
set search_path = ''
as $$
    select * from public.set_restaurant_live_status(
        p_restaurant_id, p_status, p_available_tables, p_estimated_wait_minutes, p_note, null::varchar
    );
$$;

-- ---------------------------------------------------------------------------
-- 3) Lettura pubblica: lista (con l'offerta), dettagli e pagina del QR (con link e file).
-- ---------------------------------------------------------------------------
drop function if exists public.nearby_restaurants(double precision, double precision, integer, text);

create or replace function public.nearby_restaurants(
    lat double precision,
    long double precision,
    radius_meters integer default 60000,
    search_text text default null
)
returns table (
    id uuid,
    name text,
    category text,
    address text,
    city text,
    province text,
    phone_number text,
    phone_public boolean,
    partnership_status public.partnership_status,
    live_status public.live_status,
    live_updated_at timestamptz,
    live_valid_until timestamptz,
    available_tables smallint,
    estimated_wait_minutes smallint,
    note varchar(80),
    latitude double precision,
    longitude double precision,
    distance_meters double precision,
    offer varchar(60)
)
language sql
stable
security definer
set search_path = ''
as $$
    select
        r.id,
        r.name,
        r.category,
        r.address,
        r.city,
        r.province,
        case when r.phone_public then r.phone_number else null end as phone_number,
        r.phone_public,
        r.partnership_status,
        case when r.partnership_status = 'ACTIVE_PARTNER' then s.status else null end as live_status,
        case when r.partnership_status = 'ACTIVE_PARTNER' then s.updated_at else null end as live_updated_at,
        case when r.partnership_status = 'ACTIVE_PARTNER' then s.valid_until else null end as live_valid_until,
        case when r.partnership_status = 'ACTIVE_PARTNER' then s.available_tables else null end as available_tables,
        case when r.partnership_status = 'ACTIVE_PARTNER' then s.estimated_wait_minutes else null end as estimated_wait_minutes,
        case when r.partnership_status = 'ACTIVE_PARTNER' then s.note else null end as note,
        extensions.st_y(r.location::extensions.geometry) as latitude,
        extensions.st_x(r.location::extensions.geometry) as longitude,
        extensions.st_distance(
            r.location,
            extensions.st_point(long, lat)::extensions.geography
        ) as distance_meters,
        case when r.partnership_status = 'ACTIVE_PARTNER' and s.valid_until > now() then s.offer else null end as offer
    from public.restaurants r
    left join public.restaurant_live_status s on s.restaurant_id = r.id
    where r.partnership_status <> 'SUSPENDED'
      and extensions.st_dwithin(
          r.location,
          extensions.st_point(long, lat)::extensions.geography,
          least(greatest(radius_meters, 0), 100000)
      )
      and (
          search_text is null
          or btrim(search_text) = ''
          or lower(r.name) like '%' || lower(btrim(search_text)) || '%'
          or lower(r.category) like '%' || lower(btrim(search_text)) || '%'
          or lower(r.city) like '%' || lower(btrim(search_text)) || '%'
          or extensions.similarity(r.name, btrim(search_text)) >= 0.25
          or extensions.similarity(r.category, btrim(search_text)) >= 0.25
      )
    order by r.location operator(extensions.<->)
        extensions.st_point(long, lat)::extensions.geography;
$$;

drop function if exists public.restaurant_public_details(uuid);

create or replace function public.restaurant_public_details(p_restaurant_id uuid)
returns table (
    slug text,
    opening_hours jsonb,
    website_url text,
    menu_url text,
    file_path text,
    file_mime text,
    file_today_only boolean
)
language sql
stable
security definer
set search_path = ''
as $$
    select r.slug, r.opening_hours, r.website_url, r.menu_url,
           case when r.file_expires_at is null or r.file_expires_at > now() then r.file_path end,
           case when r.file_expires_at is null or r.file_expires_at > now() then r.file_mime end,
           r.file_path is not null and r.file_expires_at is not null and r.file_expires_at > now()
    from public.restaurants r
    where r.id = p_restaurant_id and r.partnership_status <> 'SUSPENDED';
$$;

drop function if exists public.public_restaurant_page(text);

create or replace function public.public_restaurant_page(p_slug text)
returns table (
    id uuid,
    slug text,
    name text,
    category text,
    address text,
    city text,
    province text,
    phone_number text,
    phone_public boolean,
    partnership_status public.partnership_status,
    live_status public.live_status,
    live_updated_at timestamptz,
    live_valid_until timestamptz,
    available_tables smallint,
    estimated_wait_minutes smallint,
    note varchar(80),
    latitude double precision,
    longitude double precision,
    offer varchar(60),
    website_url text,
    menu_url text,
    file_path text,
    file_mime text
)
language sql
stable
security definer
set search_path = ''
as $$
    select
        r.id, r.slug, r.name, r.category, r.address, r.city, r.province,
        case when r.phone_public then r.phone_number else null end,
        r.phone_public,
        r.partnership_status,
        case when r.partnership_status = 'ACTIVE_PARTNER' then s.status end,
        case when r.partnership_status = 'ACTIVE_PARTNER' then s.updated_at end,
        case when r.partnership_status = 'ACTIVE_PARTNER' then s.valid_until end,
        case when r.partnership_status = 'ACTIVE_PARTNER' then s.available_tables end,
        case when r.partnership_status = 'ACTIVE_PARTNER' then s.estimated_wait_minutes end,
        case when r.partnership_status = 'ACTIVE_PARTNER' then s.note end,
        extensions.st_y(r.location::extensions.geometry),
        extensions.st_x(r.location::extensions.geometry),
        case when r.partnership_status = 'ACTIVE_PARTNER' and s.valid_until > now() then s.offer end,
        r.website_url,
        r.menu_url,
        case when r.file_expires_at is null or r.file_expires_at > now() then r.file_path end,
        case when r.file_expires_at is null or r.file_expires_at > now() then r.file_mime end
    from public.restaurants r
    left join public.restaurant_live_status s on s.restaurant_id = r.id
    where r.slug = lower(btrim(p_slug))
      and r.partnership_status <> 'SUSPENDED';
$$;

-- ---------------------------------------------------------------------------
-- 4) Titolare e staff: note pronte, link, stato del file.
-- ---------------------------------------------------------------------------
create or replace function public.restaurant_extras(p_restaurant_id uuid)
returns table (
    quick_notes text[],
    website_url text,
    menu_url text,
    file_path text,
    file_mime text,
    file_bytes integer,
    file_expires_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
begin
    if public.restaurant_role(p_restaurant_id) is null then
        raise exception 'Not authorized for this restaurant';
    end if;
    return query
    select r.quick_notes, r.website_url, r.menu_url,
           case when r.file_expires_at is null or r.file_expires_at > now() then r.file_path end,
           case when r.file_expires_at is null or r.file_expires_at > now() then r.file_mime end,
           case when r.file_expires_at is null or r.file_expires_at > now() then r.file_bytes end,
           case when r.file_expires_at is null or r.file_expires_at > now() then r.file_expires_at end
    from public.restaurants r
    where r.id = p_restaurant_id;
end;
$$;

-- Controlli comuni: account attivo, membro (o titolare), 2FA, locale non sospeso.
create or replace function public.assert_can_edit_restaurant(p_restaurant_id uuid, p_owner_only boolean)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
    perform public.assert_active_user();
    if p_owner_only and not public.is_restaurant_owner(p_restaurant_id) then
        raise exception 'OWNER_REQUIRED';
    end if;
    if not p_owner_only and public.restaurant_role(p_restaurant_id) is null then
        raise exception 'Not authorized for this restaurant';
    end if;
    perform public.assert_restaurant_mfa();
    if (select r.partnership_status from public.restaurants r where r.id = p_restaurant_id) = 'SUSPENDED' then
        raise exception 'RESTAURANT_SUSPENDED';
    end if;
end;
$$;

-- Note pronte: titolare e staff; spazi in più tolti, doppioni tolti, al massimo 8.
create or replace function public.set_restaurant_quick_notes(p_restaurant_id uuid, p_notes text[])
returns text[]
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_clean text[];
begin
    perform public.assert_can_edit_restaurant(p_restaurant_id, false);
    select coalesce(array_agg(clean order by ord), '{}'::text[]) into v_clean
    from (
        select distinct on (lower(clean)) clean, ord
        from (
            select btrim(regexp_replace(coalesce(n, ''), '\s+', ' ', 'g')) as clean, ord
            from unnest(coalesce(p_notes, '{}'::text[])) with ordinality as t(n, ord)
        ) as cleaned
        where clean <> ''
        order by lower(clean), ord
    ) as unique_notes;
    if cardinality(v_clean) > 8 then
        raise exception 'QUICK_NOTES_LIMIT';
    end if;
    if exists (select 1 from unnest(v_clean) as n where char_length(n) > 80) then
        raise exception 'NOTE_TOO_LONG';
    end if;
    update public.restaurants set quick_notes = v_clean where id = p_restaurant_id;
    perform public.log_audit('QUICK_NOTES_UPDATED', p_restaurant_id, null,
        jsonb_build_object('count', cardinality(v_clean)));
    return v_clean;
end;
$$;

-- Link del sito e del menù: solo il titolare. "www.sito.it" diventa "https://www.sito.it".
create or replace function public.set_restaurant_links(p_restaurant_id uuid, p_website_url text, p_menu_url text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_website text := nullif(btrim(coalesce(p_website_url, '')), '');
    v_menu text := nullif(btrim(coalesce(p_menu_url, '')), '');
    v_old record;
begin
    perform public.assert_can_edit_restaurant(p_restaurant_id, true);
    if v_website is not null and v_website !~* '^https?://' then
        v_website := 'https://' || v_website;
    end if;
    if v_menu is not null and v_menu !~* '^https?://' then
        v_menu := 'https://' || v_menu;
    end if;
    if not public.valid_public_link(v_website) or not public.valid_public_link(v_menu) then
        raise exception 'INVALID_LINK';
    end if;
    select r.website_url, r.menu_url into v_old from public.restaurants r where r.id = p_restaurant_id;
    if v_old.website_url is not distinct from v_website and v_old.menu_url is not distinct from v_menu then
        return;
    end if;
    update public.restaurants
    set website_url = v_website, menu_url = v_menu, extras_changed_at = now(), extras_reviewed_at = null
    where id = p_restaurant_id;
    perform public.log_audit('LINKS_UPDATED', p_restaurant_id, null,
        jsonb_build_object('website_url', v_website, 'menu_url', v_menu));
end;
$$;

-- ---------------------------------------------------------------------------
-- 5) File: controllo prima del caricamento (come utente), registrazione (solo server).
-- ---------------------------------------------------------------------------
create or replace function public.restaurant_file_check(p_restaurant_id uuid)
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
    perform public.assert_can_edit_restaurant(p_restaurant_id, true);
    if (select r.partnership_status from public.restaurants r where r.id = p_restaurant_id) <> 'ACTIVE_PARTNER' then
        raise exception 'Restaurant is not an active partner';
    end if;
end;
$$;

-- Registra il file appena caricato e restituisce quello vecchio, da cancellare.
create or replace function public.restaurant_file_attach(
    p_restaurant_id uuid,
    p_user_id uuid,
    p_path text,
    p_mime text,
    p_bytes integer,
    p_today_only boolean
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_old text;
    v_expires timestamptz;
begin
    select r.file_path into v_old from public.restaurants r where r.id = p_restaurant_id for update;
    if not found then
        raise exception 'RESTAURANT_NOT_FOUND';
    end if;
    -- "Solo per oggi": fino alle 4 di notte (ora italiana).
    v_expires := case when p_today_only then
        ((now() at time zone 'Europe/Rome')::date + 1 + time '04:00') at time zone 'Europe/Rome'
    end;
    update public.restaurants
    set file_path = p_path, file_mime = p_mime, file_bytes = p_bytes, file_expires_at = v_expires,
        extras_changed_at = now(), extras_reviewed_at = null
    where id = p_restaurant_id;
    perform public.log_audit('FILE_UPLOADED', p_restaurant_id, p_user_id,
        jsonb_build_object('mime', p_mime, 'bytes', p_bytes, 'today_only', p_today_only));
    return nullif(v_old, p_path);
end;
$$;

create or replace function public.restaurant_file_detach(p_restaurant_id uuid, p_user_id uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_old text;
begin
    select r.file_path into v_old from public.restaurants r where r.id = p_restaurant_id for update;
    if v_old is null then
        return null;
    end if;
    update public.restaurants
    set file_path = null, file_mime = null, file_bytes = null, file_expires_at = null
    where id = p_restaurant_id;
    perform public.log_audit('FILE_REMOVED', p_restaurant_id, p_user_id, '{}'::jsonb);
    return v_old;
end;
$$;

-- Pulizia notturna: file scaduti ("solo per oggi") e file del contenitore che nessun locale usa
-- più (sostituiti, tolti dall'admin, locale tornato "solo directory"). Restituisce i nomi da
-- cancellare dal contenitore (lo fa la Edge Function: i file non si cancellano con l'SQL).
create or replace function public.restaurant_files_cleanup()
returns setof text
language plpgsql
security definer
set search_path = ''
as $$
begin
    update public.restaurants
    set file_path = null, file_mime = null, file_bytes = null, file_expires_at = null
    where file_expires_at is not null and file_expires_at <= now();

    if to_regclass('storage.objects') is null then
        return;
    end if;
    return query execute $q$
        select o.name
        from storage.objects o
        where o.bucket_id = 'restaurant-files'
          and o.created_at < now() - interval '1 hour'
          and not exists (select 1 from public.restaurants r where r.file_path = o.name)
        order by o.created_at
        limit 500
    $q$;
end;
$$;

-- ---------------------------------------------------------------------------
-- 6) Pannello admin: link e file da controllare.
-- ---------------------------------------------------------------------------
create or replace function public.admin_list_restaurant_extras(p_only_unreviewed boolean default true, p_limit integer default 100)
returns table (
    restaurant_id uuid,
    name text,
    city text,
    website_url text,
    menu_url text,
    file_path text,
    file_mime text,
    file_bytes integer,
    file_expires_at timestamptz,
    changed_at timestamptz,
    reviewed_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
begin
    perform public.assert_admin();
    return query
    select r.id, r.name, r.city, r.website_url, r.menu_url, r.file_path, r.file_mime, r.file_bytes,
           r.file_expires_at, r.extras_changed_at, r.extras_reviewed_at
    from public.restaurants r
    where (r.website_url is not null or r.menu_url is not null or r.file_path is not null)
      and (not p_only_unreviewed or r.extras_reviewed_at is null
           or r.extras_reviewed_at < r.extras_changed_at)
    order by r.extras_changed_at desc nulls last
    limit least(greatest(coalesce(p_limit, 100), 1), 500);
end;
$$;

-- p_action: OK (visto), REMOVE_LINKS, REMOVE_FILE, REMOVE_ALL.
create or replace function public.admin_review_restaurant_extras(p_restaurant_id uuid, p_action text, p_reason text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    perform public.assert_admin();
    if p_action not in ('OK', 'REMOVE_LINKS', 'REMOVE_FILE', 'REMOVE_ALL') then
        raise exception 'INVALID_ACTION';
    end if;
    update public.restaurants
    set website_url = case when p_action in ('REMOVE_LINKS', 'REMOVE_ALL') then null else website_url end,
        menu_url = case when p_action in ('REMOVE_LINKS', 'REMOVE_ALL') then null else menu_url end,
        file_path = case when p_action in ('REMOVE_FILE', 'REMOVE_ALL') then null else file_path end,
        file_mime = case when p_action in ('REMOVE_FILE', 'REMOVE_ALL') then null else file_mime end,
        file_bytes = case when p_action in ('REMOVE_FILE', 'REMOVE_ALL') then null else file_bytes end,
        file_expires_at = case when p_action in ('REMOVE_FILE', 'REMOVE_ALL') then null else file_expires_at end,
        extras_reviewed_at = now()
    where id = p_restaurant_id;
    if not found then
        raise exception 'RESTAURANT_NOT_FOUND';
    end if;
    perform public.log_audit('ADMIN_EXTRAS_' || p_action, p_restaurant_id, null,
        jsonb_build_object('reason', p_reason));
end;
$$;

-- ---------------------------------------------------------------------------
-- 7) Permessi.
-- ---------------------------------------------------------------------------
revoke execute on function public.valid_quick_notes(text[]) from public, anon, authenticated;
revoke execute on function public.valid_public_link(text) from public, anon, authenticated;
revoke execute on function public.clear_extras_when_unclaimed() from public, anon, authenticated;
revoke execute on function public.assert_can_edit_restaurant(uuid, boolean) from public, anon, authenticated;

revoke all on function public.nearby_restaurants(double precision, double precision, integer, text) from public;
grant execute on function public.nearby_restaurants(double precision, double precision, integer, text) to anon, authenticated;
revoke all on function public.restaurant_public_details(uuid) from public;
grant execute on function public.restaurant_public_details(uuid) to anon, authenticated;
revoke all on function public.public_restaurant_page(text) from public;
grant execute on function public.public_restaurant_page(text) to anon, authenticated;

do $$
declare
    v_fn text;
begin
    foreach v_fn in array array[
        'public.set_restaurant_live_status(uuid, public.live_status, smallint, smallint, varchar, varchar)',
        'public.set_restaurant_live_status(uuid, public.live_status, smallint, smallint, varchar)',
        'public.restaurant_extras(uuid)',
        'public.set_restaurant_quick_notes(uuid, text[])',
        'public.set_restaurant_links(uuid, text, text)',
        'public.restaurant_file_check(uuid)',
        'public.admin_list_restaurant_extras(boolean, integer)',
        'public.admin_review_restaurant_extras(uuid, text, text)'
    ] loop
        execute format('revoke execute on function %s from public, anon', v_fn);
        execute format('grant execute on function %s to authenticated', v_fn);
    end loop;
    foreach v_fn in array array[
        'public.restaurant_file_attach(uuid, uuid, text, text, integer, boolean)',
        'public.restaurant_file_detach(uuid, uuid)',
        'public.restaurant_files_cleanup()'
    ] loop
        execute format('revoke execute on function %s from public, anon, authenticated', v_fn);
        execute format('grant execute on function %s to service_role', v_fn);
    end loop;
end;
$$;

-- Controllo: colonne nuove (atteso 5) e due versioni della pubblicazione (5 e 6 parametri).
select
    (select count(*) from information_schema.columns
     where table_schema = 'public'
       and ((table_name = 'restaurants' and column_name in ('quick_notes', 'website_url', 'menu_url', 'file_path'))
            or (table_name = 'restaurant_live_status' and column_name = 'offer'))) as colonne_nuove,
    (select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
     where n.nspname = 'public' and p.proname = 'set_restaurant_live_status') as versioni_pubblicazione;
