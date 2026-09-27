-- HAPOSTO — SEED DEV "PSEUDO-REALISTICO" (36 locali FITTIZI tra Pesaro, Fano, Urbino, Gabicce Mare).
--
-- Richiede le migration 0001–0004 e 0006 (colonna data_source). Rieseguibile.
-- Nomi, telefoni e stati sono INVENTATI: nessun locale reale è coinvolto. Le vie sono reali solo
-- per rendere credibili gli indirizzi. Ogni riga è marcata data_source = 'DEV_SEED' e si cancella
-- con supabase/dev/dev_purge.sql prima di andare in produzione.
--
-- Alcuni stati sono già scaduti apposta (es. "Ristorante Tre Porte", "Il Lido Veg"): l'app deve
-- mostrarli come "Da aggiornare". Il simulatore (supabase/dev/dev_tools.sql) li fa evolvere nel tempo.

-- Anche il seed dimostrativo dello Step 7 è dato di test.
update public.restaurants set data_source = 'DEV_SEED'
where id::text like '10000000-0000-0000-0000-%' and data_source <> 'DEV_SEED';

insert into public.restaurants (
    id, name, category, address, city, province, location, phone_number, phone_public,
    partnership_status, data_source
) values
    ('20000000-0000-0000-0000-000000000001', 'Osteria del Fanale Verde', 'Cucina di mare', 'Via Rossini 41', 'Pesaro', 'PU',
     extensions.st_point(12.9131, 43.9112)::extensions.geography, '+390721000101', true, 'ACTIVE_PARTNER', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000002', 'Trattoria Nonna Adelmina', 'Trattoria', 'Via Branca 18', 'Pesaro', 'PU',
     extensions.st_point(12.9147, 43.9091)::extensions.geography, '+390721000102', true, 'ACTIVE_PARTNER', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000003', 'Pizzeria Forno a Legna Sfera', 'Pizzeria', 'Viale della Repubblica 7', 'Pesaro', 'PU',
     extensions.st_point(12.9109, 43.9138)::extensions.geography, '+390721000103', true, 'ACTIVE_PARTNER', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000004', 'Bottega della Piadina Rossiniana', 'Piadineria', 'Via San Francesco 22', 'Pesaro', 'PU',
     extensions.st_point(12.9118, 43.91)::extensions.geography, null, false, 'ACTIVE_PARTNER', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000005', 'Sushi Onda Adriatica', 'Sushi', 'Viale Trieste 120', 'Pesaro', 'PU',
     extensions.st_point(12.9053, 43.9161)::extensions.geography, '+390721000105', true, 'ACTIVE_PARTNER', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000006', 'Il Molo di Levante', 'Pesce', 'Via Mameli 60', 'Pesaro', 'PU',
     extensions.st_point(12.9185, 43.916)::extensions.geography, '+390721000106', true, 'ACTIVE_PARTNER', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000007', 'Braceria Monte Ardizio', 'Carne e griglia', 'Strada Panoramica Ardizio 12', 'Pesaro', 'PU',
     extensions.st_point(12.9265, 43.9023)::extensions.geography, '+390721000107', true, 'ACTIVE_PARTNER', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000008', 'Verde Pisello Bistrot', 'Vegetariana', 'Via Cavour 9', 'Pesaro', 'PU',
     extensions.st_point(12.9126, 43.9094)::extensions.geography, null, false, 'ACTIVE_PARTNER', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000009', 'Enoteca Taverna del Corso', 'Enoteca con cucina', 'Corso XI Settembre 88', 'Pesaro', 'PU',
     extensions.st_point(12.9097, 43.9107)::extensions.geography, '+390721000109', true, 'ACTIVE_PARTNER', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000010', 'Burger Lab Baia Flaminia', 'Hamburger', 'Viale Varsavia 30', 'Pesaro', 'PU',
     extensions.st_point(12.8958, 43.911)::extensions.geography, null, false, 'ACTIVE_PARTNER', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000011', 'Pasta Fresca Villa Fastiggi', 'Pasta fresca', 'Via Fastiggi 3', 'Pesaro', 'PU',
     extensions.st_point(12.8905, 43.8975)::extensions.geography, '+390721000111', true, 'ACTIVE_PARTNER', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000012', 'Ristorante Tre Porte', 'Cucina marchigiana', 'Via Passeri 70', 'Pesaro', 'PU',
     extensions.st_point(12.9161, 43.9085)::extensions.geography, '+390721000112', true, 'ACTIVE_PARTNER', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000013', 'Pizzeria Soria Napoletana', 'Pizzeria', 'Via Solferino 15', 'Pesaro', 'PU',
     extensions.st_point(12.908, 43.9062)::extensions.geography, null, false, 'ACTIVE_PARTNER', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000014', 'Locanda del Foglia', 'Trattoria', 'Via Lungofoglia 5', 'Pesaro', 'PU',
     extensions.st_point(12.902, 43.9055)::extensions.geography, null, false, 'DIRECTORY_ONLY', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000015', 'Chiosco Spiaggia di Levante', 'Cucina di mare', 'Lungomare Nazario Sauro 40', 'Pesaro', 'PU',
     extensions.st_point(12.9205, 43.915)::extensions.geography, null, false, 'DIRECTORY_ONLY', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000016', 'Gastronomia Il Pozzo', 'Gastronomia', 'Via Mazzolari 4', 'Pesaro', 'PU',
     extensions.st_point(12.9109, 43.9079)::extensions.geography, null, false, 'DIRECTORY_ONLY', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000017', 'Kebab & Falafel Mediterraneo', 'Etnico', 'Via Giusti 12', 'Pesaro', 'PU',
     extensions.st_point(12.9135, 43.9046)::extensions.geography, null, false, 'DIRECTORY_ONLY', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000018', 'Osteria Muraglia', 'Osteria', 'Via Diaz 33', 'Pesaro', 'PU',
     extensions.st_point(12.918, 43.899)::extensions.geography, '+390721000118', true, 'PAUSED', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000019', 'Trattoria del Brodetto Fanese', 'Cucina di mare', 'Via Garibaldi 25', 'Fano', 'PU',
     extensions.st_point(13.0193, 43.8436)::extensions.geography, '+390721000201', true, 'ACTIVE_PARTNER', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000020', 'Pizzeria Arco d''Augusto', 'Pizzeria', 'Via Arco d''Augusto 14', 'Fano', 'PU',
     extensions.st_point(13.0161, 43.8428)::extensions.geography, null, false, 'ACTIVE_PARTNER', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000021', 'Moretta Caffè e Cucina', 'Bistrot', 'Piazza XX Settembre 3', 'Fano', 'PU',
     extensions.st_point(13.0184, 43.8433)::extensions.geography, '+390721000203', true, 'ACTIVE_PARTNER', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000022', 'Sassonia Pesce Crudo', 'Pesce', 'Viale Adriatico 50', 'Fano', 'PU',
     extensions.st_point(13.024, 43.8405)::extensions.geography, '+390721000204', true, 'ACTIVE_PARTNER', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000023', 'Il Lido Veg', 'Vegetariana', 'Viale Cairoli 18', 'Fano', 'PU',
     extensions.st_point(13.0205, 43.8458)::extensions.geography, null, false, 'ACTIVE_PARTNER', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000024', 'Osteria Porto Borghetto', 'Osteria', 'Via del Moletto 7', 'Fano', 'PU',
     extensions.st_point(13.018, 43.8462)::extensions.geography, '+390721000206', true, 'ACTIVE_PARTNER', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000025', 'Piadineria Malatesta', 'Piadineria', 'Corso Matteotti 90', 'Fano', 'PU',
     extensions.st_point(13.0147, 43.844)::extensions.geography, null, false, 'DIRECTORY_ONLY', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000026', 'Ristorante Pincio', 'Cucina marchigiana', 'Via Pincio 2', 'Fano', 'PU',
     extensions.st_point(13.0128, 43.8418)::extensions.geography, null, false, 'DIRECTORY_ONLY', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000027', 'Osteria del Duca', 'Cucina marchigiana', 'Via Raffaello 21', 'Urbino', 'PU',
     extensions.st_point(12.6352, 43.7264)::extensions.geography, '+390722000301', true, 'ACTIVE_PARTNER', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000028', 'Crescia & Vino Montefeltro', 'Enoteca con cucina', 'Via Mazzini 40', 'Urbino', 'PU',
     extensions.st_point(12.6378, 43.7246)::extensions.geography, null, false, 'ACTIVE_PARTNER', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000029', 'Pizzeria Mercatale', 'Pizzeria', 'Borgo Mercatale 6', 'Urbino', 'PU',
     extensions.st_point(12.636, 43.7232)::extensions.geography, '+390722000303', true, 'ACTIVE_PARTNER', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000030', 'Trattoria Palazzo Ducale', 'Trattoria', 'Via Puccinotti 11', 'Urbino', 'PU',
     extensions.st_point(12.6358, 43.7243)::extensions.geography, null, false, 'CLAIM_PENDING', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000031', 'Mensa Studenti Aperta', 'Self-service', 'Via Saffi 30', 'Urbino', 'PU',
     extensions.st_point(12.6394, 43.727)::extensions.geography, null, false, 'DIRECTORY_ONLY', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000032', 'Terrazza sul Porto Gabicce', 'Pesce', 'Via del Porto 12', 'Gabicce Mare', 'PU',
     extensions.st_point(12.7581, 43.9651)::extensions.geography, '+390541000401', true, 'ACTIVE_PARTNER', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000033', 'Pizzeria Gradara Vista', 'Pizzeria', 'Viale della Vittoria 28', 'Gabicce Mare', 'PU',
     extensions.st_point(12.7552, 43.9638)::extensions.geography, null, false, 'ACTIVE_PARTNER', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000034', 'Beach Bistrot Castello', 'Bistrot', 'Via Vittorio Veneto 90', 'Gabicce Mare', 'PU',
     extensions.st_point(12.7536, 43.9644)::extensions.geography, '+390541000403', true, 'ACTIVE_PARTNER', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000035', 'Grigliata del Colle', 'Carne e griglia', 'Via Panoramica 5', 'Gabicce Mare', 'PU',
     extensions.st_point(12.7605, 43.9612)::extensions.geography, null, false, 'DIRECTORY_ONLY', 'DEV_SEED'),
    ('20000000-0000-0000-0000-000000000036', 'Gelateria Cucina Sole', 'Bistrot', 'Via Cesare Battisti 3', 'Gabicce Mare', 'PU',
     extensions.st_point(12.757, 43.9648)::extensions.geography, null, false, 'ACTIVE_PARTNER', 'DEV_SEED')
on conflict (id) do update set
    name = excluded.name,
    category = excluded.category,
    address = excluded.address,
    city = excluded.city,
    province = excluded.province,
    location = excluded.location,
    phone_number = excluded.phone_number,
    phone_public = excluded.phone_public,
    partnership_status = excluded.partnership_status,
    data_source = excluded.data_source;

insert into public.restaurant_live_status (
    restaurant_id, status, available_tables, estimated_wait_minutes, note, updated_at, valid_until, updated_via
) values
    ('20000000-0000-0000-0000-000000000001', 'AVAILABLE', 4, 0, 'Tavoli anche all''aperto', now() - interval '4 minutes', now() - interval '4 minutes' + interval '30 minutes', 'DEV_SIMULATOR'),
    ('20000000-0000-0000-0000-000000000002', 'LIMITED', 1, 10, 'Ultimi tavoli per 2', now() - interval '9 minutes', now() - interval '9 minutes' + interval '30 minutes', 'DEV_SIMULATOR'),
    ('20000000-0000-0000-0000-000000000003', 'FULL', null, 30, 'Pieno fino alle 21:30', now() - interval '2 minutes', now() - interval '2 minutes' + interval '30 minutes', 'DEV_SIMULATOR'),
    ('20000000-0000-0000-0000-000000000004', 'AVAILABLE', 6, 0, null, now() - interval '12 minutes', now() - interval '12 minutes' + interval '30 minutes', 'DEV_SIMULATOR'),
    ('20000000-0000-0000-0000-000000000005', 'AVAILABLE', 3, null, null, now() - interval '6 minutes', now() - interval '6 minutes' + interval '30 minutes', 'DEV_SIMULATOR'),
    ('20000000-0000-0000-0000-000000000006', 'LIMITED', 2, 15, 'Solo sala interna', now() - interval '17 minutes', now() - interval '17 minutes' + interval '30 minutes', 'DEV_SIMULATOR'),
    ('20000000-0000-0000-0000-000000000007', 'AVAILABLE', 5, null, 'Terrazza panoramica', now() - interval '22 minutes', now() - interval '22 minutes' + interval '30 minutes', 'DEV_SIMULATOR'),
    ('20000000-0000-0000-0000-000000000008', 'AVAILABLE', 2, null, null, now() - interval '1 minutes', now() - interval '1 minutes' + interval '30 minutes', 'DEV_SIMULATOR'),
    ('20000000-0000-0000-0000-000000000009', 'FULL', null, 20, null, now() - interval '5 minutes', now() - interval '5 minutes' + interval '30 minutes', 'DEV_SIMULATOR'),
    ('20000000-0000-0000-0000-000000000010', 'AVAILABLE', 8, null, 'Posti anche al bancone', now() - interval '14 minutes', now() - interval '14 minutes' + interval '30 minutes', 'DEV_SIMULATOR'),
    ('20000000-0000-0000-0000-000000000012', 'AVAILABLE', 3, null, null, now() - interval '48 minutes', now() - interval '48 minutes' + interval '30 minutes', 'DEV_SIMULATOR'),
    ('20000000-0000-0000-0000-000000000013', 'LIMITED', 1, 20, null, now() - interval '8 minutes', now() - interval '8 minutes' + interval '30 minutes', 'DEV_SIMULATOR'),
    ('20000000-0000-0000-0000-000000000019', 'AVAILABLE', 4, null, 'Brodetto disponibile', now() - interval '3 minutes', now() - interval '3 minutes' + interval '30 minutes', 'DEV_SIMULATOR'),
    ('20000000-0000-0000-0000-000000000020', 'FULL', null, 25, null, now() - interval '6 minutes', now() - interval '6 minutes' + interval '30 minutes', 'DEV_SIMULATOR'),
    ('20000000-0000-0000-0000-000000000021', 'LIMITED', 1, 5, 'Solo tavoli fuori', now() - interval '11 minutes', now() - interval '11 minutes' + interval '30 minutes', 'DEV_SIMULATOR'),
    ('20000000-0000-0000-0000-000000000022', 'AVAILABLE', 6, 0, null, now() - interval '2 minutes', now() - interval '2 minutes' + interval '30 minutes', 'DEV_SIMULATOR'),
    ('20000000-0000-0000-0000-000000000023', 'AVAILABLE', 2, null, null, now() - interval '33 minutes', now() - interval '33 minutes' + interval '30 minutes', 'DEV_SIMULATOR'),
    ('20000000-0000-0000-0000-000000000027', 'AVAILABLE', 3, null, 'Crescia sfogliata', now() - interval '7 minutes', now() - interval '7 minutes' + interval '30 minutes', 'DEV_SIMULATOR'),
    ('20000000-0000-0000-0000-000000000028', 'LIMITED', 1, 15, null, now() - interval '4 minutes', now() - interval '4 minutes' + interval '30 minutes', 'DEV_SIMULATOR'),
    ('20000000-0000-0000-0000-000000000029', 'AVAILABLE', 5, null, null, now() - interval '19 minutes', now() - interval '19 minutes' + interval '30 minutes', 'DEV_SIMULATOR'),
    ('20000000-0000-0000-0000-000000000032', 'FULL', null, 40, 'Solo asporto', now() - interval '3 minutes', now() - interval '3 minutes' + interval '30 minutes', 'DEV_SIMULATOR'),
    ('20000000-0000-0000-0000-000000000033', 'AVAILABLE', 4, null, null, now() - interval '10 minutes', now() - interval '10 minutes' + interval '30 minutes', 'DEV_SIMULATOR'),
    ('20000000-0000-0000-0000-000000000034', 'LIMITED', 2, 10, null, now() - interval '15 minutes', now() - interval '15 minutes' + interval '30 minutes', 'DEV_SIMULATOR'),
    ('20000000-0000-0000-0000-000000000036', 'AVAILABLE', 3, null, null, now() - interval '26 minutes', now() - interval '26 minutes' + interval '30 minutes', 'DEV_SIMULATOR')
on conflict (restaurant_id) do update set
    status = excluded.status,
    available_tables = excluded.available_tables,
    estimated_wait_minutes = excluded.estimated_wait_minutes,
    note = excluded.note,
    updated_at = excluded.updated_at,
    valid_until = excluded.valid_until,
    updated_via = excluded.updated_via;
