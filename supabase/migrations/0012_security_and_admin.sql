-- HAPOSTO — Sicurezza dei locali e pannello amministratore.
--
-- Esegui DOPO 0011. Rieseguibile.
--
-- Cosa aggiunge:
--   1. 2FA obbligatoria (TOTP di Supabase Auth, livello "aal2") per chi gestisce un locale:
--      senza il codice dell'app di autenticazione non si pubblica, non si cambia nulla del locale.
--   2. Prova che il locale è davvero tuo: l'admin chiama il numero PUBBLICO del locale e detta un
--      codice di 6 cifre; il richiedente lo inserisce nell'app. Solo dopo l'admin approva.
--   3. Registro operazioni (audit_log) di tutto ciò che è sensibile.
--   4. Blocco immediato di un account da parte dell'admin.
--   5. Accesso al pannello admin con SECONDA credenziale (utente + password, bcrypt) valida
--      30 minuti e legata alla singola sessione del telefono; blocco dopo 5 tentativi sbagliati.
--   6. Funzioni del pannello admin (panoramica, locali, utenti, abbonamenti, log, impostazioni).
--   7. Limite di pubblicazioni per evitare abusi.
--
-- Le funzioni admin_* si possono usare anche dal SQL Editor di Supabase (lì non c'è un utente
-- collegato): è il "canale di emergenza" del proprietario del progetto.

create extension if not exists pgcrypto with schema extensions;

-- ---------------------------------------------------------------------------
-- 0) Configurazione (pubblica: MAI segreti qui).
-- ---------------------------------------------------------------------------
insert into public.app_config (key, value, description) values
    ('security',
     '{"restaurant_mfa_required": true, "admin_session_minutes": 30, "max_publish_per_10min": 30}',
     'restaurant_mfa_required: 2FA obbligatoria per gestire un locale. admin_session_minutes: durata dello sblocco del pannello admin. max_publish_per_10min: limite anti-abuso.'),
    ('public_links',
     '{"site_base_url": "https://haposto.app", "privacy_url": "https://haposto.app/privacy", "terms_url": "https://haposto.app/termini", "restaurant_terms_url": "https://haposto.app/termini-ristoranti", "delete_account_url": "https://haposto.app/cancella-account", "support_email": "info@haposto.app"}',
     'Indirizzi pubblici usati dall''app (QR, documenti legali, contatti).'),
    ('legal',
     '{"terms_version": "2026-10", "restaurant_terms_version": "2026-10"}',
     'Versione corrente dei documenti: se cambia, l''app chiede di riaccettarli.')
on conflict (key) do nothing;

-- ---------------------------------------------------------------------------
-- 1) Informazioni sulla sessione (token JWT di Supabase Auth).
-- ---------------------------------------------------------------------------
create or replace function public.current_aal()
returns text
language sql
stable
set search_path = ''
as $$
    select coalesce(auth.jwt() ->> 'aal', 'aal1');
$$;

create or replace function public.current_session_id()
returns text
language sql
stable
set search_path = ''
as $$
    select nullif(auth.jwt() ->> 'session_id', '');
$$;

create or replace function public.config_value(p_key text, p_field text)
returns text
language sql
stable
security definer
set search_path = ''
as $$
    select c.value ->> p_field from public.app_config c where c.key = p_key;
$$;

-- ---------------------------------------------------------------------------
-- 2) Blocco account.
-- ---------------------------------------------------------------------------
alter table public.profiles
    add column if not exists blocked_at timestamptz,
    add column if not exists blocked_reason text check (blocked_reason is null or char_length(blocked_reason) <= 300);

create or replace function public.is_user_blocked(p_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select coalesce((select p.blocked_at is not null from public.profiles p where p.id = p_user_id), false);
$$;

create or replace function public.assert_active_user()
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
    if auth.uid() is null then
        raise exception 'AUTH_REQUIRED';
    end if;
    if public.is_user_blocked(auth.uid()) then
        raise exception 'ACCOUNT_BLOCKED';
    end if;
end;
$$;

-- Un account bloccato perde subito ogni ruolo nei locali (tutte le regole passano da qui).
create or replace function public.restaurant_role(target_restaurant_id uuid)
returns public.restaurant_user_role
language sql
stable
security definer
set search_path = ''
as $$
    select ru.role
    from public.restaurant_users ru
    where ru.restaurant_id = target_restaurant_id
      and ru.user_id = auth.uid()
      and not public.is_user_blocked(auth.uid());
$$;

create or replace function public.is_restaurant_member(target_restaurant_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select public.restaurant_role(target_restaurant_id) is not null;
$$;

-- ---------------------------------------------------------------------------
-- 3) 2FA per chi gestisce un locale.
-- ---------------------------------------------------------------------------
create or replace function public.restaurant_mfa_satisfied()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select public.current_aal() = 'aal2'
        or not coalesce(public.config_value('security', 'restaurant_mfa_required')::boolean, true);
$$;

create or replace function public.assert_restaurant_mfa()
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
    if not public.restaurant_mfa_satisfied() then
        raise exception 'MFA_REQUIRED';
    end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- 4) Registro operazioni.
-- ---------------------------------------------------------------------------
create table if not exists public.audit_log (
    id bigint generated always as identity primary key,
    created_at timestamptz not null default now(),
    actor_id uuid references auth.users(id) on delete set null,
    actor_kind text not null check (actor_kind in ('USER', 'ADMIN', 'CONSOLE', 'SERVICE', 'SYSTEM')),
    action text not null check (action ~ '^[A-Z_]{3,60}$'),
    restaurant_id uuid references public.restaurants(id) on delete set null,
    target_user_id uuid references auth.users(id) on delete set null,
    details jsonb not null default '{}'::jsonb
);
create index if not exists audit_log_created_idx on public.audit_log (created_at desc);
create index if not exists audit_log_restaurant_idx on public.audit_log (restaurant_id, created_at desc);
create index if not exists audit_log_actor_idx on public.audit_log (actor_id, created_at desc);
create index if not exists audit_log_target_idx on public.audit_log (target_user_id, created_at desc);

alter table public.audit_log enable row level security;
revoke all on table public.audit_log from anon, authenticated;

-- ---------------------------------------------------------------------------
-- 5) Credenziali e sessioni del pannello admin.
-- ---------------------------------------------------------------------------
create table if not exists public.admin_credentials (
    user_id uuid primary key references auth.users(id) on delete cascade,
    username text not null unique check (username ~ '^[a-z0-9._-]{4,32}$'),
    password_hash text not null,
    failed_attempts integer not null default 0,
    locked_until timestamptz,
    last_unlock_at timestamptz,
    updated_at timestamptz not null default now()
);

create table if not exists public.admin_sessions (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references auth.users(id) on delete cascade,
    jwt_session_id text not null,
    created_at timestamptz not null default now(),
    expires_at timestamptz not null,
    revoked_at timestamptz
);
create index if not exists admin_sessions_user_idx on public.admin_sessions (user_id, expires_at desc);

alter table public.admin_credentials enable row level security;
alter table public.admin_sessions enable row level security;
revoke all on table public.admin_credentials from anon, authenticated;
revoke all on table public.admin_sessions from anon, authenticated;

-- Account marcato come admin (serve solo a decidere se mostrare la finestra di sblocco).
create or replace function public.is_platform_admin_account()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select coalesce(
        (select p.is_platform_admin and p.blocked_at is null from public.profiles p where p.id = auth.uid()),
        false);
$$;

-- Poteri da admin: account admin + 2FA + pannello sbloccato in QUESTA sessione del telefono.
create or replace function public.is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select public.is_platform_admin_account()
       and public.current_aal() = 'aal2'
       and exists (
           select 1 from public.admin_sessions s
           where s.user_id = auth.uid()
             and s.jwt_session_id = public.current_session_id()
             and s.revoked_at is null
             and s.expires_at > now()
       );
$$;

-- Admin sbloccato, oppure SQL Editor / server (nessun utente collegato).
create or replace function public.assert_admin()
returns void
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
    if auth.uid() is not null and not public.is_platform_admin() then
        raise exception 'ADMIN_REQUIRED';
    end if;
end;
$$;

create or replace function public.log_audit(
    p_action text,
    p_restaurant_id uuid default null,
    p_target_user_id uuid default null,
    p_details jsonb default '{}'::jsonb
)
returns void
language sql
security definer
set search_path = ''
as $$
    insert into public.audit_log (actor_id, actor_kind, action, restaurant_id, target_user_id, details)
    values (
        auth.uid(),
        case
            when auth.uid() is null and coalesce(auth.jwt() ->> 'role', '') = 'service_role' then 'SERVICE'
            when auth.uid() is null then 'CONSOLE'
            when public.is_platform_admin() then 'ADMIN'
            else 'USER'
        end,
        p_action,
        p_restaurant_id,
        p_target_user_id,
        coalesce(p_details, '{}'::jsonb)
    );
$$;

-- Solo dal SQL Editor: crea/cambia le credenziali admin di un account e lo marca admin.
create or replace function public.admin_set_credentials(p_email text, p_username text, p_password text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user uuid;
    v_username text := lower(btrim(coalesce(p_username, '')));
begin
    if auth.uid() is not null then
        raise exception 'CONSOLE_ONLY';
    end if;
    select u.id into v_user from auth.users u where lower(u.email) = lower(btrim(p_email));
    if v_user is null then
        raise exception 'USER_NOT_REGISTERED';
    end if;
    if v_username !~ '^[a-z0-9._-]{4,32}$' then
        raise exception 'INVALID_USERNAME';
    end if;
    if char_length(coalesce(p_password, '')) < 12 then
        raise exception 'PASSWORD_TOO_SHORT';
    end if;

    insert into public.profiles (id) values (v_user) on conflict (id) do nothing;
    update public.profiles set is_platform_admin = true where id = v_user;

    insert into public.admin_credentials (user_id, username, password_hash)
    values (v_user, v_username, extensions.crypt(p_password, extensions.gen_salt('bf', 10)))
    on conflict (user_id) do update set
        username = excluded.username,
        password_hash = excluded.password_hash,
        failed_attempts = 0,
        locked_until = null,
        updated_at = now();

    update public.admin_sessions set revoked_at = now() where user_id = v_user and revoked_at is null;
    perform public.log_audit('ADMIN_CREDENTIALS_SET', null, v_user, jsonb_build_object('username', v_username));
end;
$$;

-- Sblocco del pannello. Non solleva errori sulle credenziali sbagliate (così il contatore dei
-- tentativi resta salvato): risponde ok=false e un codice.
create or replace function public.admin_unlock(p_username text, p_password text)
returns table (ok boolean, error_code text, valid_until timestamptz)
language plpgsql
volatile
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
    v_uid uuid := auth.uid();
    v_session text := public.current_session_id();
    v_cred public.admin_credentials;
    v_minutes integer := coalesce(public.config_value('security', 'admin_session_minutes')::integer, 30);
    v_until timestamptz;
begin
    if v_uid is null then
        return query select false, 'AUTH_REQUIRED'::text, null::timestamptz;
        return;
    end if;
    if not public.is_platform_admin_account() then
        perform public.log_audit('ADMIN_UNLOCK_DENIED', null, v_uid, '{"reason": "NOT_ADMIN"}');
        return query select false, 'NOT_ADMIN'::text, null::timestamptz;
        return;
    end if;
    if public.current_aal() <> 'aal2' then
        return query select false, 'MFA_REQUIRED'::text, null::timestamptz;
        return;
    end if;
    if v_session is null then
        return query select false, 'SESSION_REQUIRED'::text, null::timestamptz;
        return;
    end if;

    select * into v_cred from public.admin_credentials c where c.user_id = v_uid for update;
    if v_cred.user_id is null then
        return query select false, 'NO_CREDENTIALS'::text, null::timestamptz;
        return;
    end if;
    if v_cred.locked_until is not null and v_cred.locked_until > now() then
        return query select false, 'LOCKED'::text, v_cred.locked_until;
        return;
    end if;

    if lower(btrim(coalesce(p_username, ''))) <> v_cred.username
       or v_cred.password_hash <> extensions.crypt(coalesce(p_password, ''), v_cred.password_hash) then
        update public.admin_credentials c
        set failed_attempts = case when c.failed_attempts + 1 >= 5 then 0 else c.failed_attempts + 1 end,
            locked_until = case when c.failed_attempts + 1 >= 5 then now() + interval '15 minutes' else null end
        where c.user_id = v_uid;
        perform public.log_audit('ADMIN_UNLOCK_FAILED', null, v_uid,
            jsonb_build_object('attempt', v_cred.failed_attempts + 1));
        if v_cred.failed_attempts + 1 >= 5 then
            return query select false, 'LOCKED'::text, now() + interval '15 minutes';
        else
            return query select false, 'INVALID_CREDENTIALS'::text, null::timestamptz;
        end if;
        return;
    end if;

    update public.admin_credentials c
    set failed_attempts = 0, locked_until = null, last_unlock_at = now()
    where c.user_id = v_uid;

    v_until := now() + make_interval(mins => greatest(5, least(v_minutes, 240)));
    update public.admin_sessions s set revoked_at = now() where s.user_id = v_uid and s.revoked_at is null;
    insert into public.admin_sessions (user_id, jwt_session_id, expires_at) values (v_uid, v_session, v_until);
    perform public.log_audit('ADMIN_UNLOCK', null, v_uid, '{}');
    return query select true, null::text, v_until;
end;
$$;

create or replace function public.admin_lock()
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    update public.admin_sessions s
    set revoked_at = now()
    where s.user_id = auth.uid() and s.revoked_at is null;
    perform public.log_audit('ADMIN_LOCK', null, auth.uid(), '{}');
end;
$$;

create or replace function public.my_admin_status()
returns table (
    is_admin_account boolean,
    has_credentials boolean,
    mfa_ok boolean,
    unlocked_until timestamptz,
    locked_until timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
    select
        public.is_platform_admin_account(),
        exists (select 1 from public.admin_credentials c where c.user_id = auth.uid()),
        public.current_aal() = 'aal2',
        (select max(s.expires_at) from public.admin_sessions s
         where s.user_id = auth.uid()
           and s.jwt_session_id = public.current_session_id()
           and s.revoked_at is null
           and s.expires_at > now()),
        (select c.locked_until from public.admin_credentials c
         where c.user_id = auth.uid() and c.locked_until > now());
$$;

-- ---------------------------------------------------------------------------
-- 6) Pubblicazione dello stato: 2FA, account attivo, limite anti-abuso.
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
    v_role public.restaurant_user_role;
    v_details boolean;
    v_partnership public.partnership_status;
    v_available_tables smallint;
    v_wait smallint;
    v_note varchar(80);
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
-- 7) Staff: 2FA, registro operazioni, elenco membri.
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
    perform public.assert_active_user();
    if not public.is_restaurant_owner(p_restaurant_id) then
        raise exception 'OWNER_REQUIRED';
    end if;
    perform public.assert_restaurant_mfa();
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
        raise exception 'USER_NOT_REGISTERED';
    end if;
    if public.is_user_blocked(v_user) then
        raise exception 'ACCOUNT_BLOCKED';
    end if;
    if exists (select 1 from public.restaurant_users ru where ru.restaurant_id = p_restaurant_id and ru.user_id = v_user) then
        raise exception 'ALREADY_MEMBER';
    end if;

    insert into public.restaurant_users (restaurant_id, user_id, role)
    values (p_restaurant_id, v_user, 'STAFF');
    perform public.log_audit('STAFF_ADDED', p_restaurant_id, v_user, '{}');
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
    perform public.assert_active_user();
    -- Il titolare toglie lo staff; un membro dello staff può togliersi da solo.
    if not public.is_restaurant_owner(p_restaurant_id)
       and not (p_user_id = auth.uid() and public.restaurant_role(p_restaurant_id) = 'STAFF') then
        raise exception 'OWNER_REQUIRED';
    end if;
    perform public.assert_restaurant_mfa();
    delete from public.restaurant_users
    where restaurant_id = p_restaurant_id and user_id = p_user_id and role = 'STAFF';
    if found then
        perform public.log_audit('STAFF_REMOVED', p_restaurant_id, p_user_id, '{}');
    end if;
end;
$$;

create or replace function public.restaurant_members(p_restaurant_id uuid)
returns table (
    user_id uuid,
    email text,
    display_name text,
    role public.restaurant_user_role,
    member_since timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
begin
    if not public.is_restaurant_owner(p_restaurant_id) and not public.is_platform_admin() then
        raise exception 'OWNER_REQUIRED';
    end if;
    perform public.assert_restaurant_mfa();
    return query
    select ru.user_id, u.email::text, p.display_name, ru.role, ru.created_at
    from public.restaurant_users ru
    join auth.users u on u.id = ru.user_id
    left join public.profiles p on p.id = ru.user_id
    where ru.restaurant_id = p_restaurant_id
    order by ru.role, ru.created_at;
end;
$$;

-- ---------------------------------------------------------------------------
-- 8) Richieste di gestione: codice telefonico, limiti, registro, notifiche.
-- ---------------------------------------------------------------------------
alter table public.restaurant_claims
    add column if not exists phone_code_hash text,
    add column if not exists phone_code_expires_at timestamptz,
    add column if not exists phone_code_attempts integer not null default 0,
    add column if not exists phone_verified_at timestamptz;

-- Il richiedente vede la propria richiesta ma MAI l'impronta del codice.
revoke select on table public.restaurant_claims from authenticated;
grant select (id, restaurant_id, user_id, status, contact_info, created_at, reviewed_at, review_note,
              phone_verified_at, phone_code_expires_at)
    on table public.restaurant_claims to authenticated;

create or replace function public.submit_restaurant_claim(
    p_restaurant_id uuid,
    p_contact_info text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user uuid := auth.uid();
    v_status public.partnership_status;
    v_claim_id uuid;
    v_contact text := btrim(coalesce(p_contact_info, ''));
begin
    perform public.assert_active_user();
    if char_length(v_contact) not between 3 and 240 then
        raise exception 'INVALID_CONTACT';
    end if;

    select r.partnership_status into v_status
    from public.restaurants r
    where r.id = p_restaurant_id
    for update;

    if v_status is null then
        raise exception 'RESTAURANT_NOT_FOUND';
    end if;
    if v_status = 'SUSPENDED' then
        raise exception 'RESTAURANT_SUSPENDED';
    end if;
    if exists (
        select 1 from public.restaurant_users ru
        where ru.restaurant_id = p_restaurant_id and ru.user_id = v_user
    ) then
        raise exception 'ALREADY_MEMBER';
    end if;
    if exists (
        select 1 from public.restaurant_claims c
        where c.restaurant_id = p_restaurant_id and c.user_id = v_user and c.status = 'PENDING'
    ) then
        raise exception 'CLAIM_ALREADY_PENDING';
    end if;
    if (select count(*) from public.restaurant_claims c where c.user_id = v_user and c.status = 'PENDING') >= 3 then
        raise exception 'TOO_MANY_CLAIMS';
    end if;

    insert into public.restaurant_claims (restaurant_id, user_id, status, contact_info)
    values (p_restaurant_id, v_user, 'PENDING', v_contact)
    returning id into v_claim_id;

    if v_status = 'DIRECTORY_ONLY' then
        update public.restaurants set partnership_status = 'CLAIM_PENDING' where id = p_restaurant_id;
    end if;

    perform public.log_audit('CLAIM_SUBMITTED', p_restaurant_id, v_user,
        jsonb_build_object('claim_id', v_claim_id, 'restaurant_was', v_status));
    return v_claim_id;
end;
$$;

create or replace function public.register_new_restaurant(
    p_name text,
    p_category text,
    p_address text,
    p_city text,
    p_province text,
    p_latitude double precision,
    p_longitude double precision,
    p_phone_number text,
    p_contact_info text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_restaurant uuid;
begin
    perform public.assert_active_user();
    if p_latitude is null or p_longitude is null
       or p_latitude not between -90 and 90 or p_longitude not between -180 and 180 then
        raise exception 'INVALID_LOCATION';
    end if;
    if char_length(btrim(coalesce(p_name, ''))) not between 2 and 160
       or char_length(btrim(coalesce(p_address, ''))) not between 3 and 240
       or char_length(btrim(coalesce(p_city, ''))) not between 2 and 100 then
        raise exception 'INVALID_RESTAURANT_DATA';
    end if;
    if (select count(*) from public.audit_log a
        where a.actor_id = auth.uid() and a.action = 'RESTAURANT_REGISTERED'
          and a.created_at > now() - interval '1 day') >= 2 then
        raise exception 'TOO_MANY_REGISTRATIONS';
    end if;

    insert into public.restaurants (
        name, category, address, city, province, location,
        phone_number, phone_public, partnership_status, data_source
    ) values (
        btrim(p_name),
        left(coalesce(nullif(btrim(p_category), ''), 'Ristorante'), 100),
        btrim(p_address),
        btrim(p_city),
        upper(left(coalesce(nullif(btrim(p_province), ''), 'PU'), 8)),
        extensions.st_point(p_longitude, p_latitude)::extensions.geography,
        nullif(left(btrim(coalesce(p_phone_number, '')), 40), ''),
        false,
        'DIRECTORY_ONLY',
        'PARTNER_SIGNUP'
    )
    returning id into v_restaurant;

    perform public.log_audit('RESTAURANT_REGISTERED', v_restaurant, auth.uid(),
        jsonb_build_object('name', btrim(p_name), 'city', btrim(p_city)));
    perform public.submit_restaurant_claim(v_restaurant, p_contact_info);
    return v_restaurant;
end;
$$;

create or replace function public.cancel_my_claim(p_claim_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_restaurant uuid;
begin
    update public.restaurant_claims c
    set status = 'CANCELLED', reviewed_at = now(), phone_code_hash = null
    where c.id = p_claim_id
      and c.user_id = auth.uid()
      and c.status = 'PENDING'
    returning c.restaurant_id into v_restaurant;

    if v_restaurant is null then
        raise exception 'CLAIM_NOT_FOUND';
    end if;
    perform public.reset_claim_pending_if_idle(v_restaurant);
    perform public.log_audit('CLAIM_CANCELLED', v_restaurant, auth.uid(), jsonb_build_object('claim_id', p_claim_id));
end;
$$;

-- Le richieste dell'utente, con il nome del locale (per la schermata "Verifica in corso").
create or replace function public.my_claims()
returns table (
    claim_id uuid,
    restaurant_id uuid,
    restaurant_name text,
    restaurant_city text,
    status public.claim_status,
    created_at timestamptz,
    reviewed_at timestamptz,
    review_note text,
    phone_code_pending boolean,
    phone_verified_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
    select c.id, r.id, r.name, r.city, c.status, c.created_at, c.reviewed_at, c.review_note,
           c.phone_code_hash is not null and c.phone_code_expires_at > now() and c.phone_verified_at is null,
           c.phone_verified_at
    from public.restaurant_claims c
    join public.restaurants r on r.id = c.restaurant_id
    where c.user_id = auth.uid()
    order by c.created_at desc
    limit 20;
$$;

-- Admin: genera il codice da dettare al telefono PUBBLICO del locale. Restituisce il codice in
-- chiaro una sola volta; nel database resta solo l'impronta (bcrypt).
create or replace function public.admin_issue_claim_code(p_claim_id uuid)
returns text
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
    v_claim public.restaurant_claims;
    v_code text;
begin
    perform public.assert_admin();
    select * into v_claim from public.restaurant_claims c where c.id = p_claim_id for update;
    if v_claim.id is null then
        raise exception 'CLAIM_NOT_FOUND';
    end if;
    if v_claim.status <> 'PENDING' then
        raise exception 'CLAIM_NOT_PENDING';
    end if;

    v_code := lpad((abs(('x' || encode(extensions.gen_random_bytes(4), 'hex'))::bit(32)::bigint) % 1000000)::text, 6, '0');
    update public.restaurant_claims
    set phone_code_hash = extensions.crypt(v_code, extensions.gen_salt('bf', 8)),
        phone_code_expires_at = now() + interval '48 hours',
        phone_code_attempts = 0,
        phone_verified_at = null
    where id = p_claim_id;

    perform public.log_audit('CLAIM_CODE_ISSUED', v_claim.restaurant_id, v_claim.user_id,
        jsonb_build_object('claim_id', p_claim_id));
    return v_code;
end;
$$;

-- Il richiedente inserisce il codice ricevuto al telefono del locale. Massimo 5 tentativi.
create or replace function public.verify_my_claim_code(p_claim_id uuid, p_code text)
returns table (ok boolean, error_code text, attempts_left integer)
language plpgsql
volatile
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
    v_claim public.restaurant_claims;
begin
    perform public.assert_active_user();
    select * into v_claim from public.restaurant_claims c
    where c.id = p_claim_id and c.user_id = auth.uid()
    for update;

    if v_claim.id is null then
        return query select false, 'CLAIM_NOT_FOUND'::text, 0;
        return;
    end if;
    if v_claim.status <> 'PENDING' then
        return query select false, 'CLAIM_NOT_PENDING'::text, 0;
        return;
    end if;
    if v_claim.phone_verified_at is not null then
        return query select true, null::text, 0;
        return;
    end if;
    if v_claim.phone_code_hash is null or v_claim.phone_code_expires_at <= now() then
        return query select false, 'NO_ACTIVE_CODE'::text, 0;
        return;
    end if;
    if v_claim.phone_code_attempts >= 5 then
        return query select false, 'TOO_MANY_ATTEMPTS'::text, 0;
        return;
    end if;

    if v_claim.phone_code_hash = extensions.crypt(btrim(coalesce(p_code, '')), v_claim.phone_code_hash) then
        update public.restaurant_claims
        set phone_verified_at = now(), phone_code_hash = null
        where id = p_claim_id;
        perform public.log_audit('CLAIM_PHONE_VERIFIED', v_claim.restaurant_id, auth.uid(),
            jsonb_build_object('claim_id', p_claim_id));
        return query select true, null::text, 0;
    else
        update public.restaurant_claims
        set phone_code_attempts = phone_code_attempts + 1,
            phone_code_hash = case when phone_code_attempts + 1 >= 5 then null else phone_code_hash end
        where id = p_claim_id;
        perform public.log_audit('CLAIM_PHONE_CODE_WRONG', v_claim.restaurant_id, auth.uid(),
            jsonb_build_object('claim_id', p_claim_id, 'attempt', v_claim.phone_code_attempts + 1));
        return query select false,
            case when v_claim.phone_code_attempts + 1 >= 5 then 'TOO_MANY_ATTEMPTS' else 'WRONG_CODE' end::text,
            greatest(0, 4 - v_claim.phone_code_attempts);
    end if;
end;
$$;

drop function if exists public.admin_review_claim(uuid, boolean, text);
create or replace function public.admin_review_claim(
    p_claim_id uuid,
    p_approve boolean,
    p_note text default null,
    p_skip_phone_check boolean default false
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_claim public.restaurant_claims;
    v_note text := nullif(btrim(coalesce(p_note, '')), '');
    v_name text;
begin
    perform public.assert_admin();

    select * into v_claim
    from public.restaurant_claims c
    where c.id = p_claim_id
    for update;

    if v_claim.id is null then
        raise exception 'CLAIM_NOT_FOUND';
    end if;
    if v_claim.status <> 'PENDING' then
        raise exception 'CLAIM_NOT_PENDING';
    end if;
    if p_approve and v_claim.phone_verified_at is null
       and not (p_skip_phone_check and char_length(coalesce(v_note, '')) >= 5) then
        -- Prima si verifica al telefono del locale (admin_issue_claim_code + codice nell'app).
        -- Eccezione solo con motivazione scritta (es. "visita di persona con documento").
        raise exception 'PHONE_NOT_VERIFIED';
    end if;
    if p_approve and public.is_user_blocked(v_claim.user_id) then
        raise exception 'ACCOUNT_BLOCKED';
    end if;

    update public.restaurant_claims
    set status = case when p_approve then 'APPROVED'::public.claim_status else 'REJECTED'::public.claim_status end,
        reviewed_at = now(),
        reviewed_by = auth.uid(),
        review_note = v_note,
        phone_code_hash = null
    where id = p_claim_id;

    select r.name into v_name from public.restaurants r where r.id = v_claim.restaurant_id;

    if p_approve then
        insert into public.restaurant_users (restaurant_id, user_id, role)
        values (v_claim.restaurant_id, v_claim.user_id, 'OWNER')
        on conflict (restaurant_id, user_id) do update set role = 'OWNER';

        update public.restaurants
        set partnership_status = 'ACTIVE_PARTNER'
        where id = v_claim.restaurant_id
          and partnership_status in ('DIRECTORY_ONLY', 'CLAIM_PENDING');
    else
        perform public.reset_claim_pending_if_idle(v_claim.restaurant_id);
    end if;

    insert into public.notification_outbox (user_id, kind, restaurant_id, title, body, data)
    values (
        v_claim.user_id,
        'CLAIM_UPDATE',
        v_claim.restaurant_id,
        case when p_approve then 'Richiesta approvata' else 'Richiesta non approvata' end,
        left(case when p_approve
                  then coalesce(v_name, 'Il tuo locale') || ': ora puoi gestirlo da HAPOSTO.'
                  else coalesce(v_name, 'Il locale') || ': la richiesta non è stata approvata.'
                       || coalesce(' ' || v_note, '') end, 240),
        jsonb_build_object('restaurant_id', v_claim.restaurant_id, 'action', 'OPEN_RESTAURANT_AREA')
    );

    perform public.log_audit(
        case when p_approve then 'CLAIM_APPROVED' else 'CLAIM_REJECTED' end,
        v_claim.restaurant_id, v_claim.user_id,
        jsonb_build_object('claim_id', p_claim_id, 'note', v_note,
                           'phone_verified', v_claim.phone_verified_at is not null,
                           'skip_phone_check', coalesce(p_skip_phone_check, false)));
end;
$$;

drop function if exists public.admin_pending_claims();
create or replace function public.admin_pending_claims()
returns table (
    claim_id uuid,
    created_at timestamptz,
    restaurant_id uuid,
    restaurant_name text,
    restaurant_city text,
    restaurant_address text,
    restaurant_phone text,
    partnership_status public.partnership_status,
    current_owners integer,
    requester_id uuid,
    requester_email text,
    requester_name text,
    contact_info text,
    phone_code_active boolean,
    phone_verified_at timestamptz
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
    select c.id, c.created_at, r.id, r.name, r.city, r.address, r.phone_number, r.partnership_status,
           (select count(*)::integer from public.restaurant_users ru
            where ru.restaurant_id = r.id and ru.role = 'OWNER'),
           c.user_id, u.email::text, p.display_name, c.contact_info,
           c.phone_code_hash is not null and c.phone_code_expires_at > now(),
           c.phone_verified_at
    from public.restaurant_claims c
    join public.restaurants r on r.id = c.restaurant_id
    left join auth.users u on u.id = c.user_id
    left join public.profiles p on p.id = c.user_id
    where c.status = 'PENDING'
    order by c.created_at;
end;
$$;

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
    perform public.assert_admin();
    if p_months not between 1 and 36 then
        raise exception 'INVALID_MONTHS';
    end if;
    if exists (select 1 from public.restaurant_subscriptions s
               where s.restaurant_id = p_restaurant_id and s.provider = 'STRIPE'
                 and s.status in ('TRIALING', 'ACTIVE', 'PAST_DUE')) then
        -- Un abbonamento pagato si gestisce su Stripe, non si sovrascrive a mano.
        raise exception 'PAID_SUBSCRIPTION_ACTIVE';
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

    perform public.log_audit('PLAN_GRANTED', p_restaurant_id, null,
        jsonb_build_object('plan', p_plan_code, 'months', p_months, 'note', p_note, 'subscription_id', v_id));
    return v_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- 9) Pannello admin: panoramica, locali, utenti, abbonamenti, log, impostazioni.
-- ---------------------------------------------------------------------------
create or replace function public.admin_overview()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
    perform public.assert_admin();
    return jsonb_build_object(
        'users_total', (select count(*) from auth.users),
        'users_last_7_days', (select count(*) from auth.users u where u.created_at > now() - interval '7 days'),
        'users_blocked', (select count(*) from public.profiles p where p.blocked_at is not null),
        'restaurants_total', (select count(*) from public.restaurants r where r.data_source <> 'DEV_SEED'),
        'partners', (select count(*) from public.restaurants r where r.partnership_status = 'ACTIVE_PARTNER'),
        'claims_pending', (select count(*) from public.restaurant_claims c where c.status = 'PENDING'),
        'restaurants_suspended', (select count(*) from public.restaurants r where r.partnership_status = 'SUSPENDED'),
        'partners_live_now', (select count(*) from public.restaurant_live_status s
                              join public.restaurants r on r.id = s.restaurant_id
                              where r.partnership_status = 'ACTIVE_PARTNER' and s.valid_until > now()),
        'publishes_last_24h', (select count(*) from public.status_history h where h.updated_at > now() - interval '24 hours'),
        'restaurant_subscriptions_paid', (select count(*) from public.restaurant_subscriptions s
                                          where s.provider = 'STRIPE' and s.status in ('TRIALING', 'ACTIVE', 'PAST_DUE')),
        'restaurant_subscriptions_manual', (select count(*) from public.restaurant_subscriptions s
                                            where s.provider = 'MANUAL' and s.status in ('TRIALING', 'ACTIVE', 'PAST_DUE')),
        'consumer_plus_active', (select count(*) from public.consumer_subscriptions s
                                 where s.plan_code = 'CONSUMER_PLUS' and s.status in ('TRIALING', 'ACTIVE', 'PAST_DUE')),
        'revenue_last_30_days_cents', (select coalesce(sum(p.amount_cents), 0) from public.payments p
                                       where p.status = 'SUCCEEDED' and p.paid_at > now() - interval '30 days'),
        'beta_until', public.config_value('beta', 'restaurants_all_pro_until')
    );
end;
$$;

create or replace function public.admin_list_restaurants(
    p_query text default null,
    p_status text default null,
    p_limit integer default 50,
    p_offset integer default 0
)
returns table (
    restaurant_id uuid,
    name text,
    city text,
    partnership_status public.partnership_status,
    data_source text,
    plan_code text,
    members integer,
    last_publish_at timestamptz,
    phone_number text,
    slug text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
    v_query text := nullif(lower(btrim(coalesce(p_query, ''))), '');
begin
    perform public.assert_admin();
    return query
    select r.id, r.name, r.city, r.partnership_status, r.data_source,
           public.restaurant_plan_code(r.id),
           (select count(*)::integer from public.restaurant_users ru where ru.restaurant_id = r.id),
           (select max(h.updated_at) from public.status_history h where h.restaurant_id = r.id),
           r.phone_number, r.slug
    from public.restaurants r
    where (v_query is null
           or lower(r.name) like '%' || v_query || '%'
           or lower(r.city) like '%' || v_query || '%'
           or r.id::text = v_query
           or r.slug = v_query)
      and (p_status is null or r.partnership_status::text = p_status)
    order by (r.partnership_status = 'CLAIM_PENDING') desc, r.name
    limit greatest(1, least(coalesce(p_limit, 50), 200))
    offset greatest(0, coalesce(p_offset, 0));
end;
$$;

create or replace function public.admin_restaurant_detail(p_restaurant_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_result jsonb;
begin
    perform public.assert_admin();
    select jsonb_build_object(
        'restaurant', jsonb_build_object(
            'id', r.id, 'name', r.name, 'category', r.category, 'address', r.address, 'city', r.city,
            'province', r.province, 'phone_number', r.phone_number, 'phone_public', r.phone_public,
            'partnership_status', r.partnership_status, 'data_source', r.data_source, 'slug', r.slug,
            'latitude', extensions.st_y(r.location::extensions.geometry),
            'longitude', extensions.st_x(r.location::extensions.geometry),
            'created_at', r.created_at),
        'plan_code', public.restaurant_plan_code(r.id),
        'live', (select to_jsonb(s) - 'restaurant_id' from public.restaurant_live_status s where s.restaurant_id = r.id),
        'members', coalesce((
            select jsonb_agg(jsonb_build_object('user_id', ru.user_id, 'email', u.email, 'role', ru.role,
                                                'since', ru.created_at) order by ru.role, ru.created_at)
            from public.restaurant_users ru join auth.users u on u.id = ru.user_id
            where ru.restaurant_id = r.id), '[]'::jsonb),
        'claims', coalesce((
            select jsonb_agg(jsonb_build_object('claim_id', c.id, 'status', c.status, 'email', u.email,
                                                'created_at', c.created_at, 'phone_verified_at', c.phone_verified_at,
                                                'review_note', c.review_note) order by c.created_at desc)
            from public.restaurant_claims c left join auth.users u on u.id = c.user_id
            where c.restaurant_id = r.id), '[]'::jsonb),
        'subscriptions', coalesce((
            select jsonb_agg(jsonb_build_object('id', s.id, 'plan_code', s.plan_code, 'status', s.status,
                                                'provider', s.provider, 'period_end', s.current_period_end,
                                                'note', s.note) order by s.created_at desc)
            from public.restaurant_subscriptions s where s.restaurant_id = r.id), '[]'::jsonb),
        'recent_publishes', coalesce((
            select jsonb_agg(x order by x.updated_at desc) from (
                select h.status, h.updated_at, h.updated_via, u.email as by_email
                from public.status_history h left join auth.users u on u.id = h.updated_by
                where h.restaurant_id = r.id order by h.updated_at desc limit 20) x), '[]'::jsonb),
        'stats_30_days', (
            select jsonb_build_object('detail_views', coalesce(sum(st.detail_views), 0),
                                      'directions_taps', coalesce(sum(st.directions_taps), 0),
                                      'call_taps', coalesce(sum(st.call_taps), 0),
                                      'live_updates', coalesce(sum(st.live_updates), 0))
            from public.restaurant_daily_stats st
            where st.restaurant_id = r.id and st.day > current_date - 30)
    ) into v_result
    from public.restaurants r
    where r.id = p_restaurant_id;

    if v_result is null then
        raise exception 'RESTAURANT_NOT_FOUND';
    end if;
    return v_result;
end;
$$;

create or replace function public.admin_update_restaurant(
    p_restaurant_id uuid,
    p_name text default null,
    p_category text default null,
    p_address text default null,
    p_city text default null,
    p_province text default null,
    p_latitude double precision default null,
    p_longitude double precision default null,
    p_phone_number text default null,
    p_phone_public boolean default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_before jsonb;
begin
    perform public.assert_admin();
    select to_jsonb(r) - 'location' into v_before from public.restaurants r where r.id = p_restaurant_id for update;
    if v_before is null then
        raise exception 'RESTAURANT_NOT_FOUND';
    end if;
    if (p_latitude is null) <> (p_longitude is null) then
        raise exception 'INVALID_LOCATION';
    end if;

    update public.restaurants r set
        name = coalesce(nullif(btrim(p_name), ''), r.name),
        category = coalesce(nullif(btrim(p_category), ''), r.category),
        address = coalesce(nullif(btrim(p_address), ''), r.address),
        city = coalesce(nullif(btrim(p_city), ''), r.city),
        province = upper(coalesce(nullif(btrim(p_province), ''), r.province)),
        location = case when p_latitude is null then r.location
                        else extensions.st_point(p_longitude, p_latitude)::extensions.geography end,
        phone_number = case when p_phone_number is null then r.phone_number
                            else nullif(btrim(p_phone_number), '') end,
        phone_public = case
            when p_phone_public is null then r.phone_public and
                 (case when p_phone_number is null then r.phone_number else nullif(btrim(p_phone_number), '') end) is not null
            else p_phone_public and
                 (case when p_phone_number is null then r.phone_number else nullif(btrim(p_phone_number), '') end) is not null
        end
    where r.id = p_restaurant_id;

    perform public.log_audit('RESTAURANT_EDITED_BY_ADMIN', p_restaurant_id, null,
        jsonb_build_object('before', v_before));
end;
$$;

create or replace function public.admin_set_restaurant_status(
    p_restaurant_id uuid,
    p_status public.partnership_status,
    p_note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_old public.partnership_status;
begin
    perform public.assert_admin();
    select r.partnership_status into v_old from public.restaurants r where r.id = p_restaurant_id for update;
    if v_old is null then
        raise exception 'RESTAURANT_NOT_FOUND';
    end if;
    if p_status = 'ACTIVE_PARTNER'
       and not exists (select 1 from public.restaurant_users ru where ru.restaurant_id = p_restaurant_id and ru.role = 'OWNER') then
        raise exception 'OWNER_REQUIRED';
    end if;
    update public.restaurants set partnership_status = p_status where id = p_restaurant_id;
    if p_status in ('SUSPENDED', 'DIRECTORY_ONLY', 'PAUSED') then
        delete from public.restaurant_live_status where restaurant_id = p_restaurant_id;
    end if;
    perform public.log_audit('RESTAURANT_STATUS_CHANGED', p_restaurant_id, null,
        jsonb_build_object('from', v_old, 'to', p_status, 'note', p_note));
end;
$$;

create or replace function public.admin_add_member(
    p_restaurant_id uuid,
    p_email text,
    p_role public.restaurant_user_role,
    p_note text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_user uuid;
begin
    perform public.assert_admin();
    select u.id into v_user from auth.users u where lower(u.email) = lower(btrim(p_email));
    if v_user is null then
        raise exception 'USER_NOT_REGISTERED';
    end if;
    insert into public.restaurant_users (restaurant_id, user_id, role)
    values (p_restaurant_id, v_user, p_role)
    on conflict (restaurant_id, user_id) do update set role = excluded.role;
    perform public.log_audit('MEMBER_SET_BY_ADMIN', p_restaurant_id, v_user,
        jsonb_build_object('role', p_role, 'note', p_note));
    return v_user;
end;
$$;

create or replace function public.admin_remove_member(
    p_restaurant_id uuid,
    p_user_id uuid,
    p_note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    perform public.assert_admin();
    delete from public.restaurant_users where restaurant_id = p_restaurant_id and user_id = p_user_id;
    if found then
        perform public.log_audit('MEMBER_REMOVED_BY_ADMIN', p_restaurant_id, p_user_id,
            jsonb_build_object('note', p_note));
    end if;
    -- Senza più titolari il locale non può restare "live".
    if not exists (select 1 from public.restaurant_users ru where ru.restaurant_id = p_restaurant_id and ru.role = 'OWNER') then
        update public.restaurants set partnership_status = 'DIRECTORY_ONLY'
        where id = p_restaurant_id and partnership_status = 'ACTIVE_PARTNER';
        delete from public.restaurant_live_status where restaurant_id = p_restaurant_id;
    end if;
end;
$$;

create or replace function public.admin_list_users(
    p_query text default null,
    p_filter text default 'ALL',
    p_limit integer default 50,
    p_offset integer default 0
)
returns table (
    user_id uuid,
    email text,
    display_name text,
    created_at timestamptz,
    last_sign_in_at timestamptz,
    is_admin boolean,
    blocked_at timestamptz,
    consumer_plan text,
    restaurants integer
)
language plpgsql
stable
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
    v_query text := nullif(lower(btrim(coalesce(p_query, ''))), '');
begin
    perform public.assert_admin();
    return query
    select u.id, u.email::text, p.display_name, u.created_at, u.last_sign_in_at,
           coalesce(p.is_platform_admin, false), p.blocked_at,
           public.consumer_plan_code(u.id),
           (select count(*)::integer from public.restaurant_users ru where ru.user_id = u.id)
    from auth.users u
    left join public.profiles p on p.id = u.id
    where (v_query is null or lower(u.email) like '%' || v_query || '%'
           or lower(coalesce(p.display_name, '')) like '%' || v_query || '%'
           or u.id::text = v_query)
      and case coalesce(p_filter, 'ALL')
              when 'ADMINS' then coalesce(p.is_platform_admin, false)
              when 'BLOCKED' then p.blocked_at is not null
              when 'RESTAURANT' then exists (select 1 from public.restaurant_users ru where ru.user_id = u.id)
              when 'PLUS' then public.consumer_plan_code(u.id) = 'CONSUMER_PLUS'
              else true
          end
    order by u.created_at desc
    limit greatest(1, least(coalesce(p_limit, 50), 200))
    offset greatest(0, coalesce(p_offset, 0));
end;
$$;

create or replace function public.admin_user_detail(p_user_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_result jsonb;
begin
    perform public.assert_admin();
    select jsonb_build_object(
        'user', jsonb_build_object('id', u.id, 'email', u.email, 'created_at', u.created_at,
                                   'last_sign_in_at', u.last_sign_in_at),
        'profile', (select to_jsonb(p) from public.profiles p where p.id = u.id),
        'consumer_plan', public.consumer_plan_code(u.id),
        'restaurants', coalesce((
            select jsonb_agg(jsonb_build_object('restaurant_id', r.id, 'name', r.name, 'city', r.city, 'role', ru.role))
            from public.restaurant_users ru join public.restaurants r on r.id = ru.restaurant_id
            where ru.user_id = u.id), '[]'::jsonb),
        'claims', coalesce((
            select jsonb_agg(jsonb_build_object('claim_id', c.id, 'restaurant', r.name, 'status', c.status,
                                                'created_at', c.created_at) order by c.created_at desc)
            from public.restaurant_claims c join public.restaurants r on r.id = c.restaurant_id
            where c.user_id = u.id), '[]'::jsonb),
        'subscriptions', coalesce((
            select jsonb_agg(jsonb_build_object('id', s.id, 'plan_code', s.plan_code, 'status', s.status,
                                                'provider', s.provider, 'period_end', s.current_period_end)
                             order by s.created_at desc)
            from public.consumer_subscriptions s where s.user_id = u.id), '[]'::jsonb),
        'favorites', (select count(*) from public.favorites f where f.user_id = u.id),
        'active_alerts', (select count(*) from public.availability_alerts a where a.user_id = u.id and a.is_active),
        'recent_activity', coalesce((
            select jsonb_agg(x order by x.created_at desc) from (
                select a.created_at, a.action, a.actor_kind, a.details
                from public.audit_log a
                where a.actor_id = u.id or a.target_user_id = u.id
                order by a.created_at desc limit 30) x), '[]'::jsonb)
    ) into v_result
    from auth.users u
    where u.id = p_user_id;

    if v_result is null then
        raise exception 'USER_NOT_FOUND';
    end if;
    return v_result;
end;
$$;

create or replace function public.admin_set_user_blocked(
    p_user_id uuid,
    p_blocked boolean,
    p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    perform public.assert_admin();
    if p_user_id = auth.uid() then
        raise exception 'CANNOT_BLOCK_SELF';
    end if;
    if p_blocked and exists (select 1 from public.profiles p where p.id = p_user_id and p.is_platform_admin) then
        -- Un altro admin si toglie dal SQL Editor, non dall'app.
        raise exception 'CANNOT_BLOCK_ADMIN';
    end if;
    insert into public.profiles (id) values (p_user_id) on conflict (id) do nothing;
    update public.profiles
    set blocked_at = case when p_blocked then now() else null end,
        blocked_reason = case when p_blocked then left(nullif(btrim(coalesce(p_reason, '')), ''), 300) else null end
    where id = p_user_id;
    update public.admin_sessions set revoked_at = now() where user_id = p_user_id and revoked_at is null;
    -- Impedisce anche nuovi accessi e rinnovi di sessione (Supabase Auth legge banned_until).
    begin
        update auth.users set banned_until = case when p_blocked then 'infinity'::timestamptz else null end
        where id = p_user_id;
    exception when others then
        null;  -- se non consentito, bastano i controlli del database
    end;
    perform public.log_audit(case when p_blocked then 'USER_BLOCKED' else 'USER_UNBLOCKED' end,
        null, p_user_id, jsonb_build_object('reason', p_reason));
end;
$$;

create or replace function public.admin_grant_consumer_plan(
    p_user_id uuid,
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
    perform public.assert_admin();
    if p_months not between 1 and 36 then
        raise exception 'INVALID_MONTHS';
    end if;
    if exists (select 1 from public.consumer_subscriptions s
               where s.user_id = p_user_id and s.provider <> 'PROMO'
                 and s.status in ('TRIALING', 'ACTIVE', 'PAST_DUE')) then
        raise exception 'PAID_SUBSCRIPTION_ACTIVE';
    end if;
    update public.consumer_subscriptions
    set status = 'CANCELED'
    where user_id = p_user_id and provider = 'PROMO' and status in ('TRIALING', 'ACTIVE', 'PAST_DUE');
    insert into public.consumer_subscriptions (user_id, plan_code, status, provider, current_period_end, auto_renewing)
    values (p_user_id, 'CONSUMER_PLUS', 'ACTIVE', 'PROMO', now() + make_interval(months => p_months), false)
    returning id into v_id;
    perform public.log_audit('PLUS_GRANTED', null, p_user_id,
        jsonb_build_object('months', p_months, 'note', p_note, 'subscription_id', v_id));
    return v_id;
end;
$$;

-- Chiude un abbonamento dato a mano (MANUAL/PROMO). Quelli pagati si chiudono su Stripe/Play.
create or replace function public.admin_cancel_subscription(
    p_kind text,
    p_subscription_id uuid,
    p_note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_restaurant uuid;
    v_user uuid;
begin
    perform public.assert_admin();
    if p_kind = 'RESTAURANT' then
        update public.restaurant_subscriptions
        set status = 'CANCELED', note = left(coalesce(note || ' · ', '') || coalesce(p_note, 'Chiuso da admin'), 300)
        where id = p_subscription_id and provider in ('MANUAL', 'BETA') and status in ('TRIALING', 'ACTIVE', 'PAST_DUE')
        returning restaurant_id into v_restaurant;
        if v_restaurant is null then
            raise exception 'SUBSCRIPTION_NOT_CANCELLABLE';
        end if;
    elsif p_kind = 'CONSUMER' then
        update public.consumer_subscriptions
        set status = 'CANCELED'
        where id = p_subscription_id and provider = 'PROMO' and status in ('TRIALING', 'ACTIVE', 'PAST_DUE')
        returning user_id into v_user;
        if v_user is null then
            raise exception 'SUBSCRIPTION_NOT_CANCELLABLE';
        end if;
    else
        raise exception 'INVALID_KIND';
    end if;
    perform public.log_audit('SUBSCRIPTION_CANCELED_BY_ADMIN', v_restaurant, v_user,
        jsonb_build_object('kind', p_kind, 'subscription_id', p_subscription_id, 'note', p_note));
end;
$$;

create or replace function public.admin_list_subscriptions(p_kind text default 'ALL', p_limit integer default 100)
returns table (
    kind text,
    subscription_id uuid,
    subject_id uuid,
    subject_name text,
    plan_code text,
    status text,
    provider text,
    current_period_end timestamptz,
    created_at timestamptz
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
    select * from (
        select 'RESTAURANT'::text, s.id, s.restaurant_id, r.name, s.plan_code, s.status, s.provider,
               s.current_period_end, s.created_at
        from public.restaurant_subscriptions s join public.restaurants r on r.id = s.restaurant_id
        where coalesce(p_kind, 'ALL') in ('ALL', 'RESTAURANT')
        union all
        select 'CONSUMER'::text, s.id, s.user_id, u.email::text, s.plan_code, s.status, s.provider,
               s.current_period_end, s.created_at
        from public.consumer_subscriptions s join auth.users u on u.id = s.user_id
        where coalesce(p_kind, 'ALL') in ('ALL', 'CONSUMER')
    ) x
    order by (x.status in ('TRIALING', 'ACTIVE', 'PAST_DUE')) desc, x.created_at desc
    limit greatest(1, least(coalesce(p_limit, 100), 500));
end;
$$;

create or replace function public.admin_list_payments(p_limit integer default 100, p_offset integer default 0)
returns table (
    payment_id uuid,
    paid_at timestamptz,
    payer_kind text,
    payer_name text,
    provider text,
    plan_code text,
    amount_cents integer,
    vat_cents integer,
    status text,
    invoice_number text
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
    select p.id, coalesce(p.paid_at, p.created_at), p.payer_kind,
           coalesce(r.name, u.email::text, '—'),
           p.provider, p.plan_code, p.amount_cents, p.vat_cents, p.status, p.invoice_number
    from public.payments p
    left join public.restaurants r on r.id = p.restaurant_id
    left join auth.users u on u.id = p.user_id
    order by coalesce(p.paid_at, p.created_at) desc
    limit greatest(1, least(coalesce(p_limit, 100), 500))
    offset greatest(0, coalesce(p_offset, 0));
end;
$$;

create or replace function public.admin_audit_log(
    p_limit integer default 100,
    p_before_id bigint default null,
    p_action text default null,
    p_restaurant_id uuid default null,
    p_user_id uuid default null
)
returns table (
    log_id bigint,
    created_at timestamptz,
    actor_kind text,
    actor_email text,
    action text,
    restaurant_id uuid,
    restaurant_name text,
    target_email text,
    details jsonb
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
    select a.id, a.created_at, a.actor_kind, ua.email::text, a.action, a.restaurant_id, r.name,
           ut.email::text, a.details
    from public.audit_log a
    left join auth.users ua on ua.id = a.actor_id
    left join auth.users ut on ut.id = a.target_user_id
    left join public.restaurants r on r.id = a.restaurant_id
    where (p_before_id is null or a.id < p_before_id)
      and (p_action is null or a.action = p_action or a.action like p_action || '%')
      and (p_restaurant_id is null or a.restaurant_id = p_restaurant_id)
      and (p_user_id is null or a.actor_id = p_user_id or a.target_user_id = p_user_id)
    order by a.id desc
    limit greatest(1, least(coalesce(p_limit, 100), 500));
end;
$$;

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
    if p_key not in ('beta', 'security', 'min_supported_app_version', 'public_links', 'legal', 'dev_tools_enabled') then
        raise exception 'CONFIG_KEY_NOT_EDITABLE';
    end if;
    if p_value is null then
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
-- 10) Regole di accesso aggiornate: account bloccati e 2FA sui dati sensibili dei locali.
-- ---------------------------------------------------------------------------
drop policy if exists "favorites_own" on public.favorites;
create policy "favorites_own"
on public.favorites
for all
to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()) and not public.is_user_blocked((select auth.uid())));

drop policy if exists "alerts_own" on public.availability_alerts;
create policy "alerts_own"
on public.availability_alerts
for all
to authenticated
using (user_id = (select auth.uid()))
with check (user_id = (select auth.uid()) and not public.is_user_blocked((select auth.uid())));

-- Prenotazioni: dati personali dei clienti → solo membri con 2FA.
drop policy if exists "reservations_members_read" on public.reservations;
create policy "reservations_members_read"
on public.reservations
for select
to authenticated
using (public.restaurant_role(restaurant_id) is not null and public.restaurant_mfa_satisfied());

drop policy if exists "reservations_members_write" on public.reservations;
create policy "reservations_members_write"
on public.reservations
for insert
to authenticated
with check (
    public.restaurant_role(restaurant_id) is not null
    and public.restaurant_mfa_satisfied()
    and public.restaurant_has_feature(restaurant_id, 'RESERVATIONS_CLOUD')
    and created_by = (select auth.uid())
);

drop policy if exists "reservations_members_update" on public.reservations;
create policy "reservations_members_update"
on public.reservations
for update
to authenticated
using (public.restaurant_role(restaurant_id) is not null and public.restaurant_mfa_satisfied())
with check (
    public.restaurant_role(restaurant_id) is not null
    and public.restaurant_mfa_satisfied()
    and public.restaurant_has_feature(restaurant_id, 'RESERVATIONS_CLOUD')
);

drop policy if exists "reservations_members_delete" on public.reservations;
create policy "reservations_members_delete"
on public.reservations
for delete
to authenticated
using (public.restaurant_role(restaurant_id) is not null and public.restaurant_mfa_satisfied());

-- Dati di fatturazione: solo titolare con 2FA.
drop policy if exists "billing_profiles_owner_read" on public.restaurant_billing_profiles;
create policy "billing_profiles_owner_read"
on public.restaurant_billing_profiles
for select
to authenticated
using ((public.is_restaurant_owner(restaurant_id) and public.restaurant_mfa_satisfied()) or public.is_platform_admin());

drop policy if exists "billing_profiles_owner_insert" on public.restaurant_billing_profiles;
create policy "billing_profiles_owner_insert"
on public.restaurant_billing_profiles
for insert
to authenticated
with check (public.is_restaurant_owner(restaurant_id) and public.restaurant_mfa_satisfied());

drop policy if exists "billing_profiles_owner_update" on public.restaurant_billing_profiles;
create policy "billing_profiles_owner_update"
on public.restaurant_billing_profiles
for update
to authenticated
using (public.is_restaurant_owner(restaurant_id) and public.restaurant_mfa_satisfied())
with check (public.is_restaurant_owner(restaurant_id) and public.restaurant_mfa_satisfied());

-- ---------------------------------------------------------------------------
-- 11) Permessi sulle funzioni.
-- ---------------------------------------------------------------------------
-- Interne (usate solo da altre funzioni o dalle policy).
revoke execute on function public.log_audit(text, uuid, uuid, jsonb) from public, anon, authenticated;
revoke execute on function public.config_value(text, text) from public, anon, authenticated;
revoke execute on function public.assert_active_user() from public, anon, authenticated;
revoke execute on function public.assert_restaurant_mfa() from public, anon, authenticated;
revoke execute on function public.assert_admin() from public, anon, authenticated;
revoke execute on function public.is_user_blocked(uuid) from public, anon;
revoke execute on function public.admin_set_credentials(text, text, text) from public, anon, authenticated;
grant execute on function public.is_user_blocked(uuid) to authenticated;
grant execute on function public.current_aal() to anon, authenticated;
grant execute on function public.current_session_id() to authenticated;
grant execute on function public.restaurant_mfa_satisfied() to authenticated;

-- Per gli utenti collegati.
do $$
declare
    v_fn text;
begin
    foreach v_fn in array array[
        'public.is_platform_admin_account()',
        'public.is_platform_admin()',
        'public.admin_unlock(text, text)',
        'public.admin_lock()',
        'public.my_admin_status()',
        'public.restaurant_members(uuid)',
        'public.my_claims()',
        'public.verify_my_claim_code(uuid, text)',
        'public.submit_restaurant_claim(uuid, text)',
        'public.register_new_restaurant(text, text, text, text, text, double precision, double precision, text, text)',
        'public.cancel_my_claim(uuid)',
        'public.set_restaurant_live_status(uuid, public.live_status, smallint, smallint, varchar)',
        'public.add_restaurant_staff(uuid, text)',
        'public.remove_restaurant_staff(uuid, uuid)',
        'public.restaurant_role(uuid)',
        'public.is_restaurant_member(uuid)',
        -- Admin: il controllo vero è dentro (assert_admin), il permesso serve a chiamarle.
        'public.admin_issue_claim_code(uuid)',
        'public.admin_review_claim(uuid, boolean, text, boolean)',
        'public.admin_pending_claims()',
        'public.admin_grant_restaurant_plan(uuid, text, integer, text)',
        'public.admin_overview()',
        'public.admin_list_restaurants(text, text, integer, integer)',
        'public.admin_restaurant_detail(uuid)',
        'public.admin_update_restaurant(uuid, text, text, text, text, text, double precision, double precision, text, boolean)',
        'public.admin_set_restaurant_status(uuid, public.partnership_status, text)',
        'public.admin_add_member(uuid, text, public.restaurant_user_role, text)',
        'public.admin_remove_member(uuid, uuid, text)',
        'public.admin_list_users(text, text, integer, integer)',
        'public.admin_user_detail(uuid)',
        'public.admin_set_user_blocked(uuid, boolean, text)',
        'public.admin_grant_consumer_plan(uuid, integer, text)',
        'public.admin_cancel_subscription(text, uuid, text)',
        'public.admin_list_subscriptions(text, integer)',
        'public.admin_list_payments(integer, integer)',
        'public.admin_audit_log(integer, bigint, text, uuid, uuid)',
        'public.admin_set_config(text, jsonb)'
    ] loop
        execute format('revoke execute on function %s from public, anon', v_fn);
        execute format('grant execute on function %s to authenticated', v_fn);
    end loop;
end;
$$;
