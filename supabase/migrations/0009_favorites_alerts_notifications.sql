-- HAPOSTO STEP 11 + 16 — Preferiti, "Avvisami quando c'è posto", token push, coda notifiche,
-- promemoria al ristoratore.
--
-- Esegui DOPO 0008.
-- Il database NON invia notifiche: mette i messaggi in public.notification_outbox. Una Supabase
-- Edge Function (service_role) li legge, li invia via Firebase Cloud Messaging e segna sent_at.

-- ---------------------------------------------------------------------------
-- 1) Preferiti (account gratuito: fino a 5; Plus: illimitati).
-- ---------------------------------------------------------------------------
create table if not exists public.favorites (
    user_id uuid not null references auth.users(id) on delete cascade,
    restaurant_id uuid not null references public.restaurants(id) on delete cascade,
    created_at timestamptz not null default now(),
    primary key (user_id, restaurant_id)
);

create or replace function public.enforce_favorites_limit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    if (select count(*) from public.favorites f where f.user_id = new.user_id)
        >= public.consumer_limit(new.user_id, 'favorites_max') then
        raise exception 'FAVORITES_LIMIT_REACHED';
    end if;
    return new;
end;
$$;

drop trigger if exists favorites_limit on public.favorites;
create trigger favorites_limit
    before insert on public.favorites
    for each row execute function public.enforce_favorites_limit();

-- ---------------------------------------------------------------------------
-- 2) Avvisi di disponibilità (solo Plus). Un avviso vale per una serata (scadenza).
-- ---------------------------------------------------------------------------
create table if not exists public.availability_alerts (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    restaurant_id uuid not null references public.restaurants(id) on delete cascade,
    notify_on text not null default 'AVAILABLE' check (notify_on in ('AVAILABLE', 'AVAILABLE_OR_LIMITED')),
    expires_at timestamptz not null default (now() + interval '6 hours'),
    is_active boolean not null default true,
    last_notified_at timestamptz,
    created_at timestamptz not null default now(),
    constraint alert_window check (expires_at > created_at and expires_at <= created_at + interval '24 hours')
);

create unique index if not exists availability_alerts_one_active_uidx
    on public.availability_alerts (user_id, restaurant_id)
    where is_active;
create index if not exists availability_alerts_restaurant_idx
    on public.availability_alerts (restaurant_id)
    where is_active;

create or replace function public.enforce_alert_plan()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    if not public.consumer_has_feature(new.user_id, 'AVAILABILITY_ALERTS') then
        raise exception 'PLUS_REQUIRED';
    end if;
    if new.is_active and (
        select count(*) from public.availability_alerts a
        where a.user_id = new.user_id and a.is_active and a.expires_at > now()
    ) >= public.consumer_limit(new.user_id, 'active_alerts_max') then
        raise exception 'ALERTS_LIMIT_REACHED';
    end if;
    return new;
end;
$$;

drop trigger if exists availability_alerts_plan on public.availability_alerts;
create trigger availability_alerts_plan
    before insert on public.availability_alerts
    for each row execute function public.enforce_alert_plan();

-- ---------------------------------------------------------------------------
-- 3) Token dei dispositivi per le notifiche push (utenti e ristoratori).
-- ---------------------------------------------------------------------------
create table if not exists public.device_push_tokens (
    token text primary key check (char_length(token) between 10 and 4096),
    user_id uuid not null references auth.users(id) on delete cascade,
    platform text not null check (platform in ('ANDROID', 'IOS', 'WEB')),
    app_version text,
    created_at timestamptz not null default now(),
    last_seen_at timestamptz not null default now()
);
create index if not exists device_push_tokens_user_idx on public.device_push_tokens (user_id);

create or replace function public.register_push_token(
    p_token text,
    p_platform text,
    p_app_version text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    if auth.uid() is null then
        raise exception 'AUTH_REQUIRED';
    end if;
    -- Un token appartiene a un solo dispositivo: se cambia utente, passa al nuovo.
    insert into public.device_push_tokens (token, user_id, platform, app_version)
    values (p_token, auth.uid(), p_platform, p_app_version)
    on conflict (token) do update set
        user_id = excluded.user_id,
        platform = excluded.platform,
        app_version = excluded.app_version,
        last_seen_at = now();
end;
$$;

-- ---------------------------------------------------------------------------
-- 4) Coda delle notifiche da inviare (letta dalla Edge Function).
-- ---------------------------------------------------------------------------
create table if not exists public.notification_outbox (
    id bigint generated always as identity primary key,
    user_id uuid not null references auth.users(id) on delete cascade,
    kind text not null check (kind in ('AVAILABILITY_ALERT', 'MANAGER_REMINDER', 'CLAIM_UPDATE', 'SYSTEM')),
    restaurant_id uuid references public.restaurants(id) on delete cascade,
    title text not null check (char_length(title) <= 80),
    body text not null check (char_length(body) <= 240),
    data jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now(),
    sent_at timestamptz,
    attempts integer not null default 0,
    last_error text
);
create index if not exists notification_outbox_pending_idx
    on public.notification_outbox (created_at)
    where sent_at is null;
create index if not exists notification_outbox_restaurant_kind_idx
    on public.notification_outbox (restaurant_id, kind, created_at desc);

-- Quando un locale torna disponibile, accoda gli avvisi Plus che lo aspettavano.
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
        return new;  -- semplice riconferma dello stesso stato: nessuna notifica
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
           jsonb_build_object('restaurant_id', new.restaurant_id, 'status', new.status)
    from due d;

    return new;
end;
$$;

drop trigger if exists live_status_alerts on public.restaurant_live_status;
create trigger live_status_alerts
    after insert or update on public.restaurant_live_status
    for each row execute function public.enqueue_availability_alerts();

-- Promemoria al ristoratore quando lo stato sta per scadere (da pianificare con pg_cron ogni 5 min).
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
           jsonb_build_object('restaurant_id', s.restaurant_id, 'action', 'OPEN_DASHBOARD')
    from public.restaurant_live_status s
    join public.restaurants r on r.id = s.restaurant_id and r.partnership_status = 'ACTIVE_PARTNER'
    join public.restaurant_users ru on ru.restaurant_id = s.restaurant_id
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

-- ---------------------------------------------------------------------------
-- 5) Accessi.
-- ---------------------------------------------------------------------------
alter table public.favorites enable row level security;
alter table public.availability_alerts enable row level security;
alter table public.device_push_tokens enable row level security;
alter table public.notification_outbox enable row level security;

revoke all on table public.favorites from anon, authenticated;
revoke all on table public.availability_alerts from anon, authenticated;
revoke all on table public.device_push_tokens from anon, authenticated;
revoke all on table public.notification_outbox from anon, authenticated;

grant select, insert, delete on table public.favorites to authenticated;
grant select, insert, delete on table public.availability_alerts to authenticated;
grant update (is_active) on table public.availability_alerts to authenticated;
grant select, delete on table public.device_push_tokens to authenticated;
grant select on table public.notification_outbox to authenticated;

drop policy if exists "favorites_own" on public.favorites;
create policy "favorites_own"
on public.favorites
for all
to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

drop policy if exists "alerts_own" on public.availability_alerts;
create policy "alerts_own"
on public.availability_alerts
for all
to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

drop policy if exists "push_tokens_own" on public.device_push_tokens;
create policy "push_tokens_own"
on public.device_push_tokens
for all
to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()));

drop policy if exists "outbox_own_read" on public.notification_outbox;
create policy "outbox_own_read"
on public.notification_outbox
for select
to authenticated
using (user_id = (select auth.uid()));

revoke execute on function public.enforce_favorites_limit() from public, anon, authenticated;
revoke execute on function public.enforce_alert_plan() from public, anon, authenticated;
revoke execute on function public.enqueue_availability_alerts() from public, anon, authenticated;
revoke execute on function public.enqueue_manager_reminders() from public, anon, authenticated;
revoke execute on function public.register_push_token(text, text, text) from public, anon;
grant execute on function public.register_push_token(text, text, text) to authenticated;
grant execute on function public.enqueue_manager_reminders() to service_role;
