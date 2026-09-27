-- HAPOSTO STEP 7.9 — Permessi più stretti, provenienza dei dati, configurazione pubblica.
--
-- Esegui DOPO 0001–0004. (0005 resta riservata allo Step 10 / Realtime.)
-- Rieseguibile: ogni istruzione controlla se l'oggetto esiste già.

-- ---------------------------------------------------------------------------
-- 1) Funzioni di scrittura: niente EXECUTE per gli utenti anonimi.
--    Su Supabase le nuove funzioni in "public" ricevono EXECUTE anche per anon
--    tramite i default privileges: "revoke ... from public" (0004) non basta.
--    set_restaurant_live_status resta comunque protetta dal controllo di membership.
-- ---------------------------------------------------------------------------
revoke execute on function public.set_restaurant_live_status(uuid, public.live_status, smallint, smallint, varchar) from anon;
revoke execute on function public.is_restaurant_member(uuid) from anon;

-- ---------------------------------------------------------------------------
-- 2) Provenienza di ogni locale.
--    MANUAL          inserito a mano dall'amministratore
--    DEV_SEED        dato di test (da cancellare prima della produzione)
--    OSM_IMPORT      importato da OpenStreetMap (licenza ODbL: attribuzione obbligatoria)
--    PARTNER_SIGNUP  creato dal ristoratore stesso durante la registrazione
-- ---------------------------------------------------------------------------
alter table public.restaurants
    add column if not exists data_source text not null default 'MANUAL',
    add column if not exists source_ref text;

alter table public.restaurants drop constraint if exists restaurants_data_source_check;
alter table public.restaurants add constraint restaurants_data_source_check
    check (data_source in ('MANUAL', 'DEV_SEED', 'OSM_IMPORT', 'PARTNER_SIGNUP'));

create unique index if not exists restaurants_source_ref_uidx
    on public.restaurants (data_source, source_ref)
    where source_ref is not null;

-- Il seed dimostrativo dello Step 7 (id 10000000-…) è dato di test.
update public.restaurants
set data_source = 'DEV_SEED'
where id::text like '10000000-0000-0000-0000-%'
  and data_source = 'MANUAL';

-- ---------------------------------------------------------------------------
-- 3) Chi ha pubblicato lo stato LIVE (statistiche, simulatore DEV, audit).
-- ---------------------------------------------------------------------------
alter table public.restaurant_live_status
    add column if not exists updated_via text not null default 'OWNER';
alter table public.restaurant_live_status drop constraint if exists restaurant_live_status_updated_via_check;
alter table public.restaurant_live_status add constraint restaurant_live_status_updated_via_check
    check (updated_via in ('OWNER', 'STAFF', 'ADMIN', 'DEV_APP', 'DEV_SIMULATOR'));

alter table public.status_history
    add column if not exists updated_via text not null default 'OWNER';
alter table public.status_history drop constraint if exists status_history_updated_via_check;
alter table public.status_history add constraint status_history_updated_via_check
    check (updated_via in ('OWNER', 'STAFF', 'ADMIN', 'DEV_APP', 'DEV_SIMULATOR'));

-- ---------------------------------------------------------------------------
-- 4) updated_at automatico sui locali.
-- ---------------------------------------------------------------------------
create or replace function public.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

drop trigger if exists restaurants_touch_updated_at on public.restaurants;
create trigger restaurants_touch_updated_at
    before update on public.restaurants
    for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- 5) Configurazione pubblica dell'app (leggibile da tutti).
--    MAI inserire qui chiavi, password o altri segreti.
-- ---------------------------------------------------------------------------
create table if not exists public.app_config (
    key text primary key check (key ~ '^[a-z0-9_]{2,60}$'),
    value jsonb not null,
    description text,
    updated_at timestamptz not null default now()
);

alter table public.app_config enable row level security;
revoke all on table public.app_config from anon, authenticated;
grant select on table public.app_config to anon, authenticated;

drop policy if exists "app_config_public_read" on public.app_config;
create policy "app_config_public_read"
on public.app_config
for select
to anon, authenticated
using (true);

insert into public.app_config (key, value, description) values
    ('beta', '{"restaurants_all_pro_until": "2027-06-30T23:59:59Z"}',
     'Durante la beta tutti i ristoranti hanno le funzioni PRO senza pagare.'),
    ('min_supported_app_version', '8',
     'versionCode minimo supportato: sotto questa soglia l''app può chiedere di aggiornarsi.'),
    ('dev_tools_enabled', 'false',
     'Solo progetti DEV: abilita dev_publish_live_status (vedi supabase/dev/dev_tools.sql).')
on conflict (key) do nothing;
