-- HAPOSTO STEP 7 — V1 schema aligned with docs/V1_CONTRACT_FREEZE.md.

create type public.partnership_status as enum (
    'DIRECTORY_ONLY',
    'CLAIM_PENDING',
    'ACTIVE_PARTNER',
    'PAUSED',
    'SUSPENDED'
);

create type public.live_status as enum (
    'AVAILABLE',
    'LIMITED',
    'FULL'
);

create type public.restaurant_user_role as enum (
    'OWNER',
    'STAFF'
);

create type public.claim_status as enum (
    'PENDING',
    'APPROVED',
    'REJECTED',
    'CANCELLED'
);

create table public.restaurants (
    id uuid primary key default gen_random_uuid(),
    name text not null check (char_length(name) between 1 and 160),
    category text not null default 'Ristorante' check (char_length(category) between 1 and 100),
    address text not null check (char_length(address) between 1 and 240),
    city text not null check (char_length(city) between 1 and 100),
    province text not null default 'PU' check (char_length(province) between 1 and 8),
    postal_code text,
    location extensions.geography(POINT) not null,
    phone_number text,
    phone_public boolean not null default false,
    partnership_status public.partnership_status not null default 'DIRECTORY_ONLY',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint public_phone_requires_number check (not phone_public or phone_number is not null)
);

create index restaurants_location_gix
    on public.restaurants using gist (location);

create index restaurants_name_trgm_idx
    on public.restaurants using gin (name extensions.gin_trgm_ops);

create index restaurants_category_trgm_idx
    on public.restaurants using gin (category extensions.gin_trgm_ops);

create table public.restaurant_live_status (
    restaurant_id uuid primary key references public.restaurants(id) on delete cascade,
    status public.live_status not null,
    available_tables smallint check (available_tables is null or available_tables between 0 and 99),
    estimated_wait_minutes smallint check (estimated_wait_minutes is null or estimated_wait_minutes between 0 and 240),
    note varchar(80),
    updated_at timestamptz not null default now(),
    valid_until timestamptz not null default (now() + interval '30 minutes'),
    constraint live_status_valid_window check (valid_until > updated_at),
    constraint full_has_no_available_tables check (status <> 'FULL' or available_tables is null)
);

create table public.restaurant_users (
    restaurant_id uuid not null references public.restaurants(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    role public.restaurant_user_role not null,
    created_at timestamptz not null default now(),
    primary key (restaurant_id, user_id)
);

create table public.restaurant_claims (
    id uuid primary key default gen_random_uuid(),
    restaurant_id uuid not null references public.restaurants(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    status public.claim_status not null default 'PENDING',
    contact_info text not null check (char_length(contact_info) between 3 and 240),
    created_at timestamptz not null default now(),
    reviewed_at timestamptz,
    reviewed_by uuid references auth.users(id) on delete set null
);

create index restaurant_claims_user_idx on public.restaurant_claims(user_id);
create index restaurant_claims_restaurant_idx on public.restaurant_claims(restaurant_id);

create table public.status_history (
    id bigint generated always as identity primary key,
    restaurant_id uuid not null references public.restaurants(id) on delete cascade,
    status public.live_status not null,
    available_tables smallint check (available_tables is null or available_tables between 0 and 99),
    estimated_wait_minutes smallint check (estimated_wait_minutes is null or estimated_wait_minutes between 0 and 240),
    note varchar(80),
    updated_at timestamptz not null,
    valid_until timestamptz not null,
    updated_by uuid references auth.users(id) on delete set null,
    constraint history_valid_window check (valid_until > updated_at),
    constraint history_full_has_no_available_tables check (status <> 'FULL' or available_tables is null)
);

create index status_history_restaurant_time_idx
    on public.status_history(restaurant_id, updated_at desc);
