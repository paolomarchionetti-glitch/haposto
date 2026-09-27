-- HAPOSTO STEP 12 + 17 — Pagina pubblica/QR, statistiche per il ristoratore, import directory reale.
--
-- Esegui DOPO 0010.

-- ---------------------------------------------------------------------------
-- 1) Indirizzo leggibile per la pagina pubblica: haposto.app/<slug>
-- ---------------------------------------------------------------------------
alter table public.restaurants add column if not exists slug text;
alter table public.restaurants drop constraint if exists restaurants_slug_format;
alter table public.restaurants add constraint restaurants_slug_format
    check (slug is null or slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$');
create unique index if not exists restaurants_slug_uidx on public.restaurants (slug);

create or replace function public.slugify(p_text text)
returns text
language sql
immutable
set search_path = ''
as $$
    select btrim(
        regexp_replace(
            translate(lower(coalesce(p_text, '')),
                      'àáâäãèéêëìíîïòóôöõùúûüçñ''’',
                      'aaaaaeeeeiiiiooooouuuucn  '),
            '[^a-z0-9]+', '-', 'g'),
        '-');
$$;

create or replace function public.assign_restaurant_slug()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_base text;
    v_candidate text;
    v_n integer := 1;
begin
    if new.slug is not null then
        return new;
    end if;
    v_base := left(public.slugify(new.name || '-' || new.city), 70);
    if v_base = '' then
        v_base := 'locale';
    end if;
    v_candidate := v_base;
    while exists (select 1 from public.restaurants r where r.slug = v_candidate and r.id <> new.id) loop
        v_n := v_n + 1;
        v_candidate := v_base || '-' || v_n;
    end loop;
    new.slug := v_candidate;
    return new;
end;
$$;

drop trigger if exists restaurants_assign_slug on public.restaurants;
create trigger restaurants_assign_slug
    before insert or update of name, city, slug on public.restaurants
    for each row execute function public.assign_restaurant_slug();

-- Locali già presenti: l'update fa scattare il trigger, che assegna lo slug.
update public.restaurants set slug = null where slug is null;

-- Dati per la pagina pubblica: stessa forma di nearby_restaurants (senza distanza) + slug.
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
    longitude double precision
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
        extensions.st_x(r.location::extensions.geometry)
    from public.restaurants r
    left join public.restaurant_live_status s on s.restaurant_id = r.id
    where r.slug = lower(btrim(p_slug))
      and r.partnership_status <> 'SUSPENDED';
$$;

-- ---------------------------------------------------------------------------
-- 2) Statistiche giornaliere, anonime (nessun dato dell'utente: solo contatori).
-- ---------------------------------------------------------------------------
create table if not exists public.restaurant_daily_stats (
    restaurant_id uuid not null references public.restaurants(id) on delete cascade,
    day date not null,
    detail_views integer not null default 0,
    directions_taps integer not null default 0,
    call_taps integer not null default 0,
    public_page_views integer not null default 0,
    shares integer not null default 0,
    live_updates integer not null default 0,
    primary key (restaurant_id, day)
);

create or replace function public.track_restaurant_event(p_restaurant_id uuid, p_event text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_day date := (now() at time zone 'Europe/Rome')::date;
begin
    if p_event not in ('DETAIL_VIEW', 'DIRECTIONS_TAP', 'CALL_TAP', 'PUBLIC_PAGE_VIEW', 'SHARE') then
        raise exception 'INVALID_EVENT';
    end if;
    if not exists (select 1 from public.restaurants r where r.id = p_restaurant_id) then
        return;
    end if;

    insert into public.restaurant_daily_stats as st (
        restaurant_id, day, detail_views, directions_taps, call_taps, public_page_views, shares
    ) values (
        p_restaurant_id, v_day,
        (p_event = 'DETAIL_VIEW')::integer,
        (p_event = 'DIRECTIONS_TAP')::integer,
        (p_event = 'CALL_TAP')::integer,
        (p_event = 'PUBLIC_PAGE_VIEW')::integer,
        (p_event = 'SHARE')::integer
    )
    on conflict (restaurant_id, day) do update set
        detail_views = st.detail_views + excluded.detail_views,
        directions_taps = st.directions_taps + excluded.directions_taps,
        call_taps = st.call_taps + excluded.call_taps,
        public_page_views = st.public_page_views + excluded.public_page_views,
        shares = st.shares + excluded.shares;
end;
$$;

-- Ogni pubblicazione dello stato conta come "aggiornamento" nelle statistiche.
create or replace function public.count_live_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    insert into public.restaurant_daily_stats as st (restaurant_id, day, live_updates)
    values (new.restaurant_id, (new.updated_at at time zone 'Europe/Rome')::date, 1)
    on conflict (restaurant_id, day) do update set live_updates = st.live_updates + 1;
    return new;
end;
$$;

drop trigger if exists status_history_count_update on public.status_history;
create trigger status_history_count_update
    after insert on public.status_history
    for each row execute function public.count_live_update();

-- Statistiche per il ristoratore: Basic vede 7 giorni, Pro 90 (limite "analytics_days" del piano).
create or replace function public.restaurant_stats(p_restaurant_id uuid, p_days integer default 30)
returns table (
    day date,
    detail_views integer,
    directions_taps integer,
    call_taps integer,
    public_page_views integer,
    shares integer,
    live_updates integer
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_days integer;
begin
    if public.restaurant_role(p_restaurant_id) is null and not public.is_platform_admin() then
        raise exception 'Not authorized for this restaurant';
    end if;
    v_days := least(greatest(coalesce(p_days, 30), 1),
                    greatest(public.restaurant_limit(p_restaurant_id, 'analytics_days'), 1));

    return query
    select st.day, st.detail_views, st.directions_taps, st.call_taps,
           st.public_page_views, st.shares, st.live_updates
    from public.restaurant_daily_stats st
    where st.restaurant_id = p_restaurant_id
      and st.day > (now() at time zone 'Europe/Rome')::date - v_days
    order by st.day desc;
end;
$$;

-- ---------------------------------------------------------------------------
-- 3) Import di una directory reale (es. OpenStreetMap) come locali DIRECTORY_ONLY.
--    Per OpenStreetMap usa supabase/ops/import_osm_overpass.sql (carica lo staging e importa).
--    Altre fonti: righe in directory_import_staging (Table Editor → Import CSV), poi
--    select * from public.admin_import_directory('NOME_FONTE');
-- ---------------------------------------------------------------------------
create table if not exists public.directory_import_staging (
    source_ref text primary key,
    name text not null,
    category text,
    address text,
    city text not null,
    province text,
    latitude double precision not null,
    longitude double precision not null,
    phone_number text,
    imported_at timestamptz not null default now()
);

create or replace function public.admin_import_directory(p_data_source text default 'OSM_IMPORT')
returns table (inserted integer, updated integer, skipped integer)
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_inserted integer := 0;
    v_updated integer := 0;
    v_total integer;
begin
    -- Dall'app serve un amministratore; dal SQL Editor (nessun utente) è consentito.
    if auth.uid() is not null and not public.is_platform_admin() then
        raise exception 'ADMIN_REQUIRED';
    end if;
    if p_data_source not in ('OSM_IMPORT', 'MANUAL') then
        raise exception 'INVALID_DATA_SOURCE';
    end if;

    select count(*) into v_total from public.directory_import_staging;

    -- Aggiorna solo i locali ancora "solo directory": i dati di un partner li gestisce lui.
    update public.restaurants r
    set name = left(btrim(st.name), 160),
        category = coalesce(nullif(btrim(st.category), ''), r.category),
        address = coalesce(nullif(btrim(st.address), ''), r.address),
        city = left(btrim(st.city), 100),
        province = upper(coalesce(nullif(btrim(st.province), ''), r.province)),
        location = extensions.st_point(st.longitude, st.latitude)::extensions.geography
    from public.directory_import_staging st
    where r.data_source = p_data_source
      and r.source_ref = st.source_ref
      and r.partnership_status = 'DIRECTORY_ONLY';
    get diagnostics v_updated = row_count;

    insert into public.restaurants (
        name, category, address, city, province, location,
        phone_number, phone_public, partnership_status, data_source, source_ref
    )
    select left(btrim(st.name), 160),
           coalesce(nullif(btrim(st.category), ''), 'Ristorante'),
           coalesce(nullif(btrim(st.address), ''), btrim(st.city)),
           left(btrim(st.city), 100),
           upper(coalesce(nullif(btrim(st.province), ''), 'PU')),
           extensions.st_point(st.longitude, st.latitude)::extensions.geography,
           nullif(btrim(coalesce(st.phone_number, '')), ''),
           false,
           'DIRECTORY_ONLY',
           p_data_source,
           st.source_ref
    from public.directory_import_staging st
    where btrim(st.name) <> ''
      and st.latitude between -90 and 90
      and st.longitude between -180 and 180
      -- Qualsiasi fonte: un locale importato e poi corretto a mano (data_source = 'MANUAL',
      -- stesso source_ref) non viene né duplicato né sovrascritto.
      and not exists (
          select 1 from public.restaurants r
          where r.source_ref = st.source_ref
      );
    get diagnostics v_inserted = row_count;

    return query select v_inserted, v_updated, greatest(v_total - v_inserted - v_updated, 0);
end;
$$;

-- ---------------------------------------------------------------------------
-- 4) Accessi.
-- ---------------------------------------------------------------------------
alter table public.restaurant_daily_stats enable row level security;
alter table public.directory_import_staging enable row level security;
revoke all on table public.restaurant_daily_stats from anon, authenticated;
revoke all on table public.directory_import_staging from anon, authenticated;
-- Nessuna policy: le statistiche si leggono con restaurant_stats(); lo staging solo da SQL Editor.

revoke execute on function public.slugify(text) from public, anon, authenticated;
revoke execute on function public.assign_restaurant_slug() from public, anon, authenticated;
revoke execute on function public.count_live_update() from public, anon, authenticated;
revoke execute on function public.admin_import_directory(text) from public, anon;
revoke execute on function public.restaurant_stats(uuid, integer) from public, anon;
revoke execute on function public.public_restaurant_page(text) from public;
revoke execute on function public.track_restaurant_event(uuid, text) from public;

-- Lo slug è pubblico per natura (è il link condivisibile): leggibile come le altre colonne della directory.
grant select (slug) on table public.restaurants to anon, authenticated;

grant execute on function public.public_restaurant_page(text) to anon, authenticated;
grant execute on function public.track_restaurant_event(uuid, text) to anon, authenticated;
grant execute on function public.restaurant_stats(uuid, integer) to authenticated;
grant execute on function public.admin_import_directory(text) to authenticated;
