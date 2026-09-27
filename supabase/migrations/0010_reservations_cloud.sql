-- HAPOSTO — Registro prenotazioni di sala sincronizzato (funzione PRO, facoltativa).
--
-- Esegui DOPO 0009.
-- Oggi l'app salva le prenotazioni solo sul telefono. Questa tabella serve quando il locale vuole
-- condividerle tra più dispositivi della sala. NON è una prenotazione fatta dal cliente: è il
-- quaderno interno del ristorante. Contiene dati personali di clienti: accesso solo ai membri del
-- locale e cancellazione automatica dopo 30 giorni (minimizzazione GDPR).

create table if not exists public.reservations (
    id uuid primary key default gen_random_uuid(),
    restaurant_id uuid not null references public.restaurants(id) on delete cascade,
    -- Id generato dal telefono: rende idempotente la sincronizzazione offline.
    client_id uuid not null,
    reservation_date date not null,
    reservation_time time,
    party_size smallint not null check (party_size between 1 and 99),
    customer_name text not null check (char_length(customer_name) between 1 and 80),
    customer_phone text check (customer_phone is null or char_length(customer_phone) between 3 and 30),
    table_label text check (table_label is null or char_length(table_label) <= 20),
    note text check (note is null or char_length(note) <= 200),
    status text not null default 'BOOKED' check (status in ('BOOKED', 'SEATED', 'NO_SHOW', 'CANCELED')),
    source text not null default 'PHONE' check (source in ('PHONE', 'WALK_IN', 'WHATSAPP', 'OTHER')),
    created_by uuid references auth.users(id) on delete set null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (restaurant_id, client_id)
);

create index if not exists reservations_restaurant_day_idx
    on public.reservations (restaurant_id, reservation_date, reservation_time);

drop trigger if exists reservations_touch on public.reservations;
create trigger reservations_touch
    before update on public.reservations
    for each row execute function public.touch_updated_at();

alter table public.reservations enable row level security;
revoke all on table public.reservations from anon, authenticated;
grant select, insert, update, delete on table public.reservations to authenticated;

drop policy if exists "reservations_members_read" on public.reservations;
create policy "reservations_members_read"
on public.reservations
for select
to authenticated
using (public.restaurant_role(restaurant_id) is not null);

drop policy if exists "reservations_members_write" on public.reservations;
create policy "reservations_members_write"
on public.reservations
for insert
to authenticated
with check (
    public.restaurant_role(restaurant_id) is not null
    and public.restaurant_has_feature(restaurant_id, 'RESERVATIONS_CLOUD')
    and created_by = (select auth.uid())
);

drop policy if exists "reservations_members_update" on public.reservations;
create policy "reservations_members_update"
on public.reservations
for update
to authenticated
using (public.restaurant_role(restaurant_id) is not null)
with check (
    public.restaurant_role(restaurant_id) is not null
    and public.restaurant_has_feature(restaurant_id, 'RESERVATIONS_CLOUD')
);

drop policy if exists "reservations_members_delete" on public.reservations;
create policy "reservations_members_delete"
on public.reservations
for delete
to authenticated
using (public.restaurant_role(restaurant_id) is not null);

-- Cancellazione automatica (da pianificare con pg_cron, es. ogni notte alle 04:00).
create or replace function public.purge_old_reservations(p_keep_days integer default 30)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_count integer;
begin
    delete from public.reservations
    where reservation_date < current_date - greatest(p_keep_days, 1);
    get diagnostics v_count = row_count;
    return v_count;
end;
$$;

revoke execute on function public.purge_old_reservations(integer) from public, anon, authenticated;
grant execute on function public.purge_old_reservations(integer) to service_role;
