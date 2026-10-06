--
-- PostgreSQL database dump
--

\restrict bbD6Bg1sYE0VMd7XUWJF6AfktlfSLisQRPhhyPcpQHQusLBt1azvqJwha60tyqg

-- Dumped from database version 17.6
-- Dumped by pg_dump version 18.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: auth; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA auth;


--
-- Name: pg_cron; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_cron WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION pg_cron; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_cron IS 'Job scheduler for PostgreSQL';


--
-- Name: extensions; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA extensions;


--
-- Name: graphql; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA graphql;


--
-- Name: graphql_public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA graphql_public;


--
-- Name: pg_net; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;


--
-- Name: EXTENSION pg_net; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_net IS 'Async HTTP';


--
-- Name: pgbouncer; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA pgbouncer;


--
-- Name: realtime; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA realtime;


--
-- Name: storage; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA storage;


--
-- Name: vault; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA vault;


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA extensions;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA extensions;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- Name: supabase_vault; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS supabase_vault WITH SCHEMA vault;


--
-- Name: EXTENSION supabase_vault; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION supabase_vault IS 'Supabase Vault Extension';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: aal_level; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.aal_level AS ENUM (
    'aal1',
    'aal2',
    'aal3'
);


--
-- Name: code_challenge_method; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.code_challenge_method AS ENUM (
    's256',
    'plain'
);


--
-- Name: factor_status; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_status AS ENUM (
    'unverified',
    'verified'
);


--
-- Name: factor_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_type AS ENUM (
    'totp',
    'webauthn',
    'phone',
    'recovery_code'
);


--
-- Name: oauth_authorization_status; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_authorization_status AS ENUM (
    'pending',
    'approved',
    'denied',
    'expired'
);


--
-- Name: oauth_client_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_client_type AS ENUM (
    'public',
    'confidential'
);


--
-- Name: oauth_registration_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_registration_type AS ENUM (
    'dynamic',
    'manual'
);


--
-- Name: oauth_response_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_response_type AS ENUM (
    'code'
);


--
-- Name: one_time_token_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.one_time_token_type AS ENUM (
    'confirmation_token',
    'reauthentication_token',
    'recovery_token',
    'email_change_token_new',
    'email_change_token_current',
    'phone_change_token'
);


--
-- Name: claim_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.claim_status AS ENUM (
    'PENDING',
    'APPROVED',
    'REJECTED',
    'CANCELLED'
);


--
-- Name: live_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.live_status AS ENUM (
    'AVAILABLE',
    'LIMITED',
    'FULL'
);


--
-- Name: partnership_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.partnership_status AS ENUM (
    'DIRECTORY_ONLY',
    'CLAIM_PENDING',
    'ACTIVE_PARTNER',
    'PAUSED',
    'SUSPENDED'
);


--
-- Name: restaurant_user_role; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.restaurant_user_role AS ENUM (
    'OWNER',
    'STAFF'
);


--
-- Name: action; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.action AS ENUM (
    'INSERT',
    'UPDATE',
    'DELETE',
    'TRUNCATE',
    'ERROR'
);


--
-- Name: equality_op; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.equality_op AS ENUM (
    'eq',
    'neq',
    'lt',
    'lte',
    'gt',
    'gte',
    'in',
    'like',
    'ilike',
    'is',
    'match',
    'imatch',
    'isdistinct'
);


--
-- Name: user_defined_filter; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.user_defined_filter AS (
	column_name text,
	op realtime.equality_op,
	value text,
	negate boolean
);


--
-- Name: wal_column; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.wal_column AS (
	name text,
	type_name text,
	type_oid oid,
	value jsonb,
	is_pkey boolean,
	is_selectable boolean
);


--
-- Name: wal_rls; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.wal_rls AS (
	wal jsonb,
	is_rls_enabled boolean,
	subscription_ids uuid[],
	errors text[]
);


--
-- Name: buckettype; Type: TYPE; Schema: storage; Owner: -
--

CREATE TYPE storage.buckettype AS ENUM (
    'STANDARD',
    'ANALYTICS',
    'VECTOR'
);


--
-- Name: email(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.email() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.email', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'email')
  )::text
$$;


--
-- Name: FUNCTION email(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.email() IS 'Deprecated. Use auth.jwt() -> ''email'' instead.';


--
-- Name: jwt(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.jwt() RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
  select 
    coalesce(
        nullif(current_setting('request.jwt.claim', true), ''),
        nullif(current_setting('request.jwt.claims', true), '')
    )::jsonb
$$;


--
-- Name: role(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.role() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  )::text
$$;


--
-- Name: FUNCTION role(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.role() IS 'Deprecated. Use auth.jwt() -> ''role'' instead.';


--
-- Name: uid(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.uid() RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid
$$;


--
-- Name: FUNCTION uid(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.uid() IS 'Deprecated. Use auth.jwt() -> ''sub'' instead.';


--
-- Name: grant_pg_cron_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_cron_access() RETURNS event_trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
  IF EXISTS (
    SELECT
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_cron'
  )
  THEN
    grant usage on schema cron to postgres with grant option;

    alter default privileges in schema cron grant all on tables to postgres with grant option;
    alter default privileges in schema cron grant all on functions to postgres with grant option;
    alter default privileges in schema cron grant all on sequences to postgres with grant option;

    alter default privileges for user supabase_admin in schema cron grant all
        on sequences to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on tables to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on functions to postgres with grant option;

    grant all privileges on all tables in schema cron to postgres with grant option;
    revoke all on table cron.job from postgres;
    grant select on table cron.job to postgres with grant option;
    revoke trigger on cron.job_run_details from postgres;
  END IF;
END;
$$;


--
-- Name: FUNCTION grant_pg_cron_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_cron_access() IS 'Grants access to pg_cron';


--
-- Name: grant_pg_graphql_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_graphql_access() RETURNS event_trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $_$
begin
    if not exists (
        select 1
        from pg_catalog.pg_event_trigger_ddl_commands() ev
        join pg_catalog.pg_extension e on ev.objid = e.oid
        where e.extname = 'pg_graphql'
    ) then
        return;
    end if;

    drop function if exists graphql_public.graphql;
    create or replace function graphql_public.graphql(
        "operationName" text default null,
        query text default null,
        variables jsonb default null,
        extensions jsonb default null
    )
        returns jsonb
        language sql
    as $$
        select graphql.resolve(
            query := query,
            variables := coalesce(variables, '{}'),
            "operationName" := "operationName",
            extensions := extensions
        );
    $$;

    -- Attach the wrapper to the extension so DROP EXTENSION cascades to it,
    -- which in turn triggers set_graphql_placeholder to reinstall the "not enabled" stub.
    alter extension pg_graphql add function graphql_public.graphql(text, text, jsonb, jsonb);

    grant usage on schema graphql to postgres, anon, authenticated, service_role;
    grant execute on function graphql.resolve to postgres, anon, authenticated, service_role;
    grant usage on schema graphql to postgres with grant option;
    grant usage on schema graphql_public to postgres with grant option;
end;
$_$;


--
-- Name: FUNCTION grant_pg_graphql_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_graphql_access() IS 'Grants access to pg_graphql';


--
-- Name: grant_pg_net_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_net_access() RETURNS event_trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_net'
  )
  THEN
    IF NOT EXISTS (
      SELECT 1
      FROM pg_roles
      WHERE rolname = 'supabase_functions_admin'
    )
    THEN
      CREATE USER supabase_functions_admin NOINHERIT CREATEROLE LOGIN NOREPLICATION;
    END IF;

    GRANT USAGE ON SCHEMA net TO supabase_functions_admin, postgres, anon, authenticated, service_role;

    IF EXISTS (
      SELECT FROM pg_extension
      WHERE extname = 'pg_net'
      -- all versions in use on existing projects as of 2025-02-20
      -- version 0.12.0 onwards don't need these applied
      AND extversion IN ('0.2', '0.6', '0.7', '0.7.1', '0.8.0', '0.10.0', '0.11.0')
    ) THEN
      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;

      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;

      REVOKE ALL ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;
      REVOKE ALL ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;

      GRANT EXECUTE ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
      GRANT EXECUTE ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
    END IF;
  END IF;
END;
$$;


--
-- Name: FUNCTION grant_pg_net_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_net_access() IS 'Grants access to pg_net';


--
-- Name: pgrst_ddl_watch(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.pgrst_ddl_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN SELECT * FROM pg_event_trigger_ddl_commands()
  LOOP
    IF cmd.command_tag IN (
      'CREATE SCHEMA', 'ALTER SCHEMA'
    , 'CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO', 'ALTER TABLE'
    , 'CREATE FOREIGN TABLE', 'ALTER FOREIGN TABLE'
    , 'CREATE VIEW', 'ALTER VIEW'
    , 'CREATE MATERIALIZED VIEW', 'ALTER MATERIALIZED VIEW'
    , 'CREATE FUNCTION', 'ALTER FUNCTION'
    , 'CREATE TRIGGER'
    , 'CREATE TYPE', 'ALTER TYPE'
    , 'CREATE RULE'
    , 'COMMENT'
    )
    -- don't notify in case of CREATE TEMP table or other objects created on pg_temp
    AND cmd.schema_name is distinct from 'pg_temp'
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


--
-- Name: pgrst_drop_watch(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.pgrst_drop_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
DECLARE
  obj record;
BEGIN
  FOR obj IN SELECT * FROM pg_event_trigger_dropped_objects()
  LOOP
    IF obj.object_type IN (
      'schema'
    , 'table'
    , 'foreign table'
    , 'view'
    , 'materialized view'
    , 'function'
    , 'trigger'
    , 'type'
    , 'rule'
    )
    AND obj.is_temporary IS false -- no pg_temp objects
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


--
-- Name: set_graphql_placeholder(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.set_graphql_placeholder() RETURNS event_trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $_$
    DECLARE
    graphql_is_dropped bool;
    BEGIN
    graphql_is_dropped = (
        SELECT ev.schema_name = 'graphql_public'
        FROM pg_event_trigger_dropped_objects() AS ev
        WHERE ev.schema_name = 'graphql_public'
    );

    IF graphql_is_dropped
    THEN
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language plpgsql
            set search_path to ''
        as $$
            DECLARE
                server_version float;
            BEGIN
                server_version = (SELECT (SPLIT_PART((select version()), ' ', 2))::float);

                IF server_version >= 14 THEN
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql extension is not enabled.'
                            )
                        )
                    );
                ELSE
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql is only available on projects running Postgres 14 onwards.'
                            )
                        )
                    );
                END IF;
            END;
        $$;
    END IF;

    END;
$_$;


--
-- Name: FUNCTION set_graphql_placeholder(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.set_graphql_placeholder() IS 'Reintroduces placeholder function for graphql_public.graphql';


--
-- Name: graphql(text, text, jsonb, jsonb); Type: FUNCTION; Schema: graphql_public; Owner: -
--

CREATE FUNCTION graphql_public.graphql("operationName" text DEFAULT NULL::text, query text DEFAULT NULL::text, variables jsonb DEFAULT NULL::jsonb, extensions jsonb DEFAULT NULL::jsonb) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$
            DECLARE
                server_version float;
            BEGIN
                server_version = (SELECT (SPLIT_PART((select version()), ' ', 2))::float);

                IF server_version >= 14 THEN
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql extension is not enabled.'
                            )
                        )
                    );
                ELSE
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql is only available on projects running Postgres 14 onwards.'
                            )
                        )
                    );
                END IF;
            END;
        $$;


--
-- Name: get_auth(text); Type: FUNCTION; Schema: pgbouncer; Owner: -
--

CREATE FUNCTION pgbouncer.get_auth(p_usename text) RETURNS TABLE(username text, password text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
  BEGIN
      RAISE DEBUG 'PgBouncer auth request: %', p_usename;

      RETURN QUERY
      SELECT
          rolname::text,
          CASE WHEN rolvaliduntil < now()
              THEN null
              ELSE rolpassword::text
          END
      FROM pg_authid
      WHERE rolname=$1 and rolcanlogin;
  END;
  $_$;


--
-- Name: accept_restaurant_terms(text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.accept_restaurant_terms(p_version text, p_specific_clauses_accepted boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: accept_terms(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.accept_terms(p_version text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: add_restaurant_staff(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.add_restaurant_staff(p_restaurant_id uuid, p_email text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: admin_add_member(uuid, text, public.restaurant_user_role, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_add_member(p_restaurant_id uuid, p_email text, p_role public.restaurant_user_role, p_note text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: admin_audit_log(integer, bigint, text, uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_audit_log(p_limit integer DEFAULT 100, p_before_id bigint DEFAULT NULL::bigint, p_action text DEFAULT NULL::text, p_restaurant_id uuid DEFAULT NULL::uuid, p_user_id uuid DEFAULT NULL::uuid) RETURNS TABLE(log_id bigint, created_at timestamp with time zone, actor_kind text, actor_email text, action text, restaurant_id uuid, restaurant_name text, target_email text, details jsonb)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: admin_cancel_subscription(text, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_cancel_subscription(p_kind text, p_subscription_id uuid, p_note text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: admin_grant_consumer_plan(uuid, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_grant_consumer_plan(p_user_id uuid, p_months integer, p_note text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: admin_grant_restaurant_plan(uuid, text, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_grant_restaurant_plan(p_restaurant_id uuid, p_plan_code text, p_months integer, p_note text DEFAULT NULL::text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: admin_import_directory(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_import_directory(p_data_source text DEFAULT 'OSM_IMPORT'::text) RETURNS TABLE(inserted integer, updated integer, skipped integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: admin_issue_claim_code(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_issue_claim_code(p_claim_id uuid) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: admin_list_payments(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_list_payments(p_limit integer DEFAULT 100, p_offset integer DEFAULT 0) RETURNS TABLE(payment_id uuid, paid_at timestamp with time zone, payer_kind text, payer_name text, provider text, plan_code text, amount_cents integer, vat_cents integer, status text, invoice_number text)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: admin_list_restaurant_extras(boolean, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_list_restaurant_extras(p_only_unreviewed boolean DEFAULT true, p_limit integer DEFAULT 100) RETURNS TABLE(restaurant_id uuid, name text, city text, website_url text, menu_url text, file_path text, file_mime text, file_bytes integer, file_expires_at timestamp with time zone, changed_at timestamp with time zone, reviewed_at timestamp with time zone)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
#variable_conflict use_column
begin
    perform public.assert_admin();
    return query
    select r.id, r.name, r.city, r.website_url, r.menu_url, r.file_path, r.file_mime, r.file_bytes,
           r.file_expires_at, r.extras_changed_at, r.extras_reviewed_at
    from public.restaurants r
    where (r.website_url is not null or r.menu_url is not null or r.file_path is not null)
      and (not p_only_unreviewed or r.extras_reviewed_at is null
           or r.extras_reviewed_at < r.extras_changed_at)
    order by r.extras_changed_at desc nulls last
    limit least(greatest(coalesce(p_limit, 100), 1), 500);
end;
$$;


--
-- Name: admin_list_restaurants(text, text, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_list_restaurants(p_query text DEFAULT NULL::text, p_status text DEFAULT NULL::text, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0) RETURNS TABLE(restaurant_id uuid, name text, city text, partnership_status public.partnership_status, data_source text, plan_code text, members integer, last_publish_at timestamp with time zone, phone_number text, slug text)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: admin_list_subscriptions(text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_list_subscriptions(p_kind text DEFAULT 'ALL'::text, p_limit integer DEFAULT 100) RETURNS TABLE(kind text, subscription_id uuid, subject_id uuid, subject_name text, plan_code text, status text, provider text, current_period_end timestamp with time zone, created_at timestamp with time zone)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: admin_list_users(text, text, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_list_users(p_query text DEFAULT NULL::text, p_filter text DEFAULT 'ALL'::text, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0) RETURNS TABLE(user_id uuid, email text, display_name text, created_at timestamp with time zone, last_sign_in_at timestamp with time zone, is_admin boolean, blocked_at timestamp with time zone, consumer_plan text, restaurants integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: admin_lock(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_lock() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
    update public.admin_sessions s
    set revoked_at = now()
    where s.user_id = auth.uid() and s.revoked_at is null;
    perform public.log_audit('ADMIN_LOCK', null, auth.uid(), '{}');
end;
$$;


--
-- Name: admin_overview(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_overview() RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: admin_pending_claims(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_pending_claims() RETURNS TABLE(claim_id uuid, created_at timestamp with time zone, restaurant_id uuid, restaurant_name text, restaurant_city text, restaurant_address text, restaurant_phone text, partnership_status public.partnership_status, current_owners integer, requester_id uuid, requester_email text, requester_name text, contact_info text, phone_code_active boolean, phone_verified_at timestamp with time zone)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: admin_remove_member(uuid, uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_remove_member(p_restaurant_id uuid, p_user_id uuid, p_note text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: admin_restaurant_detail(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_restaurant_detail(p_restaurant_id uuid) RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
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
        'plan_source', (select e.source from public.restaurant_entitlements(r.id) e),
        'plan_valid_until', (select e.valid_until from public.restaurant_entitlements(r.id) e),
        'partner_since', r.partner_since,
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
            where st.restaurant_id = r.id and st.day > public.today_rome() - 30)
    ) into v_result
    from public.restaurants r
    where r.id = p_restaurant_id;

    if v_result is null then
        raise exception 'RESTAURANT_NOT_FOUND';
    end if;
    return v_result;
end;
$$;


--
-- Name: admin_review_claim(uuid, boolean, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_review_claim(p_claim_id uuid, p_approve boolean, p_note text DEFAULT NULL::text, p_skip_phone_check boolean DEFAULT false) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: admin_review_restaurant_extras(uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_review_restaurant_extras(p_restaurant_id uuid, p_action text, p_reason text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
    perform public.assert_admin();
    if p_action not in ('OK', 'REMOVE_LINKS', 'REMOVE_FILE', 'REMOVE_ALL') then
        raise exception 'INVALID_ACTION';
    end if;
    update public.restaurants
    set website_url = case when p_action in ('REMOVE_LINKS', 'REMOVE_ALL') then null else website_url end,
        menu_url = case when p_action in ('REMOVE_LINKS', 'REMOVE_ALL') then null else menu_url end,
        file_path = case when p_action in ('REMOVE_FILE', 'REMOVE_ALL') then null else file_path end,
        file_mime = case when p_action in ('REMOVE_FILE', 'REMOVE_ALL') then null else file_mime end,
        file_bytes = case when p_action in ('REMOVE_FILE', 'REMOVE_ALL') then null else file_bytes end,
        file_expires_at = case when p_action in ('REMOVE_FILE', 'REMOVE_ALL') then null else file_expires_at end,
        extras_reviewed_at = now()
    where id = p_restaurant_id;
    if not found then
        raise exception 'RESTAURANT_NOT_FOUND';
    end if;
    perform public.log_audit('ADMIN_EXTRAS_' || p_action, p_restaurant_id, null,
        jsonb_build_object('reason', p_reason));
end;
$$;


--
-- Name: admin_set_config(text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_set_config(p_key text, p_value jsonb) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: admin_set_credentials(text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_set_credentials(p_email text, p_username text, p_password text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
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
$_$;


--
-- Name: admin_set_restaurant_status(uuid, public.partnership_status, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_set_restaurant_status(p_restaurant_id uuid, p_status public.partnership_status, p_note text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: admin_set_user_blocked(uuid, boolean, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_set_user_blocked(p_user_id uuid, p_blocked boolean, p_reason text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: admin_unlock(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_unlock(p_username text, p_password text) RETURNS TABLE(ok boolean, error_code text, valid_until timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: admin_update_restaurant(uuid, text, text, text, text, text, double precision, double precision, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_update_restaurant(p_restaurant_id uuid, p_name text DEFAULT NULL::text, p_category text DEFAULT NULL::text, p_address text DEFAULT NULL::text, p_city text DEFAULT NULL::text, p_province text DEFAULT NULL::text, p_latitude double precision DEFAULT NULL::double precision, p_longitude double precision DEFAULT NULL::double precision, p_phone_number text DEFAULT NULL::text, p_phone_public boolean DEFAULT NULL::boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: admin_user_detail(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.admin_user_detail(p_user_id uuid) RETURNS jsonb
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: assert_active_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.assert_active_user() RETURNS void
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
    if auth.uid() is null then
        raise exception 'AUTH_REQUIRED';
    end if;
    if public.is_user_blocked(auth.uid()) then
        raise exception 'ACCOUNT_BLOCKED';
    end if;
end;
$$;


--
-- Name: assert_admin(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.assert_admin() RETURNS void
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
    if auth.uid() is not null and not public.is_platform_admin() then
        raise exception 'ADMIN_REQUIRED';
    end if;
end;
$$;


--
-- Name: assert_can_edit_restaurant(uuid, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.assert_can_edit_restaurant(p_restaurant_id uuid, p_owner_only boolean) RETURNS void
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
    perform public.assert_active_user();
    if p_owner_only and not public.is_restaurant_owner(p_restaurant_id) then
        raise exception 'OWNER_REQUIRED';
    end if;
    if not p_owner_only and public.restaurant_role(p_restaurant_id) is null then
        raise exception 'Not authorized for this restaurant';
    end if;
    perform public.assert_restaurant_mfa();
    if (select r.partnership_status from public.restaurants r where r.id = p_restaurant_id) = 'SUSPENDED' then
        raise exception 'RESTAURANT_SUSPENDED';
    end if;
end;
$$;


--
-- Name: assert_restaurant_mfa(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.assert_restaurant_mfa() RETURNS void
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
    if not public.restaurant_mfa_satisfied() then
        raise exception 'MFA_REQUIRED';
    end if;
end;
$$;


--
-- Name: assign_restaurant_slug(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.assign_restaurant_slug() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: billing_log_event(text, text, text, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.billing_log_event(p_provider text, p_event_id text, p_event_type text, p_payload jsonb) RETURNS boolean
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: billing_record_payment(text, uuid, uuid, text, text, text, integer, integer, text, text, text, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.billing_record_payment(p_payer_kind text, p_restaurant_id uuid, p_user_id uuid, p_provider text, p_provider_payment_id text, p_plan_code text, p_amount_cents integer, p_vat_cents integer, p_status text, p_invoice_number text, p_invoice_url text, p_paid_at timestamp with time zone) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: billing_upsert_consumer_subscription(uuid, text, text, text, text, timestamp with time zone, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.billing_upsert_consumer_subscription(p_user_id uuid, p_plan_code text, p_status text, p_provider text, p_provider_purchase_ref text, p_current_period_end timestamp with time zone, p_auto_renewing boolean DEFAULT true) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: billing_upsert_restaurant_subscription(uuid, text, text, text, text, text, text, timestamp with time zone, timestamp with time zone, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.billing_upsert_restaurant_subscription(p_restaurant_id uuid, p_plan_code text, p_status text, p_billing_interval text, p_provider text, p_provider_customer_id text, p_provider_subscription_id text, p_current_period_start timestamp with time zone, p_current_period_end timestamp with time zone, p_cancel_at_period_end boolean DEFAULT false) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: cancel_my_claim(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.cancel_my_claim(p_claim_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: claim_notification_batch(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.claim_notification_batch(p_limit integer DEFAULT 100) RETURNS TABLE(notification_id bigint, user_id uuid, kind text, restaurant_id uuid, title text, body text, data jsonb, tokens text[])
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: clear_extras_when_unclaimed(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.clear_extras_when_unclaimed() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
begin
    if new.partnership_status = 'DIRECTORY_ONLY' and old.partnership_status is distinct from 'DIRECTORY_ONLY' then
        new.quick_notes := '{}'::text[];
        new.website_url := null;
        new.menu_url := null;
        new.file_path := null;
        new.file_mime := null;
        new.file_bytes := null;
        new.file_expires_at := null;
        new.extras_changed_at := null;
        new.extras_reviewed_at := null;
    end if;
    return new;
end;
$$;


--
-- Name: complete_notifications(bigint[], bigint[], text, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.complete_notifications(p_sent_ids bigint[], p_failed_ids bigint[] DEFAULT ARRAY[]::bigint[], p_error text DEFAULT NULL::text, p_invalid_tokens text[] DEFAULT ARRAY[]::text[]) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
    update public.notification_outbox set sent_at = now(), last_error = null
    where id = any(coalesce(p_sent_ids, array[]::bigint[]));
    update public.notification_outbox set last_error = left(coalesce(p_error, 'errore'), 500)
    where id = any(coalesce(p_failed_ids, array[]::bigint[]));
    delete from public.device_push_tokens where token = any(coalesce(p_invalid_tokens, array[]::text[]));
end;
$$;


--
-- Name: config_value(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.config_value(p_key text, p_field text) RETURNS text
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
    select c.value ->> p_field from public.app_config c where c.key = p_key;
$$;


--
-- Name: consumer_has_feature(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.consumer_has_feature(p_user_id uuid, p_feature text) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
    select coalesce(
        (select p_feature = any(p.features) from public.plans p
         where p.code = public.consumer_plan_code(p_user_id)),
        false
    );
$$;


--
-- Name: consumer_limit(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.consumer_limit(p_user_id uuid, p_limit text) RETURNS integer
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
    select coalesce(
        (select (p.limits ->> p_limit)::integer from public.plans p
         where p.code = public.consumer_plan_code(p_user_id)),
        0
    );
$$;


--
-- Name: consumer_plan_code(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.consumer_plan_code(p_user_id uuid) RETURNS text
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: count_live_update(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.count_live_update() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
    insert into public.restaurant_daily_stats as st (restaurant_id, day, live_updates)
    values (new.restaurant_id, (new.updated_at at time zone 'Europe/Rome')::date, 1)
    on conflict (restaurant_id, day) do update set live_updates = st.live_updates + 1;
    return new;
end;
$$;


--
-- Name: current_aal(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.current_aal() RETURNS text
    LANGUAGE sql STABLE
    SET search_path TO ''
    AS $$
    select coalesce(auth.jwt() ->> 'aal', 'aal1');
$$;


--
-- Name: current_session_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.current_session_id() RETURNS text
    LANGUAGE sql STABLE
    SET search_path TO ''
    AS $$
    select nullif(auth.jwt() ->> 'session_id', '');
$$;


--
-- Name: delete_my_account(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.delete_my_account() RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: dev_publish_live_status(uuid, public.live_status, smallint, smallint, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.dev_publish_live_status(p_restaurant_id uuid, p_status public.live_status, p_available_tables smallint DEFAULT NULL::smallint, p_estimated_wait_minutes smallint DEFAULT NULL::smallint, p_note character varying DEFAULT NULL::character varying) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
    v_now timestamptz := now();
    v_tables smallint := case when p_status = 'FULL' then null else p_available_tables end;
begin
    if not public.dev_tools_enabled() then
        raise exception 'DEV_TOOLS_DISABLED';
    end if;
    -- Un locale di test rivendicato da un account vero lo aggiorna solo chi lo gestisce.
    if not exists (
        select 1 from public.restaurants r
        where r.id = p_restaurant_id
          and r.data_source = 'DEV_SEED'
          and r.partnership_status = 'ACTIVE_PARTNER'
          and not exists (select 1 from public.restaurant_users ru where ru.restaurant_id = r.id)
    ) then
        raise exception 'NOT_A_DEV_PARTNER';
    end if;
    if v_tables is not null and v_tables not between 0 and 99 then
        raise exception 'available_tables must be between 0 and 99';
    end if;
    if p_estimated_wait_minutes is not null and p_estimated_wait_minutes not between 0 and 240 then
        raise exception 'estimated_wait_minutes must be between 0 and 240';
    end if;

    insert into public.restaurant_live_status (
        restaurant_id, status, available_tables, estimated_wait_minutes, note, updated_at, valid_until, updated_via
    ) values (
        p_restaurant_id, p_status, v_tables, p_estimated_wait_minutes, nullif(trim(p_note), ''),
        v_now, v_now + interval '30 minutes', 'DEV_APP'
    )
    on conflict (restaurant_id) do update set
        status = excluded.status,
        available_tables = excluded.available_tables,
        estimated_wait_minutes = excluded.estimated_wait_minutes,
        note = excluded.note,
        updated_at = excluded.updated_at,
        valid_until = excluded.valid_until,
        updated_via = excluded.updated_via;

    insert into public.status_history (
        restaurant_id, status, available_tables, estimated_wait_minutes, note, updated_at, valid_until, updated_via
    ) values (
        p_restaurant_id, p_status, v_tables, p_estimated_wait_minutes, nullif(trim(p_note), ''),
        v_now, v_now + interval '30 minutes', 'DEV_APP'
    );
end;
$$;


--
-- Name: dev_simulate_live_activity(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.dev_simulate_live_activity() RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
    v_now timestamptz := now();
    v_local time := (now() at time zone 'Europe/Rome')::time;
    v_weekend boolean := extract(isodow from (now() at time zone 'Europe/Rome')) in (5, 6);
    v_phase text;
    v_roll double precision;
    v_status public.live_status;
    v_tables smallint;
    v_wait smallint;
    v_note text;
    v_count integer := 0;
    r record;
begin
    if not public.dev_tools_enabled() then
        return 0;
    end if;

    v_phase := case
        when v_local >= time '11:30' and v_local < time '14:45' then 'LUNCH'
        when v_local >= time '18:45' and v_local < time '23:00' then 'DINNER'
        when v_local >= time '23:00' or v_local < time '10:30' then 'NIGHT'
        else 'QUIET'
    end;
    if v_phase = 'NIGHT' then
        return 0;
    end if;

    for r in
        select rest.id, s.valid_until, s.updated_via, s.updated_at,
               abs(hashtext(rest.id::text)) % 5 = 0 as lazy
        from public.restaurants rest
        left join public.restaurant_live_status s on s.restaurant_id = rest.id
        where rest.data_source = 'DEV_SEED'
          and rest.partnership_status = 'ACTIVE_PARTNER'
          -- I locali per le prove sul campo con un ristoratore vero li aggiorna solo lui dall'app.
          and coalesce(rest.source_ref, '') not like 'field-test:%'
          -- ...e nemmeno quelli rivendicati da un account vero (titolare o staff).
          and not exists (select 1 from public.restaurant_users ru where ru.restaurant_id = rest.id)
    loop
        continue when r.updated_via = 'DEV_APP' and r.updated_at > v_now - interval '3 hours';
        continue when r.lazy and random() < 0.85;
        -- Aggiorna soprattutto quando lo stato è scaduto o sta per scadere; a volte cambia prima.
        continue when r.valid_until is not null
                  and r.valid_until > v_now + interval '8 minutes'
                  and random() > 0.15;

        v_roll := random();
        v_status := case v_phase
            when 'DINNER' then
                case when v_roll < (case when v_weekend then 0.25 else 0.45 end) then 'AVAILABLE'
                     when v_roll < (case when v_weekend then 0.60 else 0.78 end) then 'LIMITED'
                     else 'FULL' end
            when 'LUNCH' then
                case when v_roll < 0.55 then 'AVAILABLE' when v_roll < 0.85 then 'LIMITED' else 'FULL' end
            else
                case when v_roll < 0.80 then 'AVAILABLE' else 'LIMITED' end
        end::public.live_status;

        v_tables := case v_status
            when 'AVAILABLE' then 2 + floor(random() * 7)::smallint
            when 'LIMITED' then 1 + floor(random() * 2)::smallint
            else null
        end;
        v_wait := case v_status
            when 'AVAILABLE' then (array[null, 0, 0, 5])[1 + floor(random() * 4)::int]
            when 'LIMITED' then (array[5, 10, 15, 20])[1 + floor(random() * 4)::int]
            else (array[20, 30, 45, null])[1 + floor(random() * 4)::int]
        end;
        v_note := case v_status
            when 'AVAILABLE' then (array[null, null, 'Tavoli anche all''aperto', 'Sala interna libera', 'Posti al bancone'])[1 + floor(random() * 5)::int]
            when 'LIMITED' then (array[null, 'Ultimi tavoli per 2', 'Solo al bancone', 'Attesa breve'])[1 + floor(random() * 4)::int]
            else (array[null, 'Pieno fino alle 21:30', 'Solo asporto', 'Riprova tra mezz''ora'])[1 + floor(random() * 4)::int]
        end;

        insert into public.restaurant_live_status (
            restaurant_id, status, available_tables, estimated_wait_minutes, note, updated_at, valid_until, updated_via
        ) values (
            r.id, v_status, v_tables, v_wait, v_note, v_now, v_now + interval '30 minutes', 'DEV_SIMULATOR'
        )
        on conflict (restaurant_id) do update set
            status = excluded.status,
            available_tables = excluded.available_tables,
            estimated_wait_minutes = excluded.estimated_wait_minutes,
            note = excluded.note,
            updated_at = excluded.updated_at,
            valid_until = excluded.valid_until,
            updated_via = excluded.updated_via;

        insert into public.status_history (
            restaurant_id, status, available_tables, estimated_wait_minutes, note, updated_at, valid_until, updated_via
        ) values (
            r.id, v_status, v_tables, v_wait, v_note, v_now, v_now + interval '30 minutes', 'DEV_SIMULATOR'
        );
        v_count := v_count + 1;
    end loop;

    return v_count;
end;
$$;


--
-- Name: dev_tools_enabled(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.dev_tools_enabled() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
    select coalesce((select c.value = 'true'::jsonb from public.app_config c where c.key = 'dev_tools_enabled'), false);
$$;


--
-- Name: enforce_alert_plan(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enforce_alert_plan() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: enforce_favorites_limit(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enforce_favorites_limit() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
    if (select count(*) from public.favorites f where f.user_id = new.user_id)
        >= public.consumer_limit(new.user_id, 'favorites_max') then
        raise exception 'FAVORITES_LIMIT_REACHED';
    end if;
    return new;
end;
$$;


--
-- Name: enforce_live_status_plan(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enforce_live_status_plan() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
    if auth.uid() is not null
       and new.updated_via in ('OWNER', 'STAFF')
       and not public.restaurant_has_feature(new.restaurant_id, 'LIVE_STATUS') then
        raise exception 'SUBSCRIPTION_REQUIRED';
    end if;
    return new;
end;
$$;


--
-- Name: enqueue_availability_alerts(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enqueue_availability_alerts() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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
           jsonb_build_object('restaurant_id', new.restaurant_id, 'status', new.status, 'action', 'OPEN_RESTAURANT',
                              'restaurant_name', v_name)
    from due d
    join public.profiles p on p.id = d.user_id
    where p.notify_availability_alerts and p.blocked_at is null;

    return new;
end;
$$;


--
-- Name: enqueue_manager_reminders(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enqueue_manager_reminders() RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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
                              'status', s.status, 'restaurant_name', r.name)
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


--
-- Name: enqueue_plan_expiry_notices(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.enqueue_plan_expiry_notices() RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: handle_new_auth_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_new_auth_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: is_platform_admin(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_platform_admin() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: is_platform_admin_account(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_platform_admin_account() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
    select coalesce(
        (select p.is_platform_admin and p.blocked_at is null from public.profiles p where p.id = auth.uid()),
        false);
$$;


--
-- Name: is_restaurant_member(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_restaurant_member(target_restaurant_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
    select public.restaurant_role(target_restaurant_id) is not null;
$$;


--
-- Name: is_restaurant_owner(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_restaurant_owner(target_restaurant_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
    select coalesce(public.restaurant_role(target_restaurant_id) = 'OWNER', false);
$$;


--
-- Name: is_user_blocked(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.is_user_blocked(p_user_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
    select coalesce((select p.blocked_at is not null from public.profiles p where p.id = p_user_id), false);
$$;


--
-- Name: log_audit(text, uuid, uuid, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.log_audit(p_action text, p_restaurant_id uuid DEFAULT NULL::uuid, p_target_user_id uuid DEFAULT NULL::uuid, p_details jsonb DEFAULT '{}'::jsonb) RETURNS void
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: my_admin_status(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.my_admin_status() RETURNS TABLE(is_admin_account boolean, has_credentials boolean, mfa_ok boolean, unlocked_until timestamp with time zone, locked_until timestamp with time zone)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: my_claims(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.my_claims() RETURNS TABLE(claim_id uuid, restaurant_id uuid, restaurant_name text, restaurant_city text, status public.claim_status, created_at timestamp with time zone, reviewed_at timestamp with time zone, review_note text, phone_code_pending boolean, phone_verified_at timestamp with time zone)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
    select c.id, r.id, r.name, r.city, c.status, c.created_at, c.reviewed_at, c.review_note,
           c.phone_code_hash is not null and c.phone_code_expires_at > now() and c.phone_verified_at is null,
           c.phone_verified_at
    from public.restaurant_claims c
    join public.restaurants r on r.id = c.restaurant_id
    where c.user_id = auth.uid()
    order by c.created_at desc
    limit 20;
$$;


--
-- Name: my_entitlements(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.my_entitlements() RETURNS TABLE(plan_code text, plan_name text, features text[], limits jsonb, valid_until timestamp with time zone)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
    select p.code, p.name, p.features, p.limits,
           (select s.current_period_end from public.consumer_subscriptions s
            where s.user_id = auth.uid() and s.status in ('TRIALING', 'ACTIVE', 'PAST_DUE')
            order by s.created_at desc limit 1)
    from public.plans p
    where p.code = case when auth.uid() is null then 'CONSUMER_FREE'
                        else public.consumer_plan_code(auth.uid()) end;
$$;


--
-- Name: my_profile(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.my_profile() RETURNS TABLE(user_id uuid, email text, display_name text, is_admin_account boolean, blocked boolean, blocked_reason text, accepted_terms_version text, current_terms_version text, accepted_restaurant_terms_version text, current_restaurant_terms_version text, marketing_opt_in boolean, notify_manager_reminders boolean, notify_availability_alerts boolean, notify_claim_updates boolean, consumer_plan text, consumer_plan_until timestamp with time zone, restaurants integer, aal text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: my_restaurants(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.my_restaurants() RETURNS TABLE(restaurant_id uuid, name text, city text, role public.restaurant_user_role, partnership_status public.partnership_status)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
    select r.id, r.name, r.city, ru.role, r.partnership_status
    from public.restaurant_users ru
    join public.restaurants r on r.id = ru.restaurant_id
    where ru.user_id = auth.uid()
    order by r.name;
$$;


--
-- Name: nearby_restaurants(double precision, double precision, integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.nearby_restaurants(lat double precision, long double precision, radius_meters integer DEFAULT 60000, search_text text DEFAULT NULL::text) RETURNS TABLE(id uuid, name text, category text, address text, city text, province text, phone_number text, phone_public boolean, partnership_status public.partnership_status, live_status public.live_status, live_updated_at timestamp with time zone, live_valid_until timestamp with time zone, available_tables smallint, estimated_wait_minutes smallint, note character varying, latitude double precision, longitude double precision, distance_meters double precision, offer character varying)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: public_restaurant_page(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.public_restaurant_page(p_slug text) RETURNS TABLE(id uuid, slug text, name text, category text, address text, city text, province text, phone_number text, phone_public boolean, partnership_status public.partnership_status, live_status public.live_status, live_updated_at timestamp with time zone, live_valid_until timestamp with time zone, available_tables smallint, estimated_wait_minutes smallint, note character varying, latitude double precision, longitude double precision, offer character varying, website_url text, menu_url text, file_path text, file_mime text)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: purge_old_reservations(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.purge_old_reservations(p_keep_days integer DEFAULT 30) RETURNS integer
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
    v_count integer;
begin
    delete from public.reservations
    where reservation_date < public.today_rome() - greatest(p_keep_days, 1);
    get diagnostics v_count = row_count;
    return v_count;
end;
$$;


--
-- Name: purge_operational_data(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.purge_operational_data() RETURNS jsonb
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
    v_history integer;
    v_stats integer;
    v_audit integer;
    v_sessions integer;
begin
    delete from public.status_history where updated_at < now() - interval '180 days';
    get diagnostics v_history = row_count;
    delete from public.restaurant_daily_stats where day < public.today_rome() - 730;
    get diagnostics v_stats = row_count;
    delete from public.audit_log where created_at < now() - interval '730 days';
    get diagnostics v_audit = row_count;
    delete from public.admin_sessions where expires_at < now() - interval '7 days';
    get diagnostics v_sessions = row_count;
    return jsonb_build_object('status_history', v_history, 'daily_stats', v_stats,
                              'audit_log', v_audit, 'admin_sessions', v_sessions);
end;
$$;


--
-- Name: register_new_restaurant(text, text, text, text, text, double precision, double precision, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.register_new_restaurant(p_name text, p_category text, p_address text, p_city text, p_province text, p_latitude double precision, p_longitude double precision, p_phone_number text, p_contact_info text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: register_push_token(text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.register_push_token(p_token text, p_platform text, p_app_version text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: remove_restaurant_staff(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.remove_restaurant_staff(p_restaurant_id uuid, p_user_id uuid) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: reset_claim_pending_if_idle(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reset_claim_pending_if_idle(p_restaurant_id uuid) RETURNS void
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: restaurant_activity(uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restaurant_activity(p_restaurant_id uuid, p_limit integer DEFAULT 50) RETURNS TABLE(happened_at timestamp with time zone, kind text, actor text, summary text)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: restaurant_availability_pattern(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restaurant_availability_pattern(p_restaurant_id uuid) RETURNS TABLE(weekday integer, hour integer, samples integer, available_share numeric, limited_share numeric, full_share numeric)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: restaurant_entitlements(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restaurant_entitlements(p_restaurant_id uuid) RETURNS TABLE(plan_code text, plan_name text, features text[], limits jsonb, source text, valid_until timestamp with time zone)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: restaurant_extras(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restaurant_extras(p_restaurant_id uuid) RETURNS TABLE(quick_notes text[], website_url text, menu_url text, file_path text, file_mime text, file_bytes integer, file_expires_at timestamp with time zone)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
#variable_conflict use_column
begin
    if public.restaurant_role(p_restaurant_id) is null then
        raise exception 'Not authorized for this restaurant';
    end if;
    return query
    select r.quick_notes, r.website_url, r.menu_url,
           case when r.file_expires_at is null or r.file_expires_at > now() then r.file_path end,
           case when r.file_expires_at is null or r.file_expires_at > now() then r.file_mime end,
           case when r.file_expires_at is null or r.file_expires_at > now() then r.file_bytes end,
           case when r.file_expires_at is null or r.file_expires_at > now() then r.file_expires_at end
    from public.restaurants r
    where r.id = p_restaurant_id;
end;
$$;


--
-- Name: restaurant_file_attach(uuid, uuid, text, text, integer, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restaurant_file_attach(p_restaurant_id uuid, p_user_id uuid, p_path text, p_mime text, p_bytes integer, p_today_only boolean) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
    v_old text;
    v_expires timestamptz;
begin
    select r.file_path into v_old from public.restaurants r where r.id = p_restaurant_id for update;
    if not found then
        raise exception 'RESTAURANT_NOT_FOUND';
    end if;
    -- "Solo per oggi": fino alle 4 di notte (ora italiana).
    v_expires := case when p_today_only then
        ((now() at time zone 'Europe/Rome')::date + 1 + time '04:00') at time zone 'Europe/Rome'
    end;
    update public.restaurants
    set file_path = p_path, file_mime = p_mime, file_bytes = p_bytes, file_expires_at = v_expires,
        extras_changed_at = now(), extras_reviewed_at = null
    where id = p_restaurant_id;
    perform public.log_audit('FILE_UPLOADED', p_restaurant_id, p_user_id,
        jsonb_build_object('mime', p_mime, 'bytes', p_bytes, 'today_only', p_today_only));
    return nullif(v_old, p_path);
end;
$$;


--
-- Name: restaurant_file_check(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restaurant_file_check(p_restaurant_id uuid) RETURNS void
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
    perform public.assert_can_edit_restaurant(p_restaurant_id, true);
    if (select r.partnership_status from public.restaurants r where r.id = p_restaurant_id) <> 'ACTIVE_PARTNER' then
        raise exception 'Restaurant is not an active partner';
    end if;
end;
$$;


--
-- Name: restaurant_file_detach(uuid, uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restaurant_file_detach(p_restaurant_id uuid, p_user_id uuid) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
    v_old text;
begin
    select r.file_path into v_old from public.restaurants r where r.id = p_restaurant_id for update;
    if v_old is null then
        return null;
    end if;
    update public.restaurants
    set file_path = null, file_mime = null, file_bytes = null, file_expires_at = null
    where id = p_restaurant_id;
    perform public.log_audit('FILE_REMOVED', p_restaurant_id, p_user_id, '{}'::jsonb);
    return v_old;
end;
$$;


--
-- Name: restaurant_files_cleanup(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restaurant_files_cleanup() RETURNS SETOF text
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
begin
    update public.restaurants
    set file_path = null, file_mime = null, file_bytes = null, file_expires_at = null
    where file_expires_at is not null and file_expires_at <= now();

    if to_regclass('storage.objects') is null then
        return;
    end if;
    return query execute $q$
        select o.name
        from storage.objects o
        where o.bucket_id = 'restaurant-files'
          and o.created_at < now() - interval '1 hour'
          and not exists (select 1 from public.restaurants r where r.file_path = o.name)
        order by o.created_at
        limit 500
    $q$;
end;
$_$;


--
-- Name: restaurant_has_feature(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restaurant_has_feature(p_restaurant_id uuid, p_feature text) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
    select coalesce(
        (select p_feature = any(p.features) from public.plans p
         where p.code = public.restaurant_plan_code(p_restaurant_id)),
        false
    );
$$;


--
-- Name: restaurant_is_connected(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restaurant_is_connected(p_restaurant_id uuid) RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
    -- CASE: il piano si calcola solo per i partner (la directory ha migliaia di locali).
    select coalesce(
        (select case when r.partnership_status = 'ACTIVE_PARTNER'
                     then public.restaurant_has_feature(r.id, 'LIVE_STATUS') else false end
         from public.restaurants r where r.id = p_restaurant_id),
        false
    );
$$;


--
-- Name: restaurant_limit(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restaurant_limit(p_restaurant_id uuid, p_limit text) RETURNS integer
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
    select coalesce(
        (select (p.limits ->> p_limit)::integer from public.plans p
         where p.code = public.restaurant_plan_code(p_restaurant_id)),
        0
    );
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: restaurant_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.restaurant_subscriptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    restaurant_id uuid NOT NULL,
    plan_code text NOT NULL,
    audience text DEFAULT 'RESTAURANT'::text NOT NULL,
    status text NOT NULL,
    billing_interval text,
    provider text NOT NULL,
    provider_customer_id text,
    provider_subscription_id text,
    current_period_start timestamp with time zone,
    current_period_end timestamp with time zone,
    cancel_at_period_end boolean DEFAULT false NOT NULL,
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT restaurant_subscriptions_audience_check CHECK ((audience = 'RESTAURANT'::text)),
    CONSTRAINT restaurant_subscriptions_billing_interval_check CHECK ((billing_interval = ANY (ARRAY['MONTH'::text, 'SEMESTER'::text, 'YEAR'::text]))),
    CONSTRAINT restaurant_subscriptions_note_check CHECK (((note IS NULL) OR (char_length(note) <= 300))),
    CONSTRAINT restaurant_subscriptions_provider_check CHECK ((provider = ANY (ARRAY['STRIPE'::text, 'MANUAL'::text, 'BETA'::text]))),
    CONSTRAINT restaurant_subscriptions_status_check CHECK ((status = ANY (ARRAY['TRIALING'::text, 'ACTIVE'::text, 'PAST_DUE'::text, 'CANCELED'::text, 'EXPIRED'::text])))
);


--
-- Name: restaurant_live_subscription(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restaurant_live_subscription(p_restaurant_id uuid) RETURNS public.restaurant_subscriptions
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
    select s.*
    from public.restaurant_subscriptions s
    where s.restaurant_id = p_restaurant_id
      and s.status in ('TRIALING', 'ACTIVE', 'PAST_DUE')
      and (s.current_period_end is null or s.current_period_end > now() - interval '3 days')
    order by s.created_at desc
    limit 1;
$$;


--
-- Name: restaurant_manager_info(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restaurant_manager_info(p_restaurant_id uuid) RETURNS TABLE(restaurant_id uuid, name text, category text, address text, city text, province text, phone_number text, phone_public boolean, opening_hours jsonb, slug text, partnership_status public.partnership_status, my_role public.restaurant_user_role, plan_code text, plan_name text, plan_source text, plan_valid_until timestamp with time zone, features text[], limits jsonb, mfa_required boolean, mfa_ok boolean)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: restaurant_members(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restaurant_members(p_restaurant_id uuid) RETURNS TABLE(user_id uuid, email text, display_name text, role public.restaurant_user_role, member_since timestamp with time zone)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: restaurant_mfa_satisfied(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restaurant_mfa_satisfied() RETURNS boolean
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
    select public.current_aal() = 'aal2'
        or not coalesce(public.config_value('security', 'restaurant_mfa_required')::boolean, true);
$$;


--
-- Name: restaurant_plan_code(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restaurant_plan_code(p_restaurant_id uuid) RETURNS text
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
    select coalesce(
        (select s.plan_code from public.restaurant_live_subscription(p_restaurant_id) s where s.id is not null),
        case when public.restaurant_trial_until(p_restaurant_id) > now() then 'RESTAURANT_PRO' end,
        'RESTAURANT_BASIC'
    );
$$;


--
-- Name: restaurant_plan_ends_at(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restaurant_plan_ends_at(p_restaurant_id uuid) RETURNS timestamp with time zone
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: restaurant_public_details(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restaurant_public_details(p_restaurant_id uuid) RETURNS TABLE(slug text, opening_hours jsonb, website_url text, menu_url text, file_path text, file_mime text, file_today_only boolean)
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: restaurant_role(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restaurant_role(target_restaurant_id uuid) RETURNS public.restaurant_user_role
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
    select ru.role
    from public.restaurant_users ru
    where ru.restaurant_id = target_restaurant_id
      and ru.user_id = auth.uid()
      and not public.is_user_blocked(auth.uid());
$$;


--
-- Name: restaurant_stats(uuid, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restaurant_stats(p_restaurant_id uuid, p_days integer DEFAULT 30) RETURNS TABLE(day date, detail_views integer, directions_taps integer, call_taps integer, public_page_views integer, shares integer, live_updates integer)
    LANGUAGE plpgsql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: restaurant_trial_until(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.restaurant_trial_until(p_restaurant_id uuid) RETURNS timestamp with time zone
    LANGUAGE sql STABLE SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: set_marketing_consent(boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_marketing_consent(p_opt_in boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
begin
    perform public.assert_active_user();
    insert into public.profiles (id) values (auth.uid()) on conflict (id) do nothing;
    update public.profiles set marketing_opt_in = coalesce(p_opt_in, false) where id = auth.uid();
    insert into public.consent_log (user_id, kind, version, granted)
    values (auth.uid(), 'MARKETING', null, coalesce(p_opt_in, false));
end;
$$;


--
-- Name: set_notification_prefs(boolean, boolean, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_notification_prefs(p_manager_reminders boolean, p_availability_alerts boolean, p_claim_updates boolean) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: set_partner_since(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_partner_since() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
begin
    if new.partnership_status = 'ACTIVE_PARTNER' and new.partner_since is null then
        new.partner_since := now();
    end if;
    return new;
end;
$$;


--
-- Name: set_restaurant_links(uuid, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_restaurant_links(p_restaurant_id uuid, p_website_url text, p_menu_url text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
    v_website text := nullif(btrim(coalesce(p_website_url, '')), '');
    v_menu text := nullif(btrim(coalesce(p_menu_url, '')), '');
    v_old record;
begin
    perform public.assert_can_edit_restaurant(p_restaurant_id, true);
    if v_website is not null and v_website !~* '^https?://' then
        v_website := 'https://' || v_website;
    end if;
    if v_menu is not null and v_menu !~* '^https?://' then
        v_menu := 'https://' || v_menu;
    end if;
    if not public.valid_public_link(v_website) or not public.valid_public_link(v_menu) then
        raise exception 'INVALID_LINK';
    end if;
    select r.website_url, r.menu_url into v_old from public.restaurants r where r.id = p_restaurant_id;
    if v_old.website_url is not distinct from v_website and v_old.menu_url is not distinct from v_menu then
        return;
    end if;
    update public.restaurants
    set website_url = v_website, menu_url = v_menu, extras_changed_at = now(), extras_reviewed_at = null
    where id = p_restaurant_id;
    perform public.log_audit('LINKS_UPDATED', p_restaurant_id, null,
        jsonb_build_object('website_url', v_website, 'menu_url', v_menu));
end;
$$;


--
-- Name: restaurant_live_status; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.restaurant_live_status (
    restaurant_id uuid NOT NULL,
    status public.live_status NOT NULL,
    available_tables smallint,
    estimated_wait_minutes smallint,
    note character varying(80),
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    valid_until timestamp with time zone DEFAULT (now() + '00:30:00'::interval) NOT NULL,
    updated_via text DEFAULT 'OWNER'::text NOT NULL,
    offer character varying(60),
    CONSTRAINT full_has_no_available_tables CHECK (((status <> 'FULL'::public.live_status) OR (available_tables IS NULL))),
    CONSTRAINT live_status_valid_window CHECK ((valid_until > updated_at)),
    CONSTRAINT restaurant_live_status_available_tables_check CHECK (((available_tables IS NULL) OR ((available_tables >= 0) AND (available_tables <= 99)))),
    CONSTRAINT restaurant_live_status_estimated_wait_minutes_check CHECK (((estimated_wait_minutes IS NULL) OR ((estimated_wait_minutes >= 0) AND (estimated_wait_minutes <= 240)))),
    CONSTRAINT restaurant_live_status_updated_via_check CHECK ((updated_via = ANY (ARRAY['OWNER'::text, 'STAFF'::text, 'ADMIN'::text, 'DEV_APP'::text, 'DEV_SIMULATOR'::text])))
);


--
-- Name: set_restaurant_live_status(uuid, public.live_status, smallint, smallint, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_restaurant_live_status(p_restaurant_id uuid, p_status public.live_status, p_available_tables smallint DEFAULT NULL::smallint, p_estimated_wait_minutes smallint DEFAULT NULL::smallint, p_note character varying DEFAULT NULL::character varying) RETURNS public.restaurant_live_status
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO ''
    AS $$
    select * from public.set_restaurant_live_status(
        p_restaurant_id, p_status, p_available_tables, p_estimated_wait_minutes, p_note, null::varchar
    );
$$;


--
-- Name: set_restaurant_live_status(uuid, public.live_status, smallint, smallint, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_restaurant_live_status(p_restaurant_id uuid, p_status public.live_status, p_available_tables smallint, p_estimated_wait_minutes smallint, p_note character varying, p_offer character varying) RETURNS public.restaurant_live_status
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
    v_now timestamptz := now();
    v_role public.restaurant_user_role;
    v_details boolean;
    v_partnership public.partnership_status;
    v_available_tables smallint;
    v_wait smallint;
    v_note varchar(80);
    v_offer text;
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
    -- L'offerta ha senso solo se c'è posto; scade con lo stato (la riga si riscrive a ogni pubblicazione).
    v_offer := case when v_details and p_status <> 'FULL' then nullif(btrim(p_offer), '') end;

    if v_available_tables is not null and v_available_tables not between 0 and 99 then
        raise exception 'available_tables must be between 0 and 99';
    end if;
    if v_wait is not null and v_wait not between 0 and 240 then
        raise exception 'estimated_wait_minutes must be between 0 and 240';
    end if;
    if v_offer is not null and char_length(v_offer) > 60 then
        raise exception 'OFFER_TOO_LONG';
    end if;

    insert into public.restaurant_live_status (
        restaurant_id, status, available_tables, estimated_wait_minutes, note, offer,
        updated_at, valid_until, updated_via
    ) values (
        p_restaurant_id, p_status, v_available_tables, v_wait, v_note, v_offer,
        v_now, v_now + interval '30 minutes', v_via
    )
    on conflict (restaurant_id) do update set
        status = excluded.status,
        available_tables = excluded.available_tables,
        estimated_wait_minutes = excluded.estimated_wait_minutes,
        note = excluded.note,
        offer = excluded.offer,
        updated_at = excluded.updated_at,
        valid_until = excluded.valid_until,
        updated_via = excluded.updated_via
    returning * into v_row;

    insert into public.status_history (
        restaurant_id, status, available_tables, estimated_wait_minutes, note, offer,
        updated_at, valid_until, updated_by, updated_via
    ) values (
        v_row.restaurant_id, v_row.status, v_row.available_tables, v_row.estimated_wait_minutes,
        v_row.note, v_row.offer, v_row.updated_at, v_row.valid_until, auth.uid(), v_row.updated_via
    );

    return v_row;
end;
$$;


--
-- Name: set_restaurant_quick_notes(uuid, text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_restaurant_quick_notes(p_restaurant_id uuid, p_notes text[]) RETURNS text[]
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
declare
    v_clean text[];
begin
    perform public.assert_can_edit_restaurant(p_restaurant_id, false);
    select coalesce(array_agg(clean order by ord), '{}'::text[]) into v_clean
    from (
        select distinct on (lower(clean)) clean, ord
        from (
            select btrim(regexp_replace(coalesce(n, ''), '\s+', ' ', 'g')) as clean, ord
            from unnest(coalesce(p_notes, '{}'::text[])) with ordinality as t(n, ord)
        ) as cleaned
        where clean <> ''
        order by lower(clean), ord
    ) as unique_notes;
    if cardinality(v_clean) > 8 then
        raise exception 'QUICK_NOTES_LIMIT';
    end if;
    if exists (select 1 from unnest(v_clean) as n where char_length(n) > 80) then
        raise exception 'NOTE_TOO_LONG';
    end if;
    update public.restaurants set quick_notes = v_clean where id = p_restaurant_id;
    perform public.log_audit('QUICK_NOTES_UPDATED', p_restaurant_id, null,
        jsonb_build_object('count', cardinality(v_clean)));
    return v_clean;
end;
$$;


--
-- Name: slugify(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.slugify(p_text text) RETURNS text
    LANGUAGE sql IMMUTABLE
    SET search_path TO ''
    AS $$
    select btrim(
        regexp_replace(
            translate(lower(coalesce(p_text, '')),
                      'àáâäãèéêëìíîïòóôöõùúûüçñ''’',
                      'aaaaaeeeeiiiiooooouuuucn  '),
            '[^a-z0-9]+', '-', 'g'),
        '-');
$$;


--
-- Name: submit_restaurant_claim(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.submit_restaurant_claim(p_restaurant_id uuid, p_contact_info text) RETURNS uuid
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: today_rome(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.today_rome() RETURNS date
    LANGUAGE sql STABLE
    SET search_path TO ''
    AS $$
    select (now() at time zone 'Europe/Rome')::date;
$$;


--
-- Name: touch_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.touch_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO ''
    AS $$
begin
    new.updated_at := now();
    return new;
end;
$$;


--
-- Name: track_restaurant_event(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.track_restaurant_event(p_restaurant_id uuid, p_event text) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: unregister_push_token(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.unregister_push_token(p_token text) RETURNS void
    LANGUAGE sql SECURITY DEFINER
    SET search_path TO ''
    AS $$
    delete from public.device_push_tokens where token = p_token and user_id = auth.uid();
$$;


--
-- Name: update_restaurant_profile(uuid, text, text, text, boolean, jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_restaurant_profile(p_restaurant_id uuid, p_name text, p_category text, p_phone_number text, p_phone_public boolean, p_opening_hours jsonb) RETURNS void
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
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
$_$;


--
-- Name: valid_opening_hours(jsonb); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.valid_opening_hours(p_hours jsonb) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    SET search_path TO ''
    AS $_$
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
$_$;


--
-- Name: valid_public_link(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.valid_public_link(p_url text) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    SET search_path TO ''
    AS $_$
    select p_url is null
        or (char_length(p_url) <= 300
            and p_url ~ '^https?://[A-Za-z0-9.-]+\.[A-Za-z]{2,}(:[0-9]{2,5})?(/[^[:space:]]*)?$');
$_$;


--
-- Name: valid_quick_notes(text[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.valid_quick_notes(p_notes text[]) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    SET search_path TO ''
    AS $$
    select coalesce(cardinality(p_notes), 0) <= 8
       and not exists (
           select 1 from unnest(coalesce(p_notes, '{}'::text[])) as n
           where n is null or char_length(btrim(n)) not between 1 and 80
       );
$$;


--
-- Name: verify_my_claim_code(uuid, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.verify_my_claim_code(p_claim_id uuid, p_code text) RETURNS TABLE(ok boolean, error_code text, attempts_left integer)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $$
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


--
-- Name: apply_rls(jsonb, integer); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer DEFAULT (1024 * 1024)) RETURNS SETOF realtime.wal_rls
    LANGUAGE plpgsql
    AS $$
declare
    -- Regclass of the table e.g. public.notes
    entity_ regclass = (quote_ident(wal ->> 'schema') || '.' || quote_ident(wal ->> 'table'))::regclass;

    -- I, U, D, T: insert, update ...
    action realtime.action = (
        case wal ->> 'action'
            when 'I' then 'INSERT'
            when 'U' then 'UPDATE'
            when 'D' then 'DELETE'
            else 'ERROR'
        end
    );

    -- Is row level security enabled for the table
    is_rls_enabled bool = relrowsecurity from pg_class where oid = entity_;

    subscriptions realtime.subscription[] = array_agg(subs)
        from
            realtime.subscription subs
        where
            subs.entity = entity_
            -- Filter by action early - only get subscriptions interested in this action
            -- action_filter column can be: '*' (all), 'INSERT', 'UPDATE', or 'DELETE'
            and (subs.action_filter = '*' or subs.action_filter = action::text);

    -- Subscription vars
    working_role regrole;
    working_selected_columns text[];
    claimed_role regrole;
    claims jsonb;

    subscription_id uuid;
    subscription_has_access bool;
    visible_to_subscription_ids uuid[] = '{}';

    -- structured info for wal's columns
    columns realtime.wal_column[];
    -- previous identity values for update/delete
    old_columns realtime.wal_column[];

    error_record_exceeds_max_size boolean = octet_length(wal::text) > max_record_bytes;

    -- Primary jsonb output for record
    output jsonb;

    -- Loop record for iterating unique roles (outer loop)
    role_record record;
    -- Loop record for iterating unique selected_columns within a role (inner loop)
    cols_record record;
    -- Subscription ids visible at the role level (before fanning out by selected_columns)
    visible_role_sub_ids uuid[] = '{}';

begin
    perform set_config('role', null, true);

    columns =
        array_agg(
            (
                x->>'name',
                x->>'type',
                x->>'typeoid',
                realtime.cast(
                    (x->'value') #>> '{}',
                    coalesce(
                        (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                        (x->>'type')::regtype
                    )
                ),
                (pks ->> 'name') is not null,
                true
            )::realtime.wal_column
        )
        from
            jsonb_array_elements(wal -> 'columns') x
            left join jsonb_array_elements(wal -> 'pk') pks
                on (x ->> 'name') = (pks ->> 'name');

    old_columns =
        array_agg(
            (
                x->>'name',
                x->>'type',
                x->>'typeoid',
                realtime.cast(
                    (x->'value') #>> '{}',
                    coalesce(
                        (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                        (x->>'type')::regtype
                    )
                ),
                (pks ->> 'name') is not null,
                true
            )::realtime.wal_column
        )
        from
            jsonb_array_elements(wal -> 'identity') x
            left join jsonb_array_elements(wal -> 'pk') pks
                on (x ->> 'name') = (pks ->> 'name');

    for role_record in
        select claims_role
        from (select distinct claims_role from unnest(subscriptions)) t
        order by claims_role::text
    loop
        working_role := role_record.claims_role;

        -- Update `is_selectable` for columns and old_columns (once per role)
        columns =
            array_agg(
                (
                    c.name,
                    c.type_name,
                    c.type_oid,
                    c.value,
                    c.is_pkey,
                    pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
                )::realtime.wal_column
            )
            from
                unnest(columns) c;

        old_columns =
                array_agg(
                    (
                        c.name,
                        c.type_name,
                        c.type_oid,
                        c.value,
                        c.is_pkey,
                        pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
                    )::realtime.wal_column
                )
                from
                    unnest(old_columns) c;

        if action <> 'DELETE' and count(1) = 0 from unnest(columns) c where c.is_pkey then
            -- Fan out 400 error per distinct selected_columns for this role
            for cols_record in
                select selected_columns
                from (select distinct selected_columns from unnest(subscriptions) s where s.claims_role = working_role) t
                order by coalesce(array_to_string(selected_columns, ','), '')
            loop
                working_selected_columns := cols_record.selected_columns;
                return next (
                    jsonb_build_object(
                        'schema', wal ->> 'schema',
                        'table', wal ->> 'table',
                        'type', action
                    ),
                    is_rls_enabled,
                    (select array_agg(s.subscription_id) from unnest(subscriptions) as s where s.claims_role = working_role and (s.selected_columns is not distinct from working_selected_columns)),
                    array['Error 400: Bad Request, no primary key']
                )::realtime.wal_rls;
            end loop;

        -- The claims role does not have SELECT permission to the primary key of entity
        elsif action <> 'DELETE' and sum(c.is_selectable::int) <> count(1) from unnest(columns) c where c.is_pkey then
            -- Fan out 401 error per distinct selected_columns for this role
            for cols_record in
                select selected_columns
                from (select distinct selected_columns from unnest(subscriptions) s where s.claims_role = working_role) t
                order by coalesce(array_to_string(selected_columns, ','), '')
            loop
                working_selected_columns := cols_record.selected_columns;
                return next (
                    jsonb_build_object(
                        'schema', wal ->> 'schema',
                        'table', wal ->> 'table',
                        'type', action
                    ),
                    is_rls_enabled,
                    (select array_agg(s.subscription_id) from unnest(subscriptions) as s where s.claims_role = working_role and (s.selected_columns is not distinct from working_selected_columns)),
                    array['Error 401: Unauthorized']
                )::realtime.wal_rls;
            end loop;

        else
            -- Create the prepared statement (once per role)
            if is_rls_enabled and action <> 'DELETE' then
                if (select 1 from pg_prepared_statements where name = 'walrus_rls_stmt' limit 1) > 0 then
                    deallocate walrus_rls_stmt;
                end if;
                execute realtime.build_prepared_statement_sql('walrus_rls_stmt', entity_, columns);
            end if;

            -- Collect all visible subscription IDs for this role (filter check + RLS check)
            visible_role_sub_ids = '{}';

            for subscription_id, claims in (
                    select
                        subs.subscription_id,
                        subs.claims
                    from
                        unnest(subscriptions) subs
                    where
                        subs.entity = entity_
                        and subs.claims_role = working_role
                        and (
                            realtime.is_visible_through_filters(columns, subs.filters)
                            or (
                              action = 'DELETE'
                              and realtime.is_visible_through_filters(old_columns, subs.filters)
                            )
                        )
            ) loop

                if not is_rls_enabled or action = 'DELETE' then
                    visible_role_sub_ids = visible_role_sub_ids || subscription_id;
                else
                    -- Check if RLS allows the role to see the record
                    perform
                        -- Trim leading and trailing quotes from working_role because set_config
                        -- doesn't recognize the role as valid if they are included
                        set_config('role', trim(both '"' from working_role::text), true),
                        set_config('request.jwt.claims', claims::text, true);

                    execute 'execute walrus_rls_stmt' into subscription_has_access;

                    -- Reset the role on every FOR..LOOP batch execution.
                    -- The first batch of 10 rows is pre-fetched using the current connection role (PG internal behaviour)
                    -- then we have to reset it again otherwise it would use the role defined in the `set_config` above
                    -- to fetch the remaining rows when rows>10, which could be a user-defined role that lacks execution grants.
                    -- The flow is:
                    --   1. run batch with conn role
                    --   2. set_config working_role
                    --   3. execute walrus
                    --   4. reset role (revert)
                    --   5. repeat
                    perform set_config('role', null, true);

                    if subscription_has_access then
                        visible_role_sub_ids = visible_role_sub_ids || subscription_id;
                    end if;
                end if;
            end loop;

            perform set_config('role', null, true);

            -- Inner loop: per distinct selected_columns for this role
            for cols_record in
                select selected_columns
                from (select distinct selected_columns from unnest(subscriptions) s where s.claims_role = working_role) t
                order by coalesce(array_to_string(selected_columns, ','), '')
            loop
                working_selected_columns := cols_record.selected_columns;

                output = jsonb_build_object(
                    'schema', wal ->> 'schema',
                    'table', wal ->> 'table',
                    'type', action,
                    'commit_timestamp', to_char(
                        ((wal ->> 'timestamp')::timestamptz at time zone 'utc'),
                        'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'
                    ),
                    'columns', (
                        select
                            jsonb_agg(
                                jsonb_build_object(
                                    'name', pa.attname,
                                    'type', pt.typname
                                )
                                order by pa.attnum asc
                            )
                        from
                            pg_attribute pa
                            join pg_type pt
                                on pa.atttypid = pt.oid
                            left join (
                                select unnest(conkey) as pkey_attnum
                                from pg_constraint
                                where conrelid = entity_ and contype = 'p'
                            ) pk on pk.pkey_attnum = pa.attnum
                        where
                            attrelid = entity_
                            and attnum > 0
                            and pg_catalog.has_column_privilege(working_role, entity_, pa.attname, 'SELECT')
                            and (working_selected_columns is null or pa.attname = any(working_selected_columns) or pk.pkey_attnum is not null)
                    )
                )
                -- Add "record" key for insert and update
                || case
                    when action in ('INSERT', 'UPDATE') then
                        jsonb_build_object(
                            'record',
                            (
                                select
                                    jsonb_object_agg(
                                        -- if unchanged toast, get column name and value from old record
                                        coalesce((c).name, (oc).name),
                                        case
                                            when (c).name is null then (oc).value
                                            else (c).value
                                        end
                                    )
                                from
                                    unnest(columns) c
                                    full outer join unnest(old_columns) oc
                                        on (c).name = (oc).name
                                where
                                    coalesce((c).is_selectable, (oc).is_selectable)
                                    and (working_selected_columns is null or coalesce((c).name, (oc).name) = any(working_selected_columns) or coalesce((c).is_pkey, (oc).is_pkey))
                                    and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                            )
                        )
                    else '{}'::jsonb
                end
                -- Add "old_record" key for update and delete
                || case
                    when action = 'UPDATE' then
                        jsonb_build_object(
                                'old_record',
                                (
                                    select jsonb_object_agg((c).name, (c).value)
                                    from unnest(old_columns) c
                                    where
                                        (c).is_selectable
                                        and (working_selected_columns is null or (c).name = any(working_selected_columns) or (c).is_pkey)
                                        and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                                )
                            )
                    when action = 'DELETE' then
                        jsonb_build_object(
                            'old_record',
                            (
                                select jsonb_object_agg((c).name, (c).value)
                                from unnest(old_columns) c
                                where
                                    (c).is_selectable
                                    and (working_selected_columns is null or (c).name = any(working_selected_columns) or (c).is_pkey)
                                    and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                                    and ( not is_rls_enabled or (c).is_pkey ) -- if RLS enabled, we can't secure deletes so filter to pkey
                            )
                        )
                    else '{}'::jsonb
                end;

                -- Filter visible_role_sub_ids to those matching the current selected_columns group
                visible_to_subscription_ids = coalesce(
                    (
                        select array_agg(s.subscription_id)
                        from unnest(subscriptions) s
                        where s.claims_role = working_role
                          and (s.selected_columns is not distinct from working_selected_columns)
                          and s.subscription_id = any(visible_role_sub_ids)
                    ),
                    '{}'::uuid[]
                );

                return next (
                    output,
                    is_rls_enabled,
                    visible_to_subscription_ids,
                    case
                        when error_record_exceeds_max_size then array['Error 413: Payload Too Large']
                        else '{}'
                    end
                )::realtime.wal_rls;
            end loop;

        end if;
    end loop;

    perform set_config('role', null, true);
end;
$$;


--
-- Name: broadcast_changes(text, text, text, text, text, record, record, text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text DEFAULT 'ROW'::text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    -- Declare a variable to hold the JSONB representation of the row
    row_data jsonb := '{}'::jsonb;
BEGIN
    IF level = 'STATEMENT' THEN
        RAISE EXCEPTION 'function can only be triggered for each row, not for each statement';
    END IF;
    -- Check the operation type and handle accordingly
    IF operation = 'INSERT' OR operation = 'UPDATE' OR operation = 'DELETE' THEN
        row_data := jsonb_build_object('old_record', OLD, 'record', NEW, 'operation', operation, 'table', table_name, 'schema', table_schema);
        PERFORM realtime.send (row_data, event_name, topic_name);
    ELSE
        RAISE EXCEPTION 'Unexpected operation type: %', operation;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to process the row: %', SQLERRM;
END;

$$;


--
-- Name: build_prepared_statement_sql(text, regclass, realtime.wal_column[]); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) RETURNS text
    LANGUAGE sql
    AS $$
      /*
      Builds a sql string that, if executed, creates a prepared statement to
      tests retrive a row from *entity* by its primary key columns.
      Example
          select realtime.build_prepared_statement_sql('public.notes', '{"id"}'::text[], '{"bigint"}'::text[])
      */
          select
      'prepare ' || prepared_statement_name || ' as
          select
              exists(
                  select
                      1
                  from
                      ' || entity || '
                  where
                      ' || string_agg(quote_ident(pkc.name) || '=' || quote_nullable(pkc.value #>> '{}') , ' and ') || '
              )'
          from
              unnest(columns) pkc
          where
              pkc.is_pkey
          group by
              entity
      $$;


--
-- Name: cast(text, regtype); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime."cast"(val text, type_ regtype) RETURNS jsonb
    LANGUAGE plpgsql IMMUTABLE
    AS $$
declare
  res jsonb;
begin
  if type_::text = 'bytea' then
    return to_jsonb(val);
  end if;
  execute format('select to_jsonb(%L::'|| type_::text || ')', val) into res;
  return res;
end
$$;


--
-- Name: check_equality_op(realtime.equality_op, regtype, text, text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
/*
Casts *val_1* and *val_2* as type *type_* and check the *op* condition for truthiness
*/
declare
    op_symbol text = (
        case
            when op = 'eq' then '='
            when op = 'neq' then '!='
            when op = 'lt' then '<'
            when op = 'lte' then '<='
            when op = 'gt' then '>'
            when op = 'gte' then '>='
            when op = 'in' then '= any'
            else 'UNKNOWN OP'
        end
    );
    res boolean;
begin
    execute format(
        'select %L::'|| type_::text || ' ' || op_symbol
        || ' ( %L::'
        || (
            case
                when op = 'in' then type_::text || '[]'
                else type_::text end
        )
        || ')', val_1, val_2) into res;
    return res;
end;
$$;


--
-- Name: check_equality_op(realtime.equality_op, regtype, text, text, boolean); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text, negate boolean) RETURNS boolean
    LANGUAGE plpgsql STABLE
    AS $$
declare
    op_symbol text;
    res boolean;
begin
    -- IS DISTINCT FROM / IS NOT DISTINCT FROM: infix, both sides typed literals
    if op = 'isdistinct' then
        execute format(
            'select %L::%s %s %L::%s',
            val_1,
            type_::text,
            case when negate then 'IS NOT DISTINCT FROM' else 'IS DISTINCT FROM' end,
            val_2,
            type_::text
        ) into res;
        return res;
    end if;

    -- IS requires a keyword RHS (NULL, TRUE, FALSE, UNKNOWN), not a typed literal
    if op = 'is' then
        if val_2 not in ('null', 'true', 'false', 'unknown') then
            raise exception 'invalid value for is filter: must be null, true, false, or unknown';
        end if;
        execute format(
            'select %L::%s %s %s',
            val_1,
            type_::text,
            case when negate then 'IS NOT' else 'IS' end,
            upper(val_2)
        ) into res;
        return res;
    end if;

    op_symbol = case
        when op = 'eq'    then '='
        when op = 'neq'   then '!='
        when op = 'lt'    then '<'
        when op = 'lte'   then '<='
        when op = 'gt'    then '>'
        when op = 'gte'   then '>='
        when op = 'in'    then '= any'
        when op = 'like'   then 'LIKE'
        when op = 'ilike'  then 'ILIKE'
        when op = 'match'  then '~'
        when op = 'imatch' then '~*'
        else null
    end;

    if op_symbol is null then
        raise exception 'unsupported equality operator: %', op::text;
    end if;

    execute format(
        'select %L::%s %s (%L::%s)',
        val_1,
        type_::text,
        op_symbol,
        val_2,
        case when op = 'in' then type_::text || '[]' else type_::text end
    ) into res;

    return case when negate then not res else res end;
end;
$$;


--
-- Name: is_visible_through_filters(realtime.wal_column[], realtime.user_defined_filter[]); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
    select
        filters is null
        or array_length(filters, 1) is null
        or coalesce(
            count(col.name) = count(1)
            and sum(
                realtime.check_equality_op(
                    op:=f.op,
                    type_:=coalesce(col.type_oid::regtype, col.type_name::regtype),
                    val_1:=col.value #>> '{}',
                    val_2:=f.value,
                    negate:=coalesce(f.negate, false)
                )::int
            ) filter (where col.name is not null) = count(col.name),
            false
        )
    from
        unnest(filters) f
        left join unnest(columns) col
            on f.column_name = col.name;
$$;


--
-- Name: list_changes(name, name, integer, integer); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) RETURNS TABLE(wal jsonb, is_rls_enabled boolean, subscription_ids uuid[], errors text[], slot_changes_count bigint)
    LANGUAGE sql
    SET log_min_messages TO 'fatal'
    AS $$
  WITH pub AS (
    SELECT
      concat_ws(
        ',',
        CASE WHEN bool_or(pubinsert) THEN 'insert' ELSE NULL END,
        CASE WHEN bool_or(pubupdate) THEN 'update' ELSE NULL END,
        CASE WHEN bool_or(pubdelete) THEN 'delete' ELSE NULL END
      ) AS w2j_actions,
      coalesce(
        string_agg(
          realtime.quote_wal2json(format('%I.%I', schemaname, tablename)::regclass),
          ','
        ) filter (WHERE ppt.tablename IS NOT NULL),
        ''
      ) AS w2j_add_tables
    FROM pg_publication pp
    LEFT JOIN pg_publication_tables ppt ON pp.pubname = ppt.pubname
    WHERE pp.pubname = publication
    GROUP BY pp.pubname
    LIMIT 1
  ),
  -- MATERIALIZED ensures pg_logical_slot_get_changes is called exactly once
  w2j AS MATERIALIZED (
    SELECT x.*, pub.w2j_add_tables
    FROM pub,
         pg_logical_slot_get_changes(
           slot_name, null, max_changes,
           'include-pk', 'true',
           'include-transaction', 'false',
           'include-timestamp', 'true',
           'include-type-oids', 'true',
           'format-version', '2',
           'actions', pub.w2j_actions,
           'add-tables', pub.w2j_add_tables
         ) x
  ),
  slot_count AS (
    SELECT count(*)::bigint AS cnt
    FROM w2j
    WHERE w2j.w2j_add_tables <> ''
  ),
  rls_filtered AS (
    SELECT xyz.wal, xyz.is_rls_enabled, xyz.subscription_ids, xyz.errors
    FROM w2j,
         realtime.apply_rls(
           wal := w2j.data::jsonb,
           max_record_bytes := max_record_bytes
         ) xyz(wal, is_rls_enabled, subscription_ids, errors)
    WHERE w2j.w2j_add_tables <> ''
      AND xyz.subscription_ids[1] IS NOT NULL
  )
  SELECT rf.wal, rf.is_rls_enabled, rf.subscription_ids, rf.errors, sc.cnt
  FROM rls_filtered rf, slot_count sc

  UNION ALL

  SELECT null, null, null, null, sc.cnt
  FROM slot_count sc
  WHERE NOT EXISTS (SELECT 1 FROM rls_filtered)
$$;


--
-- Name: list_changes_sync(name, name, integer, integer); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.list_changes_sync(publication name, slot_name name, max_changes integer, max_record_bytes integer) RETURNS TABLE(wal jsonb, is_rls_enabled boolean, subscription_ids uuid[], errors text[], slot_changes_count bigint)
    LANGUAGE sql
    SET log_min_messages TO 'fatal'
    AS $$
  WITH pub AS (
    SELECT
      concat_ws(
        ',',
        CASE WHEN bool_or(pubinsert) THEN 'insert' ELSE NULL END,
        CASE WHEN bool_or(pubupdate) THEN 'update' ELSE NULL END,
        CASE WHEN bool_or(pubdelete) THEN 'delete' ELSE NULL END
      ) AS w2j_actions,
      coalesce(
        string_agg(
          realtime.quote_wal2json(format('%I.%I', schemaname, tablename)::regclass),
          ','
        ) filter (WHERE ppt.tablename IS NOT NULL),
        ''
      ) AS w2j_add_tables
    FROM pg_publication pp
    LEFT JOIN pg_publication_tables ppt ON pp.pubname = ppt.pubname
    WHERE pp.pubname = publication
    GROUP BY pp.pubname
    LIMIT 1
  ),
  -- MATERIALIZED ensures the slot is read exactly once.
  consumed AS MATERIALIZED (
    SELECT x.*, pub.w2j_add_tables
    FROM pub,
         realtime.settled_changes(
           slot_name, max_changes,
           'include-pk', 'true',
           'include-transaction', 'false',
           'include-timestamp', 'true',
           'include-type-oids', 'true',
           'format-version', '2',
           'actions', pub.w2j_actions,
           'add-tables', pub.w2j_add_tables
         ) x
  ),
  slot_count AS (
    SELECT count(*)::bigint AS cnt
    FROM consumed
    WHERE consumed.w2j_add_tables <> ''
  ),
  rls_filtered AS (
    SELECT xyz.wal, xyz.is_rls_enabled, xyz.subscription_ids, xyz.errors
    FROM consumed,
         realtime.apply_rls(
           wal := consumed.data::jsonb,
           max_record_bytes := max_record_bytes
         ) xyz(wal, is_rls_enabled, subscription_ids, errors)
    WHERE consumed.w2j_add_tables <> ''
      AND xyz.subscription_ids[1] IS NOT NULL
  )
  SELECT rf.wal, rf.is_rls_enabled, rf.subscription_ids, rf.errors, sc.cnt
  FROM rls_filtered rf, slot_count sc

  UNION ALL

  SELECT null, null, null, null, sc.cnt
  FROM slot_count sc
  WHERE NOT EXISTS (SELECT 1 FROM rls_filtered)
$$;


--
-- Name: quote_wal2json(regclass); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.quote_wal2json(entity regclass) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
  SELECT
    realtime.wal2json_escape_identifier(nsp.nspname::text)
    || '.'
    || realtime.wal2json_escape_identifier(pc.relname::text)
  FROM pg_class pc
  JOIN pg_namespace nsp ON pc.relnamespace = nsp.oid
  WHERE pc.oid = entity
$$;


--
-- Name: send(jsonb, text, text, boolean); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean DEFAULT true) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  generated_id uuid;
  final_payload jsonb;
BEGIN
  BEGIN
    generated_id := gen_random_uuid();

    -- Check if payload has an 'id' key, if not, add the generated UUID
    IF payload ? 'id' THEN
      final_payload := payload;
    ELSE
      final_payload := jsonb_set(payload, '{id}', to_jsonb(generated_id));
    END IF;

    -- Set the topic configuration
    EXECUTE format('SET LOCAL realtime.topic TO %L', topic);

    INSERT INTO realtime.messages (id, payload, event, topic, private, extension)
    VALUES (generated_id, final_payload, event, topic, private, 'broadcast');
  EXCEPTION
    WHEN OTHERS THEN
      RAISE WARNING 'WarnSendingBroadcastMessage: %', SQLERRM;
  END;
END;
$$;


--
-- Name: send_binary(bytea, text, text, boolean); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.send_binary(payload bytea, event text, topic text, private boolean DEFAULT true) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  generated_id uuid;
BEGIN
  BEGIN
    generated_id := gen_random_uuid();

    EXECUTE format('SET LOCAL realtime.topic TO %L', topic);

    INSERT INTO realtime.messages (id, binary_payload, event, topic, private, extension)
    VALUES (generated_id, payload, event, topic, private, 'broadcast');
  EXCEPTION
    WHEN OTHERS THEN
      RAISE WARNING 'WarnSendingBroadcastMessage: %', SQLERRM;
  END;
END;
$$;


--
-- Name: settled_changes(name, integer, text[]); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.settled_changes(slot_name name, max_changes integer, VARIADIC opts text[]) RETURNS TABLE(lsn pg_lsn, xid xid, data text)
    LANGUAGE plpgsql
    AS $$
declare
  upto pg_lsn;
  total bigint;
  xids xid[];
  starts bigint[];
  snapshot pg_snapshot;
  running_xids xid[];
  xmax_age int;
  cut bigint;
begin
  -- Each statement in a volatile function takes its own snapshot, which is what lets the
  -- check below see a writer that was still in flight when the peek ran. Under REPEATABLE
  -- READ the snapshot never advances, so a deferred change would never be released.
  if current_setting('transaction_isolation') <> 'read committed' then
    raise exception 'realtime.settled_changes requires READ COMMITTED';
  end if;

  -- The peek and the read below cover the same WAL, so the read cannot reach a commit the
  -- check never saw.
  upto := pg_current_wal_flush_lsn();

  -- One entry per transaction, in commit order: its xid and the position of its first
  -- change. The peek uses the caller's own options, so max_changes counts exactly what the
  -- read counts. A non-transactional logical message is emitted as soon as it is decoded,
  -- tagged with the xid of whatever transaction wrote it, so it does not mark where that
  -- transaction starts.
  select coalesce(sum(g.n), 0),
         array_agg(g.x order by g.first) filter (where g.first is not null),
         array_agg(g.first order by g.first) filter (where g.first is not null)
    into total, xids, starts
    from (
      select p.xid as x, count(*) as n,
             min(p.ord) filter (where not case
               when starts_with(p.data, '{"action":"M"') then (p.data::jsonb->>'transactional')::boolean is false
               else false
             end) as first
      from pg_logical_slot_peek_changes(slot_name, upto, max_changes, variadic opts)
           with ordinality as p(lsn, xid, data, ord)
      group by p.xid
    ) g;

  -- Nothing for the caller, but the slot still has to move past what the peek covered.
  if total = 0 then
    perform pg_replication_slot_advance(slot_name, upto);
    return;
  end if;

  if xids is not null then
    -- Taken after the peek is materialized, so a writer that was still in flight during
    -- decoding is guaranteed to show up here.
    snapshot := pg_current_snapshot();

    -- A commit record reaches the WAL before the writer leaves the proc array, so a change
    -- can be decoded while its row is invisible. apply_rls would resolve a policy against a
    -- row it cannot see and authorize it for nobody, while the read consumed it regardless.
    --
    -- xip lists transactions running when the snapshot was taken. It does not cover a writer
    -- whose xid sits at or beyond xmax, which never appears there, so the horizon is checked
    -- too. age() counts backwards from the current xid and so compares correctly across
    -- wraparound.
    select coalesce(array_agg(running.x::xid), array[]::xid[])
      into running_xids
      from pg_snapshot_xip(snapshot) running(x);
    xmax_age := age(pg_snapshot_xmax(snapshot)::xid);

    select min(u.s) into cut
      from unnest(xids, starts) as u(x, s)
      where u.x = any(running_xids) or age(u.x) <= xmax_age;
  end if;

  -- The read stops right after the commit that brings its count to upto_nchanges, so the
  -- count of changes in front of the first unsettled transaction stops it just before that
  -- transaction.
  if cut is null then
    return query
      select p.* from pg_logical_slot_get_changes(slot_name, upto, max_changes, variadic opts) p;
  elsif cut > 1 then
    return query
      select p.* from pg_logical_slot_get_changes(slot_name, upto, (cut - 1)::int, variadic opts) p;
  end if;
end;
$$;


--
-- Name: subscription_check_filters(); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.subscription_check_filters() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
declare
    col_names text[] = coalesce(
            array_agg(a.attname order by a.attnum),
            '{}'::text[]
        )
        from
            pg_catalog.pg_attribute a
        where
            a.attrelid = new.entity
            and a.attnum > 0
            and not a.attisdropped
            and pg_catalog.has_column_privilege(
                (new.claims ->> 'role'),
                a.attrelid,
                a.attnum,
                'SELECT'
            );
    filter realtime.user_defined_filter;
    col_type regtype;
    in_val jsonb;
    selected_col text;
begin
    for filter in select * from unnest(new.filters) loop
        if not filter.column_name = any(col_names) then
            raise exception 'invalid column for filter %', filter.column_name;
        end if;

        col_type = (
            select atttypid::regtype
            from pg_catalog.pg_attribute
            where attrelid = new.entity
                  and attname = filter.column_name
        );
        if col_type is null then
            raise exception 'failed to lookup type for column %', filter.column_name;
        end if;

        if filter.op = 'in'::realtime.equality_op then
            in_val = realtime.cast(filter.value, (col_type::text || '[]')::regtype);
            if coalesce(jsonb_array_length(in_val), 0) > 100 then
                raise exception 'too many values for `in` filter. Maximum 100';
            end if;
        elsif filter.op = 'is'::realtime.equality_op then
            -- `is` requires a keyword RHS rather than a typed literal
            if filter.value not in ('null', 'true', 'false', 'unknown') then
                raise exception 'invalid value for is filter: must be null, true, false, or unknown';
            end if;
            -- IS NULL works for any type, but IS TRUE/FALSE/UNKNOWN require a boolean
            -- operand. Reject the non-null keywords on non-boolean columns here so they
            -- don't abort apply_rls at WAL time.
            if filter.value <> 'null' and col_type <> 'boolean'::regtype then
                raise exception 'is % filter requires a boolean column, got %', filter.value, col_type::text;
            end if;
        elsif filter.op in ('like'::realtime.equality_op, 'ilike'::realtime.equality_op) then
            -- like/ilike apply the text pattern operator (~~); reject column types that
            -- have no such operator instead of failing at WAL time
            if not exists (
                select 1 from pg_catalog.pg_operator
                where oprname = '~~' and oprleft = col_type
            ) then
                raise exception 'operator % requires a text-compatible column type, got %', filter.op::text, col_type::text;
            end if;
        elsif filter.op in ('match'::realtime.equality_op, 'imatch'::realtime.equality_op) then
            -- match/imatch apply the regex operators ~ / ~*; reject column types that have
            -- no such operator (e.g. integer) instead of failing at WAL time, mirroring the
            -- like/ilike guard above.
            if not exists (
                select 1 from pg_catalog.pg_operator
                where oprname = case when filter.op = 'imatch'::realtime.equality_op then '~*' else '~' end
                  and oprleft = col_type
                  and oprright = col_type
                  and oprresult = 'boolean'::regtype
            ) then
                raise exception 'operator % requires a text-compatible column type, got %', filter.op::text, col_type::text;
            end if;
            -- validate the regex eagerly so a bad pattern is rejected here, not inside
            -- apply_rls where it would abort the WAL stream for the entity
            begin
                perform '' ~ filter.value;
            exception when others then
                raise exception 'invalid regular expression for % filter: %', filter.op::text, sqlerrm;
            end;
        else
            -- eq/neq/lt/lte/gt/gte: value must be coercable to the type
            perform realtime.cast(filter.value, col_type);
        end if;
    end loop;

    if new.selected_columns is not null then
        for selected_col in select * from unnest(new.selected_columns) loop
            if not selected_col = any(col_names) then
                raise exception 'invalid column for select %', selected_col;
            end if;
        end loop;
    end if;

    -- Apply consistent order to filters so the unique constraint can't be tricked by a
    -- different filter order. negate is part of the sort key.
    new.filters = coalesce(
        array_agg(f order by f.column_name, f.op, f.value, f.negate),
        '{}'
    ) from unnest(new.filters) f;

    -- Normalize selected_columns order so ARRAY['a','b'] and ARRAY['b','a'] are treated
    -- as the same subscription group in apply_rls. Preserve an empty array as '{}'
    -- ("primary keys only") so it stays distinct from NULL ("all columns"); array_agg
    -- over an empty set would otherwise collapse '{}' back to NULL.
    if new.selected_columns is not null then
        new.selected_columns = coalesce(
            (
                select array_agg(c order by c)
                from unnest(new.selected_columns) c
            ),
            '{}'::text[]
        );
    end if;

    return new;
end;
$$;


--
-- Name: to_regrole(text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.to_regrole(role_name text) RETURNS regrole
    LANGUAGE sql IMMUTABLE
    AS $$ select role_name::regrole $$;


--
-- Name: topic(); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.topic() RETURNS text
    LANGUAGE sql STABLE
    AS $$
select nullif(current_setting('realtime.topic', true), '')::text;
$$;


--
-- Name: wal2json_escape_identifier(text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.wal2json_escape_identifier(name text) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
  -- Prefix `\`, `,`, `.`, and any whitespace with `\`
  SELECT regexp_replace(name, '([\\,.[:space:]])', '\\\1', 'g')
$$;


--
-- Name: allow_any_operation(text[]); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.allow_any_operation(expected_operations text[]) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
  WITH current_operation AS (
    SELECT storage.operation() AS raw_operation
  ),
  normalized AS (
    SELECT CASE
      WHEN raw_operation LIKE 'storage.%' THEN substr(raw_operation, 9)
      ELSE raw_operation
    END AS current_operation
    FROM current_operation
  )
  SELECT EXISTS (
    SELECT 1
    FROM normalized n
    CROSS JOIN LATERAL unnest(expected_operations) AS expected_operation
    WHERE expected_operation IS NOT NULL
      AND expected_operation <> ''
      AND n.current_operation = CASE
        WHEN expected_operation LIKE 'storage.%' THEN substr(expected_operation, 9)
        ELSE expected_operation
      END
  );
$$;


--
-- Name: allow_only_operation(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.allow_only_operation(expected_operation text) RETURNS boolean
    LANGUAGE sql STABLE
    AS $$
  WITH current_operation AS (
    SELECT storage.operation() AS raw_operation
  ),
  normalized AS (
    SELECT
      CASE
        WHEN raw_operation LIKE 'storage.%' THEN substr(raw_operation, 9)
        ELSE raw_operation
      END AS current_operation,
      CASE
        WHEN expected_operation LIKE 'storage.%' THEN substr(expected_operation, 9)
        ELSE expected_operation
      END AS requested_operation
    FROM current_operation
  )
  SELECT CASE
    WHEN requested_operation IS NULL OR requested_operation = '' THEN FALSE
    ELSE COALESCE(current_operation = requested_operation, FALSE)
  END
  FROM normalized;
$$;


--
-- Name: can_insert_object(text, text, uuid, jsonb); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.can_insert_object(bucketid text, name text, owner uuid, metadata jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO "storage"."objects" ("bucket_id", "name", "owner", "metadata") VALUES (bucketid, name, owner, metadata);
  -- hack to rollback the successful insert
  RAISE sqlstate 'PT200' using
  message = 'ROLLBACK',
  detail = 'rollback successful insert';
END
$$;


--
-- Name: enforce_bucket_lifecycle_service_role(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.enforce_bucket_lifecycle_service_role() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
BEGIN
  IF current_user::text IS DISTINCT FROM TG_ARGV[0]
     AND (
       OLD.lifecycle_configuration IS DISTINCT FROM NEW.lifecycle_configuration
       OR OLD.lifecycle_configuration_generation IS DISTINCT FROM NEW.lifecycle_configuration_generation
     ) THEN
    -- AFTER runs only after caller RLS has accepted the proposed row. The API
    -- recognizes this specific error after rolling back its permission probe;
    -- direct non-service writes still fail and cannot persist the change.
    RAISE EXCEPTION 'bucket control columns may only be changed by the configured storage service role'
      USING ERRCODE = 'PST01',
            SCHEMA = TG_TABLE_SCHEMA,
            TABLE = TG_TABLE_NAME,
            CONSTRAINT = TG_NAME;
  END IF;

  RETURN NULL;
END;
$$;


--
-- Name: enforce_bucket_name_length(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.enforce_bucket_name_length() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    if length(new.name) > 100 then
        raise exception 'bucket name "%" is too long (% characters). Max is 100.', new.name, length(new.name);
    end if;
    return new;
end;
$$;


--
-- Name: extension(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.extension(name text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    _parts text[];
    _filename text;
BEGIN
    -- Split on "/" to get path segments
    SELECT string_to_array(name, '/') INTO _parts;
    -- Get the last path segment (the actual filename)
    SELECT _parts[array_length(_parts, 1)] INTO _filename;
    -- Extract extension: reverse, split on '.', then reverse again
    RETURN reverse(split_part(reverse(_filename), '.', 1));
END
$$;


--
-- Name: filename(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.filename(name text) RETURNS text
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    _parts text[];
BEGIN
    SELECT string_to_array(name, '/') INTO _parts;
    RETURN _parts[array_length(_parts, 1)];
END
$$;


--
-- Name: foldername(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.foldername(name text) RETURNS text[]
    LANGUAGE plpgsql IMMUTABLE
    AS $$
DECLARE
    _parts text[];
BEGIN
    -- Split on "/" to get path segments
    SELECT string_to_array(name, '/') INTO _parts;
    -- Return everything except the last segment
    RETURN _parts[1 : array_length(_parts,1) - 1];
END
$$;


--
-- Name: get_common_prefix(text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_common_prefix(p_key text, p_prefix text, p_delimiter text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
SELECT CASE
    WHEN p_delimiter <> ''
         AND position(p_delimiter IN substring(p_key FROM length(p_prefix) + 1)) > 0
    THEN left(
        p_key,
        length(p_prefix)
            + position(p_delimiter IN substring(p_key FROM length(p_prefix) + 1))
            + length(p_delimiter) - 1
    )
    ELSE NULL
END;
$$;


--
-- Name: get_size_by_bucket(text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_size_by_bucket(noncurrent_versions text DEFAULT 'include'::text, delete_markers text DEFAULT 'include'::text) RETURNS TABLE(size bigint, bucket_id text)
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    -- COALESCE first: NULL NOT IN (...) evaluates to NULL (not TRUE), so a
    -- bare NOT IN check silently leaves an explicit NULL argument unreset.
    noncurrent_versions := COALESCE(noncurrent_versions, 'include');
    delete_markers := COALESCE(delete_markers, 'include');
    IF noncurrent_versions NOT IN ('exclude', 'only', 'include') THEN
        noncurrent_versions := 'include';
    END IF;
    IF delete_markers NOT IN ('exclude', 'only', 'include') THEN
        delete_markers := 'include';
    END IF;

    return query
        select sum((metadata->>'size')::bigint)::bigint as size, obj.bucket_id
        from "storage".objects as obj
        where (noncurrent_versions != 'exclude' OR obj.archived_at IS NULL)
          and (noncurrent_versions != 'only' OR obj.archived_at IS NOT NULL)
          and (delete_markers != 'exclude' OR NOT obj.is_delete_marker)
          and (delete_markers != 'only' OR obj.is_delete_marker)
        group by obj.bucket_id;
END
$$;


--
-- Name: list_multipart_uploads_with_delimiter(text, text, text, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.list_multipart_uploads_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, next_key_token text DEFAULT ''::text, next_upload_token text DEFAULT ''::text, raw_prefix_param text DEFAULT NULL::text) RETURNS TABLE(key text, id text, created_at timestamp with time zone)
    LANGUAGE sql STABLE
    AS $_$
WITH candidates AS (
    SELECT
        upload.key AS object_key,
        CASE
            WHEN position($3 IN substring(upload.key FROM length(coalesce($7, $2)) + 1)) > 0
            THEN left(
                upload.key,
                length(coalesce($7, $2))
                    + position($3 IN substring(upload.key FROM length(coalesce($7, $2)) + 1))
                    + length($3) - 1
            )
            ELSE upload.key
        END AS result_key,
        upload.id,
        upload.created_at,
        position($3 IN substring(upload.key FROM length(coalesce($7, $2)) + 1)) > 0 AS is_common_prefix
    FROM storage.s3_multipart_uploads AS upload
    WHERE upload.bucket_id = $1
      AND upload.key COLLATE "C" LIKE $2 || '%'
), filtered AS (
    SELECT candidate.*
    FROM candidates AS candidate
    WHERE $5 = ''
       OR candidate.result_key COLLATE "C" > $5
       OR (
           candidate.result_key COLLATE "C" = $5
           AND NOT candidate.is_common_prefix
           AND $6 <> ''
           -- A completed or aborted marker repeats the remaining same-key uploads.
           AND COALESCE(
               (candidate.created_at, candidate.id COLLATE "C") > (
                   SELECT marker.created_at, marker.id COLLATE "C"
                   FROM storage.s3_multipart_uploads AS marker
                   WHERE marker.bucket_id = $1
                     AND marker.key COLLATE "C" = $5
                     AND marker.id = $6
               ),
               TRUE
           )
       )
), ranked AS (
    SELECT
        filtered.*,
        row_number() OVER (
            PARTITION BY filtered.result_key COLLATE "C"
            ORDER BY filtered.created_at, filtered.id COLLATE "C"
        ) AS prefix_rank
    FROM filtered
)
SELECT ranked.result_key, ranked.id, ranked.created_at
FROM ranked
WHERE NOT ranked.is_common_prefix OR ranked.prefix_rank = 1
ORDER BY ranked.result_key COLLATE "C", ranked.created_at, ranked.id COLLATE "C"
LIMIT $4;
$_$;


--
-- Name: list_objects_with_delimiter(text, text, text, integer, text, text, text, text, text, timestamp with time zone, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.list_objects_with_delimiter(_bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, start_after text DEFAULT ''::text, next_token text DEFAULT ''::text, sort_order text DEFAULT 'asc'::text, noncurrent_versions text DEFAULT 'exclude'::text, delete_markers text DEFAULT 'exclude'::text, next_token_archived_at timestamp with time zone DEFAULT NULL::timestamp with time zone, next_token_version text DEFAULT ''::text) RETURNS TABLE(name text, id uuid, metadata jsonb, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, version text, archived_at timestamp with time zone, is_delete_marker boolean, is_versioned boolean)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    v_peek_name TEXT;
    v_current RECORD;
    v_common_prefix TEXT;

    -- Configuration
    v_is_asc BOOLEAN;
    v_prefix TEXT;
    v_start TEXT;
    v_start_relative TEXT;
    v_upper_bound TEXT;
    v_file_batch_size INT;
    v_version_filter TEXT;

    -- true when noncurrent_versions can return >1 row per name; keeps them
    -- ordered most-recent-first and lets pagination resume mid-key
    v_multi_row BOOLEAN;
    v_name_order TEXT;
    v_exact_range_predicate TEXT;
    v_strict_range_predicate TEXT;
    v_inclusive_range_predicate TEXT;

    -- Seek state for the current name. archived_at is normalized to JavaScript's
    -- millisecond precision and version breaks ties within the same millisecond.
    -- Current rows use 'infinity'; NULL means no tiebreak has been established.
    v_next_seek TEXT;
    v_next_seek_at TIMESTAMPTZ;
    v_next_seek_version TEXT;
    v_next_seek_strict BOOLEAN := false;
    v_cursor_is_folder BOOLEAN;
    v_count INT := 0;
    v_previous_seek TEXT;
    v_previous_seek_at TIMESTAMPTZ;
    v_previous_seek_version TEXT;
    v_previous_count INT;

    -- Dynamic SQL for batch query only
    v_batch_query TEXT;
    v_batch_query_strict TEXT;
    v_delete_marker_peek_query TEXT;
    v_delete_marker_peek_query_strict TEXT;

BEGIN
    -- ========================================================================
    -- INITIALIZATION
    -- ========================================================================
    v_is_asc := lower(coalesce(sort_order, 'asc')) = 'asc';
    v_prefix := coalesce(prefix_param, '');
    v_start := CASE WHEN coalesce(next_token, '') <> '' THEN next_token ELSE coalesce(start_after, '') END;
    v_file_batch_size := LEAST(GREATEST(max_keys * 2, 100), 1000);
    v_next_seek_at := NULL;
    v_next_seek_version := '';

    -- COALESCE first: NULL NOT IN (...) evaluates to NULL (not TRUE), so a
    -- bare NOT IN check silently leaves an explicit NULL argument unreset.
    noncurrent_versions := COALESCE(noncurrent_versions, 'exclude');
    delete_markers := COALESCE(delete_markers, 'exclude');
    IF noncurrent_versions NOT IN ('exclude', 'only', 'include') THEN
        noncurrent_versions := 'exclude';
    END IF;
    IF delete_markers NOT IN ('exclude', 'only', 'include') THEN
        delete_markers := 'exclude';
    END IF;

    v_multi_row := noncurrent_versions IN ('only', 'include');
    v_name_order := CASE WHEN v_is_asc THEN 'ASC' ELSE 'DESC' END;

    v_version_filter := '';
    IF noncurrent_versions = 'exclude' THEN
        v_version_filter := v_version_filter || ' AND o.archived_at IS NULL';
    ELSIF noncurrent_versions = 'only' THEN
        v_version_filter := v_version_filter || ' AND o.archived_at IS NOT NULL';
    END IF;
    IF delete_markers = 'exclude' THEN
        v_version_filter := v_version_filter || ' AND NOT o.is_delete_marker';
    ELSIF delete_markers = 'only' THEN
        v_version_filter := v_version_filter || ' AND o.is_delete_marker';
    END IF;

    -- Calculate upper bound for prefix filtering (bytewise, using COLLATE "C")
    IF v_prefix = '' THEN
        v_upper_bound := NULL;
    ELSE
        v_upper_bound := left(v_prefix, -1) || chr(ascii(right(v_prefix, 1)) + 1);
    END IF;

    -- Keep caller-provided cursors inside the requested prefix range.
    IF v_start <> '' AND v_upper_bound IS NOT NULL THEN
        IF v_is_asc THEN
            IF v_start COLLATE "C" < v_prefix COLLATE "C" THEN
                v_start := '';
            ELSIF v_start COLLATE "C" >= v_upper_bound COLLATE "C" THEN
                RETURN;
            END IF;
        ELSE
            IF v_start COLLATE "C" < v_prefix COLLATE "C" THEN
                RETURN;
            ELSIF v_start COLLATE "C" >= v_upper_bound COLLATE "C" THEN
                v_start := '';
            END IF;
        END IF;
    END IF;

    v_start_relative := substring(v_start FROM length(v_prefix) + 1);

    -- Direction affects only the indexed name range and its ordering. Cursor
    -- state transitions and within-key version ordering stay shared.
    IF v_is_asc THEN
        v_exact_range_predicate := 'TRUE';
        v_strict_range_predicate := 'o.name COLLATE "C" > $2';
        v_inclusive_range_predicate := 'o.name COLLATE "C" >= $2';
        IF v_upper_bound IS NOT NULL THEN
            v_exact_range_predicate := 'o.name COLLATE "C" < $3';
            v_strict_range_predicate := v_strict_range_predicate || ' AND o.name COLLATE "C" < $3';
            v_inclusive_range_predicate := v_inclusive_range_predicate || ' AND o.name COLLATE "C" < $3';
        END IF;
    ELSE
        v_exact_range_predicate := 'TRUE';
        v_strict_range_predicate := 'o.name COLLATE "C" < $2';
        v_inclusive_range_predicate := 'o.name COLLATE "C" < $2';
        IF v_prefix <> '' THEN
            v_exact_range_predicate := 'o.name COLLATE "C" >= $3';
            v_strict_range_predicate := v_strict_range_predicate || ' AND o.name COLLATE "C" >= $3';
            v_inclusive_range_predicate := v_inclusive_range_predicate || ' AND o.name COLLATE "C" >= $3';
        END IF;
    END IF;

    -- Build batch query (dynamic SQL - called infrequently, amortized over many rows)
    -- The multi-row order matches the externally serialized cursor exactly:
    -- archived_at at millisecond precision, then version as the final tiebreak.
    --
    -- When v_multi_row, the seek is a keyset tuple comparison ("name > $2 OR
    -- (name = $2 AND tiebreak)") - Postgres won't split that OR into indexable
    -- form (confirmed even with fully literal values), so as one WHERE clause
    -- it forces a full bucket scan filtered row-by-row. Splitting it into two
    -- independently-indexable branches (exact name match with the tiebreak
    -- filter, vs. strictly-past names) combined with UNION ALL lets each
    -- branch keep name as a real index condition; the outer ORDER BY/LIMIT
    -- re-merges them into the same page the single query used to produce.
    IF v_multi_row THEN
        v_batch_query := format(
            $sql$
            SELECT *
            FROM (
                (
                    SELECT o.name, o.id, o.updated_at, o.created_at,
                           o.last_accessed_at, o.metadata, o.version,
                           o.archived_at, o.is_delete_marker, o.is_versioned
                    FROM storage.objects o
                    WHERE o.bucket_id = $1
                      AND o.name COLLATE "C" = $2
                      AND %s
                      AND NOT $7::boolean
                      AND (
                          $5::timestamptz IS NULL
                          OR COALESCE(date_trunc('milliseconds', o.archived_at), 'infinity'::timestamptz) < $5
                          OR (
                              COALESCE(date_trunc('milliseconds', o.archived_at), 'infinity'::timestamptz) = $5
                              AND COALESCE(o.version, '') > $6
                          )
                      )
                      %s
                    ORDER BY
                        COALESCE(date_trunc('milliseconds', o.archived_at), 'infinity'::timestamptz) DESC,
                        COALESCE(o.version, '') ASC
                    LIMIT $4
                )
                UNION ALL
                (
                    SELECT o.name, o.id, o.updated_at, o.created_at,
                           o.last_accessed_at, o.metadata, o.version,
                           o.archived_at, o.is_delete_marker, o.is_versioned
                    FROM storage.objects o
                    WHERE o.bucket_id = $1
                      AND %s
                      %s
                    ORDER BY
                        o.name COLLATE "C" %s,
                        COALESCE(date_trunc('milliseconds', o.archived_at), 'infinity'::timestamptz) DESC,
                        COALESCE(o.version, '') ASC
                    LIMIT $4
                )
            ) sub
            ORDER BY
                sub.name COLLATE "C" %s,
                COALESCE(date_trunc('milliseconds', sub.archived_at), 'infinity'::timestamptz) DESC,
                COALESCE(sub.version, '') ASC
            LIMIT $4
            $sql$,
            v_exact_range_predicate,
            v_version_filter,
            v_strict_range_predicate,
            v_version_filter,
            v_name_order,
            v_name_order
        );
    ELSE
        v_batch_query := format(
            $sql$
            SELECT o.name, o.id, o.updated_at, o.created_at,
                   o.last_accessed_at, o.metadata, o.version,
                   o.archived_at, o.is_delete_marker, o.is_versioned
            FROM storage.objects o
            WHERE o.bucket_id = $1
              AND %s
              %s
            ORDER BY o.name COLLATE "C" %s, o.archived_at DESC
            LIMIT $4
            $sql$,
            v_inclusive_range_predicate,
            v_version_filter,
            v_name_order
        );

        -- Strict counterpart of the query above: used once the single-row
        -- ASC batch advance (below) has left v_next_seek pointing at the
        -- last row already emitted, so an inclusive predicate would
        -- re-match it forever. Only single-row mode ever sets strict mode,
        -- so this variant is never needed when v_multi_row.
        v_batch_query_strict := format(
            $sql$
            SELECT o.name, o.id, o.updated_at, o.created_at,
                   o.last_accessed_at, o.metadata, o.version,
                   o.archived_at, o.is_delete_marker, o.is_versioned
            FROM storage.objects o
            WHERE o.bucket_id = $1
              AND %s
              %s
            ORDER BY o.name COLLATE "C" %s, o.archived_at DESC
            LIMIT $4
            $sql$,
            v_strict_range_predicate,
            v_version_filter,
            v_name_order
        );
    END IF;

    -- The static peek predicates cannot use the partial delete-marker index
    -- once PL/pgSQL switches to a generic plan because whether
    -- is_delete_marker is required remains parameter-dependent. Reuse the
    -- already-specialized batch query with a one-row limit for this sparse
    -- filter so the plan sees a literal `o.is_delete_marker` predicate.
    IF delete_markers = 'only' THEN
        v_delete_marker_peek_query :=
            'SELECT marker_page.name FROM (' || v_batch_query || ') marker_page LIMIT 1';
        IF NOT v_multi_row THEN
            v_delete_marker_peek_query_strict :=
                'SELECT marker_page.name FROM (' || v_batch_query_strict || ') marker_page LIMIT 1';
        END IF;
    END IF;

    -- ========================================================================
    -- SEEK INITIALIZATION: Determine starting position
    -- ========================================================================
    IF v_start = '' THEN
        IF v_is_asc THEN
            v_next_seek := v_prefix;
        ELSE
            -- DESC without cursor performs one specialized initial seek so
            -- partial current-version and delete-marker indexes remain available.
            EXECUTE format(
                'SELECT o.name FROM storage.objects o WHERE o.bucket_id = $1%s%s ORDER BY o.name COLLATE "C" DESC LIMIT 1',
                CASE WHEN v_upper_bound IS NOT NULL
                    THEN ' AND o.name COLLATE "C" >= $2 AND o.name COLLATE "C" < $3'
                    ELSE ''
                END,
                v_version_filter
            )
            INTO v_next_seek
            USING _bucket_id, v_prefix, v_upper_bound;

            IF v_next_seek IS NOT NULL THEN
                v_next_seek := v_next_seek || delimiter_param;
            ELSE
                RETURN;
            END IF;
        END IF;
    ELSE
        -- Folder continuation tokens retain their trailing delimiter. A
        -- delimiter-less startAfter is always a literal key boundary.
        v_cursor_is_folder := delimiter_param <> ''
            AND v_start_relative <> ''
            AND right(v_start_relative, length(delimiter_param)) = delimiter_param;

        IF v_cursor_is_folder THEN
            v_next_seek := CASE
                WHEN right(v_start, length(delimiter_param)) = delimiter_param
                    THEN v_start
                ELSE v_start || delimiter_param
            END;
            IF v_is_asc THEN
                v_next_seek := left(v_next_seek, -1)
                    || chr(ascii(right(v_next_seek, 1)) + 1);
            END IF;
            v_next_seek_strict := NOT v_is_asc;
        ELSE
            -- leaf object: when v_multi_row, stay on v_start with the
            -- caller-supplied tiebreak so a page boundary mid-key resumes
            -- that key's remaining rows instead of skipping them. Truncate
            -- to milliseconds like every other v_next_seek_at assignment -
            -- harmless today since object.ts's cursor always round-trips
            -- through JS Date first, but this shouldn't rely on that.
            IF v_multi_row THEN
                v_next_seek := v_start;
                v_next_seek_at := date_trunc('milliseconds', next_token_archived_at);
                v_next_seek_version := coalesce(next_token_version, '');
                v_next_seek_strict := coalesce(next_token, '') = '';
            ELSIF v_is_asc THEN
                v_next_seek := v_start;
                v_next_seek_strict := true;
            ELSE
                v_next_seek := v_start;
            END IF;
        END IF;
    END IF;

    -- ========================================================================
    -- MAIN LOOP: Hybrid peek-then-batch algorithm
    -- Uses STATIC SQL for peek (hot path) and DYNAMIC SQL for batch
    -- ========================================================================
    LOOP
        EXIT WHEN v_count >= max_keys;

        v_previous_seek := v_next_seek;
        v_previous_seek_at := v_next_seek_at;
        v_previous_seek_version := v_next_seek_version;
        v_previous_count := v_count;

        -- STEP 1: PEEK using STATIC SQL (plan cached, very fast)
        -- v_multi_row is branched here (rather than folded into the WHERE
        -- clause as a bound parameter) so each concrete query keeps an
        -- unconditional seek predicate - once PL/pgSQL switches to its
        -- cached generic plan (after 5 calls), a parameter-gated
        -- "(NOT v_multi_row AND name >= $x) OR (v_multi_row AND ...)"
        -- predicate stops the planner from using name as an index
        -- condition at all, degrading every subsequent peek to a full
        -- index scan filtered row-by-row instead of a bounded range scan.
        -- v_multi_row's seek predicate is a keyset tuple comparison
        -- ("name > x OR (name = x AND tiebreak)") - Postgres does not
        -- split this OR into indexable form even with fully literal
        -- values, so it falls back to a full scan filtered row-by-row.
        -- Splitting it into two independently-indexable branches (exact
        -- name match with the tiebreak filter, vs. strictly-past name)
        -- combined with UNION ALL lets each branch keep name as a real
        -- index condition; the outer ORDER BY/LIMIT picks whichever of
        -- the (at most 2) rows sorts first.
        IF delete_markers = 'only' THEN
            EXECUTE CASE WHEN v_next_seek_strict AND NOT v_multi_row
                THEN v_delete_marker_peek_query_strict
                ELSE v_delete_marker_peek_query
            END
                INTO v_peek_name
                USING _bucket_id, v_next_seek,
                    CASE WHEN v_is_asc THEN COALESCE(v_upper_bound, v_prefix) ELSE v_prefix END,
                    1, v_next_seek_at, v_next_seek_version, v_next_seek_strict;
        ELSIF v_multi_row THEN
            IF v_is_asc THEN
                IF v_upper_bound IS NOT NULL THEN
                    SELECT sub.name INTO v_peek_name FROM (
                        (SELECT o.name FROM storage.objects o
                         WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" = v_next_seek
                           AND o.name COLLATE "C" < v_upper_bound
                           AND NOT v_next_seek_strict
                           AND (v_next_seek_at IS NULL
                                OR COALESCE(date_trunc('milliseconds', o.archived_at), 'infinity'::timestamptz) < v_next_seek_at
                                OR (COALESCE(date_trunc('milliseconds', o.archived_at), 'infinity'::timestamptz) = v_next_seek_at
                                    AND COALESCE(o.version, '') > v_next_seek_version))
                           AND (noncurrent_versions != 'exclude' OR o.archived_at IS NULL)
                           AND (noncurrent_versions != 'only' OR o.archived_at IS NOT NULL)
                           AND (delete_markers != 'exclude' OR NOT o.is_delete_marker)
                           AND (delete_markers != 'only' OR o.is_delete_marker)
                         ORDER BY COALESCE(date_trunc('milliseconds', o.archived_at), 'infinity'::timestamptz) DESC, COALESCE(o.version, '') ASC LIMIT 1)
                        UNION ALL
                        (SELECT o.name FROM storage.objects o
                         WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" > v_next_seek AND o.name COLLATE "C" < v_upper_bound
                           AND (noncurrent_versions != 'exclude' OR o.archived_at IS NULL)
                           AND (noncurrent_versions != 'only' OR o.archived_at IS NOT NULL)
                           AND (delete_markers != 'exclude' OR NOT o.is_delete_marker)
                           AND (delete_markers != 'only' OR o.is_delete_marker)
                         ORDER BY o.name COLLATE "C" ASC LIMIT 1)
                    ) sub ORDER BY sub.name COLLATE "C" ASC LIMIT 1;
                ELSE
                    SELECT sub.name INTO v_peek_name FROM (
                        (SELECT o.name FROM storage.objects o
                         WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" = v_next_seek
                           AND NOT v_next_seek_strict
                           AND (v_next_seek_at IS NULL
                                OR COALESCE(date_trunc('milliseconds', o.archived_at), 'infinity'::timestamptz) < v_next_seek_at
                                OR (COALESCE(date_trunc('milliseconds', o.archived_at), 'infinity'::timestamptz) = v_next_seek_at
                                    AND COALESCE(o.version, '') > v_next_seek_version))
                           AND (noncurrent_versions != 'exclude' OR o.archived_at IS NULL)
                           AND (noncurrent_versions != 'only' OR o.archived_at IS NOT NULL)
                           AND (delete_markers != 'exclude' OR NOT o.is_delete_marker)
                           AND (delete_markers != 'only' OR o.is_delete_marker)
                         ORDER BY COALESCE(date_trunc('milliseconds', o.archived_at), 'infinity'::timestamptz) DESC, COALESCE(o.version, '') ASC LIMIT 1)
                        UNION ALL
                        (SELECT o.name FROM storage.objects o
                         WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" > v_next_seek
                           AND (noncurrent_versions != 'exclude' OR o.archived_at IS NULL)
                           AND (noncurrent_versions != 'only' OR o.archived_at IS NOT NULL)
                           AND (delete_markers != 'exclude' OR NOT o.is_delete_marker)
                           AND (delete_markers != 'only' OR o.is_delete_marker)
                         ORDER BY o.name COLLATE "C" ASC LIMIT 1)
                    ) sub ORDER BY sub.name COLLATE "C" ASC LIMIT 1;
                END IF;
            ELSE
                IF v_upper_bound IS NOT NULL THEN
                    SELECT sub.name INTO v_peek_name FROM (
                        (SELECT o.name FROM storage.objects o
                         WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" = v_next_seek
                           AND o.name COLLATE "C" >= v_prefix
                           AND NOT v_next_seek_strict
                           AND (v_next_seek_at IS NULL
                                OR COALESCE(date_trunc('milliseconds', o.archived_at), 'infinity'::timestamptz) < v_next_seek_at
                                OR (COALESCE(date_trunc('milliseconds', o.archived_at), 'infinity'::timestamptz) = v_next_seek_at
                                    AND COALESCE(o.version, '') > v_next_seek_version))
                           AND (noncurrent_versions != 'exclude' OR o.archived_at IS NULL)
                           AND (noncurrent_versions != 'only' OR o.archived_at IS NOT NULL)
                           AND (delete_markers != 'exclude' OR NOT o.is_delete_marker)
                           AND (delete_markers != 'only' OR o.is_delete_marker)
                         ORDER BY COALESCE(date_trunc('milliseconds', o.archived_at), 'infinity'::timestamptz) DESC, COALESCE(o.version, '') ASC LIMIT 1)
                        UNION ALL
                        (SELECT o.name FROM storage.objects o
                         WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek AND o.name COLLATE "C" >= v_prefix
                           AND (noncurrent_versions != 'exclude' OR o.archived_at IS NULL)
                           AND (noncurrent_versions != 'only' OR o.archived_at IS NOT NULL)
                           AND (delete_markers != 'exclude' OR NOT o.is_delete_marker)
                           AND (delete_markers != 'only' OR o.is_delete_marker)
                         ORDER BY o.name COLLATE "C" DESC LIMIT 1)
                    ) sub ORDER BY sub.name COLLATE "C" DESC LIMIT 1;
                ELSE
                    SELECT sub.name INTO v_peek_name FROM (
                        (SELECT o.name FROM storage.objects o
                         WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" = v_next_seek
                           AND NOT v_next_seek_strict
                           AND (v_next_seek_at IS NULL
                                OR COALESCE(date_trunc('milliseconds', o.archived_at), 'infinity'::timestamptz) < v_next_seek_at
                                OR (COALESCE(date_trunc('milliseconds', o.archived_at), 'infinity'::timestamptz) = v_next_seek_at
                                    AND COALESCE(o.version, '') > v_next_seek_version))
                           AND (noncurrent_versions != 'exclude' OR o.archived_at IS NULL)
                           AND (noncurrent_versions != 'only' OR o.archived_at IS NOT NULL)
                           AND (delete_markers != 'exclude' OR NOT o.is_delete_marker)
                           AND (delete_markers != 'only' OR o.is_delete_marker)
                         ORDER BY COALESCE(date_trunc('milliseconds', o.archived_at), 'infinity'::timestamptz) DESC, COALESCE(o.version, '') ASC LIMIT 1)
                        UNION ALL
                        (SELECT o.name FROM storage.objects o
                         WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek
                           AND (noncurrent_versions != 'exclude' OR o.archived_at IS NULL)
                           AND (noncurrent_versions != 'only' OR o.archived_at IS NOT NULL)
                           AND (delete_markers != 'exclude' OR NOT o.is_delete_marker)
                           AND (delete_markers != 'only' OR o.is_delete_marker)
                         ORDER BY o.name COLLATE "C" DESC LIMIT 1)
                    ) sub ORDER BY sub.name COLLATE "C" DESC LIMIT 1;
                END IF;
            END IF;
        ELSE
            -- Single-row mode is always noncurrent_versions='exclude'. Keep
            -- this predicate literal so generic plans use the current index.
            IF v_is_asc THEN
                IF v_next_seek_strict AND v_upper_bound IS NOT NULL THEN
                    SELECT o.name INTO v_peek_name FROM storage.objects o
                    WHERE o.bucket_id = _bucket_id
                      AND o.name COLLATE "C" > v_next_seek
                      AND o.name COLLATE "C" < v_upper_bound
                      AND o.archived_at IS NULL
                      AND (delete_markers != 'exclude' OR NOT o.is_delete_marker)
                      AND (delete_markers != 'only' OR o.is_delete_marker)
                    ORDER BY o.name COLLATE "C" ASC LIMIT 1;
                ELSIF v_next_seek_strict THEN
                    SELECT o.name INTO v_peek_name FROM storage.objects o
                    WHERE o.bucket_id = _bucket_id
                      AND o.name COLLATE "C" > v_next_seek
                      AND o.archived_at IS NULL
                      AND (delete_markers != 'exclude' OR NOT o.is_delete_marker)
                      AND (delete_markers != 'only' OR o.is_delete_marker)
                    ORDER BY o.name COLLATE "C" ASC LIMIT 1;
                ELSIF v_upper_bound IS NOT NULL THEN
                    SELECT o.name INTO v_peek_name FROM storage.objects o
                    WHERE o.bucket_id = _bucket_id
                      AND o.name COLLATE "C" >= v_next_seek
                      AND o.name COLLATE "C" < v_upper_bound
                      AND o.archived_at IS NULL
                      AND (delete_markers != 'exclude' OR NOT o.is_delete_marker)
                      AND (delete_markers != 'only' OR o.is_delete_marker)
                    ORDER BY o.name COLLATE "C" ASC LIMIT 1;
                ELSE
                    SELECT o.name INTO v_peek_name FROM storage.objects o
                    WHERE o.bucket_id = _bucket_id
                      AND o.name COLLATE "C" >= v_next_seek
                      AND o.archived_at IS NULL
                      AND (delete_markers != 'exclude' OR NOT o.is_delete_marker)
                      AND (delete_markers != 'only' OR o.is_delete_marker)
                    ORDER BY o.name COLLATE "C" ASC LIMIT 1;
                END IF;
            ELSE
                IF v_upper_bound IS NOT NULL THEN
                    SELECT o.name INTO v_peek_name FROM storage.objects o
                    WHERE o.bucket_id = _bucket_id
                      AND o.name COLLATE "C" < v_next_seek
                      AND o.name COLLATE "C" >= v_prefix
                      AND o.archived_at IS NULL
                      AND (delete_markers != 'exclude' OR NOT o.is_delete_marker)
                      AND (delete_markers != 'only' OR o.is_delete_marker)
                    ORDER BY o.name COLLATE "C" DESC LIMIT 1;
                ELSE
                    SELECT o.name INTO v_peek_name FROM storage.objects o
                    WHERE o.bucket_id = _bucket_id
                      AND o.name COLLATE "C" < v_next_seek
                      AND o.archived_at IS NULL
                      AND (delete_markers != 'exclude' OR NOT o.is_delete_marker)
                      AND (delete_markers != 'only' OR o.is_delete_marker)
                    ORDER BY o.name COLLATE "C" DESC LIMIT 1;
                END IF;
            END IF;
        END IF;

        EXIT WHEN v_peek_name IS NULL;

        -- STEP 2: Check if this is a FOLDER or FILE
        v_common_prefix := storage.get_common_prefix(v_peek_name, v_prefix, delimiter_param);

        IF v_common_prefix IS NOT NULL THEN
            -- FOLDER: Emit and skip to next folder (no heap access needed)
            name := v_common_prefix;
            id := NULL;
            updated_at := NULL;
            created_at := NULL;
            last_accessed_at := NULL;
            metadata := NULL;
            version := NULL;
            archived_at := NULL;
            is_delete_marker := NULL;
            is_versioned := NULL;
            RETURN NEXT;
            v_count := v_count + 1;

            -- Advance seek past the folder range
            IF v_is_asc THEN
                v_next_seek := left(v_common_prefix, -1)
                    || chr(ascii(right(v_common_prefix, 1)) + 1);
            ELSE
                v_next_seek := v_common_prefix;
            END IF;
            v_next_seek_at := NULL;
            v_next_seek_version := '';
            v_next_seek_strict := NOT v_is_asc;
        ELSE
            -- FILE: Batch fetch using DYNAMIC SQL (overhead amortized over many rows)
            -- For ASC: upper_bound is the exclusive upper limit (< condition)
            -- For DESC: prefix is the inclusive lower limit (>= condition)
            FOR v_current IN EXECUTE CASE WHEN v_next_seek_strict AND NOT v_multi_row THEN v_batch_query_strict ELSE v_batch_query END
                USING _bucket_id, v_next_seek,
                CASE WHEN v_is_asc THEN COALESCE(v_upper_bound, v_prefix) ELSE v_prefix END, v_file_batch_size, v_next_seek_at, v_next_seek_version,
                v_next_seek_strict
            LOOP
                v_common_prefix := storage.get_common_prefix(v_current.name, v_prefix, delimiter_param);

                IF v_common_prefix IS NOT NULL THEN
                    -- Hit a folder: exit batch, let peek handle it. Reset
                    -- strict mode too it may have been set by an earlier
                    -- row in this same batch (see the single-row ASC advance
                    -- below), and v_next_seek here is the folder-triggering
                    -- row's own name, which the next peek must find inclusively.
                    v_next_seek := CASE
                        WHEN v_is_asc THEN v_current.name
                        ELSE v_current.name || delimiter_param
                    END;
                    v_next_seek_at := NULL;
                    v_next_seek_version := '';
                    v_next_seek_strict := false;
                    EXIT;
                END IF;

                -- Emit file
                name := v_current.name;
                id := v_current.id;
                updated_at := v_current.updated_at;
                created_at := v_current.created_at;
                last_accessed_at := v_current.last_accessed_at;
                metadata := v_current.metadata;
                version := v_current.version;
                archived_at := v_current.archived_at;
                is_delete_marker := v_current.is_delete_marker;
                is_versioned := v_current.is_versioned;
                RETURN NEXT;
                v_count := v_count + 1;

                -- when v_multi_row, stay on this name and record its
                -- archived_at as the new tiebreak so remaining rows for the
                -- same key are picked up before moving to the next name
                IF v_multi_row THEN
                    v_next_seek := v_current.name;
                    v_next_seek_at := COALESCE(date_trunc('milliseconds', v_current.archived_at), 'infinity'::timestamptz);
                    v_next_seek_version := COALESCE(v_current.version, '');
                    v_next_seek_strict := false;
                ELSIF v_is_asc THEN
                    -- Appending the delimiter as a fake lexical successor
                    -- would skip a real key like `name || '!'` (or any
                    -- character sorting below the delimiter), which sorts
                    -- between `name` and `name || delimiter`. Track the real
                    -- name and mark the next comparison strict instead.
                    v_next_seek := v_current.name;
                    v_next_seek_strict := true;
                ELSE
                    v_next_seek := v_current.name;
                END IF;

                EXIT WHEN v_count >= max_keys;
            END LOOP;
        END IF;

        IF v_count = v_previous_count
           AND v_next_seek IS NOT DISTINCT FROM v_previous_seek
           AND v_next_seek_at IS NOT DISTINCT FROM v_previous_seek_at
           AND v_next_seek_version IS NOT DISTINCT FROM v_previous_seek_version THEN
            RAISE EXCEPTION 'storage.list_objects_with_delimiter made no progress at seek (%, %, %)',
                v_next_seek, v_next_seek_at, v_next_seek_version;
        END IF;
    END LOOP;
END;
$_$;


--
-- Name: operation(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.operation() RETURNS text
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    RETURN current_setting('storage.operation', true);
END;
$$;


--
-- Name: protect_bucket_control_columns(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.protect_bucket_control_columns() RETURNS trigger
    LANGUAGE plpgsql
    SET search_path TO 'pg_catalog'
    AS $$
DECLARE
  configuration_changed boolean;
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.lifecycle_configuration IS NOT NULL
       OR NEW.lifecycle_configuration_generation IS NOT NULL THEN
      IF NOT pg_has_role(current_user, TG_ARGV[0], 'MEMBER') THEN
        RAISE EXCEPTION 'only members of the configured storage service role may insert lifecycle policy state'
          USING ERRCODE = '42501',
                HINT = format(
                  'Insert with both lifecycle columns NULL and configure lifecycle through the Storage API afterward, or insert as a member of %I.',
                  TG_ARGV[0]
                );
      END IF;
    END IF;

    RETURN NEW;
  END IF;

  configuration_changed =
    OLD.lifecycle_configuration IS DISTINCT FROM NEW.lifecycle_configuration
    OR OLD.lifecycle_configuration_generation IS DISTINCT FROM NEW.lifecycle_configuration_generation;

  IF NOT configuration_changed THEN
    RETURN NEW;
  END IF;

  IF NEW.type IS DISTINCT FROM 'STANDARD' THEN
    RAISE EXCEPTION 'bucket versioning and lifecycle controls require a Standard bucket'
      USING ERRCODE = '0A000';
  END IF;

  IF NEW.lifecycle_configuration IS NULL
     AND NEW.lifecycle_configuration_generation IS NULL THEN
    RETURN NEW;
  END IF;

  IF NEW.lifecycle_configuration IS NULL
     OR NEW.lifecycle_configuration_generation IS NULL
     OR OLD.lifecycle_configuration IS NOT DISTINCT FROM NEW.lifecycle_configuration
     OR OLD.lifecycle_configuration_generation IS NOT DISTINCT FROM NEW.lifecycle_configuration_generation THEN
    RAISE EXCEPTION 'a changed lifecycle policy requires a new non-null generation'
      USING ERRCODE = '22023';
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: protect_delete(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.protect_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Check if storage.allow_delete_query is set to 'true'
    IF COALESCE(current_setting('storage.allow_delete_query', true), 'false') != 'true' THEN
        RAISE EXCEPTION 'Direct deletion from storage tables is not allowed. Use the Storage API instead.'
            USING HINT = 'This prevents accidental data loss from orphaned objects.',
                  ERRCODE = '42501';
    END IF;
    RETURN NULL;
END;
$$;


--
-- Name: search(text, text, integer, integer, integer, text, text, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search(prefix text, bucketname text, limits integer DEFAULT 100, levels integer DEFAULT 1, offsets integer DEFAULT 0, search text DEFAULT ''::text, sortcolumn text DEFAULT 'name'::text, sortorder text DEFAULT 'asc'::text, noncurrent_versions text DEFAULT 'exclude'::text, delete_markers text DEFAULT 'exclude'::text) RETURNS TABLE(name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb, version text, archived_at timestamp with time zone, is_delete_marker boolean, is_versioned boolean)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    v_peek_name TEXT;
    v_current RECORD;
    v_common_prefix TEXT;
    v_delimiter CONSTANT TEXT := '/';

    -- Configuration
    v_limit INT;
    v_prefix TEXT;
    v_prefix_lower TEXT;
    v_prefix_len INT;
    v_prefix_start INT;
    v_combined_levels INT;
    v_is_asc BOOLEAN;
    v_order_by TEXT;
    v_sort_order TEXT;
    v_upper_bound TEXT;
    v_file_batch_size INT;
    v_version_filter TEXT;
    v_multi_row BOOLEAN;

    -- Dynamic SQL for batch query only
    v_batch_query TEXT;
    v_delete_marker_peek_query TEXT;
    v_delete_marker_peek_query_strict TEXT;

    -- Seek state
    v_next_seek TEXT;
    v_next_seek_at TIMESTAMPTZ;
    v_next_seek_version TEXT;
    v_next_seek_strict BOOLEAN := false;
    v_count INT := 0;
    v_skipped INT := 0;
    v_previous_seek TEXT;
    v_previous_seek_at TIMESTAMPTZ;
    v_previous_seek_version TEXT;
    v_previous_count INT;
    v_previous_skipped INT;
BEGIN
    -- ========================================================================
    -- INITIALIZATION
    -- ========================================================================
    v_limit := LEAST(coalesce(limits, 100), 1500);
    v_prefix := coalesce(prefix, '') || coalesce(search, '');
    v_prefix_lower := lower(v_prefix);
    v_prefix_len := length(coalesce(prefix, ''));
    v_prefix_start := coalesce(array_length(string_to_array(coalesce(prefix, ''), v_delimiter), 1), 1);
    v_combined_levels := coalesce(array_length(string_to_array(v_prefix, v_delimiter), 1), 1);
    v_is_asc := lower(coalesce(sortorder, 'asc')) = 'asc';
    v_file_batch_size := LEAST(GREATEST(v_limit * 2, 100), 1000);
    v_next_seek_at := NULL;
    v_next_seek_version := '';

    -- COALESCE first: NULL NOT IN (...) evaluates to NULL (not TRUE), so a
    -- bare NOT IN check silently leaves an explicit NULL argument unreset.
    noncurrent_versions := COALESCE(noncurrent_versions, 'exclude');
    delete_markers := COALESCE(delete_markers, 'exclude');
    IF noncurrent_versions NOT IN ('exclude', 'only', 'include') THEN
        noncurrent_versions := 'exclude';
    END IF;
    IF delete_markers NOT IN ('exclude', 'only', 'include') THEN
        delete_markers := 'exclude';
    END IF;

    v_multi_row := noncurrent_versions IN ('only', 'include');

    v_version_filter := '';
    IF noncurrent_versions = 'exclude' THEN
        v_version_filter := v_version_filter || ' AND o.archived_at IS NULL';
    ELSIF noncurrent_versions = 'only' THEN
        v_version_filter := v_version_filter || ' AND o.archived_at IS NOT NULL';
    END IF;
    IF delete_markers = 'exclude' THEN
        v_version_filter := v_version_filter || ' AND NOT o.is_delete_marker';
    ELSIF delete_markers = 'only' THEN
        v_version_filter := v_version_filter || ' AND o.is_delete_marker';
    END IF;

    -- Validate sort column
    CASE lower(coalesce(sortcolumn, 'name'))
        WHEN 'name' THEN v_order_by := 'name';
        WHEN 'updated_at' THEN v_order_by := 'updated_at';
        WHEN 'created_at' THEN v_order_by := 'created_at';
        WHEN 'last_accessed_at' THEN v_order_by := 'last_accessed_at';
        ELSE v_order_by := 'name';
    END CASE;

    v_sort_order := CASE WHEN v_is_asc THEN 'asc' ELSE 'desc' END;

    -- ========================================================================
    -- NON-NAME SORTING: Use path_tokens approach
    -- ========================================================================
    IF v_order_by != 'name' THEN
        RETURN QUERY EXECUTE format(
            $sql$
            WITH folders AS (
                SELECT array_to_string(path_tokens[$1:$2], '/') AS folder
                FROM storage.objects
                WHERE objects.name ILIKE $3 || '%%'
                  AND bucket_id = $4
                  AND array_length(objects.path_tokens, 1) <> $2
                  AND ($7 != 'exclude' OR objects.archived_at IS NULL)
                  AND ($7 != 'only' OR objects.archived_at IS NOT NULL)
                  AND ($8 != 'exclude' OR NOT objects.is_delete_marker)
                  AND ($8 != 'only' OR objects.is_delete_marker)
                GROUP BY folder
                ORDER BY folder %s
            )
            (SELECT folder AS "name",
                   NULL::uuid AS id,
                   NULL::timestamptz AS updated_at,
                   NULL::timestamptz AS created_at,
                   NULL::timestamptz AS last_accessed_at,
                   NULL::jsonb AS metadata,
                   NULL::text AS version,
                   NULL::timestamptz AS archived_at,
                   NULL::boolean AS is_delete_marker,
                   NULL::boolean AS is_versioned FROM folders)
            UNION ALL
            (SELECT array_to_string(path_tokens[$1:$2], '/') AS "name",
                   id, updated_at, created_at, last_accessed_at, metadata,
                   version, archived_at, is_delete_marker, is_versioned
             FROM storage.objects
             WHERE objects.name ILIKE $3 || '%%'
               AND bucket_id = $4
               AND array_length(objects.path_tokens, 1) = $2
               AND ($7 != 'exclude' OR objects.archived_at IS NULL)
               AND ($7 != 'only' OR objects.archived_at IS NOT NULL)
               AND ($8 != 'exclude' OR NOT objects.is_delete_marker)
               AND ($8 != 'only' OR objects.is_delete_marker)
             -- name, then version, as tiebreaks so two versions of the same
             -- key tying on the sort column still sort deterministically
             ORDER BY %I %s, name COLLATE "C" %s, COALESCE(version, '') %s)
            LIMIT $5 OFFSET $6
            $sql$, v_sort_order, v_order_by, v_sort_order, v_sort_order, v_sort_order
        ) USING v_prefix_start, v_combined_levels, v_prefix, bucketname, v_limit, offsets, noncurrent_versions, delete_markers;
        RETURN;
    END IF;

    -- ========================================================================
    -- NAME SORTING: Hybrid skip-scan with batch optimization
    -- ========================================================================

    -- Calculate upper bound for prefix filtering
    IF v_prefix_lower = '' THEN
        v_upper_bound := NULL;
    ELSIF right(v_prefix_lower, 1) = v_delimiter THEN
        v_upper_bound := left(v_prefix_lower, -1) || chr(ascii(v_delimiter) + 1);
    ELSE
        v_upper_bound := left(v_prefix_lower, -1) || chr(ascii(right(v_prefix_lower, 1)) + 1);
    END IF;

    -- Build a resume-safe batch query. The exact-name branch returns remaining
    -- versions after the current (archived_at, version) boundary; the strict
    -- name branch returns subsequent keys. UNION ALL keeps both predicates
    -- independently indexable.
    IF v_is_asc THEN
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT * FROM (' ||
                '(SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata, o.version, o.archived_at, o.is_delete_marker, o.is_versioned FROM storage.objects o ' ||
                'WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" = $2 AND ($5::timestamptz IS NULL OR COALESCE(o.archived_at, ''infinity''::timestamptz) < $5 OR (COALESCE(o.archived_at, ''infinity''::timestamptz) = $5 AND COALESCE(o.version, '''') > $6))' ||
                v_version_filter || ' ORDER BY COALESCE(o.archived_at, ''infinity''::timestamptz) DESC, COALESCE(o.version, '''') ASC LIMIT $4) UNION ALL ' ||
                '(SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata, o.version, o.archived_at, o.is_delete_marker, o.is_versioned FROM storage.objects o ' ||
                'WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" > $2 AND lower(o.name) COLLATE "C" < $3' || v_version_filter ||
                ' ORDER BY lower(o.name) COLLATE "C" ASC, COALESCE(o.archived_at, ''infinity''::timestamptz) DESC, COALESCE(o.version, '''') ASC LIMIT $4)' ||
                ') sub ORDER BY lower(sub.name) COLLATE "C" ASC, COALESCE(sub.archived_at, ''infinity''::timestamptz) DESC, COALESCE(sub.version, '''') ASC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT * FROM (' ||
                '(SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata, o.version, o.archived_at, o.is_delete_marker, o.is_versioned FROM storage.objects o ' ||
                'WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" = $2 AND ($5::timestamptz IS NULL OR COALESCE(o.archived_at, ''infinity''::timestamptz) < $5 OR (COALESCE(o.archived_at, ''infinity''::timestamptz) = $5 AND COALESCE(o.version, '''') > $6))' ||
                v_version_filter || ' ORDER BY COALESCE(o.archived_at, ''infinity''::timestamptz) DESC, COALESCE(o.version, '''') ASC LIMIT $4) UNION ALL ' ||
                '(SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata, o.version, o.archived_at, o.is_delete_marker, o.is_versioned FROM storage.objects o ' ||
                'WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" > $2' || v_version_filter ||
                ' ORDER BY lower(o.name) COLLATE "C" ASC, COALESCE(o.archived_at, ''infinity''::timestamptz) DESC, COALESCE(o.version, '''') ASC LIMIT $4)' ||
                ') sub ORDER BY lower(sub.name) COLLATE "C" ASC, COALESCE(sub.archived_at, ''infinity''::timestamptz) DESC, COALESCE(sub.version, '''') ASC LIMIT $4';
        END IF;
    ELSE
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT * FROM (' ||
                '(SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata, o.version, o.archived_at, o.is_delete_marker, o.is_versioned FROM storage.objects o ' ||
                'WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" = $2 AND ($5::timestamptz IS NULL OR COALESCE(o.archived_at, ''infinity''::timestamptz) < $5 OR (COALESCE(o.archived_at, ''infinity''::timestamptz) = $5 AND COALESCE(o.version, '''') > $6))' ||
                v_version_filter || ' ORDER BY COALESCE(o.archived_at, ''infinity''::timestamptz) DESC, COALESCE(o.version, '''') ASC LIMIT $4) UNION ALL ' ||
                '(SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata, o.version, o.archived_at, o.is_delete_marker, o.is_versioned FROM storage.objects o ' ||
                'WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" < $2 AND lower(o.name) COLLATE "C" >= $3' || v_version_filter ||
                ' ORDER BY lower(o.name) COLLATE "C" DESC, COALESCE(o.archived_at, ''infinity''::timestamptz) DESC, COALESCE(o.version, '''') ASC LIMIT $4)' ||
                ') sub ORDER BY lower(sub.name) COLLATE "C" DESC, COALESCE(sub.archived_at, ''infinity''::timestamptz) DESC, COALESCE(sub.version, '''') ASC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT * FROM (' ||
                '(SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata, o.version, o.archived_at, o.is_delete_marker, o.is_versioned FROM storage.objects o ' ||
                'WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" = $2 AND ($5::timestamptz IS NULL OR COALESCE(o.archived_at, ''infinity''::timestamptz) < $5 OR (COALESCE(o.archived_at, ''infinity''::timestamptz) = $5 AND COALESCE(o.version, '''') > $6))' ||
                v_version_filter || ' ORDER BY COALESCE(o.archived_at, ''infinity''::timestamptz) DESC, COALESCE(o.version, '''') ASC LIMIT $4) UNION ALL ' ||
                '(SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata, o.version, o.archived_at, o.is_delete_marker, o.is_versioned FROM storage.objects o ' ||
                'WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" < $2' || v_version_filter ||
                ' ORDER BY lower(o.name) COLLATE "C" DESC, COALESCE(o.archived_at, ''infinity''::timestamptz) DESC, COALESCE(o.version, '''') ASC LIMIT $4)' ||
                ') sub ORDER BY lower(sub.name) COLLATE "C" DESC, COALESCE(sub.archived_at, ''infinity''::timestamptz) DESC, COALESCE(sub.version, '''') ASC LIMIT $4';
        END IF;
    END IF;

    -- Keep the delete-marker predicate literal so the cached generic
    -- plan can use idx_objects_delete_markers during the main-loop peek.
    IF delete_markers = 'only' THEN
        IF v_multi_row THEN
            v_delete_marker_peek_query :=
                'SELECT marker_page.name FROM (' || v_batch_query || ') marker_page LIMIT 1';
        ELSIF v_is_asc THEN
            -- Two separate literal query strings, not one gated by a bound
            -- boolean: folding "$n AND op1 OR NOT $n AND op2" into a single
            -- query defeats the generic plan's ability to push either
            -- comparison into the index. Branching in PL/pgSQL control flow
            -- instead keeps each query's index condition intact.
            v_delete_marker_peek_query :=
                'SELECT o.name FROM storage.objects o WHERE o.bucket_id = $1 ' ||
                'AND lower(o.name) COLLATE "C" >= $2' ||
                CASE WHEN v_upper_bound IS NOT NULL
                    THEN ' AND lower(o.name) COLLATE "C" < $3'
                    ELSE ''
                END ||
                v_version_filter ||
                ' ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1';
            -- Strict variant: used once the single-row ASC batch advance
            -- (below) has left v_next_seek pointing at the last row already
            -- emitted, so a plain >= would re-match it forever.
            v_delete_marker_peek_query_strict :=
                'SELECT o.name FROM storage.objects o WHERE o.bucket_id = $1 ' ||
                'AND lower(o.name) COLLATE "C" > $2' ||
                CASE WHEN v_upper_bound IS NOT NULL
                    THEN ' AND lower(o.name) COLLATE "C" < $3'
                    ELSE ''
                END ||
                v_version_filter ||
                ' ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1';
        ELSE
            v_delete_marker_peek_query :=
                'SELECT o.name FROM storage.objects o WHERE o.bucket_id = $1 ' ||
                'AND lower(o.name) COLLATE "C" < $2' ||
                CASE WHEN v_upper_bound IS NOT NULL
                    THEN ' AND lower(o.name) COLLATE "C" >= $3'
                    ELSE ''
                END ||
                v_version_filter ||
                ' ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1';
        END IF;
    END IF;

    -- Initialize seek position
    IF v_is_asc THEN
        v_next_seek := v_prefix_lower;
    ELSE
        -- DESC performs one specialized initial seek so partial current-version
        -- and delete-marker indexes remain available.
        EXECUTE format(
            'SELECT o.name FROM storage.objects o WHERE o.bucket_id = $1%s%s ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1',
            CASE WHEN v_upper_bound IS NOT NULL
                THEN ' AND lower(o.name) COLLATE "C" >= $2 AND lower(o.name) COLLATE "C" < $3'
                ELSE ''
            END,
            v_version_filter
        )
        INTO v_peek_name
        USING bucketname, v_prefix_lower, v_upper_bound;

        IF v_peek_name IS NOT NULL THEN
            v_next_seek := lower(v_peek_name) || v_delimiter;
        ELSE
            RETURN;
        END IF;
    END IF;

    -- ========================================================================
    -- MAIN LOOP: Hybrid peek-then-batch algorithm
    -- Uses STATIC SQL for peek (hot path) and DYNAMIC SQL for batch and
    -- the delete-marker-only path
    -- ========================================================================
    LOOP
        EXIT WHEN v_count >= v_limit;

        v_previous_seek := v_next_seek;
        v_previous_seek_at := v_next_seek_at;
        v_previous_seek_version := v_next_seek_version;
        v_previous_count := v_count;
        v_previous_skipped := v_skipped;

        -- STEP 1: PEEK
        v_peek_name := NULL;
        IF delete_markers = 'only' THEN
            EXECUTE CASE WHEN v_next_seek_strict
                THEN v_delete_marker_peek_query_strict
                ELSE v_delete_marker_peek_query
            END
                INTO v_peek_name
                USING bucketname, v_next_seek,
                    CASE WHEN v_is_asc THEN COALESCE(v_upper_bound, v_prefix_lower) ELSE v_prefix_lower END,
                    1, v_next_seek_at, v_next_seek_version;
        ELSIF v_multi_row AND v_next_seek_at IS NOT NULL THEN
            SELECT o.name INTO v_peek_name
            FROM storage.objects o
            WHERE o.bucket_id = bucketname
              AND lower(o.name) COLLATE "C" = v_next_seek
              AND (COALESCE(o.archived_at, 'infinity'::timestamptz) < v_next_seek_at
                   OR (COALESCE(o.archived_at, 'infinity'::timestamptz) = v_next_seek_at
                       AND COALESCE(o.version, '') > v_next_seek_version))
              AND (noncurrent_versions != 'exclude' OR o.archived_at IS NULL)
              AND (noncurrent_versions != 'only' OR o.archived_at IS NOT NULL)
              AND (delete_markers != 'exclude' OR NOT o.is_delete_marker)
              AND (delete_markers != 'only' OR o.is_delete_marker)
            ORDER BY COALESCE(o.archived_at, 'infinity'::timestamptz) DESC,
                     COALESCE(o.version, '') ASC
            LIMIT 1;

            -- The current key is exhausted. Clear its version boundary and
            -- make the following ASC name peek strict. Appending '/' is not a
            -- valid lexical successor because keys ending in characters such
            -- as '!' sort between the exhausted name and name || '/'.
            IF v_peek_name IS NULL THEN
                IF v_is_asc THEN
                    v_next_seek_strict := true;
                END IF;
                v_next_seek_at := NULL;
                v_next_seek_version := '';
            END IF;
        END IF;

        -- Single-row mode is always noncurrent_versions='exclude'. Keep the
        -- current-row predicate literal so generic plans use the current index.
        IF delete_markers != 'only' AND v_peek_name IS NULL AND NOT v_multi_row THEN
            IF v_is_asc THEN
                IF v_next_seek_strict AND v_upper_bound IS NOT NULL THEN
                    SELECT o.name INTO v_peek_name FROM storage.objects o
                    WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" > v_next_seek AND lower(o.name) COLLATE "C" < v_upper_bound
                      AND o.archived_at IS NULL
                      AND (delete_markers != 'exclude' OR NOT o.is_delete_marker)
                    ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
                ELSIF v_next_seek_strict THEN
                    SELECT o.name INTO v_peek_name FROM storage.objects o
                    WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" > v_next_seek
                      AND o.archived_at IS NULL
                      AND (delete_markers != 'exclude' OR NOT o.is_delete_marker)
                    ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
                ELSIF v_upper_bound IS NOT NULL THEN
                    SELECT o.name INTO v_peek_name FROM storage.objects o
                    WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_next_seek AND lower(o.name) COLLATE "C" < v_upper_bound
                      AND o.archived_at IS NULL
                      AND (delete_markers != 'exclude' OR NOT o.is_delete_marker)
                    ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
                ELSE
                    SELECT o.name INTO v_peek_name FROM storage.objects o
                    WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_next_seek
                      AND o.archived_at IS NULL
                      AND (delete_markers != 'exclude' OR NOT o.is_delete_marker)
                    ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
                END IF;
            ELSIF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek AND lower(o.name) COLLATE "C" >= v_prefix_lower
                  AND o.archived_at IS NULL
                  AND (delete_markers != 'exclude' OR NOT o.is_delete_marker)
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek
                  AND o.archived_at IS NULL
                  AND (delete_markers != 'exclude' OR NOT o.is_delete_marker)
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            END IF;
        ELSIF delete_markers != 'only' AND v_peek_name IS NULL AND v_is_asc THEN
            IF v_next_seek_strict AND v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" > v_next_seek AND lower(o.name) COLLATE "C" < v_upper_bound
                  AND (noncurrent_versions != 'exclude' OR o.archived_at IS NULL)
                  AND (noncurrent_versions != 'only' OR o.archived_at IS NOT NULL)
                  AND (delete_markers != 'exclude' OR NOT o.is_delete_marker)
                  AND (delete_markers != 'only' OR o.is_delete_marker)
                ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
            ELSIF v_next_seek_strict THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" > v_next_seek
                  AND (noncurrent_versions != 'exclude' OR o.archived_at IS NULL)
                  AND (noncurrent_versions != 'only' OR o.archived_at IS NOT NULL)
                  AND (delete_markers != 'exclude' OR NOT o.is_delete_marker)
                  AND (delete_markers != 'only' OR o.is_delete_marker)
                ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
            ELSIF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_next_seek AND lower(o.name) COLLATE "C" < v_upper_bound
                  AND (noncurrent_versions != 'exclude' OR o.archived_at IS NULL)
                  AND (noncurrent_versions != 'only' OR o.archived_at IS NOT NULL)
                  AND (delete_markers != 'exclude' OR NOT o.is_delete_marker)
                  AND (delete_markers != 'only' OR o.is_delete_marker)
                ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_next_seek
                  AND (noncurrent_versions != 'exclude' OR o.archived_at IS NULL)
                  AND (noncurrent_versions != 'only' OR o.archived_at IS NOT NULL)
                  AND (delete_markers != 'exclude' OR NOT o.is_delete_marker)
                  AND (delete_markers != 'only' OR o.is_delete_marker)
                ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
            END IF;
        ELSIF delete_markers != 'only' AND v_peek_name IS NULL THEN
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek AND lower(o.name) COLLATE "C" >= v_prefix_lower
                  AND (noncurrent_versions != 'exclude' OR o.archived_at IS NULL)
                  AND (noncurrent_versions != 'only' OR o.archived_at IS NOT NULL)
                  AND (delete_markers != 'exclude' OR NOT o.is_delete_marker)
                  AND (delete_markers != 'only' OR o.is_delete_marker)
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek
                  AND (noncurrent_versions != 'exclude' OR o.archived_at IS NULL)
                  AND (noncurrent_versions != 'only' OR o.archived_at IS NOT NULL)
                  AND (delete_markers != 'exclude' OR NOT o.is_delete_marker)
                  AND (delete_markers != 'only' OR o.is_delete_marker)
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            END IF;
        END IF;

        EXIT WHEN v_peek_name IS NULL;

        -- If the peek landed on a different key than we were tracking, any
        -- version boundary belongs to the OLD key and must not leak into the
        -- new one - e.g. the deleteMarkers='only' peek doesn't know or care
        -- whether it's continuing the same key or jumping to a new one, so
        -- it never clears these itself.
        IF lower(v_peek_name) IS DISTINCT FROM v_next_seek THEN
            v_next_seek_at := NULL;
            v_next_seek_version := '';
        END IF;

        -- The peek is authoritative for the next key to process. This is
        -- especially important after exhausting a multi-version key: the
        -- version boundary has been cleared, so executing the batch against
        -- a stale v_next_seek would replay every version of that old key.
        v_next_seek := lower(v_peek_name);
        v_next_seek_strict := false;

        -- STEP 2: Check if this is a FOLDER or FILE
        v_common_prefix := storage.get_common_prefix(lower(v_peek_name), v_prefix_lower, v_delimiter);

        IF v_common_prefix IS NOT NULL THEN
            -- FOLDER: Handle offset, emit if needed, skip to next folder
            IF v_skipped < offsets THEN
                v_skipped := v_skipped + 1;
            ELSE
                name := substring(rtrim(storage.get_common_prefix(v_peek_name, v_prefix, v_delimiter), v_delimiter) from v_prefix_len + 1);
                id := NULL;
                updated_at := NULL;
                created_at := NULL;
                last_accessed_at := NULL;
                metadata := NULL;
                version := NULL;
                archived_at := NULL;
                is_delete_marker := NULL;
                is_versioned := NULL;
                RETURN NEXT;
                v_count := v_count + 1;
            END IF;

            -- Advance seek past the folder range
            IF v_is_asc THEN
                v_next_seek := lower(left(v_common_prefix, -1)) || chr(ascii(v_delimiter) + 1);
            ELSE
                v_next_seek := lower(v_common_prefix);
            END IF;
            v_next_seek_at := NULL;
            v_next_seek_version := '';
        ELSE
            -- FILE: Batch fetch using DYNAMIC SQL (overhead amortized over many rows)
            -- For ASC: upper_bound is the exclusive upper limit (< condition)
            -- For DESC: prefix_lower is the inclusive lower limit (>= condition)
            FOR v_current IN EXECUTE v_batch_query
                USING bucketname, v_next_seek,
                    CASE WHEN v_is_asc THEN COALESCE(v_upper_bound, v_prefix_lower) ELSE v_prefix_lower END, v_file_batch_size,
                    v_next_seek_at, v_next_seek_version
            LOOP
                v_common_prefix := storage.get_common_prefix(lower(v_current.name), v_prefix_lower, v_delimiter);

                IF v_common_prefix IS NOT NULL THEN
                    -- Hit a folder: exit batch, let peek handle it. Reset
                    -- strict mode too - it may have been set by an earlier
                    -- row in this same batch (see the single-row ASC advance
                    -- below), and v_next_seek here is the folder-triggering
                    -- row's own name, which the next peek must find inclusively.
                    v_next_seek := CASE
                        WHEN v_is_asc THEN lower(v_current.name)
                        ELSE lower(v_current.name) || v_delimiter
                    END;
                    v_next_seek_at := NULL;
                    v_next_seek_version := '';
                    v_next_seek_strict := false;
                    EXIT;
                END IF;

                -- Handle offset skipping
                IF v_skipped < offsets THEN
                    v_skipped := v_skipped + 1;
                ELSE
                    -- Emit file
                    name := substring(v_current.name from v_prefix_len + 1);
                    id := v_current.id;
                    updated_at := v_current.updated_at;
                    created_at := v_current.created_at;
                    last_accessed_at := v_current.last_accessed_at;
                    metadata := v_current.metadata;
                    version := v_current.version;
                    archived_at := v_current.archived_at;
                    is_delete_marker := v_current.is_delete_marker;
                    is_versioned := v_current.is_versioned;
                    RETURN NEXT;
                    v_count := v_count + 1;
                END IF;

                -- Multi-row mode must remain on this key until all of its
                -- versions have crossed the internal batch boundary.
                IF v_multi_row THEN
                    v_next_seek := lower(v_current.name);
                    v_next_seek_at := COALESCE(v_current.archived_at, 'infinity'::timestamptz);
                    v_next_seek_version := COALESCE(v_current.version, '');
                ELSIF v_is_asc THEN
                    -- Appending the delimiter as a fake lexical successor would
                    -- skip a real key like `name || '!'` (or any character
                    -- sorting below the delimiter), which sorts between `name`
                    -- and `name || delimiter`. Track the real name and mark the
                    -- next comparison strict instead - same fix as the
                    -- exhausted-key case above.
                    v_next_seek := lower(v_current.name);
                    v_next_seek_strict := true;
                ELSE
                    v_next_seek := lower(v_current.name);
                END IF;

                EXIT WHEN v_count >= v_limit;
            END LOOP;
        END IF;

        IF v_count = v_previous_count
           AND v_skipped = v_previous_skipped
           AND v_next_seek IS NOT DISTINCT FROM v_previous_seek
           AND v_next_seek_at IS NOT DISTINCT FROM v_previous_seek_at
           AND v_next_seek_version IS NOT DISTINCT FROM v_previous_seek_version THEN
            RAISE EXCEPTION 'storage.search made no progress at seek (%, %, %)',
                v_next_seek, v_next_seek_at, v_next_seek_version;
        END IF;
    END LOOP;
END;
$_$;


--
-- Name: search_by_timestamp(text, text, integer, integer, text, text, text, text, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search_by_timestamp(p_prefix text, p_bucket_id text, p_limit integer, p_level integer, p_start_after text, p_sort_order text, p_sort_column text, p_sort_column_after text, noncurrent_versions text DEFAULT 'exclude'::text, delete_markers text DEFAULT 'exclude'::text, p_start_after_version text DEFAULT ''::text) RETURNS TABLE(key text, name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb, version text, archived_at timestamp with time zone, is_delete_marker boolean, is_versioned boolean)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    v_cursor_op text;
    v_query text;
    v_prefix text;
    v_prefix_pattern text;
    v_sort_order text;
    v_sort_column text;
    v_version_tiebreak text;
BEGIN
    v_prefix := coalesce(p_prefix, '');
    -- Keep the raw prefix for common-prefix calculations and escape only LIKE metacharacters.
    v_prefix_pattern := replace(v_prefix, chr(92), chr(92) || chr(92));
    v_prefix_pattern := replace(v_prefix_pattern, '%', chr(92) || '%');
    v_prefix_pattern := replace(v_prefix_pattern, '_', chr(92) || '_');

    -- COALESCE first: NULL NOT IN (...) evaluates to NULL (not TRUE), so a
    -- bare NOT IN check silently leaves an explicit NULL argument unreset.
    noncurrent_versions := COALESCE(noncurrent_versions, 'exclude');
    delete_markers := COALESCE(delete_markers, 'exclude');
    IF noncurrent_versions NOT IN ('exclude', 'only', 'include') THEN
        noncurrent_versions := 'exclude';
    END IF;
    IF delete_markers NOT IN ('exclude', 'only', 'include') THEN
        delete_markers := 'exclude';
    END IF;

    -- $9 is only populated in multi-row mode; it's always '' otherwise, so
    -- only use each row's real version as a tiebreak in multi-row mode.
    v_version_tiebreak := CASE WHEN noncurrent_versions IN ('only', 'include') THEN 'COALESCE(version, '''')' ELSE '''''' END;

    -- Defense-in-depth: this function is independently reachable and must
    -- not trust p_sort_order/p_sort_column to already be validated by a
    -- caller. Normalize to the same strict allow-list storage.search_v2
    -- uses before interpolating anything into dynamic SQL below.
    v_sort_order := lower(coalesce(p_sort_order, 'asc'));
    IF v_sort_order NOT IN ('asc', 'desc') THEN
        v_sort_order := 'asc';
    END IF;

    v_sort_column := lower(coalesce(p_sort_column, 'updated_at'));
    IF v_sort_column NOT IN ('updated_at', 'created_at') THEN
        v_sort_column := 'updated_at';
    END IF;

    IF v_sort_order = 'asc' THEN
        v_cursor_op := '>';
    ELSE
        v_cursor_op := '<';
    END IF;

    v_query := format($sql$
        WITH raw_objects AS (
            SELECT
                o.name AS obj_name,
                o.id AS obj_id,
                o.updated_at AS obj_updated_at,
                o.created_at AS obj_created_at,
                o.last_accessed_at AS obj_last_accessed_at,
                o.metadata AS obj_metadata,
                o.version AS obj_version,
                o.archived_at AS obj_archived_at,
                o.is_delete_marker AS obj_is_delete_marker,
                o.is_versioned AS obj_is_versioned,
                storage.get_common_prefix(o.name, $1, '/') AS common_prefix
            FROM storage.objects o
            WHERE o.bucket_id = $2
              AND o.name COLLATE "C" LIKE $10 || '%%'
              AND ($7 != 'exclude' OR o.archived_at IS NULL)
              AND ($7 != 'only' OR o.archived_at IS NOT NULL)
              AND ($8 != 'exclude' OR NOT o.is_delete_marker)
              AND ($8 != 'only' OR o.is_delete_marker)
        ),
        -- Aggregate common prefixes (folders)
        -- Both created_at and updated_at use MIN(obj_created_at) to match the old prefixes table behavior
        aggregated_prefixes AS (
            SELECT
                common_prefix AS name,
                NULL::uuid AS id,
                MIN(obj_created_at) AS updated_at,
                MIN(obj_created_at) AS created_at,
                NULL::timestamptz AS last_accessed_at,
                NULL::jsonb AS metadata,
                NULL::text AS version,
                NULL::timestamptz AS archived_at,
                NULL::boolean AS is_delete_marker,
                NULL::boolean AS is_versioned,
                TRUE AS is_prefix
            FROM raw_objects
            WHERE common_prefix IS NOT NULL
            GROUP BY common_prefix
        ),
        leaf_objects AS (
            SELECT
                obj_name AS name,
                obj_id AS id,
                obj_updated_at AS updated_at,
                obj_created_at AS created_at,
                obj_last_accessed_at AS last_accessed_at,
                obj_metadata AS metadata,
                obj_version AS version,
                obj_archived_at AS archived_at,
                obj_is_delete_marker AS is_delete_marker,
                obj_is_versioned AS is_versioned,
                FALSE AS is_prefix
            FROM raw_objects
            WHERE common_prefix IS NULL
        ),
        combined AS (
            SELECT * FROM aggregated_prefixes
            UNION ALL
            SELECT * FROM leaf_objects
        ),
        filtered AS (
            SELECT *
            FROM combined
            WHERE (
                $5 = ''
                OR ROW(
                    COALESCE(date_trunc('milliseconds', %I), 'epoch'::timestamptz),
                    name COLLATE "C",
                    %s
                ) %s ROW(
                    -- truncated the same way as the stored value above
                    date_trunc('milliseconds', COALESCE(NULLIF($6, '')::timestamptz, 'epoch'::timestamptz)),
                    $5,
                    $9
                )
            )
        )
        SELECT
            split_part(name, '/', $3) AS key,
            name,
            id,
            updated_at,
            created_at,
            last_accessed_at,
            metadata,
            version,
            archived_at,
            is_delete_marker,
            is_versioned
        FROM filtered
        ORDER BY
            COALESCE(date_trunc('milliseconds', %I), 'epoch'::timestamptz) %s,
            name COLLATE "C" %s,
            COALESCE(version, '') %s
        LIMIT $4
    $sql$,
        v_sort_column,
        v_version_tiebreak,
        v_cursor_op,
        v_sort_column,
        v_sort_order,
        v_sort_order,
        v_sort_order
    );

    -- version is the third tiebreak component for two versions of the same
    -- key tying on both timestamp and name (see filtered CTE / ORDER BY above)
    RETURN QUERY EXECUTE v_query
    USING v_prefix, p_bucket_id, p_level, p_limit, p_start_after, p_sort_column_after, noncurrent_versions, delete_markers, coalesce(p_start_after_version, ''), v_prefix_pattern;
END;
$_$;


--
-- Name: search_v2(text, text, integer, integer, text, text, text, text, text, text, timestamp with time zone, text, boolean); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search_v2(prefix text, bucket_name text, limits integer DEFAULT 100, levels integer DEFAULT 1, start_after text DEFAULT ''::text, sort_order text DEFAULT 'asc'::text, sort_column text DEFAULT 'name'::text, sort_column_after text DEFAULT ''::text, noncurrent_versions text DEFAULT 'exclude'::text, delete_markers text DEFAULT 'exclude'::text, start_after_archived_at timestamp with time zone DEFAULT NULL::timestamp with time zone, start_after_version text DEFAULT ''::text, start_after_is_continuation boolean DEFAULT false) RETURNS TABLE(key text, name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb, version text, archived_at timestamp with time zone, is_delete_marker boolean, is_versioned boolean)
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
    v_sort_col text;
    v_sort_ord text;
    v_limit int;
BEGIN
    -- Cap limit to maximum of 1500 records
    v_limit := LEAST(coalesce(limits, 100), 1500);

    -- Validate and normalize sort_order
    v_sort_ord := lower(coalesce(sort_order, 'asc'));
    IF v_sort_ord NOT IN ('asc', 'desc') THEN
        v_sort_ord := 'asc';
    END IF;

    -- Validate and normalize sort_column
    v_sort_col := lower(coalesce(sort_column, 'name'));
    IF v_sort_col NOT IN ('name', 'updated_at', 'created_at') THEN
        v_sort_col := 'name';
    END IF;

    -- Route to appropriate implementation
    IF v_sort_col = 'name' THEN
        -- Use list_objects_with_delimiter for name sorting (most efficient: O(k * log n))
        RETURN QUERY
        SELECT
            split_part(l.name, '/', levels) AS key,
            l.name AS name,
            l.id,
            l.updated_at,
            l.created_at,
            l.last_accessed_at,
            l.metadata,
            l.version,
            l.archived_at,
            l.is_delete_marker,
            l.is_versioned
        FROM storage.list_objects_with_delimiter(
            bucket_name,
            coalesce(prefix, ''),
            '/',
            v_limit,
            CASE WHEN start_after_is_continuation THEN '' ELSE start_after END,
            CASE WHEN start_after_is_continuation THEN start_after ELSE '' END,
            v_sort_ord,
            noncurrent_versions,
            delete_markers,
            start_after_archived_at,
            start_after_version
        ) l;
    ELSE
        -- Use aggregation approach for timestamp sorting
        -- Not efficient for large datasets but supports correct pagination
        RETURN QUERY SELECT * FROM storage.search_by_timestamp(
            prefix, bucket_name, v_limit, levels, start_after,
            v_sort_ord, v_sort_col, sort_column_after,
            noncurrent_versions, delete_markers, start_after_version
        );
    END IF;
END;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW; 
END;
$$;


--
-- Name: audit_log_entries; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.audit_log_entries (
    instance_id uuid,
    id uuid NOT NULL,
    payload json,
    created_at timestamp with time zone,
    ip_address character varying(64) DEFAULT ''::character varying NOT NULL
);


--
-- Name: TABLE audit_log_entries; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.audit_log_entries IS 'Auth: Audit trail for user actions.';


--
-- Name: custom_oauth_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.custom_oauth_providers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    provider_type text NOT NULL,
    identifier text NOT NULL,
    name text NOT NULL,
    client_id text NOT NULL,
    client_secret text NOT NULL,
    acceptable_client_ids text[] DEFAULT '{}'::text[] NOT NULL,
    scopes text[] DEFAULT '{}'::text[] NOT NULL,
    pkce_enabled boolean DEFAULT true NOT NULL,
    attribute_mapping jsonb DEFAULT '{}'::jsonb NOT NULL,
    authorization_params jsonb DEFAULT '{}'::jsonb NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    email_optional boolean DEFAULT false NOT NULL,
    issuer text,
    discovery_url text,
    skip_nonce_check boolean DEFAULT false NOT NULL,
    cached_discovery jsonb,
    discovery_cached_at timestamp with time zone,
    authorization_url text,
    token_url text,
    userinfo_url text,
    jwks_uri text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    custom_claims_allowlist text[] DEFAULT '{}'::text[] NOT NULL,
    CONSTRAINT custom_oauth_providers_authorization_url_https CHECK (((authorization_url IS NULL) OR (authorization_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_authorization_url_length CHECK (((authorization_url IS NULL) OR (char_length(authorization_url) <= 2048))),
    CONSTRAINT custom_oauth_providers_client_id_length CHECK (((char_length(client_id) >= 1) AND (char_length(client_id) <= 512))),
    CONSTRAINT custom_oauth_providers_discovery_url_length CHECK (((discovery_url IS NULL) OR (char_length(discovery_url) <= 2048))),
    CONSTRAINT custom_oauth_providers_identifier_format CHECK ((identifier ~ '^[a-z0-9][a-z0-9:-]{0,48}[a-z0-9]$'::text)),
    CONSTRAINT custom_oauth_providers_issuer_length CHECK (((issuer IS NULL) OR ((char_length(issuer) >= 1) AND (char_length(issuer) <= 2048)))),
    CONSTRAINT custom_oauth_providers_jwks_uri_https CHECK (((jwks_uri IS NULL) OR (jwks_uri ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_jwks_uri_length CHECK (((jwks_uri IS NULL) OR (char_length(jwks_uri) <= 2048))),
    CONSTRAINT custom_oauth_providers_name_length CHECK (((char_length(name) >= 1) AND (char_length(name) <= 100))),
    CONSTRAINT custom_oauth_providers_oauth2_requires_endpoints CHECK (((provider_type <> 'oauth2'::text) OR ((authorization_url IS NOT NULL) AND (token_url IS NOT NULL) AND (userinfo_url IS NOT NULL)))),
    CONSTRAINT custom_oauth_providers_oidc_discovery_url_https CHECK (((provider_type <> 'oidc'::text) OR (discovery_url IS NULL) OR (discovery_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_oidc_issuer_https CHECK (((provider_type <> 'oidc'::text) OR (issuer IS NULL) OR (issuer ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_oidc_requires_issuer CHECK (((provider_type <> 'oidc'::text) OR (issuer IS NOT NULL))),
    CONSTRAINT custom_oauth_providers_provider_type_check CHECK ((provider_type = ANY (ARRAY['oauth2'::text, 'oidc'::text]))),
    CONSTRAINT custom_oauth_providers_token_url_https CHECK (((token_url IS NULL) OR (token_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_token_url_length CHECK (((token_url IS NULL) OR (char_length(token_url) <= 2048))),
    CONSTRAINT custom_oauth_providers_userinfo_url_https CHECK (((userinfo_url IS NULL) OR (userinfo_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_userinfo_url_length CHECK (((userinfo_url IS NULL) OR (char_length(userinfo_url) <= 2048)))
);


--
-- Name: flow_state; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.flow_state (
    id uuid NOT NULL,
    user_id uuid,
    auth_code text,
    code_challenge_method auth.code_challenge_method,
    code_challenge text,
    provider_type text NOT NULL,
    provider_access_token text,
    provider_refresh_token text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    authentication_method text NOT NULL,
    auth_code_issued_at timestamp with time zone,
    invite_token text,
    referrer text,
    oauth_client_state_id uuid,
    linking_target_id uuid,
    email_optional boolean DEFAULT false NOT NULL
);


--
-- Name: TABLE flow_state; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.flow_state IS 'Stores metadata for all OAuth/SSO login flows';


--
-- Name: identities; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.identities (
    provider_id text NOT NULL,
    user_id uuid NOT NULL,
    identity_data jsonb NOT NULL,
    provider text NOT NULL,
    last_sign_in_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    email text GENERATED ALWAYS AS (lower((identity_data ->> 'email'::text))) STORED,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


--
-- Name: TABLE identities; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.identities IS 'Auth: Stores identities associated to a user.';


--
-- Name: COLUMN identities.email; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.identities.email IS 'Auth: Email is a generated column that references the optional email property in the identity_data';


--
-- Name: instances; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.instances (
    id uuid NOT NULL,
    uuid uuid,
    raw_base_config text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: TABLE instances; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.instances IS 'Auth: Manages users across multiple sites.';


--
-- Name: mfa_amr_claims; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_amr_claims (
    session_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    authentication_method text NOT NULL,
    id uuid NOT NULL
);


--
-- Name: TABLE mfa_amr_claims; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_amr_claims IS 'auth: stores authenticator method reference claims for multi factor authentication';


--
-- Name: mfa_challenges; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_challenges (
    id uuid NOT NULL,
    factor_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    verified_at timestamp with time zone,
    ip_address inet NOT NULL,
    otp_code text,
    web_authn_session_data jsonb
);


--
-- Name: TABLE mfa_challenges; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_challenges IS 'auth: stores metadata about challenge requests made';


--
-- Name: mfa_factors; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_factors (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    friendly_name text,
    factor_type auth.factor_type NOT NULL,
    status auth.factor_status NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    secret text,
    phone text,
    last_challenged_at timestamp with time zone,
    web_authn_credential jsonb,
    web_authn_aaguid uuid,
    last_webauthn_challenge_data jsonb
);


--
-- Name: TABLE mfa_factors; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_factors IS 'auth: stores metadata about factors';


--
-- Name: COLUMN mfa_factors.last_webauthn_challenge_data; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.mfa_factors.last_webauthn_challenge_data IS 'Stores the latest WebAuthn challenge data including attestation/assertion for customer verification';


--
-- Name: mfa_recovery_code_sets; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_recovery_code_sets (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    mfa_factor_id uuid NOT NULL,
    failed_verification_count integer DEFAULT 0 NOT NULL,
    verification_locked_until timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT mfa_recovery_code_sets_failed_verification_count_check CHECK ((failed_verification_count >= 0))
);


--
-- Name: mfa_recovery_codes; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_recovery_codes (
    id uuid NOT NULL,
    mfa_recovery_code_set_id uuid NOT NULL,
    code_hash text NOT NULL,
    consumed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: oauth_authorizations; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_authorizations (
    id uuid NOT NULL,
    authorization_id text NOT NULL,
    client_id uuid NOT NULL,
    user_id uuid,
    redirect_uri text NOT NULL,
    scope text NOT NULL,
    state text,
    resource text,
    code_challenge text,
    code_challenge_method auth.code_challenge_method,
    response_type auth.oauth_response_type DEFAULT 'code'::auth.oauth_response_type NOT NULL,
    status auth.oauth_authorization_status DEFAULT 'pending'::auth.oauth_authorization_status NOT NULL,
    authorization_code text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone DEFAULT (now() + '00:03:00'::interval) NOT NULL,
    approved_at timestamp with time zone,
    nonce text,
    CONSTRAINT oauth_authorizations_authorization_code_length CHECK ((char_length(authorization_code) <= 255)),
    CONSTRAINT oauth_authorizations_code_challenge_length CHECK ((char_length(code_challenge) <= 128)),
    CONSTRAINT oauth_authorizations_expires_at_future CHECK ((expires_at > created_at)),
    CONSTRAINT oauth_authorizations_nonce_length CHECK ((char_length(nonce) <= 255)),
    CONSTRAINT oauth_authorizations_redirect_uri_length CHECK ((char_length(redirect_uri) <= 2048)),
    CONSTRAINT oauth_authorizations_resource_length CHECK ((char_length(resource) <= 2048)),
    CONSTRAINT oauth_authorizations_scope_length CHECK ((char_length(scope) <= 4096)),
    CONSTRAINT oauth_authorizations_state_length CHECK ((char_length(state) <= 4096))
);


--
-- Name: oauth_client_states; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_client_states (
    id uuid NOT NULL,
    provider_type text NOT NULL,
    code_verifier text,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: TABLE oauth_client_states; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.oauth_client_states IS 'Stores OAuth states for third-party provider authentication flows where Supabase acts as the OAuth client.';


--
-- Name: oauth_clients; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_clients (
    id uuid NOT NULL,
    client_secret_hash text,
    registration_type auth.oauth_registration_type NOT NULL,
    redirect_uris text NOT NULL,
    grant_types text NOT NULL,
    client_name text,
    client_uri text,
    logo_uri text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    client_type auth.oauth_client_type DEFAULT 'confidential'::auth.oauth_client_type NOT NULL,
    token_endpoint_auth_method text NOT NULL,
    CONSTRAINT oauth_clients_client_name_length CHECK ((char_length(client_name) <= 1024)),
    CONSTRAINT oauth_clients_client_uri_length CHECK ((char_length(client_uri) <= 2048)),
    CONSTRAINT oauth_clients_logo_uri_length CHECK ((char_length(logo_uri) <= 2048)),
    CONSTRAINT oauth_clients_token_endpoint_auth_method_check CHECK ((token_endpoint_auth_method = ANY (ARRAY['client_secret_basic'::text, 'client_secret_post'::text, 'none'::text])))
);


--
-- Name: oauth_consents; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_consents (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    client_id uuid NOT NULL,
    scopes text NOT NULL,
    granted_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone,
    CONSTRAINT oauth_consents_revoked_after_granted CHECK (((revoked_at IS NULL) OR (revoked_at >= granted_at))),
    CONSTRAINT oauth_consents_scopes_length CHECK ((char_length(scopes) <= 2048)),
    CONSTRAINT oauth_consents_scopes_not_empty CHECK ((char_length(TRIM(BOTH FROM scopes)) > 0))
);


--
-- Name: one_time_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.one_time_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token_type auth.one_time_token_type NOT NULL,
    token_hash text NOT NULL,
    relates_to text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone,
    CONSTRAINT one_time_tokens_token_hash_check CHECK ((char_length(token_hash) > 0))
);


--
-- Name: refresh_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.refresh_tokens (
    instance_id uuid,
    id bigint NOT NULL,
    token character varying(255),
    user_id character varying(255),
    revoked boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    parent character varying(255),
    session_id uuid
);


--
-- Name: TABLE refresh_tokens; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.refresh_tokens IS 'Auth: Store of tokens used to refresh JWT tokens once they expire.';


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

CREATE SEQUENCE auth.refresh_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: -
--

ALTER SEQUENCE auth.refresh_tokens_id_seq OWNED BY auth.refresh_tokens.id;


--
-- Name: saml_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_providers (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    entity_id text NOT NULL,
    metadata_xml text NOT NULL,
    metadata_url text,
    attribute_mapping jsonb,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    name_id_format text,
    CONSTRAINT "entity_id not empty" CHECK ((char_length(entity_id) > 0)),
    CONSTRAINT "metadata_url not empty" CHECK (((metadata_url = NULL::text) OR (char_length(metadata_url) > 0))),
    CONSTRAINT "metadata_xml not empty" CHECK ((char_length(metadata_xml) > 0))
);


--
-- Name: TABLE saml_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_providers IS 'Auth: Manages SAML Identity Provider connections.';


--
-- Name: saml_relay_states; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_relay_states (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    request_id text NOT NULL,
    for_email text,
    redirect_to text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    flow_state_id uuid,
    CONSTRAINT "request_id not empty" CHECK ((char_length(request_id) > 0))
);


--
-- Name: TABLE saml_relay_states; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_relay_states IS 'Auth: Contains SAML Relay State information for each Service Provider initiated login.';


--
-- Name: schema_migrations; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: TABLE schema_migrations; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.schema_migrations IS 'Auth: Manages updates to the auth system.';


--
-- Name: scim_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.scim_tokens (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    token_hash text NOT NULL,
    prefix text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone,
    revoked_at timestamp with time zone,
    last_used_at timestamp with time zone,
    CONSTRAINT scim_tokens_expires_at_future CHECK (((expires_at IS NULL) OR (expires_at > created_at))),
    CONSTRAINT scim_tokens_revoked_after_created CHECK (((revoked_at IS NULL) OR (revoked_at >= created_at))),
    CONSTRAINT scim_tokens_token_hash_check CHECK ((token_hash ~ '^[0-9a-f]{64}$'::text))
);


--
-- Name: scim_users; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.scim_users (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    user_id uuid,
    resource jsonb NOT NULL,
    user_name text GENERATED ALWAYS AS (lower((resource ->> 'userName'::text))) STORED NOT NULL,
    external_id text GENERATED ALWAYS AS ((resource ->> 'externalId'::text)) STORED,
    active boolean GENERATED ALWAYS AS (COALESCE(((resource ->> 'active'::text))::boolean, true)) STORED NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone
);


--
-- Name: sessions; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sessions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    factor_id uuid,
    aal auth.aal_level,
    not_after timestamp with time zone,
    refreshed_at timestamp without time zone,
    user_agent text,
    ip inet,
    tag text,
    oauth_client_id uuid,
    refresh_token_hmac_key text,
    refresh_token_counter bigint,
    scopes text,
    CONSTRAINT sessions_scopes_length CHECK ((char_length(scopes) <= 4096))
);


--
-- Name: TABLE sessions; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sessions IS 'Auth: Stores session data associated to a user.';


--
-- Name: COLUMN sessions.not_after; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.not_after IS 'Auth: Not after is a nullable column that contains a timestamp after which the session should be regarded as expired.';


--
-- Name: COLUMN sessions.refresh_token_hmac_key; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.refresh_token_hmac_key IS 'Holds a HMAC-SHA256 key used to sign refresh tokens for this session.';


--
-- Name: COLUMN sessions.refresh_token_counter; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.refresh_token_counter IS 'Holds the ID (counter) of the last issued refresh token.';


--
-- Name: sso_domains; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_domains (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    domain text NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    CONSTRAINT "domain not empty" CHECK ((char_length(domain) > 0))
);


--
-- Name: TABLE sso_domains; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_domains IS 'Auth: Manages SSO email address domain mapping to an SSO Identity Provider.';


--
-- Name: sso_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_providers (
    id uuid NOT NULL,
    resource_id text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    disabled boolean,
    CONSTRAINT "resource_id not empty" CHECK (((resource_id = NULL::text) OR (char_length(resource_id) > 0)))
);


--
-- Name: TABLE sso_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_providers IS 'Auth: Manages SSO identity provider information; see saml_providers for SAML.';


--
-- Name: COLUMN sso_providers.resource_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sso_providers.resource_id IS 'Auth: Uniquely identifies a SSO provider according to a user-chosen resource ID (case insensitive), useful in infrastructure as code.';


--
-- Name: users; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.users (
    instance_id uuid,
    id uuid NOT NULL,
    aud character varying(255),
    role character varying(255),
    email character varying(255),
    encrypted_password character varying(255),
    email_confirmed_at timestamp with time zone,
    invited_at timestamp with time zone,
    confirmation_token character varying(255),
    confirmation_sent_at timestamp with time zone,
    recovery_token character varying(255),
    recovery_sent_at timestamp with time zone,
    email_change_token_new character varying(255),
    email_change character varying(255),
    email_change_sent_at timestamp with time zone,
    last_sign_in_at timestamp with time zone,
    raw_app_meta_data jsonb,
    raw_user_meta_data jsonb,
    is_super_admin boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    phone text DEFAULT NULL::character varying,
    phone_confirmed_at timestamp with time zone,
    phone_change text DEFAULT ''::character varying,
    phone_change_token character varying(255) DEFAULT ''::character varying,
    phone_change_sent_at timestamp with time zone,
    confirmed_at timestamp with time zone GENERATED ALWAYS AS (LEAST(email_confirmed_at, phone_confirmed_at)) STORED,
    email_change_token_current character varying(255) DEFAULT ''::character varying,
    email_change_confirm_status smallint DEFAULT 0,
    banned_until timestamp with time zone,
    reauthentication_token character varying(255) DEFAULT ''::character varying,
    reauthentication_sent_at timestamp with time zone,
    is_sso_user boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    is_anonymous boolean DEFAULT false NOT NULL,
    CONSTRAINT users_email_change_confirm_status_check CHECK (((email_change_confirm_status >= 0) AND (email_change_confirm_status <= 2)))
);


--
-- Name: TABLE users; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.users IS 'Auth: Stores user login data within a secure schema.';


--
-- Name: COLUMN users.is_sso_user; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.users.is_sso_user IS 'Auth: Set this column to true when the account comes from SSO. These accounts can have duplicate emails.';


--
-- Name: webauthn_challenges; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.webauthn_challenges (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    challenge_type text NOT NULL,
    session_data jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    CONSTRAINT webauthn_challenges_challenge_type_check CHECK ((challenge_type = ANY (ARRAY['signup'::text, 'registration'::text, 'authentication'::text])))
);


--
-- Name: webauthn_credentials; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.webauthn_credentials (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    credential_id bytea NOT NULL,
    public_key bytea NOT NULL,
    attestation_type text DEFAULT ''::text NOT NULL,
    aaguid uuid,
    sign_count bigint DEFAULT 0 NOT NULL,
    transports jsonb DEFAULT '[]'::jsonb NOT NULL,
    backup_eligible boolean DEFAULT false NOT NULL,
    backed_up boolean DEFAULT false NOT NULL,
    friendly_name text DEFAULT ''::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    last_used_at timestamp with time zone
);


--
-- Name: admin_credentials; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_credentials (
    user_id uuid NOT NULL,
    username text NOT NULL,
    password_hash text NOT NULL,
    failed_attempts integer DEFAULT 0 NOT NULL,
    locked_until timestamp with time zone,
    last_unlock_at timestamp with time zone,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT admin_credentials_username_check CHECK ((username ~ '^[a-z0-9._-]{4,32}$'::text))
);


--
-- Name: admin_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.admin_sessions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    jwt_session_id text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    revoked_at timestamp with time zone
);


--
-- Name: app_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.app_config (
    key text NOT NULL,
    value jsonb NOT NULL,
    description text,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT app_config_key_check CHECK ((key ~ '^[a-z0-9_]{2,60}$'::text))
);


--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_log (
    id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    actor_id uuid,
    actor_kind text NOT NULL,
    action text NOT NULL,
    restaurant_id uuid,
    target_user_id uuid,
    details jsonb DEFAULT '{}'::jsonb NOT NULL,
    CONSTRAINT audit_log_action_check CHECK ((action ~ '^[A-Z_]{3,60}$'::text)),
    CONSTRAINT audit_log_actor_kind_check CHECK ((actor_kind = ANY (ARRAY['USER'::text, 'ADMIN'::text, 'CONSOLE'::text, 'SERVICE'::text, 'SYSTEM'::text])))
);


--
-- Name: audit_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.audit_log ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.audit_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: availability_alerts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.availability_alerts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    restaurant_id uuid NOT NULL,
    notify_on text DEFAULT 'AVAILABLE'::text NOT NULL,
    expires_at timestamp with time zone DEFAULT (now() + '06:00:00'::interval) NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    last_notified_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT alert_window CHECK (((expires_at > created_at) AND (expires_at <= (created_at + '24:00:00'::interval)))),
    CONSTRAINT availability_alerts_notify_on_check CHECK ((notify_on = ANY (ARRAY['AVAILABLE'::text, 'AVAILABLE_OR_LIMITED'::text])))
);


--
-- Name: billing_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.billing_events (
    id bigint NOT NULL,
    provider text NOT NULL,
    event_id text NOT NULL,
    event_type text NOT NULL,
    payload jsonb NOT NULL,
    received_at timestamp with time zone DEFAULT now() NOT NULL,
    processed_at timestamp with time zone,
    error text
);


--
-- Name: billing_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.billing_events ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.billing_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: consent_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.consent_log (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    kind text NOT NULL,
    version text,
    granted boolean NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT consent_log_kind_check CHECK ((kind = ANY (ARRAY['TERMS'::text, 'PRIVACY'::text, 'RESTAURANT_TERMS'::text, 'RESTAURANT_SPECIFIC_CLAUSES'::text, 'MARKETING'::text])))
);


--
-- Name: consent_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.consent_log ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.consent_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: consumer_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.consumer_subscriptions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    plan_code text NOT NULL,
    audience text DEFAULT 'CONSUMER'::text NOT NULL,
    status text NOT NULL,
    provider text NOT NULL,
    provider_purchase_ref text,
    current_period_end timestamp with time zone,
    auto_renewing boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT consumer_subscriptions_audience_check CHECK ((audience = 'CONSUMER'::text)),
    CONSTRAINT consumer_subscriptions_provider_check CHECK ((provider = ANY (ARRAY['GOOGLE_PLAY'::text, 'APP_STORE'::text, 'STRIPE'::text, 'PROMO'::text]))),
    CONSTRAINT consumer_subscriptions_status_check CHECK ((status = ANY (ARRAY['TRIALING'::text, 'ACTIVE'::text, 'PAST_DUE'::text, 'CANCELED'::text, 'EXPIRED'::text])))
);


--
-- Name: device_push_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.device_push_tokens (
    token text NOT NULL,
    user_id uuid NOT NULL,
    platform text NOT NULL,
    app_version text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    last_seen_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT device_push_tokens_platform_check CHECK ((platform = ANY (ARRAY['ANDROID'::text, 'IOS'::text, 'WEB'::text]))),
    CONSTRAINT device_push_tokens_token_check CHECK (((char_length(token) >= 10) AND (char_length(token) <= 4096)))
);


--
-- Name: directory_import_staging; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.directory_import_staging (
    source_ref text NOT NULL,
    name text NOT NULL,
    category text,
    address text,
    city text NOT NULL,
    province text,
    latitude double precision NOT NULL,
    longitude double precision NOT NULL,
    phone_number text,
    imported_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: favorites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.favorites (
    user_id uuid NOT NULL,
    restaurant_id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: notification_outbox; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notification_outbox (
    id bigint NOT NULL,
    user_id uuid NOT NULL,
    kind text NOT NULL,
    restaurant_id uuid,
    title text NOT NULL,
    body text NOT NULL,
    data jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sent_at timestamp with time zone,
    attempts integer DEFAULT 0 NOT NULL,
    last_error text,
    CONSTRAINT notification_outbox_body_check CHECK ((char_length(body) <= 240)),
    CONSTRAINT notification_outbox_kind_check CHECK ((kind = ANY (ARRAY['AVAILABILITY_ALERT'::text, 'MANAGER_REMINDER'::text, 'CLAIM_UPDATE'::text, 'SYSTEM'::text]))),
    CONSTRAINT notification_outbox_title_check CHECK ((char_length(title) <= 80))
);


--
-- Name: notification_outbox_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.notification_outbox ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.notification_outbox_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: payments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.payments (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    payer_kind text NOT NULL,
    restaurant_id uuid,
    user_id uuid,
    provider text NOT NULL,
    provider_payment_id text NOT NULL,
    plan_code text,
    amount_cents integer NOT NULL,
    vat_cents integer,
    currency character(3) DEFAULT 'EUR'::bpchar NOT NULL,
    status text NOT NULL,
    invoice_number text,
    invoice_url text,
    paid_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT payments_amount_cents_check CHECK ((amount_cents >= 0)),
    CONSTRAINT payments_payer_kind_check CHECK ((payer_kind = ANY (ARRAY['RESTAURANT'::text, 'CONSUMER'::text]))),
    CONSTRAINT payments_provider_check CHECK ((provider = ANY (ARRAY['STRIPE'::text, 'GOOGLE_PLAY'::text, 'APP_STORE'::text, 'MANUAL'::text]))),
    CONSTRAINT payments_restaurant_has_id CHECK (((payer_kind <> 'RESTAURANT'::text) OR (restaurant_id IS NOT NULL))),
    CONSTRAINT payments_status_check CHECK ((status = ANY (ARRAY['PENDING'::text, 'SUCCEEDED'::text, 'FAILED'::text, 'REFUNDED'::text]))),
    CONSTRAINT payments_vat_cents_check CHECK (((vat_cents IS NULL) OR (vat_cents >= 0)))
);


--
-- Name: plan_expiry_notices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plan_expiry_notices (
    restaurant_id uuid NOT NULL,
    ends_at timestamp with time zone NOT NULL,
    days_before smallint NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT plan_expiry_notices_days_before_check CHECK ((days_before = ANY (ARRAY[1, 7])))
);


--
-- Name: plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.plans (
    code text NOT NULL,
    audience text NOT NULL,
    name text NOT NULL,
    tagline text,
    price_month_cents integer,
    price_year_cents integer,
    currency character(3) DEFAULT 'EUR'::bpchar NOT NULL,
    prices_include_vat boolean NOT NULL,
    features text[] DEFAULT '{}'::text[] NOT NULL,
    limits jsonb DEFAULT '{}'::jsonb NOT NULL,
    is_public boolean DEFAULT true NOT NULL,
    sort_order integer DEFAULT 0 NOT NULL,
    stripe_price_month text,
    stripe_price_year text,
    play_product_id text,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    price_semester_cents integer,
    stripe_price_semester text,
    CONSTRAINT plans_audience_check CHECK ((audience = ANY (ARRAY['RESTAURANT'::text, 'CONSUMER'::text]))),
    CONSTRAINT plans_code_check CHECK ((code ~ '^[A-Z_]{3,40}$'::text)),
    CONSTRAINT plans_price_month_cents_check CHECK (((price_month_cents IS NULL) OR (price_month_cents >= 0))),
    CONSTRAINT plans_price_semester_cents_check CHECK (((price_semester_cents IS NULL) OR (price_semester_cents >= 0))),
    CONSTRAINT plans_price_year_cents_check CHECK (((price_year_cents IS NULL) OR (price_year_cents >= 0)))
);


--
-- Name: profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.profiles (
    id uuid NOT NULL,
    display_name text,
    is_platform_admin boolean DEFAULT false NOT NULL,
    marketing_opt_in boolean DEFAULT false NOT NULL,
    accepted_terms_version text,
    accepted_terms_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    blocked_at timestamp with time zone,
    blocked_reason text,
    accepted_restaurant_terms_version text,
    accepted_restaurant_terms_at timestamp with time zone,
    notify_manager_reminders boolean DEFAULT true NOT NULL,
    notify_availability_alerts boolean DEFAULT true NOT NULL,
    notify_claim_updates boolean DEFAULT true NOT NULL,
    CONSTRAINT profiles_blocked_reason_check CHECK (((blocked_reason IS NULL) OR (char_length(blocked_reason) <= 300))),
    CONSTRAINT profiles_display_name_check CHECK (((display_name IS NULL) OR ((char_length(display_name) >= 1) AND (char_length(display_name) <= 80))))
);


--
-- Name: reservations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.reservations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    restaurant_id uuid NOT NULL,
    client_id uuid NOT NULL,
    reservation_date date NOT NULL,
    reservation_time time without time zone,
    party_size smallint NOT NULL,
    customer_name text NOT NULL,
    customer_phone text,
    table_label text,
    note text,
    status text DEFAULT 'BOOKED'::text NOT NULL,
    source text DEFAULT 'PHONE'::text NOT NULL,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT reservations_customer_name_check CHECK (((char_length(customer_name) >= 1) AND (char_length(customer_name) <= 80))),
    CONSTRAINT reservations_customer_phone_check CHECK (((customer_phone IS NULL) OR ((char_length(customer_phone) >= 3) AND (char_length(customer_phone) <= 30)))),
    CONSTRAINT reservations_note_check CHECK (((note IS NULL) OR (char_length(note) <= 200))),
    CONSTRAINT reservations_party_size_check CHECK (((party_size >= 1) AND (party_size <= 99))),
    CONSTRAINT reservations_source_check CHECK ((source = ANY (ARRAY['PHONE'::text, 'WALK_IN'::text, 'WHATSAPP'::text, 'OTHER'::text]))),
    CONSTRAINT reservations_status_check CHECK ((status = ANY (ARRAY['BOOKED'::text, 'SEATED'::text, 'NO_SHOW'::text, 'CANCELED'::text]))),
    CONSTRAINT reservations_table_label_check CHECK (((table_label IS NULL) OR (char_length(table_label) <= 20)))
);


--
-- Name: restaurant_billing_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.restaurant_billing_profiles (
    restaurant_id uuid NOT NULL,
    legal_name text NOT NULL,
    vat_number text,
    tax_code text,
    sdi_code text,
    pec_email text,
    invoice_email text,
    billing_address text NOT NULL,
    billing_city text NOT NULL,
    billing_postal_code text NOT NULL,
    billing_province text NOT NULL,
    country character(2) DEFAULT 'IT'::bpchar NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT billing_has_sdi_or_pec CHECK (((sdi_code IS NOT NULL) OR (pec_email IS NOT NULL))),
    CONSTRAINT billing_has_tax_id CHECK (((vat_number IS NOT NULL) OR (tax_code IS NOT NULL))),
    CONSTRAINT restaurant_billing_profiles_billing_address_check CHECK (((char_length(billing_address) >= 3) AND (char_length(billing_address) <= 240))),
    CONSTRAINT restaurant_billing_profiles_billing_city_check CHECK (((char_length(billing_city) >= 2) AND (char_length(billing_city) <= 100))),
    CONSTRAINT restaurant_billing_profiles_billing_postal_code_check CHECK ((billing_postal_code ~ '^[0-9]{5}$'::text)),
    CONSTRAINT restaurant_billing_profiles_billing_province_check CHECK ((billing_province ~ '^[A-Z]{2}$'::text)),
    CONSTRAINT restaurant_billing_profiles_invoice_email_check CHECK (((invoice_email IS NULL) OR (invoice_email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'::text))),
    CONSTRAINT restaurant_billing_profiles_legal_name_check CHECK (((char_length(legal_name) >= 2) AND (char_length(legal_name) <= 160))),
    CONSTRAINT restaurant_billing_profiles_pec_email_check CHECK (((pec_email IS NULL) OR (pec_email ~ '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$'::text))),
    CONSTRAINT restaurant_billing_profiles_sdi_code_check CHECK (((sdi_code IS NULL) OR (sdi_code ~ '^[A-Z0-9]{7}$'::text))),
    CONSTRAINT restaurant_billing_profiles_tax_code_check CHECK (((tax_code IS NULL) OR (tax_code ~ '^([A-Z0-9]{16}|[0-9]{11})$'::text))),
    CONSTRAINT restaurant_billing_profiles_vat_number_check CHECK (((vat_number IS NULL) OR (vat_number ~ '^[0-9]{11}$'::text)))
);


--
-- Name: restaurant_claims; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.restaurant_claims (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    restaurant_id uuid NOT NULL,
    user_id uuid NOT NULL,
    status public.claim_status DEFAULT 'PENDING'::public.claim_status NOT NULL,
    contact_info text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    reviewed_at timestamp with time zone,
    reviewed_by uuid,
    review_note text,
    phone_code_hash text,
    phone_code_expires_at timestamp with time zone,
    phone_code_attempts integer DEFAULT 0 NOT NULL,
    phone_verified_at timestamp with time zone,
    CONSTRAINT restaurant_claims_contact_info_check CHECK (((char_length(contact_info) >= 3) AND (char_length(contact_info) <= 240))),
    CONSTRAINT restaurant_claims_review_note_check CHECK (((review_note IS NULL) OR (char_length(review_note) <= 500)))
);


--
-- Name: restaurant_daily_stats; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.restaurant_daily_stats (
    restaurant_id uuid NOT NULL,
    day date NOT NULL,
    detail_views integer DEFAULT 0 NOT NULL,
    directions_taps integer DEFAULT 0 NOT NULL,
    call_taps integer DEFAULT 0 NOT NULL,
    public_page_views integer DEFAULT 0 NOT NULL,
    shares integer DEFAULT 0 NOT NULL,
    live_updates integer DEFAULT 0 NOT NULL
);


--
-- Name: restaurant_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.restaurant_users (
    restaurant_id uuid NOT NULL,
    user_id uuid NOT NULL,
    role public.restaurant_user_role NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: restaurants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.restaurants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    category text DEFAULT 'Ristorante'::text NOT NULL,
    address text NOT NULL,
    city text NOT NULL,
    province text DEFAULT 'PU'::text NOT NULL,
    postal_code text,
    location extensions.geography(Point,4326) NOT NULL,
    phone_number text,
    phone_public boolean DEFAULT false NOT NULL,
    partnership_status public.partnership_status DEFAULT 'DIRECTORY_ONLY'::public.partnership_status NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    data_source text DEFAULT 'MANUAL'::text NOT NULL,
    source_ref text,
    slug text,
    opening_hours jsonb,
    quick_notes text[] DEFAULT '{}'::text[] NOT NULL,
    website_url text,
    menu_url text,
    file_path text,
    file_mime text,
    file_bytes integer,
    file_expires_at timestamp with time zone,
    extras_changed_at timestamp with time zone,
    extras_reviewed_at timestamp with time zone,
    partner_since timestamp with time zone,
    CONSTRAINT public_phone_requires_number CHECK (((NOT phone_public) OR (phone_number IS NOT NULL))),
    CONSTRAINT restaurants_address_check CHECK (((char_length(address) >= 1) AND (char_length(address) <= 240))),
    CONSTRAINT restaurants_category_check CHECK (((char_length(category) >= 1) AND (char_length(category) <= 100))),
    CONSTRAINT restaurants_city_check CHECK (((char_length(city) >= 1) AND (char_length(city) <= 100))),
    CONSTRAINT restaurants_data_source_check CHECK ((data_source = ANY (ARRAY['MANUAL'::text, 'DEV_SEED'::text, 'OSM_IMPORT'::text, 'PARTNER_SIGNUP'::text]))),
    CONSTRAINT restaurants_file_check CHECK ((((file_path IS NULL) AND (file_mime IS NULL) AND (file_bytes IS NULL) AND (file_expires_at IS NULL)) OR ((file_path ~ '^[0-9a-f-]{36}/[A-Za-z0-9_.-]{1,80}$'::text) AND (((file_mime = ANY (ARRAY['image/jpeg'::text, 'image/webp'::text])) AND ((file_bytes >= 1) AND (file_bytes <= 1048576))) OR ((file_mime = 'application/pdf'::text) AND ((file_bytes >= 1) AND (file_bytes <= 2097152))))))),
    CONSTRAINT restaurants_links_check CHECK ((public.valid_public_link(website_url) AND public.valid_public_link(menu_url))),
    CONSTRAINT restaurants_name_check CHECK (((char_length(name) >= 1) AND (char_length(name) <= 160))),
    CONSTRAINT restaurants_opening_hours_valid CHECK (public.valid_opening_hours(opening_hours)),
    CONSTRAINT restaurants_province_check CHECK (((char_length(province) >= 1) AND (char_length(province) <= 8))),
    CONSTRAINT restaurants_quick_notes_check CHECK (public.valid_quick_notes(quick_notes)),
    CONSTRAINT restaurants_slug_format CHECK (((slug IS NULL) OR (slug ~ '^[a-z0-9]+(-[a-z0-9]+)*$'::text)))
);


--
-- Name: status_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.status_history (
    id bigint NOT NULL,
    restaurant_id uuid NOT NULL,
    status public.live_status NOT NULL,
    available_tables smallint,
    estimated_wait_minutes smallint,
    note character varying(80),
    updated_at timestamp with time zone NOT NULL,
    valid_until timestamp with time zone NOT NULL,
    updated_by uuid,
    updated_via text DEFAULT 'OWNER'::text NOT NULL,
    offer character varying(60),
    CONSTRAINT history_full_has_no_available_tables CHECK (((status <> 'FULL'::public.live_status) OR (available_tables IS NULL))),
    CONSTRAINT history_valid_window CHECK ((valid_until > updated_at)),
    CONSTRAINT status_history_available_tables_check CHECK (((available_tables IS NULL) OR ((available_tables >= 0) AND (available_tables <= 99)))),
    CONSTRAINT status_history_estimated_wait_minutes_check CHECK (((estimated_wait_minutes IS NULL) OR ((estimated_wait_minutes >= 0) AND (estimated_wait_minutes <= 240)))),
    CONSTRAINT status_history_updated_via_check CHECK ((updated_via = ANY (ARRAY['OWNER'::text, 'STAFF'::text, 'ADMIN'::text, 'DEV_APP'::text, 'DEV_SIMULATOR'::text])))
);


--
-- Name: status_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

ALTER TABLE public.status_history ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.status_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: messages; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.messages (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    binary_payload bytea,
    skip_broadcast boolean DEFAULT false NOT NULL
)
PARTITION BY RANGE (inserted_at);


--
-- Name: messages_2026_10_02; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.messages_2026_10_02 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    binary_payload bytea,
    skip_broadcast boolean DEFAULT false NOT NULL,
    CONSTRAINT messages_payload_exclusive CHECK (((payload IS NULL) OR (binary_payload IS NULL)))
);


--
-- Name: messages_2026_10_03; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.messages_2026_10_03 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    binary_payload bytea,
    skip_broadcast boolean DEFAULT false NOT NULL,
    CONSTRAINT messages_payload_exclusive CHECK (((payload IS NULL) OR (binary_payload IS NULL)))
);


--
-- Name: messages_2026_10_04; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.messages_2026_10_04 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    binary_payload bytea,
    skip_broadcast boolean DEFAULT false NOT NULL,
    CONSTRAINT messages_payload_exclusive CHECK (((payload IS NULL) OR (binary_payload IS NULL)))
);


--
-- Name: messages_2026_10_05; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.messages_2026_10_05 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    binary_payload bytea,
    skip_broadcast boolean DEFAULT false NOT NULL,
    CONSTRAINT messages_payload_exclusive CHECK (((payload IS NULL) OR (binary_payload IS NULL)))
);


--
-- Name: messages_2026_10_06; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.messages_2026_10_06 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    binary_payload bytea,
    skip_broadcast boolean DEFAULT false NOT NULL,
    CONSTRAINT messages_payload_exclusive CHECK (((payload IS NULL) OR (binary_payload IS NULL)))
);


--
-- Name: messages_2026_10_07; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.messages_2026_10_07 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    binary_payload bytea,
    skip_broadcast boolean DEFAULT false NOT NULL,
    CONSTRAINT messages_payload_exclusive CHECK (((payload IS NULL) OR (binary_payload IS NULL)))
);


--
-- Name: messages_2026_10_08; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.messages_2026_10_08 (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    binary_payload bytea,
    skip_broadcast boolean DEFAULT false NOT NULL,
    CONSTRAINT messages_payload_exclusive CHECK (((payload IS NULL) OR (binary_payload IS NULL)))
);


--
-- Name: schema_migrations; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone DEFAULT now()
);


--
-- Name: subscription; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.subscription (
    id bigint NOT NULL,
    subscription_id uuid NOT NULL,
    entity regclass NOT NULL,
    filters realtime.user_defined_filter[] DEFAULT '{}'::realtime.user_defined_filter[] NOT NULL,
    claims jsonb NOT NULL,
    claims_role regrole GENERATED ALWAYS AS (realtime.to_regrole((claims ->> 'role'::text))) STORED NOT NULL,
    created_at timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    action_filter text DEFAULT '*'::text,
    selected_columns text[],
    CONSTRAINT subscription_action_filter_check CHECK ((action_filter = ANY (ARRAY['*'::text, 'INSERT'::text, 'UPDATE'::text, 'DELETE'::text])))
);


--
-- Name: subscription_id_seq; Type: SEQUENCE; Schema: realtime; Owner: -
--

ALTER TABLE realtime.subscription ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME realtime.subscription_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: buckets; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets (
    id text NOT NULL,
    name text NOT NULL,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    public boolean DEFAULT false,
    avif_autodetection boolean DEFAULT false,
    file_size_limit bigint,
    allowed_mime_types text[],
    owner_id text,
    type storage.buckettype DEFAULT 'STANDARD'::storage.buckettype NOT NULL,
    versioning_status text DEFAULT 'DISABLED'::text NOT NULL,
    lifecycle_configuration jsonb,
    lifecycle_configuration_generation uuid,
    CONSTRAINT buckets_lifecycle_configuration_pair_check CHECK (((lifecycle_configuration IS NULL) = (lifecycle_configuration_generation IS NULL))),
    CONSTRAINT buckets_lifecycle_configuration_shape_check CHECK (((lifecycle_configuration IS NULL) OR ((jsonb_typeof(lifecycle_configuration) = 'object'::text) AND (lifecycle_configuration ? 'rules'::text) AND
CASE
    WHEN (jsonb_typeof((lifecycle_configuration -> 'rules'::text)) = 'array'::text) THEN ((jsonb_array_length((lifecycle_configuration -> 'rules'::text)) >= 1) AND (jsonb_array_length((lifecycle_configuration -> 'rules'::text)) <= 1000))
    ELSE false
END))),
    CONSTRAINT buckets_lifecycle_configuration_standard_only_check CHECK (((type = 'STANDARD'::storage.buckettype) OR ((lifecycle_configuration IS NULL) AND (lifecycle_configuration_generation IS NULL)))),
    CONSTRAINT buckets_versioning_dark_check CHECK ((versioning_status = 'DISABLED'::text)),
    CONSTRAINT buckets_versioning_standard_only_check CHECK (((type = 'STANDARD'::storage.buckettype) OR (versioning_status = 'DISABLED'::text))),
    CONSTRAINT buckets_versioning_status_check CHECK ((versioning_status = ANY (ARRAY['DISABLED'::text, 'ENABLED'::text, 'SUSPENDED'::text])))
);


--
-- Name: COLUMN buckets.owner; Type: COMMENT; Schema: storage; Owner: -
--

COMMENT ON COLUMN storage.buckets.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: buckets_analytics; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets_analytics (
    name text NOT NULL,
    type storage.buckettype DEFAULT 'ANALYTICS'::storage.buckettype NOT NULL,
    format text DEFAULT 'ICEBERG'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    deleted_at timestamp with time zone
);


--
-- Name: buckets_vectors; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets_vectors (
    id text NOT NULL,
    type storage.buckettype DEFAULT 'VECTOR'::storage.buckettype NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: migrations; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.migrations (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    hash character varying(40) NOT NULL,
    executed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: objects; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.objects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bucket_id text,
    name text,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    last_accessed_at timestamp with time zone DEFAULT now(),
    metadata jsonb,
    path_tokens text[] GENERATED ALWAYS AS (string_to_array(name, '/'::text)) STORED,
    version text,
    owner_id text,
    user_metadata jsonb,
    archived_at timestamp with time zone,
    is_delete_marker boolean DEFAULT false NOT NULL,
    is_versioned boolean DEFAULT false NOT NULL
);


--
-- Name: COLUMN objects.owner; Type: COMMENT; Schema: storage; Owner: -
--

COMMENT ON COLUMN storage.objects.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: s3_multipart_uploads; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.s3_multipart_uploads (
    id text NOT NULL,
    in_progress_size bigint DEFAULT 0 NOT NULL,
    upload_signature text NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    version text NOT NULL,
    owner_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    user_metadata jsonb,
    metadata jsonb
);


--
-- Name: s3_multipart_uploads_parts; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.s3_multipart_uploads_parts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    upload_id text NOT NULL,
    size bigint DEFAULT 0 NOT NULL,
    part_number integer NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    etag text NOT NULL,
    owner_id text,
    version text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: vector_indexes; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.vector_indexes (
    id text DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL COLLATE pg_catalog."C",
    bucket_id text NOT NULL,
    data_type text NOT NULL,
    dimension integer NOT NULL,
    distance_metric text NOT NULL,
    metadata_configuration jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: messages_2026_10_02; Type: TABLE ATTACH; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2026_10_02 FOR VALUES FROM ('2026-10-02 00:00:00') TO ('2026-10-03 00:00:00');


--
-- Name: messages_2026_10_03; Type: TABLE ATTACH; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2026_10_03 FOR VALUES FROM ('2026-10-03 00:00:00') TO ('2026-10-04 00:00:00');


--
-- Name: messages_2026_10_04; Type: TABLE ATTACH; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2026_10_04 FOR VALUES FROM ('2026-10-04 00:00:00') TO ('2026-10-05 00:00:00');


--
-- Name: messages_2026_10_05; Type: TABLE ATTACH; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2026_10_05 FOR VALUES FROM ('2026-10-05 00:00:00') TO ('2026-10-06 00:00:00');


--
-- Name: messages_2026_10_06; Type: TABLE ATTACH; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2026_10_06 FOR VALUES FROM ('2026-10-06 00:00:00') TO ('2026-10-07 00:00:00');


--
-- Name: messages_2026_10_07; Type: TABLE ATTACH; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2026_10_07 FOR VALUES FROM ('2026-10-07 00:00:00') TO ('2026-10-08 00:00:00');


--
-- Name: messages_2026_10_08; Type: TABLE ATTACH; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages ATTACH PARTITION realtime.messages_2026_10_08 FOR VALUES FROM ('2026-10-08 00:00:00') TO ('2026-10-09 00:00:00');


--
-- Name: refresh_tokens id; Type: DEFAULT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens ALTER COLUMN id SET DEFAULT nextval('auth.refresh_tokens_id_seq'::regclass);


--
-- Name: mfa_amr_claims amr_id_pk; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT amr_id_pk PRIMARY KEY (id);


--
-- Name: audit_log_entries audit_log_entries_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.audit_log_entries
    ADD CONSTRAINT audit_log_entries_pkey PRIMARY KEY (id);


--
-- Name: custom_oauth_providers custom_oauth_providers_identifier_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.custom_oauth_providers
    ADD CONSTRAINT custom_oauth_providers_identifier_key UNIQUE (identifier);


--
-- Name: custom_oauth_providers custom_oauth_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.custom_oauth_providers
    ADD CONSTRAINT custom_oauth_providers_pkey PRIMARY KEY (id);


--
-- Name: flow_state flow_state_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.flow_state
    ADD CONSTRAINT flow_state_pkey PRIMARY KEY (id);


--
-- Name: identities identities_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_pkey PRIMARY KEY (id);


--
-- Name: identities identities_provider_id_provider_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_provider_id_provider_unique UNIQUE (provider_id, provider);


--
-- Name: instances instances_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.instances
    ADD CONSTRAINT instances_pkey PRIMARY KEY (id);


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_authentication_method_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_authentication_method_pkey UNIQUE (session_id, authentication_method);


--
-- Name: mfa_challenges mfa_challenges_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_pkey PRIMARY KEY (id);


--
-- Name: mfa_factors mfa_factors_last_challenged_at_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_last_challenged_at_key UNIQUE (last_challenged_at);


--
-- Name: mfa_factors mfa_factors_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_pkey PRIMARY KEY (id);


--
-- Name: mfa_recovery_code_sets mfa_recovery_code_sets_mfa_factor_id_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_recovery_code_sets
    ADD CONSTRAINT mfa_recovery_code_sets_mfa_factor_id_key UNIQUE (mfa_factor_id);


--
-- Name: mfa_recovery_code_sets mfa_recovery_code_sets_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_recovery_code_sets
    ADD CONSTRAINT mfa_recovery_code_sets_pkey PRIMARY KEY (id);


--
-- Name: mfa_recovery_code_sets mfa_recovery_code_sets_user_id_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_recovery_code_sets
    ADD CONSTRAINT mfa_recovery_code_sets_user_id_key UNIQUE (user_id);


--
-- Name: mfa_recovery_codes mfa_recovery_codes_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_recovery_codes
    ADD CONSTRAINT mfa_recovery_codes_pkey PRIMARY KEY (id);


--
-- Name: oauth_authorizations oauth_authorizations_authorization_code_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_authorization_code_key UNIQUE (authorization_code);


--
-- Name: oauth_authorizations oauth_authorizations_authorization_id_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_authorization_id_key UNIQUE (authorization_id);


--
-- Name: oauth_authorizations oauth_authorizations_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_pkey PRIMARY KEY (id);


--
-- Name: oauth_client_states oauth_client_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_client_states
    ADD CONSTRAINT oauth_client_states_pkey PRIMARY KEY (id);


--
-- Name: oauth_clients oauth_clients_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_clients
    ADD CONSTRAINT oauth_clients_pkey PRIMARY KEY (id);


--
-- Name: oauth_consents oauth_consents_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_pkey PRIMARY KEY (id);


--
-- Name: oauth_consents oauth_consents_user_client_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_user_client_unique UNIQUE (user_id, client_id);


--
-- Name: one_time_tokens one_time_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_token_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_token_unique UNIQUE (token);


--
-- Name: saml_providers saml_providers_entity_id_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_entity_id_key UNIQUE (entity_id);


--
-- Name: saml_providers saml_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_pkey PRIMARY KEY (id);


--
-- Name: saml_relay_states saml_relay_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: scim_tokens scim_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.scim_tokens
    ADD CONSTRAINT scim_tokens_pkey PRIMARY KEY (id);


--
-- Name: scim_users scim_users_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.scim_users
    ADD CONSTRAINT scim_users_pkey PRIMARY KEY (id);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sso_domains sso_domains_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_pkey PRIMARY KEY (id);


--
-- Name: sso_providers sso_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_providers
    ADD CONSTRAINT sso_providers_pkey PRIMARY KEY (id);


--
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: webauthn_challenges webauthn_challenges_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.webauthn_challenges
    ADD CONSTRAINT webauthn_challenges_pkey PRIMARY KEY (id);


--
-- Name: webauthn_credentials webauthn_credentials_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.webauthn_credentials
    ADD CONSTRAINT webauthn_credentials_pkey PRIMARY KEY (id);


--
-- Name: admin_credentials admin_credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_credentials
    ADD CONSTRAINT admin_credentials_pkey PRIMARY KEY (user_id);


--
-- Name: admin_credentials admin_credentials_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_credentials
    ADD CONSTRAINT admin_credentials_username_key UNIQUE (username);


--
-- Name: admin_sessions admin_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_sessions
    ADD CONSTRAINT admin_sessions_pkey PRIMARY KEY (id);


--
-- Name: app_config app_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_config
    ADD CONSTRAINT app_config_pkey PRIMARY KEY (key);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: availability_alerts availability_alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.availability_alerts
    ADD CONSTRAINT availability_alerts_pkey PRIMARY KEY (id);


--
-- Name: billing_events billing_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_events
    ADD CONSTRAINT billing_events_pkey PRIMARY KEY (id);


--
-- Name: billing_events billing_events_provider_event_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.billing_events
    ADD CONSTRAINT billing_events_provider_event_id_key UNIQUE (provider, event_id);


--
-- Name: consent_log consent_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consent_log
    ADD CONSTRAINT consent_log_pkey PRIMARY KEY (id);


--
-- Name: consumer_subscriptions consumer_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consumer_subscriptions
    ADD CONSTRAINT consumer_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: device_push_tokens device_push_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.device_push_tokens
    ADD CONSTRAINT device_push_tokens_pkey PRIMARY KEY (token);


--
-- Name: directory_import_staging directory_import_staging_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.directory_import_staging
    ADD CONSTRAINT directory_import_staging_pkey PRIMARY KEY (source_ref);


--
-- Name: favorites favorites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_pkey PRIMARY KEY (user_id, restaurant_id);


--
-- Name: notification_outbox notification_outbox_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_outbox
    ADD CONSTRAINT notification_outbox_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: payments payments_provider_provider_payment_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_provider_provider_payment_id_key UNIQUE (provider, provider_payment_id);


--
-- Name: plan_expiry_notices plan_expiry_notices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plan_expiry_notices
    ADD CONSTRAINT plan_expiry_notices_pkey PRIMARY KEY (restaurant_id, ends_at, days_before);


--
-- Name: plans plans_code_audience_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT plans_code_audience_key UNIQUE (code, audience);


--
-- Name: plans plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plans
    ADD CONSTRAINT plans_pkey PRIMARY KEY (code);


--
-- Name: profiles profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_pkey PRIMARY KEY (id);


--
-- Name: reservations reservations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_pkey PRIMARY KEY (id);


--
-- Name: reservations reservations_restaurant_id_client_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_restaurant_id_client_id_key UNIQUE (restaurant_id, client_id);


--
-- Name: restaurant_billing_profiles restaurant_billing_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_billing_profiles
    ADD CONSTRAINT restaurant_billing_profiles_pkey PRIMARY KEY (restaurant_id);


--
-- Name: restaurant_claims restaurant_claims_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_claims
    ADD CONSTRAINT restaurant_claims_pkey PRIMARY KEY (id);


--
-- Name: restaurant_daily_stats restaurant_daily_stats_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_daily_stats
    ADD CONSTRAINT restaurant_daily_stats_pkey PRIMARY KEY (restaurant_id, day);


--
-- Name: restaurant_live_status restaurant_live_status_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_live_status
    ADD CONSTRAINT restaurant_live_status_pkey PRIMARY KEY (restaurant_id);


--
-- Name: restaurant_subscriptions restaurant_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_subscriptions
    ADD CONSTRAINT restaurant_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: restaurant_users restaurant_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_users
    ADD CONSTRAINT restaurant_users_pkey PRIMARY KEY (restaurant_id, user_id);


--
-- Name: restaurants restaurants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurants
    ADD CONSTRAINT restaurants_pkey PRIMARY KEY (id);


--
-- Name: status_history status_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_history
    ADD CONSTRAINT status_history_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2026_10_02 messages_2026_10_02_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages_2026_10_02
    ADD CONSTRAINT messages_2026_10_02_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2026_10_03 messages_2026_10_03_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages_2026_10_03
    ADD CONSTRAINT messages_2026_10_03_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2026_10_04 messages_2026_10_04_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages_2026_10_04
    ADD CONSTRAINT messages_2026_10_04_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2026_10_05 messages_2026_10_05_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages_2026_10_05
    ADD CONSTRAINT messages_2026_10_05_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2026_10_06 messages_2026_10_06_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages_2026_10_06
    ADD CONSTRAINT messages_2026_10_06_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2026_10_07 messages_2026_10_07_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages_2026_10_07
    ADD CONSTRAINT messages_2026_10_07_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages_2026_10_08 messages_2026_10_08_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages_2026_10_08
    ADD CONSTRAINT messages_2026_10_08_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: messages messages_payload_exclusive; Type: CHECK CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE realtime.messages
    ADD CONSTRAINT messages_payload_exclusive CHECK (((payload IS NULL) OR (binary_payload IS NULL))) NOT VALID;


--
-- Name: subscription pk_subscription; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.subscription
    ADD CONSTRAINT pk_subscription PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: buckets_analytics buckets_analytics_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets_analytics
    ADD CONSTRAINT buckets_analytics_pkey PRIMARY KEY (id);


--
-- Name: buckets buckets_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets
    ADD CONSTRAINT buckets_pkey PRIMARY KEY (id);


--
-- Name: buckets_vectors buckets_vectors_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets_vectors
    ADD CONSTRAINT buckets_vectors_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_name_key; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_name_key UNIQUE (name);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: objects objects_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT objects_pkey PRIMARY KEY (id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_pkey PRIMARY KEY (id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_pkey PRIMARY KEY (id);


--
-- Name: vector_indexes vector_indexes_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.vector_indexes
    ADD CONSTRAINT vector_indexes_pkey PRIMARY KEY (id);


--
-- Name: audit_logs_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX audit_logs_instance_id_idx ON auth.audit_log_entries USING btree (instance_id);


--
-- Name: confirmation_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX confirmation_token_idx ON auth.users USING btree (confirmation_token) WHERE ((confirmation_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: custom_oauth_providers_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX custom_oauth_providers_created_at_idx ON auth.custom_oauth_providers USING btree (created_at);


--
-- Name: custom_oauth_providers_enabled_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX custom_oauth_providers_enabled_idx ON auth.custom_oauth_providers USING btree (enabled);


--
-- Name: custom_oauth_providers_identifier_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX custom_oauth_providers_identifier_idx ON auth.custom_oauth_providers USING btree (identifier);


--
-- Name: custom_oauth_providers_provider_type_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX custom_oauth_providers_provider_type_idx ON auth.custom_oauth_providers USING btree (provider_type);


--
-- Name: email_change_token_current_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_current_idx ON auth.users USING btree (email_change_token_current) WHERE ((email_change_token_current)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_new_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_new_idx ON auth.users USING btree (email_change_token_new) WHERE ((email_change_token_new)::text !~ '^[0-9 ]*$'::text);


--
-- Name: factor_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX factor_id_created_at_idx ON auth.mfa_factors USING btree (user_id, created_at);


--
-- Name: flow_state_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX flow_state_created_at_idx ON auth.flow_state USING btree (created_at DESC);


--
-- Name: identities_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_email_idx ON auth.identities USING btree (email text_pattern_ops);


--
-- Name: INDEX identities_email_idx; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.identities_email_idx IS 'Auth: Ensures indexed queries on the email column';


--
-- Name: identities_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_user_id_idx ON auth.identities USING btree (user_id);


--
-- Name: idx_auth_code; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_auth_code ON auth.flow_state USING btree (auth_code);


--
-- Name: idx_oauth_client_states_created_at; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_oauth_client_states_created_at ON auth.oauth_client_states USING btree (created_at);


--
-- Name: idx_user_id_auth_method; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_user_id_auth_method ON auth.flow_state USING btree (user_id, authentication_method);


--
-- Name: idx_users_created_at_desc; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_users_created_at_desc ON auth.users USING btree (created_at DESC);


--
-- Name: idx_users_email; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_users_email ON auth.users USING btree (email);


--
-- Name: idx_users_last_sign_in_at_desc; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_users_last_sign_in_at_desc ON auth.users USING btree (last_sign_in_at DESC);


--
-- Name: idx_users_name; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_users_name ON auth.users USING btree (((raw_user_meta_data ->> 'name'::text))) WHERE ((raw_user_meta_data ->> 'name'::text) IS NOT NULL);


--
-- Name: mfa_challenge_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_challenge_created_at_idx ON auth.mfa_challenges USING btree (created_at DESC);


--
-- Name: mfa_factors_user_friendly_name_unique; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX mfa_factors_user_friendly_name_unique ON auth.mfa_factors USING btree (friendly_name, user_id) WHERE (TRIM(BOTH FROM friendly_name) <> ''::text);


--
-- Name: mfa_factors_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_factors_user_id_idx ON auth.mfa_factors USING btree (user_id);


--
-- Name: mfa_recovery_codes_set_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_recovery_codes_set_id_idx ON auth.mfa_recovery_codes USING btree (mfa_recovery_code_set_id);


--
-- Name: oauth_auth_pending_exp_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_auth_pending_exp_idx ON auth.oauth_authorizations USING btree (expires_at) WHERE (status = 'pending'::auth.oauth_authorization_status);


--
-- Name: oauth_clients_deleted_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_clients_deleted_at_idx ON auth.oauth_clients USING btree (deleted_at);


--
-- Name: oauth_consents_active_client_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_consents_active_client_idx ON auth.oauth_consents USING btree (client_id) WHERE (revoked_at IS NULL);


--
-- Name: oauth_consents_active_user_client_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_consents_active_user_client_idx ON auth.oauth_consents USING btree (user_id, client_id) WHERE (revoked_at IS NULL);


--
-- Name: oauth_consents_user_order_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_consents_user_order_idx ON auth.oauth_consents USING btree (user_id, granted_at DESC);


--
-- Name: one_time_tokens_relates_to_hash_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX one_time_tokens_relates_to_hash_idx ON auth.one_time_tokens USING hash (relates_to);


--
-- Name: one_time_tokens_token_hash_hash_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX one_time_tokens_token_hash_hash_idx ON auth.one_time_tokens USING hash (token_hash);


--
-- Name: one_time_tokens_user_id_token_type_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX one_time_tokens_user_id_token_type_key ON auth.one_time_tokens USING btree (user_id, token_type);


--
-- Name: reauthentication_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX reauthentication_token_idx ON auth.users USING btree (reauthentication_token) WHERE ((reauthentication_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: recovery_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX recovery_token_idx ON auth.users USING btree (recovery_token) WHERE ((recovery_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: refresh_tokens_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_idx ON auth.refresh_tokens USING btree (instance_id);


--
-- Name: refresh_tokens_instance_id_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_user_id_idx ON auth.refresh_tokens USING btree (instance_id, user_id);


--
-- Name: refresh_tokens_parent_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_parent_idx ON auth.refresh_tokens USING btree (parent);


--
-- Name: refresh_tokens_session_id_revoked_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_session_id_revoked_idx ON auth.refresh_tokens USING btree (session_id, revoked);


--
-- Name: refresh_tokens_updated_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_updated_at_idx ON auth.refresh_tokens USING btree (updated_at DESC);


--
-- Name: saml_providers_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_providers_sso_provider_id_idx ON auth.saml_providers USING btree (sso_provider_id);


--
-- Name: saml_relay_states_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_created_at_idx ON auth.saml_relay_states USING btree (created_at DESC);


--
-- Name: saml_relay_states_for_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_for_email_idx ON auth.saml_relay_states USING btree (for_email);


--
-- Name: saml_relay_states_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_sso_provider_id_idx ON auth.saml_relay_states USING btree (sso_provider_id);


--
-- Name: scim_tokens_expires_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX scim_tokens_expires_at_idx ON auth.scim_tokens USING btree (expires_at);


--
-- Name: scim_tokens_revoked_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX scim_tokens_revoked_at_idx ON auth.scim_tokens USING btree (revoked_at);


--
-- Name: scim_tokens_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX scim_tokens_sso_provider_id_idx ON auth.scim_tokens USING btree (sso_provider_id);


--
-- Name: scim_tokens_token_hash_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX scim_tokens_token_hash_key ON auth.scim_tokens USING btree (token_hash);


--
-- Name: scim_users_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX scim_users_created_at_idx ON auth.scim_users USING btree (sso_provider_id, created_at, id) WHERE (deleted_at IS NULL);


--
-- Name: scim_users_deleted_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX scim_users_deleted_at_idx ON auth.scim_users USING btree (deleted_at);


--
-- Name: scim_users_external_id_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX scim_users_external_id_key ON auth.scim_users USING btree (sso_provider_id, external_id) WHERE ((external_id IS NOT NULL) AND (deleted_at IS NULL));


--
-- Name: scim_users_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX scim_users_id_idx ON auth.scim_users USING btree (sso_provider_id, id) WHERE (deleted_at IS NULL);


--
-- Name: scim_users_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX scim_users_sso_provider_id_idx ON auth.scim_users USING btree (sso_provider_id);


--
-- Name: scim_users_updated_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX scim_users_updated_at_idx ON auth.scim_users USING btree (sso_provider_id, updated_at, id) WHERE (deleted_at IS NULL);


--
-- Name: scim_users_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX scim_users_user_id_idx ON auth.scim_users USING btree (user_id);


--
-- Name: scim_users_user_name_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX scim_users_user_name_idx ON auth.scim_users USING btree (sso_provider_id, user_name COLLATE "C", id) WHERE (deleted_at IS NULL);


--
-- Name: scim_users_user_name_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX scim_users_user_name_key ON auth.scim_users USING btree (sso_provider_id, user_name) WHERE (deleted_at IS NULL);


--
-- Name: sessions_not_after_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_not_after_idx ON auth.sessions USING btree (not_after DESC);


--
-- Name: sessions_oauth_client_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_oauth_client_id_idx ON auth.sessions USING btree (oauth_client_id);


--
-- Name: sessions_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_user_id_idx ON auth.sessions USING btree (user_id);


--
-- Name: sso_domains_domain_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_domains_domain_idx ON auth.sso_domains USING btree (lower(domain));


--
-- Name: sso_domains_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sso_domains_sso_provider_id_idx ON auth.sso_domains USING btree (sso_provider_id);


--
-- Name: sso_providers_resource_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_providers_resource_id_idx ON auth.sso_providers USING btree (lower(resource_id));


--
-- Name: sso_providers_resource_id_pattern_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sso_providers_resource_id_pattern_idx ON auth.sso_providers USING btree (resource_id text_pattern_ops);


--
-- Name: unique_phone_factor_per_user; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX unique_phone_factor_per_user ON auth.mfa_factors USING btree (user_id, phone);


--
-- Name: user_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX user_id_created_at_idx ON auth.sessions USING btree (user_id, created_at);


--
-- Name: users_email_partial_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX users_email_partial_key ON auth.users USING btree (email) WHERE (is_sso_user = false);


--
-- Name: INDEX users_email_partial_key; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.users_email_partial_key IS 'Auth: A partial unique index that applies only when is_sso_user is false';


--
-- Name: users_instance_id_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_email_idx ON auth.users USING btree (instance_id, lower((email)::text));


--
-- Name: users_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_idx ON auth.users USING btree (instance_id);


--
-- Name: users_is_anonymous_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_is_anonymous_idx ON auth.users USING btree (is_anonymous);


--
-- Name: webauthn_challenges_expires_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX webauthn_challenges_expires_at_idx ON auth.webauthn_challenges USING btree (expires_at);


--
-- Name: webauthn_challenges_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX webauthn_challenges_user_id_idx ON auth.webauthn_challenges USING btree (user_id);


--
-- Name: webauthn_credentials_credential_id_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX webauthn_credentials_credential_id_key ON auth.webauthn_credentials USING btree (credential_id);


--
-- Name: webauthn_credentials_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX webauthn_credentials_user_id_idx ON auth.webauthn_credentials USING btree (user_id);


--
-- Name: admin_sessions_user_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX admin_sessions_user_idx ON public.admin_sessions USING btree (user_id, expires_at DESC);


--
-- Name: audit_log_actor_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_log_actor_idx ON public.audit_log USING btree (actor_id, created_at DESC);


--
-- Name: audit_log_created_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_log_created_idx ON public.audit_log USING btree (created_at DESC);


--
-- Name: audit_log_restaurant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_log_restaurant_idx ON public.audit_log USING btree (restaurant_id, created_at DESC);


--
-- Name: audit_log_target_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX audit_log_target_idx ON public.audit_log USING btree (target_user_id, created_at DESC);


--
-- Name: availability_alerts_one_active_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX availability_alerts_one_active_uidx ON public.availability_alerts USING btree (user_id, restaurant_id) WHERE is_active;


--
-- Name: availability_alerts_restaurant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX availability_alerts_restaurant_idx ON public.availability_alerts USING btree (restaurant_id) WHERE is_active;


--
-- Name: consent_log_user_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX consent_log_user_idx ON public.consent_log USING btree (user_id, created_at DESC);


--
-- Name: consumer_subscriptions_one_live_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX consumer_subscriptions_one_live_uidx ON public.consumer_subscriptions USING btree (user_id) WHERE (status = ANY (ARRAY['TRIALING'::text, 'ACTIVE'::text, 'PAST_DUE'::text]));


--
-- Name: consumer_subscriptions_provider_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX consumer_subscriptions_provider_uidx ON public.consumer_subscriptions USING btree (provider, provider_purchase_ref) WHERE (provider_purchase_ref IS NOT NULL);


--
-- Name: device_push_tokens_user_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX device_push_tokens_user_idx ON public.device_push_tokens USING btree (user_id);


--
-- Name: notification_outbox_pending_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notification_outbox_pending_idx ON public.notification_outbox USING btree (created_at) WHERE (sent_at IS NULL);


--
-- Name: notification_outbox_restaurant_kind_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX notification_outbox_restaurant_kind_idx ON public.notification_outbox USING btree (restaurant_id, kind, created_at DESC);


--
-- Name: reservations_restaurant_day_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX reservations_restaurant_day_idx ON public.reservations USING btree (restaurant_id, reservation_date, reservation_time);


--
-- Name: restaurant_claims_one_pending_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX restaurant_claims_one_pending_uidx ON public.restaurant_claims USING btree (restaurant_id, user_id) WHERE (status = 'PENDING'::public.claim_status);


--
-- Name: restaurant_claims_restaurant_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX restaurant_claims_restaurant_idx ON public.restaurant_claims USING btree (restaurant_id);


--
-- Name: restaurant_claims_user_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX restaurant_claims_user_idx ON public.restaurant_claims USING btree (user_id);


--
-- Name: restaurant_subscriptions_one_live_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX restaurant_subscriptions_one_live_uidx ON public.restaurant_subscriptions USING btree (restaurant_id) WHERE (status = ANY (ARRAY['TRIALING'::text, 'ACTIVE'::text, 'PAST_DUE'::text]));


--
-- Name: restaurant_subscriptions_provider_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX restaurant_subscriptions_provider_uidx ON public.restaurant_subscriptions USING btree (provider, provider_subscription_id) WHERE (provider_subscription_id IS NOT NULL);


--
-- Name: restaurants_category_trgm_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX restaurants_category_trgm_idx ON public.restaurants USING gin (category extensions.gin_trgm_ops);


--
-- Name: restaurants_location_gix; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX restaurants_location_gix ON public.restaurants USING gist (location);


--
-- Name: restaurants_name_trgm_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX restaurants_name_trgm_idx ON public.restaurants USING gin (name extensions.gin_trgm_ops);


--
-- Name: restaurants_slug_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX restaurants_slug_uidx ON public.restaurants USING btree (slug);


--
-- Name: restaurants_source_ref_uidx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX restaurants_source_ref_uidx ON public.restaurants USING btree (data_source, source_ref) WHERE (source_ref IS NOT NULL);


--
-- Name: status_history_restaurant_time_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX status_history_restaurant_time_idx ON public.status_history USING btree (restaurant_id, updated_at DESC);


--
-- Name: ix_realtime_subscription_entity; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX ix_realtime_subscription_entity ON realtime.subscription USING btree (entity);


--
-- Name: messages_inserted_at_topic_index; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX messages_inserted_at_topic_index ON ONLY realtime.messages USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2026_10_02_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX messages_2026_10_02_inserted_at_topic_idx ON realtime.messages_2026_10_02 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2026_10_03_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX messages_2026_10_03_inserted_at_topic_idx ON realtime.messages_2026_10_03 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2026_10_04_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX messages_2026_10_04_inserted_at_topic_idx ON realtime.messages_2026_10_04 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2026_10_05_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX messages_2026_10_05_inserted_at_topic_idx ON realtime.messages_2026_10_05 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2026_10_06_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX messages_2026_10_06_inserted_at_topic_idx ON realtime.messages_2026_10_06 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2026_10_07_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX messages_2026_10_07_inserted_at_topic_idx ON realtime.messages_2026_10_07 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: messages_2026_10_08_inserted_at_topic_idx; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX messages_2026_10_08_inserted_at_topic_idx ON realtime.messages_2026_10_08 USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: subscription_subscription_id_entity_filters_action_filter_selec; Type: INDEX; Schema: realtime; Owner: -
--

CREATE UNIQUE INDEX subscription_subscription_id_entity_filters_action_filter_selec ON realtime.subscription USING btree (subscription_id, entity, filters, action_filter, COALESCE(selected_columns, '{}'::text[]));


--
-- Name: bname; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX bname ON storage.buckets USING btree (name);


--
-- Name: buckets_analytics_unique_name_idx; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX buckets_analytics_unique_name_idx ON storage.buckets_analytics USING btree (name) WHERE (deleted_at IS NULL);


--
-- Name: idx_multipart_uploads_list; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_multipart_uploads_list ON storage.s3_multipart_uploads USING btree (bucket_id, key, created_at);


--
-- Name: idx_objects_bucket_id_name; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_objects_bucket_id_name ON storage.objects USING btree (bucket_id, name COLLATE "C");


--
-- Name: idx_objects_bucket_id_name_lower; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_objects_bucket_id_name_lower ON storage.objects USING btree (bucket_id, lower(name) COLLATE "C");


--
-- Name: idx_objects_current_version; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX idx_objects_current_version ON storage.objects USING btree (bucket_id, name COLLATE "C") WHERE (archived_at IS NULL);


--
-- Name: idx_objects_delete_markers; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_objects_delete_markers ON storage.objects USING btree (bucket_id, name COLLATE "C") WHERE is_delete_marker;


--
-- Name: idx_objects_null_version; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX idx_objects_null_version ON storage.objects USING btree (bucket_id, name COLLATE "C") WHERE (NOT is_versioned);


--
-- Name: name_prefix_search; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX name_prefix_search ON storage.objects USING btree (name text_pattern_ops);


--
-- Name: objects_bucket_id_name_version_key; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX objects_bucket_id_name_version_key ON storage.objects USING btree (bucket_id, name COLLATE "C", version) NULLS NOT DISTINCT;


--
-- Name: vector_indexes_name_bucket_id_idx; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX vector_indexes_name_bucket_id_idx ON storage.vector_indexes USING btree (name, bucket_id);


--
-- Name: messages_2026_10_02_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2026_10_02_inserted_at_topic_idx;


--
-- Name: messages_2026_10_02_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2026_10_02_pkey;


--
-- Name: messages_2026_10_03_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2026_10_03_inserted_at_topic_idx;


--
-- Name: messages_2026_10_03_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2026_10_03_pkey;


--
-- Name: messages_2026_10_04_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2026_10_04_inserted_at_topic_idx;


--
-- Name: messages_2026_10_04_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2026_10_04_pkey;


--
-- Name: messages_2026_10_05_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2026_10_05_inserted_at_topic_idx;


--
-- Name: messages_2026_10_05_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2026_10_05_pkey;


--
-- Name: messages_2026_10_06_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2026_10_06_inserted_at_topic_idx;


--
-- Name: messages_2026_10_06_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2026_10_06_pkey;


--
-- Name: messages_2026_10_07_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2026_10_07_inserted_at_topic_idx;


--
-- Name: messages_2026_10_07_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2026_10_07_pkey;


--
-- Name: messages_2026_10_08_inserted_at_topic_idx; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_inserted_at_topic_index ATTACH PARTITION realtime.messages_2026_10_08_inserted_at_topic_idx;


--
-- Name: messages_2026_10_08_pkey; Type: INDEX ATTACH; Schema: realtime; Owner: -
--

ALTER INDEX realtime.messages_pkey ATTACH PARTITION realtime.messages_2026_10_08_pkey;


--
-- Name: users on_auth_user_created; Type: TRIGGER; Schema: auth; Owner: -
--

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();


--
-- Name: availability_alerts availability_alerts_plan; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER availability_alerts_plan BEFORE INSERT ON public.availability_alerts FOR EACH ROW EXECUTE FUNCTION public.enforce_alert_plan();


--
-- Name: consumer_subscriptions consumer_subscriptions_touch; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER consumer_subscriptions_touch BEFORE UPDATE ON public.consumer_subscriptions FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();


--
-- Name: favorites favorites_limit; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER favorites_limit BEFORE INSERT ON public.favorites FOR EACH ROW EXECUTE FUNCTION public.enforce_favorites_limit();


--
-- Name: restaurant_live_status live_status_alerts; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER live_status_alerts AFTER INSERT OR UPDATE ON public.restaurant_live_status FOR EACH ROW EXECUTE FUNCTION public.enqueue_availability_alerts();


--
-- Name: profiles profiles_touch_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER profiles_touch_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();


--
-- Name: reservations reservations_touch; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER reservations_touch BEFORE UPDATE ON public.reservations FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();


--
-- Name: restaurant_billing_profiles restaurant_billing_profiles_touch; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER restaurant_billing_profiles_touch BEFORE UPDATE ON public.restaurant_billing_profiles FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();


--
-- Name: restaurant_live_status restaurant_live_status_plan; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER restaurant_live_status_plan BEFORE INSERT OR UPDATE ON public.restaurant_live_status FOR EACH ROW EXECUTE FUNCTION public.enforce_live_status_plan();


--
-- Name: restaurant_subscriptions restaurant_subscriptions_touch; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER restaurant_subscriptions_touch BEFORE UPDATE ON public.restaurant_subscriptions FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();


--
-- Name: restaurants restaurants_assign_slug; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER restaurants_assign_slug BEFORE INSERT OR UPDATE OF name, city, slug ON public.restaurants FOR EACH ROW EXECUTE FUNCTION public.assign_restaurant_slug();


--
-- Name: restaurants restaurants_clear_extras_when_unclaimed; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER restaurants_clear_extras_when_unclaimed BEFORE UPDATE OF partnership_status ON public.restaurants FOR EACH ROW EXECUTE FUNCTION public.clear_extras_when_unclaimed();


--
-- Name: restaurants restaurants_partner_since; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER restaurants_partner_since BEFORE INSERT OR UPDATE OF partnership_status ON public.restaurants FOR EACH ROW EXECUTE FUNCTION public.set_partner_since();


--
-- Name: restaurants restaurants_touch_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER restaurants_touch_updated_at BEFORE UPDATE ON public.restaurants FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();


--
-- Name: status_history status_history_count_update; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER status_history_count_update AFTER INSERT ON public.status_history FOR EACH ROW EXECUTE FUNCTION public.count_live_update();


--
-- Name: subscription tr_check_filters; Type: TRIGGER; Schema: realtime; Owner: -
--

CREATE TRIGGER tr_check_filters BEFORE INSERT OR UPDATE ON realtime.subscription FOR EACH ROW EXECUTE FUNCTION realtime.subscription_check_filters();


--
-- Name: buckets enforce_bucket_name_length_trigger; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER enforce_bucket_name_length_trigger BEFORE INSERT OR UPDATE OF name ON storage.buckets FOR EACH ROW EXECUTE FUNCTION storage.enforce_bucket_name_length();


--
-- Name: buckets protect_bucket_control_insert; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER protect_bucket_control_insert BEFORE INSERT ON storage.buckets FOR EACH ROW EXECUTE FUNCTION storage.protect_bucket_control_columns('service_role');


--
-- Name: buckets protect_bucket_control_update; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER protect_bucket_control_update BEFORE UPDATE OF lifecycle_configuration, lifecycle_configuration_generation ON storage.buckets FOR EACH ROW EXECUTE FUNCTION storage.protect_bucket_control_columns();


--
-- Name: buckets protect_bucket_control_update_role; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER protect_bucket_control_update_role AFTER UPDATE OF lifecycle_configuration, lifecycle_configuration_generation ON storage.buckets FOR EACH ROW EXECUTE FUNCTION storage.enforce_bucket_lifecycle_service_role('service_role');


--
-- Name: buckets protect_buckets_delete; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER protect_buckets_delete BEFORE DELETE ON storage.buckets FOR EACH STATEMENT EXECUTE FUNCTION storage.protect_delete();


--
-- Name: objects protect_objects_delete; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER protect_objects_delete BEFORE DELETE ON storage.objects FOR EACH STATEMENT EXECUTE FUNCTION storage.protect_delete();


--
-- Name: objects update_objects_updated_at; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER update_objects_updated_at BEFORE UPDATE ON storage.objects FOR EACH ROW EXECUTE FUNCTION storage.update_updated_at_column();


--
-- Name: identities identities_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: mfa_challenges mfa_challenges_auth_factor_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_auth_factor_id_fkey FOREIGN KEY (factor_id) REFERENCES auth.mfa_factors(id) ON DELETE CASCADE;


--
-- Name: mfa_factors mfa_factors_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: mfa_recovery_code_sets mfa_recovery_code_sets_mfa_factor_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_recovery_code_sets
    ADD CONSTRAINT mfa_recovery_code_sets_mfa_factor_id_fkey FOREIGN KEY (mfa_factor_id) REFERENCES auth.mfa_factors(id) ON DELETE CASCADE;


--
-- Name: mfa_recovery_code_sets mfa_recovery_code_sets_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_recovery_code_sets
    ADD CONSTRAINT mfa_recovery_code_sets_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: mfa_recovery_codes mfa_recovery_codes_mfa_recovery_code_set_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_recovery_codes
    ADD CONSTRAINT mfa_recovery_codes_mfa_recovery_code_set_id_fkey FOREIGN KEY (mfa_recovery_code_set_id) REFERENCES auth.mfa_recovery_code_sets(id) ON DELETE CASCADE;


--
-- Name: oauth_authorizations oauth_authorizations_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: oauth_authorizations oauth_authorizations_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: oauth_consents oauth_consents_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: oauth_consents oauth_consents_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: one_time_tokens one_time_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: refresh_tokens refresh_tokens_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: saml_providers saml_providers_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_flow_state_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_flow_state_id_fkey FOREIGN KEY (flow_state_id) REFERENCES auth.flow_state(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: scim_tokens scim_tokens_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.scim_tokens
    ADD CONSTRAINT scim_tokens_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: scim_users scim_users_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.scim_users
    ADD CONSTRAINT scim_users_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: scim_users scim_users_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.scim_users
    ADD CONSTRAINT scim_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: sessions sessions_oauth_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_oauth_client_id_fkey FOREIGN KEY (oauth_client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: sso_domains sso_domains_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: webauthn_challenges webauthn_challenges_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.webauthn_challenges
    ADD CONSTRAINT webauthn_challenges_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: webauthn_credentials webauthn_credentials_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.webauthn_credentials
    ADD CONSTRAINT webauthn_credentials_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: admin_credentials admin_credentials_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_credentials
    ADD CONSTRAINT admin_credentials_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: admin_sessions admin_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.admin_sessions
    ADD CONSTRAINT admin_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: audit_log audit_log_actor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_actor_id_fkey FOREIGN KEY (actor_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: audit_log audit_log_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id) ON DELETE SET NULL;


--
-- Name: audit_log audit_log_target_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_target_user_id_fkey FOREIGN KEY (target_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: availability_alerts availability_alerts_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.availability_alerts
    ADD CONSTRAINT availability_alerts_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id) ON DELETE CASCADE;


--
-- Name: availability_alerts availability_alerts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.availability_alerts
    ADD CONSTRAINT availability_alerts_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: consent_log consent_log_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consent_log
    ADD CONSTRAINT consent_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: consumer_subscriptions consumer_subscriptions_plan_code_audience_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consumer_subscriptions
    ADD CONSTRAINT consumer_subscriptions_plan_code_audience_fkey FOREIGN KEY (plan_code, audience) REFERENCES public.plans(code, audience);


--
-- Name: consumer_subscriptions consumer_subscriptions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.consumer_subscriptions
    ADD CONSTRAINT consumer_subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: device_push_tokens device_push_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.device_push_tokens
    ADD CONSTRAINT device_push_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: favorites favorites_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id) ON DELETE CASCADE;


--
-- Name: favorites favorites_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.favorites
    ADD CONSTRAINT favorites_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: notification_outbox notification_outbox_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_outbox
    ADD CONSTRAINT notification_outbox_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id) ON DELETE CASCADE;


--
-- Name: notification_outbox notification_outbox_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notification_outbox
    ADD CONSTRAINT notification_outbox_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: payments payments_plan_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_plan_code_fkey FOREIGN KEY (plan_code) REFERENCES public.plans(code);


--
-- Name: payments payments_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id) ON DELETE RESTRICT;


--
-- Name: payments payments_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: plan_expiry_notices plan_expiry_notices_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.plan_expiry_notices
    ADD CONSTRAINT plan_expiry_notices_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id) ON DELETE CASCADE;


--
-- Name: profiles profiles_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.profiles
    ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: reservations reservations_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: reservations reservations_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id) ON DELETE CASCADE;


--
-- Name: restaurant_billing_profiles restaurant_billing_profiles_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_billing_profiles
    ADD CONSTRAINT restaurant_billing_profiles_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id) ON DELETE CASCADE;


--
-- Name: restaurant_claims restaurant_claims_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_claims
    ADD CONSTRAINT restaurant_claims_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id) ON DELETE CASCADE;


--
-- Name: restaurant_claims restaurant_claims_reviewed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_claims
    ADD CONSTRAINT restaurant_claims_reviewed_by_fkey FOREIGN KEY (reviewed_by) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: restaurant_claims restaurant_claims_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_claims
    ADD CONSTRAINT restaurant_claims_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: restaurant_daily_stats restaurant_daily_stats_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_daily_stats
    ADD CONSTRAINT restaurant_daily_stats_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id) ON DELETE CASCADE;


--
-- Name: restaurant_live_status restaurant_live_status_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_live_status
    ADD CONSTRAINT restaurant_live_status_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id) ON DELETE CASCADE;


--
-- Name: restaurant_subscriptions restaurant_subscriptions_plan_code_audience_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_subscriptions
    ADD CONSTRAINT restaurant_subscriptions_plan_code_audience_fkey FOREIGN KEY (plan_code, audience) REFERENCES public.plans(code, audience);


--
-- Name: restaurant_subscriptions restaurant_subscriptions_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_subscriptions
    ADD CONSTRAINT restaurant_subscriptions_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id) ON DELETE CASCADE;


--
-- Name: restaurant_users restaurant_users_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_users
    ADD CONSTRAINT restaurant_users_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id) ON DELETE CASCADE;


--
-- Name: restaurant_users restaurant_users_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.restaurant_users
    ADD CONSTRAINT restaurant_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: status_history status_history_restaurant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_history
    ADD CONSTRAINT status_history_restaurant_id_fkey FOREIGN KEY (restaurant_id) REFERENCES public.restaurants(id) ON DELETE CASCADE;


--
-- Name: status_history status_history_updated_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_history
    ADD CONSTRAINT status_history_updated_by_fkey FOREIGN KEY (updated_by) REFERENCES auth.users(id) ON DELETE SET NULL;


--
-- Name: objects objects_bucketId_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT "objects_bucketId_fkey" FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_upload_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_upload_id_fkey FOREIGN KEY (upload_id) REFERENCES storage.s3_multipart_uploads(id) ON DELETE CASCADE;


--
-- Name: vector_indexes vector_indexes_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.vector_indexes
    ADD CONSTRAINT vector_indexes_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets_vectors(id);


--
-- Name: audit_log_entries; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.audit_log_entries ENABLE ROW LEVEL SECURITY;

--
-- Name: flow_state; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.flow_state ENABLE ROW LEVEL SECURITY;

--
-- Name: identities; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.identities ENABLE ROW LEVEL SECURITY;

--
-- Name: instances; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.instances ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_amr_claims; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_amr_claims ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_challenges; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_challenges ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_factors; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_factors ENABLE ROW LEVEL SECURITY;

--
-- Name: one_time_tokens; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.one_time_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: refresh_tokens; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.refresh_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_providers; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.saml_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_relay_states; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.saml_relay_states ENABLE ROW LEVEL SECURITY;

--
-- Name: schema_migrations; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.schema_migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: sessions; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_domains; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sso_domains ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_providers; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sso_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: users; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

--
-- Name: admin_credentials; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.admin_credentials ENABLE ROW LEVEL SECURITY;

--
-- Name: admin_sessions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.admin_sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: availability_alerts alerts_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY alerts_own ON public.availability_alerts TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid))) WITH CHECK (((user_id = ( SELECT auth.uid() AS uid)) AND (NOT public.is_user_blocked(( SELECT auth.uid() AS uid)))));


--
-- Name: app_config; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

--
-- Name: app_config app_config_public_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY app_config_public_read ON public.app_config FOR SELECT TO authenticated, anon USING (true);


--
-- Name: audit_log; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

--
-- Name: availability_alerts; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.availability_alerts ENABLE ROW LEVEL SECURITY;

--
-- Name: billing_events; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.billing_events ENABLE ROW LEVEL SECURITY;

--
-- Name: restaurant_billing_profiles billing_profiles_owner_insert; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY billing_profiles_owner_insert ON public.restaurant_billing_profiles FOR INSERT TO authenticated WITH CHECK ((public.is_restaurant_owner(restaurant_id) AND public.restaurant_mfa_satisfied()));


--
-- Name: restaurant_billing_profiles billing_profiles_owner_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY billing_profiles_owner_read ON public.restaurant_billing_profiles FOR SELECT TO authenticated USING (((public.is_restaurant_owner(restaurant_id) AND public.restaurant_mfa_satisfied()) OR public.is_platform_admin()));


--
-- Name: restaurant_billing_profiles billing_profiles_owner_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY billing_profiles_owner_update ON public.restaurant_billing_profiles FOR UPDATE TO authenticated USING ((public.is_restaurant_owner(restaurant_id) AND public.restaurant_mfa_satisfied())) WITH CHECK ((public.is_restaurant_owner(restaurant_id) AND public.restaurant_mfa_satisfied()));


--
-- Name: restaurant_claims claims_admin_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY claims_admin_read ON public.restaurant_claims FOR SELECT TO authenticated USING (public.is_platform_admin());


--
-- Name: restaurant_claims claims_own_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY claims_own_read ON public.restaurant_claims FOR SELECT TO authenticated USING ((( SELECT auth.uid() AS uid) = user_id));


--
-- Name: consent_log; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.consent_log ENABLE ROW LEVEL SECURITY;

--
-- Name: consent_log consent_log_own_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY consent_log_own_read ON public.consent_log FOR SELECT TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: consumer_subscriptions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.consumer_subscriptions ENABLE ROW LEVEL SECURITY;

--
-- Name: consumer_subscriptions consumer_subscriptions_own_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY consumer_subscriptions_own_read ON public.consumer_subscriptions FOR SELECT TO authenticated USING (((user_id = ( SELECT auth.uid() AS uid)) OR public.is_platform_admin()));


--
-- Name: device_push_tokens; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.device_push_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: directory_import_staging; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.directory_import_staging ENABLE ROW LEVEL SECURITY;

--
-- Name: favorites; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

--
-- Name: favorites favorites_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY favorites_own ON public.favorites TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid))) WITH CHECK (((user_id = ( SELECT auth.uid() AS uid)) AND (NOT public.is_user_blocked(( SELECT auth.uid() AS uid)))));


--
-- Name: status_history history_member_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY history_member_read ON public.status_history FOR SELECT TO authenticated USING (public.is_restaurant_member(restaurant_id));


--
-- Name: restaurant_live_status live_status_public_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY live_status_public_read ON public.restaurant_live_status FOR SELECT TO authenticated, anon USING ((EXISTS ( SELECT 1
   FROM public.restaurants r
  WHERE ((r.id = restaurant_live_status.restaurant_id) AND (r.partnership_status = 'ACTIVE_PARTNER'::public.partnership_status)))));


--
-- Name: notification_outbox; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.notification_outbox ENABLE ROW LEVEL SECURITY;

--
-- Name: notification_outbox outbox_own_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY outbox_own_read ON public.notification_outbox FOR SELECT TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: payments; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

--
-- Name: payments payments_payer_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY payments_payer_read ON public.payments FOR SELECT TO authenticated USING ((((payer_kind = 'RESTAURANT'::text) AND public.is_restaurant_owner(restaurant_id)) OR ((payer_kind = 'CONSUMER'::text) AND (user_id = ( SELECT auth.uid() AS uid))) OR public.is_platform_admin()));


--
-- Name: plan_expiry_notices; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.plan_expiry_notices ENABLE ROW LEVEL SECURITY;

--
-- Name: plans; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.plans ENABLE ROW LEVEL SECURITY;

--
-- Name: plans plans_admin_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY plans_admin_read ON public.plans FOR SELECT TO authenticated USING (public.is_platform_admin());


--
-- Name: plans plans_public_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY plans_public_read ON public.plans FOR SELECT TO authenticated, anon USING (is_public);


--
-- Name: profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: profiles profiles_own_or_admin_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profiles_own_or_admin_read ON public.profiles FOR SELECT TO authenticated USING (((id = ( SELECT auth.uid() AS uid)) OR public.is_platform_admin()));


--
-- Name: profiles profiles_own_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY profiles_own_update ON public.profiles FOR UPDATE TO authenticated USING ((id = ( SELECT auth.uid() AS uid))) WITH CHECK ((id = ( SELECT auth.uid() AS uid)));


--
-- Name: device_push_tokens push_tokens_own; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY push_tokens_own ON public.device_push_tokens TO authenticated USING ((user_id = ( SELECT auth.uid() AS uid))) WITH CHECK ((user_id = ( SELECT auth.uid() AS uid)));


--
-- Name: reservations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.reservations ENABLE ROW LEVEL SECURITY;

--
-- Name: reservations reservations_members_delete; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY reservations_members_delete ON public.reservations FOR DELETE TO authenticated USING (((public.restaurant_role(restaurant_id) IS NOT NULL) AND public.restaurant_mfa_satisfied()));


--
-- Name: reservations reservations_members_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY reservations_members_read ON public.reservations FOR SELECT TO authenticated USING (((public.restaurant_role(restaurant_id) IS NOT NULL) AND public.restaurant_mfa_satisfied()));


--
-- Name: reservations reservations_members_update; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY reservations_members_update ON public.reservations FOR UPDATE TO authenticated USING (((public.restaurant_role(restaurant_id) IS NOT NULL) AND public.restaurant_mfa_satisfied())) WITH CHECK (((public.restaurant_role(restaurant_id) IS NOT NULL) AND public.restaurant_mfa_satisfied() AND public.restaurant_has_feature(restaurant_id, 'RESERVATIONS_CLOUD'::text)));


--
-- Name: reservations reservations_members_write; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY reservations_members_write ON public.reservations FOR INSERT TO authenticated WITH CHECK (((public.restaurant_role(restaurant_id) IS NOT NULL) AND public.restaurant_mfa_satisfied() AND public.restaurant_has_feature(restaurant_id, 'RESERVATIONS_CLOUD'::text) AND (created_by = ( SELECT auth.uid() AS uid))));


--
-- Name: restaurant_billing_profiles; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.restaurant_billing_profiles ENABLE ROW LEVEL SECURITY;

--
-- Name: restaurant_claims; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.restaurant_claims ENABLE ROW LEVEL SECURITY;

--
-- Name: restaurant_daily_stats; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.restaurant_daily_stats ENABLE ROW LEVEL SECURITY;

--
-- Name: restaurant_live_status; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.restaurant_live_status ENABLE ROW LEVEL SECURITY;

--
-- Name: restaurant_subscriptions; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.restaurant_subscriptions ENABLE ROW LEVEL SECURITY;

--
-- Name: restaurant_subscriptions restaurant_subscriptions_member_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY restaurant_subscriptions_member_read ON public.restaurant_subscriptions FOR SELECT TO authenticated USING (((public.restaurant_role(restaurant_id) IS NOT NULL) OR public.is_platform_admin()));


--
-- Name: restaurant_users; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.restaurant_users ENABLE ROW LEVEL SECURITY;

--
-- Name: restaurant_users restaurant_users_member_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY restaurant_users_member_read ON public.restaurant_users FOR SELECT TO authenticated USING ((( SELECT auth.uid() AS uid) = user_id));


--
-- Name: restaurant_users restaurant_users_owner_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY restaurant_users_owner_read ON public.restaurant_users FOR SELECT TO authenticated USING ((public.is_restaurant_owner(restaurant_id) OR public.is_platform_admin()));


--
-- Name: restaurants; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.restaurants ENABLE ROW LEVEL SECURITY;

--
-- Name: restaurants restaurants_public_read; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY restaurants_public_read ON public.restaurants FOR SELECT TO authenticated, anon USING ((partnership_status <> 'SUSPENDED'::public.partnership_status));


--
-- Name: status_history; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.status_history ENABLE ROW LEVEL SECURITY;

--
-- Name: messages; Type: ROW SECURITY; Schema: realtime; Owner: -
--

ALTER TABLE realtime.messages ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets_analytics; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets_analytics ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets_vectors; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets_vectors ENABLE ROW LEVEL SECURITY;

--
-- Name: migrations; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: objects; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.s3_multipart_uploads ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads_parts; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.s3_multipart_uploads_parts ENABLE ROW LEVEL SECURITY;

--
-- Name: vector_indexes; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.vector_indexes ENABLE ROW LEVEL SECURITY;

--
-- Name: supabase_realtime; Type: PUBLICATION; Schema: -; Owner: -
--

CREATE PUBLICATION supabase_realtime WITH (publish = 'insert, update, delete, truncate');


--
-- Name: supabase_realtime_messages_publication; Type: PUBLICATION; Schema: -; Owner: -
--

CREATE PUBLICATION supabase_realtime_messages_publication WITH (publish = 'insert, update, delete, truncate');


--
-- Name: supabase_realtime restaurant_live_status; Type: PUBLICATION TABLE; Schema: public; Owner: -
--

ALTER PUBLICATION supabase_realtime ADD TABLE ONLY public.restaurant_live_status;


--
-- Name: supabase_realtime_messages_publication messages; Type: PUBLICATION TABLE; Schema: realtime; Owner: -
--

ALTER PUBLICATION supabase_realtime_messages_publication ADD TABLE ONLY realtime.messages;


--
-- Name: issue_graphql_placeholder; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_graphql_placeholder ON sql_drop
         WHEN TAG IN ('DROP EXTENSION')
   EXECUTE FUNCTION extensions.set_graphql_placeholder();


--
-- Name: issue_pg_cron_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_cron_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_cron_access();


--
-- Name: issue_pg_graphql_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_graphql_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_graphql_access();


--
-- Name: issue_pg_net_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_net_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_net_access();


--
-- Name: pgrst_ddl_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER pgrst_ddl_watch ON ddl_command_end
   EXECUTE FUNCTION extensions.pgrst_ddl_watch();


--
-- Name: pgrst_drop_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER pgrst_drop_watch ON sql_drop
   EXECUTE FUNCTION extensions.pgrst_drop_watch();


--
-- PostgreSQL database dump complete
--

\unrestrict bbD6Bg1sYE0VMd7XUWJF6AfktlfSLisQRPhhyPcpQHQusLBt1azvqJwha60tyqg

