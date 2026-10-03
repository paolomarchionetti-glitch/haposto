-- HAPOSTO — Modello di pagamento: prezzi IVA inclusa, semestrale, prova per ogni locale,
-- "Non collegato" per chi non ha un piano, avvisi prima della scadenza.
--
-- Esegui DOPO 0015. Rieseguibile (anche più volte, in ordine dopo le altre).
--
-- Decisioni del titolare (2 ottobre 2026, prezzi provvisori):
--   - ristoranti, piano unico Pro: 19,90 € al mese, 99,90 € per 6 mesi, 199,90 € l'anno, IVA inclusa;
--   - utenti, Plus: 0,99 € al mese, 4,99 € per 6 mesi, 9,99 € l'anno, IVA inclusa;
--   - beta: tutti Pro fino alla data in app_config 'beta'; chi diventa partner dopo ha una prova
--     di N giorni (app_config 'restaurant_trial', 30 di partenza, modificabile dal pannello admin);
--     chi entra poco prima della fine della beta ha comunque i suoi N giorni;
--   - finita la prova, senza abbonamento il locale resta nella lista come "Non collegato": niente
--     stato, niente offerta, niente link e file, e non può pubblicare (SUBSCRIPTION_REQUIRED).
--
-- Le app già installate continuano a funzionare: le funzioni pubbliche mantengono le stesse colonne.

-- ---------------------------------------------------------------------------
-- 1) Prezzi (IVA inclusa) e periodo semestrale.
-- ---------------------------------------------------------------------------
alter table public.plans
    add column if not exists price_semester_cents integer
        check (price_semester_cents is null or price_semester_cents >= 0);
alter table public.plans add column if not exists stripe_price_semester text;

update public.plans
set price_month_cents = 1990, price_semester_cents = 9990, price_year_cents = 19990,
    prices_include_vat = true, updated_at = now()
where code = 'RESTAURANT_PRO';

update public.plans
set price_month_cents = 99, price_semester_cents = 499, price_year_cents = 999,
    prices_include_vat = true, updated_at = now()
where code = 'CONSUMER_PLUS';

-- "Basic" non è più un piano gratuito: è il locale senza piano, che non pubblica lo stato.
update public.plans
set name = 'Nessun piano',
    tagline = 'Locale non collegato: lo stato non si pubblica',
    price_month_cents = null, price_semester_cents = null, price_year_cents = null,
    features = array['ANALYTICS_BASIC'],
    limits = '{"staff_accounts": 0, "analytics_days": 7}'::jsonb,
    is_public = false,
    updated_at = now()
where code = 'RESTAURANT_BASIC';

alter table public.restaurant_subscriptions
    drop constraint if exists restaurant_subscriptions_billing_interval_check;
alter table public.restaurant_subscriptions
    add constraint restaurant_subscriptions_billing_interval_check
    check (billing_interval in ('MONTH', 'SEMESTER', 'YEAR'));

-- ---------------------------------------------------------------------------
-- 2) Da quando il locale è partner (inizio della prova). Solo la prima volta: tornare partner
--    dopo essere usciti non regala un'altra prova (l'admin può sempre dare mesi di Pro).
-- ---------------------------------------------------------------------------
alter table public.restaurants add column if not exists partner_since timestamptz;

update public.restaurants r
set partner_since = coalesce(
    (select max(c.reviewed_at) from public.restaurant_claims c
     where c.restaurant_id = r.id and c.status = 'APPROVED'),
    r.created_at,
    now()
)
where r.partnership_status = 'ACTIVE_PARTNER' and r.partner_since is null;

create or replace function public.set_partner_since()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    if new.partnership_status = 'ACTIVE_PARTNER' and new.partner_since is null then
        new.partner_since := now();
    end if;
    return new;
end;
$$;

drop trigger if exists restaurants_partner_since on public.restaurants;
create trigger restaurants_partner_since
    before insert or update of partnership_status on public.restaurants
    for each row execute function public.set_partner_since();

-- ---------------------------------------------------------------------------
-- 3) Durata della prova, modificabile dal pannello admin (Impostazioni → restaurant_trial).
-- ---------------------------------------------------------------------------
insert into public.app_config (key, value, description) values
    ('restaurant_trial', '{"days": 30}',
     'Giorni di prova gratuita per ogni locale da quando diventa partner (0–365). Vale anche per chi entra poco prima della fine della beta.')
on conflict (key) do nothing;

create or replace function public.admin_set_config(p_key text, p_value jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_old jsonb;
begin
    perform public.assert_admin();
    if p_key not in ('beta', 'security', 'min_supported_app_version', 'public_links', 'legal',
                     'dev_tools_enabled', 'restaurant_trial') then
        raise exception 'CONFIG_KEY_NOT_EDITABLE';
    end if;
    if p_value is null then
        raise exception 'INVALID_CONFIG_VALUE';
    end if;
    if p_key = 'restaurant_trial' and (
        jsonb_typeof(p_value -> 'days') is distinct from 'number'
        or (p_value ->> 'days')::numeric not between 0 and 365
        or (p_value ->> 'days')::numeric <> trunc((p_value ->> 'days')::numeric)
    ) then
        raise exception 'INVALID_CONFIG_VALUE';
    end if;
    select c.value into v_old from public.app_config c where c.key = p_key for update;
    insert into public.app_config (key, value) values (p_key, p_value)
    on conflict (key) do update set value = excluded.value, updated_at = now();
    perform public.log_audit('CONFIG_CHANGED', null, null,
        jsonb_build_object('key', p_key, 'from', v_old, 'to', p_value));
end;
$$;

-- ---------------------------------------------------------------------------
-- 4) Quale piano vale adesso: abbonamento → prova (beta compresa) → nessun piano.
-- ---------------------------------------------------------------------------
-- Fine del periodo gratuito del locale: il più tardi tra fine beta e inizio partner + giorni di prova.
create or replace function public.restaurant_trial_until(p_restaurant_id uuid)
returns timestamptz
language sql
stable
security definer
set search_path = ''
as $$
    select nullif(greatest(
        coalesce((select (c.value ->> 'restaurants_all_pro_until')::timestamptz
                  from public.app_config c where c.key = 'beta'), '-infinity'::timestamptz),
        coalesce((select r.partner_since
                         + make_interval(days => coalesce(
                             (select (c.value ->> 'days')::integer from public.app_config c
                              where c.key = 'restaurant_trial'), 30))
                  from public.restaurants r where r.id = p_restaurant_id), '-infinity'::timestamptz)
    ), '-infinity'::timestamptz);
$$;

-- Abbonamento che vale adesso (3 giorni di tolleranza se il rinnovo è in ritardo).
create or replace function public.restaurant_live_subscription(p_restaurant_id uuid)
returns public.restaurant_subscriptions
language sql
stable
security definer
set search_path = ''
as $$
    select s.*
    from public.restaurant_subscriptions s
    where s.restaurant_id = p_restaurant_id
      and s.status in ('TRIALING', 'ACTIVE', 'PAST_DUE')
      and (s.current_period_end is null or s.current_period_end > now() - interval '3 days')
    order by s.created_at desc
    limit 1;
$$;

create or replace function public.restaurant_plan_code(p_restaurant_id uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
    select coalesce(
        (select s.plan_code from public.restaurant_live_subscription(p_restaurant_id) s where s.id is not null),
        case when public.restaurant_trial_until(p_restaurant_id) > now() then 'RESTAURANT_PRO' end,
        'RESTAURANT_BASIC'
    );
$$;

-- Fonte: STRIPE / MANUAL / BETA (abbonamento), BETA (beta generale), TRIAL (prova del locale),
-- NONE (nessun piano: "Non collegato").
create or replace function public.restaurant_entitlements(p_restaurant_id uuid)
returns table (
    plan_code text,
    plan_name text,
    features text[],
    limits jsonb,
    source text,
    valid_until timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_code text;
    v_sub public.restaurant_subscriptions;
    v_trial timestamptz;
    v_beta timestamptz;
begin
    if public.restaurant_role(p_restaurant_id) is null and not public.is_platform_admin() then
        raise exception 'Not authorized for this restaurant';
    end if;

    v_code := public.restaurant_plan_code(p_restaurant_id);
    v_sub := public.restaurant_live_subscription(p_restaurant_id);
    v_trial := public.restaurant_trial_until(p_restaurant_id);
    v_beta := public.config_value('beta', 'restaurants_all_pro_until')::timestamptz;

    return query
    select p.code, p.name, p.features, p.limits,
           case
               when v_sub.id is not null then v_sub.provider
               when v_trial > now() then case when v_beta is not null and v_beta >= v_trial then 'BETA' else 'TRIAL' end
               else 'NONE'
           end,
           case
               when v_sub.id is not null then v_sub.current_period_end
               when v_trial > now() then v_trial
           end
    from public.plans p
    where p.code = v_code;
end;
$$;

-- Il locale si vede "collegato" (stato, offerta, link e file) solo se partner e con un piano.
create or replace function public.restaurant_is_connected(p_restaurant_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    -- CASE: il piano si calcola solo per i partner (la directory ha migliaia di locali).
    select coalesce(
        (select case when r.partnership_status = 'ACTIVE_PARTNER'
                     then public.restaurant_has_feature(r.id, 'LIVE_STATUS') else false end
         from public.restaurants r where r.id = p_restaurant_id),
        false
    );
$$;

-- ---------------------------------------------------------------------------
-- 5) Senza piano non si pubblica. Il controllo sta sulla tabella, così vale per ogni versione
--    della funzione di pubblicazione (anche le app vecchie). Le scritture del server, dei seed
--    e degli strumenti DEV (senza utente) non sono toccate.
-- ---------------------------------------------------------------------------
create or replace function public.enforce_live_status_plan()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    if auth.uid() is not null
       and new.updated_via in ('OWNER', 'STAFF')
       and not public.restaurant_has_feature(new.restaurant_id, 'LIVE_STATUS') then
        raise exception 'SUBSCRIPTION_REQUIRED';
    end if;
    return new;
end;
$$;

drop trigger if exists restaurant_live_status_plan on public.restaurant_live_status;
create trigger restaurant_live_status_plan
    before insert or update on public.restaurant_live_status
    for each row execute function public.enforce_live_status_plan();

-- ---------------------------------------------------------------------------
-- 6) Letture pubbliche: un partner senza piano appare come "solo directory" (Non collegato).
--    Stesse colonne della 0015.
-- ---------------------------------------------------------------------------
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
        case when r.partnership_status = 'ACTIVE_PARTNER' and not k.connected
             then 'DIRECTORY_ONLY'::public.partnership_status
             else r.partnership_status end as partnership_status,
        case when k.connected then s.status else null end as live_status,
        case when k.connected then s.updated_at else null end as live_updated_at,
        case when k.connected then s.valid_until else null end as live_valid_until,
        case when k.connected then s.available_tables else null end as available_tables,
        case when k.connected then s.estimated_wait_minutes else null end as estimated_wait_minutes,
        case when k.connected then s.note else null end as note,
        extensions.st_y(r.location::extensions.geometry) as latitude,
        extensions.st_x(r.location::extensions.geometry) as longitude,
        extensions.st_distance(
            r.location,
            extensions.st_point(long, lat)::extensions.geography
        ) as distance_meters,
        case when k.connected and s.valid_until > now() then s.offer else null end as offer
    from public.restaurants r
    cross join lateral (
        select case when r.partnership_status = 'ACTIVE_PARTNER'
                    then public.restaurant_has_feature(r.id, 'LIVE_STATUS') else false end as connected
    ) k
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
    select r.slug, r.opening_hours,
           case when k.connected then r.website_url end,
           case when k.connected then r.menu_url end,
           case when k.connected and (r.file_expires_at is null or r.file_expires_at > now()) then r.file_path end,
           case when k.connected and (r.file_expires_at is null or r.file_expires_at > now()) then r.file_mime end,
           k.connected and r.file_path is not null and r.file_expires_at is not null and r.file_expires_at > now()
    from public.restaurants r
    cross join lateral (select public.restaurant_is_connected(r.id) as connected) k
    where r.id = p_restaurant_id and r.partnership_status <> 'SUSPENDED';
$$;

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
        case when r.partnership_status = 'ACTIVE_PARTNER' and not k.connected
             then 'DIRECTORY_ONLY'::public.partnership_status
             else r.partnership_status end,
        case when k.connected then s.status end,
        case when k.connected then s.updated_at end,
        case when k.connected then s.valid_until end,
        case when k.connected then s.available_tables end,
        case when k.connected then s.estimated_wait_minutes end,
        case when k.connected then s.note end,
        extensions.st_y(r.location::extensions.geometry),
        extensions.st_x(r.location::extensions.geometry),
        case when k.connected and s.valid_until > now() then s.offer end,
        case when k.connected then r.website_url end,
        case when k.connected then r.menu_url end,
        case when k.connected and (r.file_expires_at is null or r.file_expires_at > now()) then r.file_path end,
        case when k.connected and (r.file_expires_at is null or r.file_expires_at > now()) then r.file_mime end
    from public.restaurants r
    cross join lateral (select public.restaurant_is_connected(r.id) as connected) k
    left join public.restaurant_live_status s on s.restaurant_id = r.id
    where r.slug = lower(btrim(p_slug))
      and r.partnership_status <> 'SUSPENDED';
$$;

-- ---------------------------------------------------------------------------
-- 7) Avvisi al titolare 7 giorni e 1 giorno prima che il periodo pagato o gratuito finisca
--    (non per gli abbonamenti Stripe che si rinnovano da soli). Un avviso per scadenza.
-- ---------------------------------------------------------------------------
create table if not exists public.plan_expiry_notices (
    restaurant_id uuid not null references public.restaurants(id) on delete cascade,
    ends_at timestamptz not null,
    days_before smallint not null check (days_before in (1, 7)),
    created_at timestamptz not null default now(),
    primary key (restaurant_id, ends_at, days_before)
);

alter table public.plan_expiry_notices enable row level security;
revoke all on table public.plan_expiry_notices from public, anon, authenticated;
grant select, insert, update, delete on table public.plan_expiry_notices to service_role;

-- Fine del periodo che vale adesso: null se si rinnova da solo o se il locale non ha piano.
create or replace function public.restaurant_plan_ends_at(p_restaurant_id uuid)
returns timestamptz
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_sub public.restaurant_subscriptions := public.restaurant_live_subscription(p_restaurant_id);
    v_trial timestamptz := public.restaurant_trial_until(p_restaurant_id);
begin
    if v_sub.id is not null then
        if v_sub.provider = 'STRIPE' and not v_sub.cancel_at_period_end then
            return null;
        end if;
        return v_sub.current_period_end;
    end if;
    if v_trial > now() then
        return v_trial;
    end if;
    return null;
end;
$$;

create or replace function public.enqueue_plan_expiry_notices()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_restaurant record;
    v_days smallint;
    v_count integer := 0;
    v_date text;
begin
    for v_restaurant in
        select r.id, r.name, public.restaurant_plan_ends_at(r.id) as ends_at
        from public.restaurants r
        where r.partnership_status = 'ACTIVE_PARTNER'
    loop
        continue when v_restaurant.ends_at is null
                   or v_restaurant.ends_at <= now()
                   or v_restaurant.ends_at > now() + interval '7 days';
        v_days := case when v_restaurant.ends_at <= now() + interval '1 day' then 1 else 7 end;

        insert into public.plan_expiry_notices (restaurant_id, ends_at, days_before)
        values (v_restaurant.id, v_restaurant.ends_at, v_days)
        on conflict do nothing;
        continue when not found;

        v_date := to_char(v_restaurant.ends_at at time zone 'Europe/Rome', 'DD/MM/YYYY');
        insert into public.notification_outbox (user_id, kind, restaurant_id, title, body, data)
        select ru.user_id, 'SYSTEM', v_restaurant.id,
               case when v_days = 1 then 'Il piano del locale scade domani' else 'Il piano del locale scade tra pochi giorni' end,
               -- Solo informazioni: la notifica passa dall'app, dove non si invita al pagamento.
               left(v_restaurant.name, 80) || ': il piano finisce il ' || v_date
                   || '. Poi il locale appare "Non collegato" e lo stato non si pubblica. Info: info@haposto.app',
               jsonb_build_object('type', 'PLAN_EXPIRING', 'ends_at', v_restaurant.ends_at)
        from public.restaurant_users ru
        where ru.restaurant_id = v_restaurant.id and ru.role = 'OWNER';
        v_count := v_count + 1;
    end loop;
    return v_count;
end;
$$;

-- ---------------------------------------------------------------------------
-- 8) Permessi.
-- ---------------------------------------------------------------------------
revoke execute on function public.set_partner_since() from public, anon, authenticated;
revoke execute on function public.enforce_live_status_plan() from public, anon, authenticated;
revoke execute on function public.restaurant_trial_until(uuid) from public, anon, authenticated;
revoke execute on function public.restaurant_live_subscription(uuid) from public, anon, authenticated;
revoke execute on function public.restaurant_is_connected(uuid) from public, anon, authenticated;
revoke execute on function public.restaurant_plan_ends_at(uuid) from public, anon, authenticated;
revoke execute on function public.enqueue_plan_expiry_notices() from public, anon, authenticated;
grant execute on function public.restaurant_trial_until(uuid) to service_role;
grant execute on function public.restaurant_live_subscription(uuid) to service_role;
grant execute on function public.restaurant_is_connected(uuid) to service_role;
grant execute on function public.restaurant_plan_ends_at(uuid) to service_role;
grant execute on function public.enqueue_plan_expiry_notices() to service_role;

revoke all on function public.nearby_restaurants(double precision, double precision, integer, text) from public;
grant execute on function public.nearby_restaurants(double precision, double precision, integer, text) to anon, authenticated;
revoke all on function public.restaurant_public_details(uuid) from public;
grant execute on function public.restaurant_public_details(uuid) to anon, authenticated;
revoke all on function public.public_restaurant_page(text) from public;
grant execute on function public.public_restaurant_page(text) to anon, authenticated;

-- Controllo finale: prezzi, prova e trigger al loro posto.
select
    (select price_month_cents || '/' || price_semester_cents || '/' || price_year_cents
     from public.plans where code = 'RESTAURANT_PRO') as prezzi_pro,
    (select price_month_cents || '/' || price_semester_cents || '/' || price_year_cents
     from public.plans where code = 'CONSUMER_PLUS') as prezzi_plus,
    (select value ->> 'days' from public.app_config where key = 'restaurant_trial') as giorni_di_prova,
    (select count(*) from pg_trigger where tgname in ('restaurant_live_status_plan', 'restaurants_partner_since')) as controlli;
