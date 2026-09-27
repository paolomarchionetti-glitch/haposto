-- HAPOSTO STEP 14 — Piani, abbonamenti, pagamenti, dati di fatturazione, diritti (entitlements).
--
-- Esegui DOPO 0007.
-- Principio: il database NON incassa nulla. I pagamenti avvengono su Stripe (ristoranti, via web)
-- o Google Play Billing (utenti Plus, in app). Un webhook lato server (Supabase Edge Function con
-- service_role) registra l'esito qui. L'app legge soltanto: "che piano ho? cosa posso fare?".

-- ---------------------------------------------------------------------------
-- 1) Catalogo dei piani (prezzi INDICATIVI: da confermare prima del lancio).
-- ---------------------------------------------------------------------------
create table if not exists public.plans (
    code text primary key check (code ~ '^[A-Z_]{3,40}$'),
    audience text not null check (audience in ('RESTAURANT', 'CONSUMER')),
    name text not null,
    tagline text,
    price_month_cents integer check (price_month_cents is null or price_month_cents >= 0),
    price_year_cents integer check (price_year_cents is null or price_year_cents >= 0),
    currency char(3) not null default 'EUR',
    prices_include_vat boolean not null,
    features text[] not null default '{}',
    limits jsonb not null default '{}'::jsonb,
    is_public boolean not null default true,
    sort_order integer not null default 0,
    stripe_price_month text,
    stripe_price_year text,
    play_product_id text,
    updated_at timestamptz not null default now(),
    unique (code, audience)
);

insert into public.plans (
    code, audience, name, tagline, price_month_cents, price_year_cents,
    prices_include_vat, features, limits, is_public, sort_order, play_product_id
) values
    ('RESTAURANT_BASIC', 'RESTAURANT', 'Basic', 'Il tuo stato live, gratis per sempre',
     0, 0, false,
     array['LIVE_STATUS', 'PHONE_PUBLIC', 'PUBLIC_PAGE_QR', 'ANALYTICS_BASIC'],
     '{"staff_accounts": 0, "analytics_days": 7}', true, 10, null),
    ('RESTAURANT_PRO', 'RESTAURANT', 'Pro', 'Più coperti, meno telefonate, con i numeri',
     1290, 9900, false,
     array['LIVE_STATUS', 'PHONE_PUBLIC', 'PUBLIC_PAGE_QR', 'ANALYTICS_BASIC', 'LIVE_DETAILS',
           'ANALYTICS', 'STAFF_ACCOUNTS', 'FOLLOWER_NOTIFICATIONS', 'RESERVATIONS_CLOUD', 'REMINDERS'],
     '{"staff_accounts": 5, "analytics_days": 90}', true, 20, null),
    ('RESTAURANT_PRO_PLUS', 'RESTAURANT', 'Pro+', 'Gruppi, integrazioni e API (su richiesta)',
     null, null, false,
     array['LIVE_STATUS', 'PHONE_PUBLIC', 'PUBLIC_PAGE_QR', 'ANALYTICS_BASIC', 'LIVE_DETAILS',
           'ANALYTICS', 'STAFF_ACCOUNTS', 'FOLLOWER_NOTIFICATIONS', 'RESERVATIONS_CLOUD', 'REMINDERS',
           'MULTI_LOCATION', 'API_ACCESS', 'POS_INTEGRATION'],
     '{"staff_accounts": 50, "analytics_days": 365}', false, 30, null),
    ('CONSUMER_FREE', 'CONSUMER', 'Gratis', 'Trova posto adesso, senza account',
     0, 0, true,
     array['SEARCH_LIVE', 'FAVORITES_SYNC'],
     '{"favorites_max": 5, "search_radius_km": 60, "active_alerts_max": 0}', true, 10, null),
    ('CONSUMER_PLUS', 'CONSUMER', 'Plus', 'Avvisami quando si libera un tavolo',
     149, 999, true,
     array['SEARCH_LIVE', 'FAVORITES_SYNC', 'AVAILABILITY_ALERTS', 'ADVANCED_FILTERS',
           'EXTENDED_RADIUS', 'AVAILABILITY_HISTORY'],
     '{"favorites_max": 200, "search_radius_km": 100, "active_alerts_max": 10}', true, 20, 'haposto_plus')
on conflict (code) do nothing;

alter table public.plans enable row level security;
revoke all on table public.plans from anon, authenticated;
grant select on table public.plans to anon, authenticated;

drop policy if exists "plans_public_read" on public.plans;
create policy "plans_public_read"
on public.plans
for select
to anon, authenticated
using (is_public);

drop policy if exists "plans_admin_read" on public.plans;
create policy "plans_admin_read"
on public.plans
for select
to authenticated
using (public.is_platform_admin());

-- ---------------------------------------------------------------------------
-- 2) Abbonamenti ristorante (Stripe web, manuale per il pilot, beta).
-- ---------------------------------------------------------------------------
create table if not exists public.restaurant_subscriptions (
    id uuid primary key default gen_random_uuid(),
    restaurant_id uuid not null references public.restaurants(id) on delete cascade,
    plan_code text not null,
    audience text not null default 'RESTAURANT' check (audience = 'RESTAURANT'),
    status text not null check (status in ('TRIALING', 'ACTIVE', 'PAST_DUE', 'CANCELED', 'EXPIRED')),
    billing_interval text check (billing_interval in ('MONTH', 'YEAR')),
    provider text not null check (provider in ('STRIPE', 'MANUAL', 'BETA')),
    provider_customer_id text,
    provider_subscription_id text,
    current_period_start timestamptz,
    current_period_end timestamptz,
    cancel_at_period_end boolean not null default false,
    note text check (note is null or char_length(note) <= 300),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    foreign key (plan_code, audience) references public.plans(code, audience)
);

create unique index if not exists restaurant_subscriptions_one_live_uidx
    on public.restaurant_subscriptions (restaurant_id)
    where status in ('TRIALING', 'ACTIVE', 'PAST_DUE');

create unique index if not exists restaurant_subscriptions_provider_uidx
    on public.restaurant_subscriptions (provider, provider_subscription_id)
    where provider_subscription_id is not null;

drop trigger if exists restaurant_subscriptions_touch on public.restaurant_subscriptions;
create trigger restaurant_subscriptions_touch
    before update on public.restaurant_subscriptions
    for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- 3) Abbonamenti utente (Plus via Google Play; promo; Stripe solo per eventuale web).
-- ---------------------------------------------------------------------------
create table if not exists public.consumer_subscriptions (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    plan_code text not null,
    audience text not null default 'CONSUMER' check (audience = 'CONSUMER'),
    status text not null check (status in ('TRIALING', 'ACTIVE', 'PAST_DUE', 'CANCELED', 'EXPIRED')),
    provider text not null check (provider in ('GOOGLE_PLAY', 'APP_STORE', 'STRIPE', 'PROMO')),
    provider_purchase_ref text,
    current_period_end timestamptz,
    auto_renewing boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    foreign key (plan_code, audience) references public.plans(code, audience)
);

create unique index if not exists consumer_subscriptions_one_live_uidx
    on public.consumer_subscriptions (user_id)
    where status in ('TRIALING', 'ACTIVE', 'PAST_DUE');

create unique index if not exists consumer_subscriptions_provider_uidx
    on public.consumer_subscriptions (provider, provider_purchase_ref)
    where provider_purchase_ref is not null;

drop trigger if exists consumer_subscriptions_touch on public.consumer_subscriptions;
create trigger consumer_subscriptions_touch
    before update on public.consumer_subscriptions
    for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- 4) Dati di fatturazione del ristorante (fattura elettronica italiana).
-- ---------------------------------------------------------------------------
create table if not exists public.restaurant_billing_profiles (
    restaurant_id uuid primary key references public.restaurants(id) on delete cascade,
    legal_name text not null check (char_length(legal_name) between 2 and 160),
    vat_number text check (vat_number is null or vat_number ~ '^[0-9]{11}$'),
    tax_code text check (tax_code is null or tax_code ~ '^([A-Z0-9]{16}|[0-9]{11})$'),
    sdi_code text check (sdi_code is null or sdi_code ~ '^[A-Z0-9]{7}$'),
    pec_email text check (pec_email is null or pec_email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),
    invoice_email text check (invoice_email is null or invoice_email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'),
    billing_address text not null check (char_length(billing_address) between 3 and 240),
    billing_city text not null check (char_length(billing_city) between 2 and 100),
    billing_postal_code text not null check (billing_postal_code ~ '^[0-9]{5}$'),
    billing_province text not null check (billing_province ~ '^[A-Z]{2}$'),
    country char(2) not null default 'IT',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint billing_has_tax_id check (vat_number is not null or tax_code is not null),
    constraint billing_has_sdi_or_pec check (sdi_code is not null or pec_email is not null)
);

drop trigger if exists restaurant_billing_profiles_touch on public.restaurant_billing_profiles;
create trigger restaurant_billing_profiles_touch
    before update on public.restaurant_billing_profiles
    for each row execute function public.touch_updated_at();

-- ---------------------------------------------------------------------------
-- 5) Registro pagamenti (specchio dei provider) e log eventi webhook (idempotenza).
-- ---------------------------------------------------------------------------
create table if not exists public.payments (
    id uuid primary key default gen_random_uuid(),
    payer_kind text not null check (payer_kind in ('RESTAURANT', 'CONSUMER')),
    -- Pagamenti B2B da conservare ai fini fiscali: il locale non si cancella se ha pagamenti.
    restaurant_id uuid references public.restaurants(id) on delete restrict,
    user_id uuid references auth.users(id) on delete set null,
    provider text not null check (provider in ('STRIPE', 'GOOGLE_PLAY', 'APP_STORE', 'MANUAL')),
    provider_payment_id text not null,
    plan_code text references public.plans(code),
    amount_cents integer not null check (amount_cents >= 0),
    vat_cents integer check (vat_cents is null or vat_cents >= 0),
    currency char(3) not null default 'EUR',
    status text not null check (status in ('PENDING', 'SUCCEEDED', 'FAILED', 'REFUNDED')),
    invoice_number text,
    invoice_url text,
    paid_at timestamptz,
    created_at timestamptz not null default now(),
    unique (provider, provider_payment_id),
    constraint payments_restaurant_has_id check (payer_kind <> 'RESTAURANT' or restaurant_id is not null)
);

create table if not exists public.billing_events (
    id bigint generated always as identity primary key,
    provider text not null,
    event_id text not null,
    event_type text not null,
    payload jsonb not null,
    received_at timestamptz not null default now(),
    processed_at timestamptz,
    error text,
    unique (provider, event_id)
);

-- ---------------------------------------------------------------------------
-- 6) Diritti: quale piano vale adesso e quali funzioni sblocca.
-- ---------------------------------------------------------------------------
create or replace function public.restaurant_plan_code(p_restaurant_id uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
    select coalesce(
        (
            select s.plan_code
            from public.restaurant_subscriptions s
            where s.restaurant_id = p_restaurant_id
              and s.status in ('TRIALING', 'ACTIVE', 'PAST_DUE')
              -- 3 giorni di tolleranza se il rinnovo è in ritardo.
              and (s.current_period_end is null or s.current_period_end > now() - interval '3 days')
            order by s.created_at desc
            limit 1
        ),
        case
            when (select (c.value ->> 'restaurants_all_pro_until')::timestamptz
                  from public.app_config c where c.key = 'beta') > now()
            then 'RESTAURANT_PRO'
        end,
        'RESTAURANT_BASIC'
    );
$$;

create or replace function public.restaurant_has_feature(p_restaurant_id uuid, p_feature text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select coalesce(
        (select p_feature = any(p.features) from public.plans p
         where p.code = public.restaurant_plan_code(p_restaurant_id)),
        false
    );
$$;

create or replace function public.restaurant_limit(p_restaurant_id uuid, p_limit text)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
    select coalesce(
        (select (p.limits ->> p_limit)::integer from public.plans p
         where p.code = public.restaurant_plan_code(p_restaurant_id)),
        0
    );
$$;

create or replace function public.consumer_plan_code(p_user_id uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
    select coalesce(
        (
            select s.plan_code
            from public.consumer_subscriptions s
            where s.user_id = p_user_id
              and s.status in ('TRIALING', 'ACTIVE', 'PAST_DUE')
              and (s.current_period_end is null or s.current_period_end > now() - interval '3 days')
            order by s.created_at desc
            limit 1
        ),
        'CONSUMER_FREE'
    );
$$;

create or replace function public.consumer_has_feature(p_user_id uuid, p_feature text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select coalesce(
        (select p_feature = any(p.features) from public.plans p
         where p.code = public.consumer_plan_code(p_user_id)),
        false
    );
$$;

create or replace function public.consumer_limit(p_user_id uuid, p_limit text)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
    select coalesce(
        (select (p.limits ->> p_limit)::integer from public.plans p
         where p.code = public.consumer_plan_code(p_user_id)),
        0
    );
$$;

-- Per l'app del ristoratore: piano attuale, funzioni, limiti, fonte e scadenza.
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
begin
    if public.restaurant_role(p_restaurant_id) is null and not public.is_platform_admin() then
        raise exception 'Not authorized for this restaurant';
    end if;

    v_code := public.restaurant_plan_code(p_restaurant_id);
    select * into v_sub
    from public.restaurant_subscriptions s
    where s.restaurant_id = p_restaurant_id
      and s.status in ('TRIALING', 'ACTIVE', 'PAST_DUE')
    order by s.created_at desc
    limit 1;

    return query
    select p.code, p.name, p.features, p.limits,
           case
               when v_sub.id is not null then v_sub.provider
               when v_code = 'RESTAURANT_PRO' then 'BETA'
               else 'FREE'
           end,
           case
               when v_sub.id is not null then v_sub.current_period_end
               when v_code = 'RESTAURANT_PRO' then
                   (select (c.value ->> 'restaurants_all_pro_until')::timestamptz
                    from public.app_config c where c.key = 'beta')
           end
    from public.plans p
    where p.code = v_code;
end;
$$;

-- Per l'app dell'utente: senza login risponde "Gratis".
create or replace function public.my_entitlements()
returns table (
    plan_code text,
    plan_name text,
    features text[],
    limits jsonb,
    valid_until timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
    select p.code, p.name, p.features, p.limits,
           (select s.current_period_end from public.consumer_subscriptions s
            where s.user_id = auth.uid() and s.status in ('TRIALING', 'ACTIVE', 'PAST_DUE')
            order by s.created_at desc limit 1)
    from public.plans p
    where p.code = case when auth.uid() is null then 'CONSUMER_FREE'
                        else public.consumer_plan_code(auth.uid()) end;
$$;

-- ---------------------------------------------------------------------------
-- 7) Regole di piano sulla pubblicazione: con BASIC si pubblica lo stato con 1 tap;
--    tavoli, attesa e nota (LIVE_DETAILS) sono PRO. Durante la beta tutti sono PRO.
-- ---------------------------------------------------------------------------
create or replace function public.set_restaurant_live_status(
    p_restaurant_id uuid,
    p_status public.live_status,
    p_available_tables smallint default null,
    p_estimated_wait_minutes smallint default null,
    p_note varchar(80) default null
)
returns public.restaurant_live_status
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_now timestamptz := now();
    v_role public.restaurant_user_role := public.restaurant_role(p_restaurant_id);
    v_details boolean := public.restaurant_has_feature(p_restaurant_id, 'LIVE_DETAILS');
    v_available_tables smallint;
    v_wait smallint;
    v_note varchar(80);
    v_via text;
    v_row public.restaurant_live_status;
begin
    if v_role is null then
        raise exception 'Not authorized for this restaurant';
    end if;
    v_via := case when v_role = 'STAFF' then 'STAFF' else 'OWNER' end;

    if not exists (
        select 1 from public.restaurants r
        where r.id = p_restaurant_id and r.partnership_status = 'ACTIVE_PARTNER'
    ) then
        raise exception 'Restaurant is not an active partner';
    end if;

    v_available_tables := case when p_status = 'FULL' or not v_details then null else p_available_tables end;
    v_wait := case when v_details then p_estimated_wait_minutes end;
    v_note := case when v_details then nullif(trim(p_note), '') end;

    if v_available_tables is not null and v_available_tables not between 0 and 99 then
        raise exception 'available_tables must be between 0 and 99';
    end if;
    if v_wait is not null and v_wait not between 0 and 240 then
        raise exception 'estimated_wait_minutes must be between 0 and 240';
    end if;

    insert into public.restaurant_live_status (
        restaurant_id, status, available_tables, estimated_wait_minutes, note,
        updated_at, valid_until, updated_via
    ) values (
        p_restaurant_id, p_status, v_available_tables, v_wait, v_note,
        v_now, v_now + interval '30 minutes', v_via
    )
    on conflict (restaurant_id) do update set
        status = excluded.status,
        available_tables = excluded.available_tables,
        estimated_wait_minutes = excluded.estimated_wait_minutes,
        note = excluded.note,
        updated_at = excluded.updated_at,
        valid_until = excluded.valid_until,
        updated_via = excluded.updated_via
    returning * into v_row;

    insert into public.status_history (
        restaurant_id, status, available_tables, estimated_wait_minutes, note,
        updated_at, valid_until, updated_by, updated_via
    ) values (
        v_row.restaurant_id, v_row.status, v_row.available_tables, v_row.estimated_wait_minutes,
        v_row.note, v_row.updated_at, v_row.valid_until, auth.uid(), v_row.updated_via
    );

    return v_row;
end;
$$;

-- ---------------------------------------------------------------------------
-- 8) Staff del locale (funzione PRO, con limite per piano).
-- ---------------------------------------------------------------------------
create or replace function public.add_restaurant_staff(p_restaurant_id uuid, p_email text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user uuid;
    v_count integer;
begin
    if not public.is_restaurant_owner(p_restaurant_id) then
        raise exception 'OWNER_REQUIRED';
    end if;
    if not public.restaurant_has_feature(p_restaurant_id, 'STAFF_ACCOUNTS') then
        raise exception 'PLAN_UPGRADE_REQUIRED';
    end if;

    select count(*) into v_count
    from public.restaurant_users ru
    where ru.restaurant_id = p_restaurant_id and ru.role = 'STAFF';
    if v_count >= public.restaurant_limit(p_restaurant_id, 'staff_accounts') then
        raise exception 'STAFF_LIMIT_REACHED';
    end if;

    select u.id into v_user from auth.users u where lower(u.email) = lower(btrim(p_email));
    if v_user is null then
        -- La persona deve prima accedere una volta all'app con quell'email.
        raise exception 'USER_NOT_REGISTERED';
    end if;

    insert into public.restaurant_users (restaurant_id, user_id, role)
    values (p_restaurant_id, v_user, 'STAFF')
    on conflict (restaurant_id, user_id) do nothing;
    return v_user;
end;
$$;

create or replace function public.remove_restaurant_staff(p_restaurant_id uuid, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    if not public.is_restaurant_owner(p_restaurant_id) then
        raise exception 'OWNER_REQUIRED';
    end if;
    delete from public.restaurant_users
    where restaurant_id = p_restaurant_id and user_id = p_user_id and role = 'STAFF';
end;
$$;

-- ---------------------------------------------------------------------------
-- 9) Funzioni riservate al server (webhook Stripe / Google Play con service_role).
-- ---------------------------------------------------------------------------
create or replace function public.billing_log_event(
    p_provider text,
    p_event_id text,
    p_event_type text,
    p_payload jsonb
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_id bigint;
begin
    insert into public.billing_events (provider, event_id, event_type, payload)
    values (p_provider, p_event_id, p_event_type, p_payload)
    on conflict (provider, event_id) do nothing
    returning id into v_id;
    -- false = evento già visto: il webhook non deve rielaborarlo.
    return v_id is not null;
end;
$$;

create or replace function public.billing_upsert_restaurant_subscription(
    p_restaurant_id uuid,
    p_plan_code text,
    p_status text,
    p_billing_interval text,
    p_provider text,
    p_provider_customer_id text,
    p_provider_subscription_id text,
    p_current_period_start timestamptz,
    p_current_period_end timestamptz,
    p_cancel_at_period_end boolean default false
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_id uuid;
begin
    select s.id into v_id
    from public.restaurant_subscriptions s
    where s.provider = p_provider and s.provider_subscription_id = p_provider_subscription_id
    for update;

    if v_id is null and p_status in ('TRIALING', 'ACTIVE', 'PAST_DUE') then
        -- Un nuovo abbonamento attivo sostituisce quello precedente (es. da BETA/MANUAL a STRIPE).
        update public.restaurant_subscriptions
        set status = 'CANCELED'
        where restaurant_id = p_restaurant_id
          and status in ('TRIALING', 'ACTIVE', 'PAST_DUE');
    end if;

    if v_id is null then
        insert into public.restaurant_subscriptions (
            restaurant_id, plan_code, status, billing_interval, provider,
            provider_customer_id, provider_subscription_id,
            current_period_start, current_period_end, cancel_at_period_end
        ) values (
            p_restaurant_id, p_plan_code, p_status, p_billing_interval, p_provider,
            p_provider_customer_id, p_provider_subscription_id,
            p_current_period_start, p_current_period_end, coalesce(p_cancel_at_period_end, false)
        )
        returning id into v_id;
    else
        update public.restaurant_subscriptions
        set plan_code = p_plan_code,
            status = p_status,
            billing_interval = p_billing_interval,
            provider_customer_id = coalesce(p_provider_customer_id, provider_customer_id),
            current_period_start = p_current_period_start,
            current_period_end = p_current_period_end,
            cancel_at_period_end = coalesce(p_cancel_at_period_end, false)
        where id = v_id;
    end if;
    return v_id;
end;
$$;

create or replace function public.billing_upsert_consumer_subscription(
    p_user_id uuid,
    p_plan_code text,
    p_status text,
    p_provider text,
    p_provider_purchase_ref text,
    p_current_period_end timestamptz,
    p_auto_renewing boolean default true
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_id uuid;
begin
    select s.id into v_id
    from public.consumer_subscriptions s
    where s.provider = p_provider and s.provider_purchase_ref = p_provider_purchase_ref
    for update;

    if v_id is null and p_status in ('TRIALING', 'ACTIVE', 'PAST_DUE') then
        update public.consumer_subscriptions
        set status = 'CANCELED'
        where user_id = p_user_id and status in ('TRIALING', 'ACTIVE', 'PAST_DUE');
    end if;

    if v_id is null then
        insert into public.consumer_subscriptions (
            user_id, plan_code, status, provider, provider_purchase_ref, current_period_end, auto_renewing
        ) values (
            p_user_id, p_plan_code, p_status, p_provider, p_provider_purchase_ref,
            p_current_period_end, coalesce(p_auto_renewing, true)
        )
        returning id into v_id;
    else
        update public.consumer_subscriptions
        set plan_code = p_plan_code,
            status = p_status,
            current_period_end = p_current_period_end,
            auto_renewing = coalesce(p_auto_renewing, true)
        where id = v_id;
    end if;
    return v_id;
end;
$$;

create or replace function public.billing_record_payment(
    p_payer_kind text,
    p_restaurant_id uuid,
    p_user_id uuid,
    p_provider text,
    p_provider_payment_id text,
    p_plan_code text,
    p_amount_cents integer,
    p_vat_cents integer,
    p_status text,
    p_invoice_number text,
    p_invoice_url text,
    p_paid_at timestamptz
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_id uuid;
begin
    insert into public.payments (
        payer_kind, restaurant_id, user_id, provider, provider_payment_id, plan_code,
        amount_cents, vat_cents, status, invoice_number, invoice_url, paid_at
    ) values (
        p_payer_kind, p_restaurant_id, p_user_id, p_provider, p_provider_payment_id, p_plan_code,
        p_amount_cents, p_vat_cents, p_status, p_invoice_number, p_invoice_url, p_paid_at
    )
    on conflict (provider, provider_payment_id) do update set
        status = excluded.status,
        invoice_number = coalesce(excluded.invoice_number, public.payments.invoice_number),
        invoice_url = coalesce(excluded.invoice_url, public.payments.invoice_url),
        paid_at = coalesce(excluded.paid_at, public.payments.paid_at)
    returning id into v_id;
    return v_id;
end;
$$;

-- Pilot: l'amministratore regala o registra un piano (bonifico, accordo, prova gratuita).
create or replace function public.admin_grant_restaurant_plan(
    p_restaurant_id uuid,
    p_plan_code text,
    p_months integer,
    p_note text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_id uuid;
begin
    if not public.is_platform_admin() then
        raise exception 'ADMIN_REQUIRED';
    end if;
    if p_months not between 1 and 36 then
        raise exception 'INVALID_MONTHS';
    end if;

    update public.restaurant_subscriptions
    set status = 'CANCELED'
    where restaurant_id = p_restaurant_id and status in ('TRIALING', 'ACTIVE', 'PAST_DUE');

    insert into public.restaurant_subscriptions (
        restaurant_id, plan_code, status, provider, current_period_start, current_period_end, note
    ) values (
        p_restaurant_id, p_plan_code, 'ACTIVE', 'MANUAL', now(),
        now() + make_interval(months => p_months), p_note
    )
    returning id into v_id;
    return v_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- 10) Accessi (RLS): il client legge solo ciò che lo riguarda e non scrive nulla di contabile.
-- ---------------------------------------------------------------------------
alter table public.restaurant_subscriptions enable row level security;
alter table public.consumer_subscriptions enable row level security;
alter table public.restaurant_billing_profiles enable row level security;
alter table public.payments enable row level security;
alter table public.billing_events enable row level security;

revoke all on table public.restaurant_subscriptions from anon, authenticated;
revoke all on table public.consumer_subscriptions from anon, authenticated;
revoke all on table public.restaurant_billing_profiles from anon, authenticated;
revoke all on table public.payments from anon, authenticated;
revoke all on table public.billing_events from anon, authenticated;

grant select on table public.restaurant_subscriptions to authenticated;
grant select on table public.consumer_subscriptions to authenticated;
grant select, insert, update on table public.restaurant_billing_profiles to authenticated;
grant select on table public.payments to authenticated;

drop policy if exists "restaurant_subscriptions_member_read" on public.restaurant_subscriptions;
create policy "restaurant_subscriptions_member_read"
on public.restaurant_subscriptions
for select
to authenticated
using (public.restaurant_role(restaurant_id) is not null or public.is_platform_admin());

drop policy if exists "consumer_subscriptions_own_read" on public.consumer_subscriptions;
create policy "consumer_subscriptions_own_read"
on public.consumer_subscriptions
for select
to authenticated
using (user_id = (select auth.uid()) or public.is_platform_admin());

drop policy if exists "billing_profiles_owner_read" on public.restaurant_billing_profiles;
create policy "billing_profiles_owner_read"
on public.restaurant_billing_profiles
for select
to authenticated
using (public.is_restaurant_owner(restaurant_id) or public.is_platform_admin());

drop policy if exists "billing_profiles_owner_insert" on public.restaurant_billing_profiles;
create policy "billing_profiles_owner_insert"
on public.restaurant_billing_profiles
for insert
to authenticated
with check (public.is_restaurant_owner(restaurant_id));

drop policy if exists "billing_profiles_owner_update" on public.restaurant_billing_profiles;
create policy "billing_profiles_owner_update"
on public.restaurant_billing_profiles
for update
to authenticated
using (public.is_restaurant_owner(restaurant_id))
with check (public.is_restaurant_owner(restaurant_id));

drop policy if exists "payments_payer_read" on public.payments;
create policy "payments_payer_read"
on public.payments
for select
to authenticated
using (
    (payer_kind = 'RESTAURANT' and public.is_restaurant_owner(restaurant_id))
    or (payer_kind = 'CONSUMER' and user_id = (select auth.uid()))
    or public.is_platform_admin()
);
-- billing_events: nessuna policy → leggibile/scrivibile solo da service_role.

-- Funzioni: chi può chiamare cosa.
revoke execute on function public.restaurant_plan_code(uuid) from public, anon;
revoke execute on function public.restaurant_has_feature(uuid, text) from public, anon;
revoke execute on function public.restaurant_limit(uuid, text) from public, anon;
revoke execute on function public.consumer_plan_code(uuid) from public, anon, authenticated;
revoke execute on function public.consumer_has_feature(uuid, text) from public, anon, authenticated;
revoke execute on function public.consumer_limit(uuid, text) from public, anon, authenticated;
revoke execute on function public.restaurant_entitlements(uuid) from public, anon;
revoke execute on function public.add_restaurant_staff(uuid, text) from public, anon;
revoke execute on function public.remove_restaurant_staff(uuid, uuid) from public, anon;
revoke execute on function public.admin_grant_restaurant_plan(uuid, text, integer, text) from public, anon;
revoke execute on function public.set_restaurant_live_status(uuid, public.live_status, smallint, smallint, varchar) from public, anon;

grant execute on function public.restaurant_plan_code(uuid) to authenticated;
grant execute on function public.restaurant_has_feature(uuid, text) to authenticated;
grant execute on function public.restaurant_limit(uuid, text) to authenticated;
grant execute on function public.restaurant_entitlements(uuid) to authenticated;
grant execute on function public.my_entitlements() to anon, authenticated;
grant execute on function public.add_restaurant_staff(uuid, text) to authenticated;
grant execute on function public.remove_restaurant_staff(uuid, uuid) to authenticated;
grant execute on function public.admin_grant_restaurant_plan(uuid, text, integer, text) to authenticated;
grant execute on function public.set_restaurant_live_status(uuid, public.live_status, smallint, smallint, varchar) to authenticated;

revoke execute on function public.billing_log_event(text, text, text, jsonb) from public, anon, authenticated;
revoke execute on function public.billing_upsert_restaurant_subscription(uuid, text, text, text, text, text, text, timestamptz, timestamptz, boolean) from public, anon, authenticated;
revoke execute on function public.billing_upsert_consumer_subscription(uuid, text, text, text, text, timestamptz, boolean) from public, anon, authenticated;
revoke execute on function public.billing_record_payment(text, uuid, uuid, text, text, text, integer, integer, text, text, text, timestamptz) from public, anon, authenticated;
grant execute on function public.billing_log_event(text, text, text, jsonb) to service_role;
grant execute on function public.billing_upsert_restaurant_subscription(uuid, text, text, text, text, text, text, timestamptz, timestamptz, boolean) to service_role;
grant execute on function public.billing_upsert_consumer_subscription(uuid, text, text, text, text, timestamptz, boolean) to service_role;
grant execute on function public.billing_record_payment(text, uuid, uuid, text, text, text, integer, integer, text, text, text, timestamptz) to service_role;
