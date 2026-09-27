-- HAPOSTO STEP 8 — Account (utenti e ristoratori), profili, amministrazione dei claim.
--
-- Esegui DOPO 0006. Richiede Supabase Auth attivo (Authentication → Providers → Google).
-- L'account è FACOLTATIVO per chi cerca un tavolo: serve solo per funzioni avanzate
-- (preferiti sincronizzati, avvisi, Plus) e per chi gestisce un locale.

-- ---------------------------------------------------------------------------
-- 1) Profilo applicativo, uno per ogni utente Supabase Auth.
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
    id uuid primary key references auth.users(id) on delete cascade,
    display_name text check (display_name is null or char_length(display_name) between 1 and 80),
    is_platform_admin boolean not null default false,
    marketing_opt_in boolean not null default false,
    accepted_terms_version text,
    accepted_terms_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

drop trigger if exists profiles_touch_updated_at on public.profiles;
create trigger profiles_touch_updated_at
    before update on public.profiles
    for each row execute function public.touch_updated_at();

-- Creazione automatica del profilo alla registrazione (Google o email).
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    insert into public.profiles (id, display_name)
    values (
        new.id,
        nullif(left(coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name', ''), 80), '')
    )
    on conflict (id) do nothing;
    return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_auth_user();

-- Utenti già registrati prima di questa migration.
insert into public.profiles (id)
select u.id from auth.users u
on conflict (id) do nothing;

create or replace function public.is_platform_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select coalesce(
        (select p.is_platform_admin from public.profiles p where p.id = auth.uid()),
        false
    );
$$;

create or replace function public.accept_terms(p_version text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    if auth.uid() is null then
        raise exception 'AUTH_REQUIRED';
    end if;
    if p_version is null or char_length(p_version) not between 1 and 20 then
        raise exception 'INVALID_TERMS_VERSION';
    end if;
    update public.profiles
    set accepted_terms_version = p_version,
        accepted_terms_at = now()
    where id = auth.uid();
end;
$$;

alter table public.profiles enable row level security;
revoke all on table public.profiles from anon, authenticated;
grant select on table public.profiles to authenticated;
-- Solo questi campi sono modificabili dal client: is_platform_admin e i termini no.
grant update (display_name, marketing_opt_in) on table public.profiles to authenticated;

drop policy if exists "profiles_own_or_admin_read" on public.profiles;
create policy "profiles_own_or_admin_read"
on public.profiles
for select
to authenticated
using (id = (select auth.uid()) or public.is_platform_admin());

drop policy if exists "profiles_own_update" on public.profiles;
create policy "profiles_own_update"
on public.profiles
for update
to authenticated
using (id = (select auth.uid()))
with check (id = (select auth.uid()));

-- ---------------------------------------------------------------------------
-- 2) Ruoli nel locale.
-- ---------------------------------------------------------------------------
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
      and ru.user_id = auth.uid();
$$;

create or replace function public.is_restaurant_owner(target_restaurant_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select coalesce(public.restaurant_role(target_restaurant_id) = 'OWNER', false);
$$;

-- Il titolare vede anche i membri del proprio staff (la policy 0004 mostra solo la propria riga).
drop policy if exists "restaurant_users_owner_read" on public.restaurant_users;
create policy "restaurant_users_owner_read"
on public.restaurant_users
for select
to authenticated
using (public.is_restaurant_owner(restaurant_id) or public.is_platform_admin());

create or replace function public.my_restaurants()
returns table (
    restaurant_id uuid,
    name text,
    city text,
    role public.restaurant_user_role,
    partnership_status public.partnership_status
)
language sql
stable
security definer
set search_path = ''
as $$
    select r.id, r.name, r.city, ru.role, r.partnership_status
    from public.restaurant_users ru
    join public.restaurants r on r.id = ru.restaurant_id
    where ru.user_id = auth.uid()
    order by r.name;
$$;

-- ---------------------------------------------------------------------------
-- 3) Claim: "questo locale è mio" → verifica manuale → titolare.
-- ---------------------------------------------------------------------------
alter table public.restaurant_claims
    add column if not exists review_note text check (review_note is null or char_length(review_note) <= 500);

create unique index if not exists restaurant_claims_one_pending_uidx
    on public.restaurant_claims (restaurant_id, user_id)
    where status = 'PENDING';

-- Le richieste passano dalla funzione (validazioni), non da insert diretti.
revoke insert on table public.restaurant_claims from authenticated;
drop policy if exists "claims_own_insert" on public.restaurant_claims;

drop policy if exists "claims_admin_read" on public.restaurant_claims;
create policy "claims_admin_read"
on public.restaurant_claims
for select
to authenticated
using (public.is_platform_admin());

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
    if v_user is null then
        raise exception 'AUTH_REQUIRED';
    end if;
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

    insert into public.restaurant_claims (restaurant_id, user_id, status, contact_info)
    values (p_restaurant_id, v_user, 'PENDING', v_contact)
    returning id into v_claim_id;

    if v_status = 'DIRECTORY_ONLY' then
        update public.restaurants set partnership_status = 'CLAIM_PENDING' where id = p_restaurant_id;
    end if;

    return v_claim_id;
end;
$$;

-- Riporta a DIRECTORY_ONLY un locale "in verifica" se non ha più richieste aperte né titolari.
create or replace function public.reset_claim_pending_if_idle(p_restaurant_id uuid)
returns void
language sql
security definer
set search_path = ''
as $$
    update public.restaurants r
    set partnership_status = 'DIRECTORY_ONLY'
    where r.id = p_restaurant_id
      and r.partnership_status = 'CLAIM_PENDING'
      and not exists (
          select 1 from public.restaurant_claims c
          where c.restaurant_id = p_restaurant_id and c.status = 'PENDING'
      )
      and not exists (
          select 1 from public.restaurant_users ru where ru.restaurant_id = p_restaurant_id
      );
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
    set status = 'CANCELLED', reviewed_at = now()
    where c.id = p_claim_id
      and c.user_id = auth.uid()
      and c.status = 'PENDING'
    returning c.restaurant_id into v_restaurant;

    if v_restaurant is null then
        raise exception 'CLAIM_NOT_FOUND';
    end if;
    perform public.reset_claim_pending_if_idle(v_restaurant);
end;
$$;

create or replace function public.admin_review_claim(
    p_claim_id uuid,
    p_approve boolean,
    p_note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_claim public.restaurant_claims;
begin
    if not public.is_platform_admin() then
        raise exception 'ADMIN_REQUIRED';
    end if;

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

    update public.restaurant_claims
    set status = case when p_approve then 'APPROVED'::public.claim_status else 'REJECTED'::public.claim_status end,
        reviewed_at = now(),
        reviewed_by = auth.uid(),
        review_note = nullif(btrim(coalesce(p_note, '')), '')
    where id = p_claim_id;

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
end;
$$;

create or replace function public.admin_pending_claims()
returns table (
    claim_id uuid,
    created_at timestamptz,
    restaurant_id uuid,
    restaurant_name text,
    restaurant_city text,
    requester_email text,
    contact_info text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
    if not public.is_platform_admin() then
        raise exception 'ADMIN_REQUIRED';
    end if;
    return query
    select c.id, c.created_at, r.id, r.name, r.city, u.email::text, c.contact_info
    from public.restaurant_claims c
    join public.restaurants r on r.id = c.restaurant_id
    left join auth.users u on u.id = c.user_id
    where c.status = 'PENDING'
    order by c.created_at;
end;
$$;

-- ---------------------------------------------------------------------------
-- 4) Registrazione di un locale che non è ancora in directory.
--    Il locale nasce DIRECTORY_ONLY + richiesta PENDING: diventa LIVE solo dopo la verifica.
-- ---------------------------------------------------------------------------
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
    if auth.uid() is null then
        raise exception 'AUTH_REQUIRED';
    end if;
    if p_latitude not between -90 and 90 or p_longitude not between -180 and 180 then
        raise exception 'INVALID_LOCATION';
    end if;

    insert into public.restaurants (
        name, category, address, city, province, location,
        phone_number, phone_public, partnership_status, data_source
    ) values (
        btrim(p_name),
        coalesce(nullif(btrim(p_category), ''), 'Ristorante'),
        btrim(p_address),
        btrim(p_city),
        upper(coalesce(nullif(btrim(p_province), ''), 'PU')),
        extensions.st_point(p_longitude, p_latitude)::extensions.geography,
        nullif(btrim(coalesce(p_phone_number, '')), ''),
        false,
        'DIRECTORY_ONLY',
        'PARTNER_SIGNUP'
    )
    returning id into v_restaurant;

    perform public.submit_restaurant_claim(v_restaurant, p_contact_info);
    return v_restaurant;
end;
$$;

-- ---------------------------------------------------------------------------
-- 5) Permessi sulle funzioni: niente per anon, solo ciò che serve agli autenticati.
-- ---------------------------------------------------------------------------
revoke execute on function public.handle_new_auth_user() from public, anon, authenticated;
revoke execute on function public.reset_claim_pending_if_idle(uuid) from public, anon, authenticated;

revoke execute on function public.is_platform_admin() from public, anon;
revoke execute on function public.accept_terms(text) from public, anon;
revoke execute on function public.restaurant_role(uuid) from public, anon;
revoke execute on function public.is_restaurant_owner(uuid) from public, anon;
revoke execute on function public.my_restaurants() from public, anon;
revoke execute on function public.submit_restaurant_claim(uuid, text) from public, anon;
revoke execute on function public.cancel_my_claim(uuid) from public, anon;
revoke execute on function public.admin_review_claim(uuid, boolean, text) from public, anon;
revoke execute on function public.admin_pending_claims() from public, anon;
revoke execute on function public.register_new_restaurant(text, text, text, text, text, double precision, double precision, text, text) from public, anon;
revoke execute on function public.set_restaurant_live_status(uuid, public.live_status, smallint, smallint, varchar) from public, anon;

grant execute on function public.is_platform_admin() to authenticated;
grant execute on function public.accept_terms(text) to authenticated;
grant execute on function public.restaurant_role(uuid) to authenticated;
grant execute on function public.is_restaurant_owner(uuid) to authenticated;
grant execute on function public.my_restaurants() to authenticated;
grant execute on function public.submit_restaurant_claim(uuid, text) to authenticated;
grant execute on function public.cancel_my_claim(uuid) to authenticated;
grant execute on function public.admin_review_claim(uuid, boolean, text) to authenticated;
grant execute on function public.admin_pending_claims() to authenticated;
grant execute on function public.register_new_restaurant(text, text, text, text, text, double precision, double precision, text, text) to authenticated;
grant execute on function public.set_restaurant_live_status(uuid, public.live_status, smallint, smallint, varchar) to authenticated;
