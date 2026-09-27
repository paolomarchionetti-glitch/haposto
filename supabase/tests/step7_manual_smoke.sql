-- HAPOSTO STEP 7 — manual smoke checks for Supabase SQL Editor.
-- Run AFTER migrations 0001-0004 and optional seed 900_example_fictional_data.sql.
-- Read-only: this file performs SELECT checks only.

-- 1. Required extensions must exist in extensions schema.
select extname, n.nspname as schema_name
from pg_extension e
join pg_namespace n on n.oid = e.extnamespace
where extname in ('postgis', 'pg_trgm')
order by extname;

-- 2. Required tables must exist and RLS must be enabled.
select c.relname as table_name, c.relrowsecurity as rls_enabled
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in (
      'restaurants', 'restaurant_live_status', 'restaurant_users',
      'restaurant_claims', 'status_history'
  )
order by c.relname;

-- 3. Seed overview.
select id, name, category, city, partnership_status, phone_public
from public.restaurants
order by city, name;

-- 4. PostGIS distance + LIVE rows around Pesaro.
select *
from public.nearby_restaurants(43.9125, 12.9138, 60000, null)
limit 20;

-- 5. Server-side fuzzy/text search capability.
select id, name, category, city, distance_meters
from public.nearby_restaurants(43.9125, 12.9138, 60000, 'levante');

-- 6. V1 constraint check: no FULL row may expose free tables.
select count(*) as invalid_full_rows
from public.restaurant_live_status
where status = 'FULL' and available_tables is not null;

-- Expected invalid_full_rows = 0.
