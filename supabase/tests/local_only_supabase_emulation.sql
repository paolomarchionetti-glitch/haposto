-- SOLO PER TEST LOCALI / CI. NON ESEGUIRE MAI SU SUPABASE (lì questi oggetti esistono già).
-- Riproduce il minimo di un progetto Supabase appena creato: ruoli API, schema auth, auth.uid(),
-- schema extensions e i default privileges che concedono EXECUTE/ALL ai ruoli API.

create role anon nologin noinherit;
create role authenticated nologin noinherit;
create role service_role nologin noinherit bypassrls;
create schema if not exists extensions;
grant usage on schema extensions to anon, authenticated, service_role;
grant usage on schema public to anon, authenticated, service_role;
create schema auth;
grant usage on schema auth to anon, authenticated, service_role;
create table auth.users (
    id uuid primary key default gen_random_uuid(),
    email text unique,
    raw_user_meta_data jsonb not null default '{}'::jsonb,
    created_at timestamptz not null default now()
);
-- Same definition as Supabase: claim.sub setting or the sub inside request.jwt.claims.
create function auth.uid() returns uuid language sql stable as $$
    select coalesce(
        nullif(current_setting('request.jwt.claim.sub', true), ''),
        (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
    )::uuid
$$;
create function auth.role() returns text language sql stable as $$
    select nullif(current_setting('request.jwt.claim.role', true), '')
$$;
grant execute on function auth.uid(), auth.role() to anon, authenticated, service_role;
create publication supabase_realtime;
-- Supabase default privileges: new objects in public are granted to the API roles.
alter default privileges in schema public grant all on tables to anon, authenticated, service_role;
alter default privileges in schema public grant all on functions to anon, authenticated, service_role;
alter default privileges in schema public grant all on sequences to anon, authenticated, service_role;
