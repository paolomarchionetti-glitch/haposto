-- HAPOSTO STEP 7 — RLS + explicit least-privilege grants.
-- Current Supabase guidance treats grants and policies as separate layers, so revoke first.

alter table public.restaurants enable row level security;
alter table public.restaurant_live_status enable row level security;
alter table public.restaurant_users enable row level security;
alter table public.restaurant_claims enable row level security;
alter table public.status_history enable row level security;

revoke all on table public.restaurants from anon, authenticated;
revoke all on table public.restaurant_live_status from anon, authenticated;
revoke all on table public.restaurant_users from anon, authenticated;
revoke all on table public.restaurant_claims from anon, authenticated;
revoke all on table public.status_history from anon, authenticated;

create policy "restaurants_public_read"
on public.restaurants
for select
to anon, authenticated
using (partnership_status <> 'SUSPENDED');

create policy "live_status_public_read"
on public.restaurant_live_status
for select
to anon, authenticated
using (
    exists (
        select 1
        from public.restaurants r
        where r.id = restaurant_id
          and r.partnership_status = 'ACTIVE_PARTNER'
    )
);

create policy "restaurant_users_member_read"
on public.restaurant_users
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "claims_own_read"
on public.restaurant_claims
for select
to authenticated
using ((select auth.uid()) = user_id);

create policy "claims_own_insert"
on public.restaurant_claims
for insert
to authenticated
with check ((select auth.uid()) = user_id and status = 'PENDING');

create policy "history_member_read"
on public.status_history
for select
to authenticated
using (public.is_restaurant_member(restaurant_id));

-- Direct live-status writes are intentionally not granted to mobile roles.
-- Authenticated restaurant writes will go through set_restaurant_live_status() in STEP 9.
grant select (
    id, name, category, address, city, province, postal_code,
    partnership_status, created_at, updated_at, phone_public
) on public.restaurants to anon, authenticated;

grant select on public.restaurant_live_status to anon, authenticated;
grant select on public.restaurant_users to authenticated;
grant select, insert on public.restaurant_claims to authenticated;
grant select on public.status_history to authenticated;

revoke all on function public.nearby_restaurants(double precision, double precision, integer, text) from public;
revoke all on function public.set_restaurant_live_status(uuid, public.live_status, smallint, smallint, varchar) from public;
revoke all on function public.is_restaurant_member(uuid) from public;

grant execute on function public.nearby_restaurants(double precision, double precision, integer, text)
    to anon, authenticated;

grant execute on function public.set_restaurant_live_status(uuid, public.live_status, smallint, smallint, varchar)
    to authenticated;

grant execute on function public.is_restaurant_member(uuid)
    to authenticated;
