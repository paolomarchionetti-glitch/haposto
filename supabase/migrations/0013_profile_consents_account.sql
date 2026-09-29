-- HAPOSTO — Profilo e orari del locale, registro attività, consensi, cancellazione account,
-- preferenze notifiche, storico disponibilità (Plus), conservazione dei dati.
--
-- Esegui DOPO 0012. Rieseguibile.

-- ---------------------------------------------------------------------------
-- 1) Orari di apertura del locale.
--    Formato: {"mon": [["12:00","14:30"],["19:00","23:30"]], "tue": [], ...}
--    Giorni: mon tue wed thu fri sat sun; fino a 3 fasce al giorno; la chiusura può essere
--    dopo mezzanotte (es. ["19:00","01:00"]).
-- ---------------------------------------------------------------------------
create or replace function public.valid_opening_hours(p_hours jsonb)
returns boolean
language plpgsql
immutable
set search_path = ''
as $$
declare
    v_day text;
    v_ranges jsonb;
    v_range jsonb;
begin
    if p_hours is null then
        return true;
    end if;
    if jsonb_typeof(p_hours) <> 'object' then
        return false;
    end if;
    for v_day, v_ranges in select * from jsonb_each(p_hours) loop
        if v_day not in ('mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun') then
            return false;
        end if;
        if jsonb_typeof(v_ranges) <> 'array' or jsonb_array_length(v_ranges) > 3 then
            return false;
        end if;
        for v_range in select * from jsonb_array_elements(v_ranges) loop
            if jsonb_typeof(v_range) <> 'array' or jsonb_array_length(v_range) <> 2
               or (v_range ->> 0) !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'
               or (v_range ->> 1) !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'
               or (v_range ->> 0) = (v_range ->> 1) then
                return false;
            end if;
        end loop;
    end loop;
    return true;
end;
$$;

alter table public.restaurants add column if not exists opening_hours jsonb;
alter table public.restaurants drop constraint if exists restaurants_opening_hours_valid;
alter table public.restaurants add constraint restaurants_opening_hours_valid
    check (public.valid_opening_hours(opening_hours));
grant select (opening_hours) on table public.restaurants to anon, authenticated;

-- Dati pubblici aggiuntivi per la scheda (link condivisibile e orari).
create or replace function public.restaurant_public_details(p_restaurant_id uuid)
returns table (slug text, opening_hours jsonb)
language sql
stable
security definer
set search_path = ''
as $$
    select r.slug, r.opening_hours
    from public.restaurants r
    where r.id = p_restaurant_id and r.partnership_status <> 'SUSPENDED';
$$;

-- ---------------------------------------------------------------------------
-- 2) Il titolare modifica i dati del proprio locale (non l'indirizzo: lo cambia l'admin).
-- ---------------------------------------------------------------------------
create or replace function public.update_restaurant_profile(
    p_restaurant_id uuid,
    p_name text,
    p_category text,
    p_phone_number text,
    p_phone_public boolean,
    p_opening_hours jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_before public.restaurants;
    v_name text := btrim(coalesce(p_name, ''));
    v_category text := btrim(coalesce(p_category, ''));
    v_phone text := nullif(btrim(coalesce(p_phone_number, '')), '');
    v_changes jsonb := '{}'::jsonb;
begin
    perform public.assert_active_user();
    if not public.is_restaurant_owner(p_restaurant_id) then
        raise exception 'OWNER_REQUIRED';
    end if;
    perform public.assert_restaurant_mfa();

    if char_length(v_name) not between 2 and 160 then
        raise exception 'INVALID_NAME';
    end if;
    if char_length(v_category) not between 2 and 100 then
        raise exception 'INVALID_CATEGORY';
    end if;
    if v_phone is not null and v_phone !~ '^\+?[0-9 ./-]{6,24}$' then
        raise exception 'INVALID_PHONE';
    end if;
    if coalesce(p_phone_public, false) and v_phone is null then
        raise exception 'PHONE_REQUIRED';
    end if;
    if not public.valid_opening_hours(p_opening_hours) then
        raise exception 'INVALID_OPENING_HOURS';
    end if;

    select * into v_before from public.restaurants r where r.id = p_restaurant_id for update;
    if v_before.partnership_status = 'SUSPENDED' then
        raise exception 'RESTAURANT_SUSPENDED';
    end if;

    if v_before.name is distinct from v_name then
        v_changes := v_changes || jsonb_build_object('name', jsonb_build_array(v_before.name, v_name));
    end if;
    if v_before.category is distinct from v_category then
        v_changes := v_changes || jsonb_build_object('category', jsonb_build_array(v_before.category, v_category));
    end if;
    if v_before.phone_number is distinct from v_phone then
        v_changes := v_changes || jsonb_build_object('phone_number', jsonb_build_array(v_before.phone_number, v_phone));
    end if;
    if v_before.phone_public is distinct from coalesce(p_phone_public, false) then
        v_changes := v_changes || jsonb_build_object('phone_public', jsonb_build_array(v_before.phone_public, coalesce(p_phone_public, false)));
    end if;
    if v_before.opening_hours is distinct from p_opening_hours then
        v_changes := v_changes || jsonb_build_object('opening_hours', true);
    end if;

    update public.restaurants
    set name = v_name,
        category = v_category,
        phone_number = v_phone,
        phone_public = coalesce(p_phone_public, false),
        opening_hours = p_opening_hours
    where id = p_restaurant_id;

    if v_changes <> '{}'::jsonb then
        perform public.log_audit('RESTAURANT_PROFILE_UPDATED', p_restaurant_id, null, v_changes);
    end if;
end;
$$;

-- Tutto quello che serve alla dashboard in una chiamata.
create or replace function public.restaurant_manager_info(p_restaurant_id uuid)
returns table (
    restaurant_id uuid,
    name text,
    category text,
    address text,
    city text,
    province text,
    phone_number text,
    phone_public boolean,
    opening_hours jsonb,
    slug text,
    partnership_status public.partnership_status,
    my_role public.restaurant_user_role,
    plan_code text,
    plan_name text,
    plan_source text,
    plan_valid_until timestamptz,
    features text[],
    limits jsonb,
    mfa_required boolean,
    mfa_ok boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
    v_role public.restaurant_user_role := public.restaurant_role(p_restaurant_id);
begin
    if v_role is null then
        raise exception 'Not authorized for this restaurant';
    end if;
    return query
    select r.id, r.name, r.category, r.address, r.city, r.province, r.phone_number, r.phone_public,
           r.opening_hours, r.slug, r.partnership_status, v_role,
           e.plan_code, e.plan_name, e.source, e.valid_until, e.features, e.limits,
           coalesce(public.config_value('security', 'restaurant_mfa_required')::boolean, true),
           public.restaurant_mfa_satisfied()
    from public.restaurants r
    cross join lateral public.restaurant_entitlements(r.id) e
    where r.id = p_restaurant_id;
end;
$$;

-- Registro attività del locale per titolare e staff: chi ha pubblicato cosa, chi ha cambiato cosa.
create or replace function public.restaurant_activity(p_restaurant_id uuid, p_limit integer default 50)
returns table (
    happened_at timestamptz,
    kind text,
    actor text,
    summary text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
begin
    if public.restaurant_role(p_restaurant_id) is null and not public.is_platform_admin() then
        raise exception 'Not authorized for this restaurant';
    end if;
    perform public.assert_restaurant_mfa();
    return query
    select * from (
        select h.updated_at,
               'PUBLISH'::text,
               case h.updated_via
                   when 'DEV_SIMULATOR' then 'Simulatore'
                   when 'DEV_APP' then 'App di prova'
                   else coalesce(p.display_name, u.email::text, 'Account eliminato')
               end,
               case h.status
                   when 'AVAILABLE' then 'C''è posto'
                   when 'LIMITED' then 'Pochi posti'
                   else 'Completo'
               end
               || coalesce(' · ' || h.available_tables || ' tavoli', '')
               || coalesce(' · attesa ' || h.estimated_wait_minutes || ' min', '')
        from public.status_history h
        left join auth.users u on u.id = h.updated_by
        left join public.profiles p on p.id = h.updated_by
        where h.restaurant_id = p_restaurant_id
        union all
        select a.created_at,
               a.action,
               case when a.actor_kind in ('ADMIN', 'CONSOLE', 'SERVICE') then 'HAPOSTO'
                    else coalesce(p.display_name, u.email::text, 'Account eliminato') end,
               case a.action
                   when 'STAFF_ADDED' then 'Aggiunto un collaboratore: ' || coalesce(ut.email::text, '?')
                   when 'STAFF_REMOVED' then 'Rimosso un collaboratore: ' || coalesce(ut.email::text, '?')
                   when 'RESTAURANT_PROFILE_UPDATED' then 'Modificati i dati del locale'
                   when 'CLAIM_SUBMITTED' then 'Richiesta di gestione inviata'
                   when 'CLAIM_APPROVED' then 'Richiesta di gestione approvata'
                   when 'CLAIM_REJECTED' then 'Richiesta di gestione rifiutata'
                   when 'CLAIM_PHONE_VERIFIED' then 'Verifica telefonica completata'
                   when 'PLAN_GRANTED' then 'Piano attivato da HAPOSTO'
                   when 'RESTAURANT_STATUS_CHANGED' then 'Stato del locale cambiato da HAPOSTO'
                   when 'RESTAURANT_EDITED_BY_ADMIN' then 'Dati corretti da HAPOSTO'
                   when 'MEMBER_SET_BY_ADMIN' then 'Accesso assegnato da HAPOSTO'
                   when 'MEMBER_REMOVED_BY_ADMIN' then 'Accesso rimosso da HAPOSTO'
                   else a.action
               end
        from public.audit_log a
        left join auth.users u on u.id = a.actor_id
        left join public.profiles p on p.id = a.actor_id
        left join auth.users ut on ut.id = a.target_user_id
        where a.restaurant_id = p_restaurant_id
          and a.action not in ('CLAIM_CODE_ISSUED', 'CLAIM_PHONE_CODE_WRONG')
    ) x
    order by 1 desc
    limit greatest(1, least(coalesce(p_limit, 50), 200));
end;
$$;

-- ---------------------------------------------------------------------------
-- 3) Consensi (prova di accettazione, art. 7 GDPR) e preferenze.
-- ---------------------------------------------------------------------------
create table if not exists public.consent_log (
    id bigint generated always as identity primary key,
    user_id uuid not null references auth.users(id) on delete cascade,
    kind text not null check (kind in ('TERMS', 'PRIVACY', 'RESTAURANT_TERMS', 'RESTAURANT_SPECIFIC_CLAUSES', 'MARKETING')),
    version text,
    granted boolean not null,
    created_at timestamptz not null default now()
);
create index if not exists consent_log_user_idx on public.consent_log (user_id, created_at desc);

alter table public.consent_log enable row level security;
revoke all on table public.consent_log from anon, authenticated;
grant select on table public.consent_log to authenticated;
drop policy if exists "consent_log_own_read" on public.consent_log;
create policy "consent_log_own_read"
on public.consent_log
for select
to authenticated
using (user_id = (select auth.uid()));

alter table public.profiles
    add column if not exists accepted_restaurant_terms_version text,
    add column if not exists accepted_restaurant_terms_at timestamptz,
    add column if not exists notify_manager_reminders boolean not null default true,
    add column if not exists notify_availability_alerts boolean not null default true,
    add column if not exists notify_claim_updates boolean not null default true;

create or replace function public.accept_terms(p_version text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    perform public.assert_active_user();
    if p_version is null or char_length(p_version) not between 1 and 20 then
        raise exception 'INVALID_TERMS_VERSION';
    end if;
    insert into public.profiles (id) values (auth.uid()) on conflict (id) do nothing;
    update public.profiles
    set accepted_terms_version = p_version,
        accepted_terms_at = now()
    where id = auth.uid();
    insert into public.consent_log (user_id, kind, version, granted)
    values (auth.uid(), 'TERMS', p_version, true), (auth.uid(), 'PRIVACY', p_version, true);
end;
$$;

-- Condizioni per i ristoratori + approvazione specifica delle clausole onerose (artt. 1341-1342 c.c.).
create or replace function public.accept_restaurant_terms(p_version text, p_specific_clauses_accepted boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    perform public.assert_active_user();
    if p_version is null or char_length(p_version) not between 1 and 20 then
        raise exception 'INVALID_TERMS_VERSION';
    end if;
    if not coalesce(p_specific_clauses_accepted, false) then
        raise exception 'SPECIFIC_CLAUSES_REQUIRED';
    end if;
    insert into public.profiles (id) values (auth.uid()) on conflict (id) do nothing;
    update public.profiles
    set accepted_restaurant_terms_version = p_version,
        accepted_restaurant_terms_at = now()
    where id = auth.uid();
    insert into public.consent_log (user_id, kind, version, granted)
    values (auth.uid(), 'RESTAURANT_TERMS', p_version, true),
           (auth.uid(), 'RESTAURANT_SPECIFIC_CLAUSES', p_version, true);
end;
$$;

create or replace function public.set_marketing_consent(p_opt_in boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    perform public.assert_active_user();
    insert into public.profiles (id) values (auth.uid()) on conflict (id) do nothing;
    update public.profiles set marketing_opt_in = coalesce(p_opt_in, false) where id = auth.uid();
    insert into public.consent_log (user_id, kind, version, granted)
    values (auth.uid(), 'MARKETING', null, coalesce(p_opt_in, false));
end;
$$;

create or replace function public.set_notification_prefs(
    p_manager_reminders boolean,
    p_availability_alerts boolean,
    p_claim_updates boolean
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    perform public.assert_active_user();
    insert into public.profiles (id) values (auth.uid()) on conflict (id) do nothing;
    update public.profiles
    set notify_manager_reminders = coalesce(p_manager_reminders, notify_manager_reminders),
        notify_availability_alerts = coalesce(p_availability_alerts, notify_availability_alerts),
        notify_claim_updates = coalesce(p_claim_updates, notify_claim_updates)
    where id = auth.uid();
end;
$$;

-- Tutto ciò che serve all'app sull'utente collegato, in una chiamata.
create or replace function public.my_profile()
returns table (
    user_id uuid,
    email text,
    display_name text,
    is_admin_account boolean,
    blocked boolean,
    blocked_reason text,
    accepted_terms_version text,
    current_terms_version text,
    accepted_restaurant_terms_version text,
    current_restaurant_terms_version text,
    marketing_opt_in boolean,
    notify_manager_reminders boolean,
    notify_availability_alerts boolean,
    notify_claim_updates boolean,
    consumer_plan text,
    consumer_plan_until timestamptz,
    restaurants integer,
    aal text
)
language sql
stable
security definer
set search_path = ''
as $$
    select u.id, u.email::text, p.display_name,
           coalesce(p.is_platform_admin, false) and p.blocked_at is null,
           p.blocked_at is not null, p.blocked_reason,
           p.accepted_terms_version, public.config_value('legal', 'terms_version'),
           p.accepted_restaurant_terms_version, public.config_value('legal', 'restaurant_terms_version'),
           coalesce(p.marketing_opt_in, false),
           coalesce(p.notify_manager_reminders, true),
           coalesce(p.notify_availability_alerts, true),
           coalesce(p.notify_claim_updates, true),
           public.consumer_plan_code(u.id),
           (select s.current_period_end from public.consumer_subscriptions s
            where s.user_id = u.id and s.status in ('TRIALING', 'ACTIVE', 'PAST_DUE')
            order by s.created_at desc limit 1),
           (select count(*)::integer from public.restaurant_users ru where ru.user_id = u.id),
           public.current_aal()
    from auth.users u
    left join public.profiles p on p.id = u.id
    where u.id = auth.uid();
$$;

-- ---------------------------------------------------------------------------
-- 4) Notifiche che rispettano le preferenze e i blocchi.
-- ---------------------------------------------------------------------------
create or replace function public.enqueue_availability_alerts()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_name text;
begin
    if tg_op = 'UPDATE' and old.status = new.status and old.valid_until > now() then
        return new;
    end if;
    if new.status not in ('AVAILABLE', 'LIMITED') then
        return new;
    end if;

    select r.name into v_name from public.restaurants r where r.id = new.restaurant_id;

    with due as (
        update public.availability_alerts a
        set last_notified_at = now(),
            is_active = false
        where a.restaurant_id = new.restaurant_id
          and a.is_active
          and a.expires_at > now()
          and (a.notify_on = 'AVAILABLE_OR_LIMITED' or new.status = 'AVAILABLE')
        returning a.user_id
    )
    insert into public.notification_outbox (user_id, kind, restaurant_id, title, body, data)
    select d.user_id,
           'AVAILABILITY_ALERT',
           new.restaurant_id,
           left(coalesce(v_name, 'Un locale') || ': c''è posto!', 80),
           case when new.status = 'AVAILABLE'
                then 'Ha appena segnalato posti liberi. Lo stato vale 30 minuti.'
                else 'Ha segnalato pochi posti: meglio sbrigarsi.' end,
           jsonb_build_object('restaurant_id', new.restaurant_id, 'status', new.status, 'action', 'OPEN_RESTAURANT')
    from due d
    join public.profiles p on p.id = d.user_id
    where p.notify_availability_alerts and p.blocked_at is null;

    return new;
end;
$$;

create or replace function public.enqueue_manager_reminders()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_count integer;
begin
    insert into public.notification_outbox (user_id, kind, restaurant_id, title, body, data)
    select ru.user_id,
           'MANAGER_REMINDER',
           s.restaurant_id,
           'Come siete messi?',
           left(r.name || ': il tuo stato scade tra pochi minuti. Un tap per confermarlo.', 240),
           jsonb_build_object('restaurant_id', s.restaurant_id, 'action', 'OPEN_DASHBOARD',
                              'status', s.status)
    from public.restaurant_live_status s
    join public.restaurants r on r.id = s.restaurant_id and r.partnership_status = 'ACTIVE_PARTNER'
    join public.restaurant_users ru on ru.restaurant_id = s.restaurant_id
    join public.profiles p on p.id = ru.user_id and p.notify_manager_reminders and p.blocked_at is null
    where s.valid_until between now() and now() + interval '5 minutes'
      and public.restaurant_has_feature(s.restaurant_id, 'REMINDERS')
      and exists (select 1 from public.device_push_tokens t where t.user_id = ru.user_id)
      and not exists (
          select 1 from public.notification_outbox o
          where o.restaurant_id = s.restaurant_id
            and o.user_id = ru.user_id
            and o.kind = 'MANAGER_REMINDER'
            and o.created_at > now() - interval '20 minutes'
      );
    get diagnostics v_count = row_count;
    return v_count;
end;
$$;

-- Per la Edge Function push-dispatch: prende un blocco di notifiche con i token dei dispositivi.
create or replace function public.claim_notification_batch(p_limit integer default 100)
returns table (
    notification_id bigint,
    user_id uuid,
    kind text,
    restaurant_id uuid,
    title text,
    body text,
    data jsonb,
    tokens text[]
)
language plpgsql
volatile
security definer
set search_path = ''
as $$
#variable_conflict use_column
begin
    return query
    with batch as (
        select o.id
        from public.notification_outbox o
        where o.sent_at is null and o.attempts < 5
        order by o.created_at
        limit greatest(1, least(coalesce(p_limit, 100), 500))
        for update skip locked
    ), marked as (
        update public.notification_outbox o
        set attempts = o.attempts + 1
        from batch b
        where o.id = b.id
        returning o.*
    )
    select m.id, m.user_id, m.kind, m.restaurant_id, m.title, m.body, m.data,
           coalesce(array(select t.token from public.device_push_tokens t where t.user_id = m.user_id), array[]::text[])
    from marked m;
end;
$$;

create or replace function public.complete_notifications(
    p_sent_ids bigint[],
    p_failed_ids bigint[] default array[]::bigint[],
    p_error text default null,
    p_invalid_tokens text[] default array[]::text[]
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    update public.notification_outbox set sent_at = now(), last_error = null
    where id = any(coalesce(p_sent_ids, array[]::bigint[]));
    update public.notification_outbox set last_error = left(coalesce(p_error, 'errore'), 500)
    where id = any(coalesce(p_failed_ids, array[]::bigint[]));
    delete from public.device_push_tokens where token = any(coalesce(p_invalid_tokens, array[]::text[]));
end;
$$;

-- L'utente toglie il token di questo telefono (uscita dall'account).
create or replace function public.unregister_push_token(p_token text)
returns void
language sql
security definer
set search_path = ''
as $$
    delete from public.device_push_tokens where token = p_token and user_id = auth.uid();
$$;

-- ---------------------------------------------------------------------------
-- 5) Cancellazione dell'account (obbligatoria per Google Play).
-- ---------------------------------------------------------------------------
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_uid uuid := auth.uid();
    v_restaurant uuid;
begin
    if v_uid is null then
        raise exception 'AUTH_REQUIRED';
    end if;

    -- Abbonamento Pro pagato su un locale di cui è l'unico titolare: va prima disdetto su Stripe.
    if exists (
        select 1
        from public.restaurant_users ru
        join public.restaurant_subscriptions s on s.restaurant_id = ru.restaurant_id
        where ru.user_id = v_uid and ru.role = 'OWNER'
          and s.provider = 'STRIPE' and s.status in ('TRIALING', 'ACTIVE', 'PAST_DUE')
          and not s.cancel_at_period_end
          and not exists (select 1 from public.restaurant_users o
                          where o.restaurant_id = ru.restaurant_id and o.role = 'OWNER' and o.user_id <> v_uid)
    ) then
        raise exception 'ACTIVE_RESTAURANT_SUBSCRIPTION';
    end if;
    -- Plus che si rinnova su Google Play: va prima disdetto nel Play Store.
    if exists (
        select 1 from public.consumer_subscriptions s
        where s.user_id = v_uid and s.provider in ('GOOGLE_PLAY', 'APP_STORE', 'STRIPE')
          and s.status in ('TRIALING', 'ACTIVE', 'PAST_DUE') and s.auto_renewing
    ) then
        raise exception 'ACTIVE_PLUS_SUBSCRIPTION';
    end if;

    -- Locali di cui è l'unico titolare: tornano "solo directory" (nessuno resta a gestirli).
    for v_restaurant in
        select ru.restaurant_id
        from public.restaurant_users ru
        where ru.user_id = v_uid and ru.role = 'OWNER'
          and not exists (select 1 from public.restaurant_users o
                          where o.restaurant_id = ru.restaurant_id and o.role = 'OWNER' and o.user_id <> v_uid)
    loop
        delete from public.restaurant_users where restaurant_id = v_restaurant;
        delete from public.restaurant_live_status where restaurant_id = v_restaurant;
        update public.restaurants set partnership_status = 'DIRECTORY_ONLY'
        where id = v_restaurant and partnership_status in ('ACTIVE_PARTNER', 'PAUSED');
        perform public.log_audit('OWNER_ACCOUNT_DELETED', v_restaurant, null, '{}');
    end loop;

    -- Richieste aperte: si chiudono e il locale torna "solo directory" se nessun altro lo chiede.
    for v_restaurant in
        update public.restaurant_claims c
        set status = 'CANCELLED', reviewed_at = now(), phone_code_hash = null
        where c.user_id = v_uid and c.status = 'PENDING'
        returning c.restaurant_id
    loop
        perform public.reset_claim_pending_if_idle(v_restaurant);
    end loop;

    delete from public.admin_credentials where user_id = v_uid;
    perform public.log_audit('ACCOUNT_DELETED', null, null, '{}');
    -- Profilo, preferiti, avvisi, token, consensi e abbonamenti si cancellano a cascata;
    -- pagamenti e registro restano senza collegamento alla persona (obblighi contabili).
    delete from auth.users where id = v_uid;
end;
$$;

-- ---------------------------------------------------------------------------
-- 6) Plus: "di solito com'è?" — storico degli stati per giorno e ora (ultime 8 settimane).
-- ---------------------------------------------------------------------------
create or replace function public.restaurant_availability_pattern(p_restaurant_id uuid)
returns table (
    weekday integer,
    hour integer,
    samples integer,
    available_share numeric,
    limited_share numeric,
    full_share numeric
)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
begin
    if auth.uid() is null or not public.consumer_has_feature(auth.uid(), 'AVAILABILITY_HISTORY') then
        raise exception 'PLUS_REQUIRED';
    end if;
    return query
    select extract(isodow from h.updated_at at time zone 'Europe/Rome')::integer,
           extract(hour from h.updated_at at time zone 'Europe/Rome')::integer,
           count(*)::integer,
           round(avg((h.status = 'AVAILABLE')::integer), 2),
           round(avg((h.status = 'LIMITED')::integer), 2),
           round(avg((h.status = 'FULL')::integer), 2)
    from public.status_history h
    join public.restaurants r on r.id = h.restaurant_id and r.partnership_status = 'ACTIVE_PARTNER'
    where h.restaurant_id = p_restaurant_id
      and h.updated_at > now() - interval '56 days'
      and h.updated_via not in ('DEV_SIMULATOR', 'DEV_APP')
    group by 1, 2
    having count(*) >= 3
    order by 1, 2;
end;
$$;

-- ---------------------------------------------------------------------------
-- 7) Conservazione dei dati (da pianificare ogni settimana: ops/scheduled_jobs.sql).
-- ---------------------------------------------------------------------------
create or replace function public.purge_operational_data()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_history integer;
    v_stats integer;
    v_audit integer;
    v_sessions integer;
begin
    delete from public.status_history where updated_at < now() - interval '180 days';
    get diagnostics v_history = row_count;
    delete from public.restaurant_daily_stats where day < current_date - 730;
    get diagnostics v_stats = row_count;
    delete from public.audit_log where created_at < now() - interval '730 days';
    get diagnostics v_audit = row_count;
    delete from public.admin_sessions where expires_at < now() - interval '7 days';
    get diagnostics v_sessions = row_count;
    return jsonb_build_object('status_history', v_history, 'daily_stats', v_stats,
                              'audit_log', v_audit, 'admin_sessions', v_sessions);
end;
$$;

-- ---------------------------------------------------------------------------
-- 8) Permessi sulle funzioni.
-- ---------------------------------------------------------------------------
revoke execute on function public.valid_opening_hours(jsonb) from public, anon, authenticated;
revoke execute on function public.claim_notification_batch(integer) from public, anon, authenticated;
revoke execute on function public.complete_notifications(bigint[], bigint[], text, text[]) from public, anon, authenticated;
revoke execute on function public.purge_operational_data() from public, anon, authenticated;
grant execute on function public.claim_notification_batch(integer) to service_role;
grant execute on function public.complete_notifications(bigint[], bigint[], text, text[]) to service_role;
grant execute on function public.purge_operational_data() to service_role;

revoke execute on function public.restaurant_public_details(uuid) from public;
grant execute on function public.restaurant_public_details(uuid) to anon, authenticated;

do $$
declare
    v_fn text;
begin
    foreach v_fn in array array[
        'public.update_restaurant_profile(uuid, text, text, text, boolean, jsonb)',
        'public.restaurant_manager_info(uuid)',
        'public.restaurant_activity(uuid, integer)',
        'public.accept_terms(text)',
        'public.accept_restaurant_terms(text, boolean)',
        'public.set_marketing_consent(boolean)',
        'public.set_notification_prefs(boolean, boolean, boolean)',
        'public.my_profile()',
        'public.unregister_push_token(text)',
        'public.delete_my_account()',
        'public.restaurant_availability_pattern(uuid)'
    ] loop
        execute format('revoke execute on function %s from public, anon', v_fn);
        execute format('grant execute on function %s to authenticated', v_fn);
    end loop;
end;
$$;
