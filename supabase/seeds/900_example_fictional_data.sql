-- HAPOSTO STEP 7 — OPTIONAL DEV SEED.
-- Every restaurant below is fictional. Safe to use only for development/testing.

insert into public.restaurants (
    id, name, category, address, city, province, postal_code,
    location, phone_number, phone_public, partnership_status
) values
(
    '10000000-0000-0000-0000-000000000001',
    'Osteria Levante Demo',
    'Cucina italiana',
    'Via Demo 12',
    'Pesaro', 'PU', '61121',
    extensions.st_point(12.9149, 43.9102)::extensions.geography,
    '+390721000001', true, 'ACTIVE_PARTNER'
),
(
    '10000000-0000-0000-0000-000000000002',
    'Porto 46 Demo',
    'Pesce',
    'Viale Esempio 46',
    'Pesaro', 'PU', '61121',
    extensions.st_point(12.9004, 43.9173)::extensions.geography,
    null, false, 'ACTIVE_PARTNER'
),
(
    '10000000-0000-0000-0000-000000000003',
    'Corte Adriatica Demo',
    'Contemporanea',
    'Piazza Demo 8',
    'Pesaro', 'PU', '61121',
    extensions.st_point(12.9120, 43.9090)::extensions.geography,
    null, false, 'ACTIVE_PARTNER'
),
(
    '10000000-0000-0000-0000-000000000004',
    'Casa Miralfiore Demo',
    'Tradizionale',
    'Via Scenario 5',
    'Pesaro', 'PU', '61121',
    extensions.st_point(12.9081, 43.9003)::extensions.geography,
    null, false, 'ACTIVE_PARTNER'
),
(
    '10000000-0000-0000-0000-000000000005',
    'Riva 27 Demo',
    'Mediterranea',
    'Lungomare Demo 27',
    'Pesaro', 'PU', '61121',
    extensions.st_point(12.8985, 43.9210)::extensions.geography,
    null, false, 'DIRECTORY_ONLY'
),
(
    '10000000-0000-0000-0000-000000000006',
    'Linea Cucina Demo',
    'Vegetariana',
    'Via Campione 14',
    'Fano', 'PU', '61032',
    extensions.st_point(13.0178, 43.8411)::extensions.geography,
    null, false, 'ACTIVE_PARTNER'
),
(
    '10000000-0000-0000-0000-000000000007',
    'Civico Zero Demo',
    'Bistrot',
    'Via Placeholder 1',
    'Urbino', 'PU', '61029',
    extensions.st_point(12.6388, 43.7261)::extensions.geography,
    null, false, 'ACTIVE_PARTNER'
)
on conflict (id) do update set
    name = excluded.name,
    category = excluded.category,
    address = excluded.address,
    city = excluded.city,
    province = excluded.province,
    postal_code = excluded.postal_code,
    location = excluded.location,
    phone_number = excluded.phone_number,
    phone_public = excluded.phone_public,
    partnership_status = excluded.partnership_status,
    updated_at = now();

insert into public.restaurant_live_status (
    restaurant_id, status, available_tables, estimated_wait_minutes, note, updated_at, valid_until
) values
(
    '10000000-0000-0000-0000-000000000001', 'AVAILABLE', 4, 0,
    'Disponibili anche tavoli all''esterno', now() - interval '3 minutes', now() + interval '27 minutes'
),
(
    '10000000-0000-0000-0000-000000000002', 'LIMITED', 1, 10,
    'Ultimi tavoli per piccoli gruppi', now() - interval '7 minutes', now() + interval '23 minutes'
),
(
    '10000000-0000-0000-0000-000000000003', 'FULL', null, 20,
    null, now() - interval '2 minutes', now() + interval '28 minutes'
),
(
    '10000000-0000-0000-0000-000000000004', 'AVAILABLE', 3, null,
    null, now() - interval '41 minutes', now() - interval '11 minutes'
),
(
    '10000000-0000-0000-0000-000000000006', 'AVAILABLE', 5, null,
    'Servizio cena iniziato', now() - interval '1 minute', now() + interval '29 minutes'
)
on conflict (restaurant_id) do update set
    status = excluded.status,
    available_tables = excluded.available_tables,
    estimated_wait_minutes = excluded.estimated_wait_minutes,
    note = excluded.note,
    updated_at = excluded.updated_at,
    valid_until = excluded.valid_until;
