-- HAPOSTO STEP 10 ONLY — DO NOT RUN IN STEP 7.
-- Before running, verify in Dashboard > Database > Publications whether this table is already
-- part of supabase_realtime. Add it only if it is not already present.

alter publication supabase_realtime add table public.restaurant_live_status;
