-- HAPOSTO STEP 7 — extensions.
-- Run once on a fresh Supabase DEV project before every other migration.

create extension if not exists postgis with schema extensions;
create extension if not exists pg_trgm with schema extensions;
