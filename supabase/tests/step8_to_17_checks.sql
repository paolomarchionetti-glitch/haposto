-- HAPOSTO — Verifica automatica di permessi (RLS) e regole di business delle migration 0006–0011.
--
-- Cosa fa: impersona a turno visitatore anonimo, ristoratore, staff, utente, amministratore e
-- server dei pagamenti, e controlla che ognuno possa fare SOLO ciò che deve.
-- Tutto avviene dentro una transazione annullata alla fine (ROLLBACK): non lascia tracce.
--
-- Prerequisito: 0001–0004 + 0006–0011 eseguite, seed 900 caricato.
-- Su Supabase crea prima 5 utenti di prova (Authentication → Users → Add user, "Auto Confirm"):
--   test-admin@haposto.test, test-owner@haposto.test, test-staff@haposto.test,
--   test-user@haposto.test, test-user2@haposto.test
-- (In locale, se non esistono, lo script li crea da sé.)
--
-- Esito atteso: tante righe "NOTICE: ok: …" e, in fondo, "TUTTI I CONTROLLI SUPERATI".
-- Al primo errore lo script si ferma con "FAIL: …" e annulla tutto.

begin;

-- Impersona un utente come farebbe Supabase: token con sub, ruolo, livello di autenticazione
-- (aal2 = ha usato la 2FA) e id della sessione del telefono.
create function pg_temp.act_as(p_email text, p_aal text default 'aal2') returns void language plpgsql as $$
declare
    v_id uuid;
begin
    if p_email = 'postgres' then
        execute 'reset role';
        perform set_config('request.jwt.claim.sub', '', true);
        perform set_config('request.jwt.claims', '', true);
    elsif p_email is null then
        perform set_config('request.jwt.claim.sub', '', true);
        perform set_config('request.jwt.claims', '{"role": "anon"}', true);
        execute 'set local role anon';
    elsif p_email = 'service_role' then
        perform set_config('request.jwt.claim.sub', '', true);
        perform set_config('request.jwt.claims', '{"role": "service_role"}', true);
        execute 'set local role service_role';
    else
        execute 'reset role';
        select id into v_id from auth.users where email = p_email;
        perform set_config('request.jwt.claim.sub', v_id::text, true);
        perform set_config('request.jwt.claims',
            json_build_object('sub', v_id, 'role', 'authenticated', 'aal', p_aal,
                              'session_id', 'sessione-di-prova-' || v_id)::text, true);
        execute 'set local role authenticated';
    end if;
end;
$$;

create function pg_temp.uid(p_email text) returns uuid language sql security definer as $$
    select id from auth.users where email = p_email
$$;

create function pg_temp.expect(p_ok boolean, p_what text) returns void language plpgsql as $$
begin
    if p_ok is distinct from true then
        raise exception 'FAIL: %', p_what;
    end if;
    raise notice 'ok: %', p_what;
end;
$$;

-- Esegue un'istruzione che DEVE fallire; se contiene p_error, verifica anche il messaggio.
create function pg_temp.expect_error(p_sql text, p_error text, p_what text) returns void language plpgsql as $$
begin
    begin
        execute p_sql;
    exception when others then
        if p_error is not null and position(p_error in sqlerrm) = 0 then
            raise exception 'FAIL: % (errore inatteso: %)', p_what, sqlerrm;
        end if;
        raise notice 'ok: % (rifiutato: %)', p_what, sqlerrm;
        return;
    end;
    raise exception 'FAIL: % (doveva essere rifiutato)', p_what;
end;
$$;

-- ---------------------------------------------------------------------------
-- 0. Utenti di prova (creati solo se mancano) e amministratore.
-- ---------------------------------------------------------------------------
do $$
declare
    v_email text;
begin
    foreach v_email in array array['test-admin@haposto.test', 'test-owner@haposto.test',
                                   'test-staff@haposto.test', 'test-user@haposto.test',
                                   'test-user2@haposto.test'] loop
        if not exists (select 1 from auth.users where email = v_email) then
            insert into auth.users (id, email, raw_user_meta_data)
            values (gen_random_uuid(), v_email, jsonb_build_object('full_name', split_part(v_email, '@', 1)));
        end if;
    end loop;
end;
$$;

select pg_temp.expect(
    (select count(*) from public.profiles p join auth.users u on u.id = p.id
     where u.email like 'test-%@haposto.test') = 5,
    'ogni utente registrato ha un profilo (trigger on_auth_user_created)');

-- Credenziali del pannello admin (seconda password) per l'account amministratore di prova.
select public.admin_set_credentials('test-admin@haposto.test', 'test.admin', 'password-di-prova-123');

-- Beta attiva per i test che seguono.
update public.app_config
set value = '{"restaurants_all_pro_until": "2099-01-01T00:00:00Z"}'
where key = 'beta';

-- ---------------------------------------------------------------------------
-- 1. Visitatore anonimo (l'app senza login).
-- ---------------------------------------------------------------------------
select pg_temp.act_as(null);
select pg_temp.expect((select count(*) from public.nearby_restaurants(43.9125, 12.9138, 60000, null)) >= 1,
    'anon: vede la directory vicina');
select pg_temp.expect((select count(*) from public.plans) = 4, 'anon: vede i 4 piani pubblici (Pro+ nascosto)');
select pg_temp.expect((select plan_code from public.my_entitlements()) = 'CONSUMER_FREE', 'anon: piano Gratis');
select pg_temp.expect((select value ->> 'restaurants_all_pro_until' from public.app_config where key = 'beta') is not null,
    'anon: legge la configurazione pubblica');
select pg_temp.expect((select name from public.public_restaurant_page('osteria-levante-demo-pesaro')) = 'Osteria Levante Demo',
    'anon: apre la pagina pubblica dallo slug');
select public.track_restaurant_event('10000000-0000-0000-0000-000000000001', 'DETAIL_VIEW');
select pg_temp.expect_error(
    $q$select public.set_restaurant_live_status('10000000-0000-0000-0000-000000000001', 'FULL')$q$,
    'permission denied', 'anon: non può pubblicare stati');
select pg_temp.expect_error($q$select count(*) from public.profiles$q$, 'permission denied', 'anon: non legge i profili');
select pg_temp.expect_error($q$select count(*) from public.payments$q$, 'permission denied', 'anon: non legge i pagamenti');
select pg_temp.expect_error(
    $q$select public.track_restaurant_event('10000000-0000-0000-0000-000000000001', 'HACK')$q$,
    'INVALID_EVENT', 'anon: evento statistico non valido rifiutato');

-- ---------------------------------------------------------------------------
-- 2. Ristoratore: richiesta di gestione (claim) di un locale "solo directory".
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-owner@haposto.test');
select public.submit_restaurant_claim('10000000-0000-0000-0000-000000000005', '+39 0721 000555');
select pg_temp.expect((select count(*) from public.restaurant_claims where status = 'PENDING') = 1,
    'titolare: vede la propria richiesta in verifica');
select pg_temp.expect_error(
    $q$select public.submit_restaurant_claim('10000000-0000-0000-0000-000000000005', '+39 0721 000555')$q$,
    'CLAIM_ALREADY_PENDING', 'titolare: niente richieste doppie');
select pg_temp.expect_error(
    $q$select public.admin_review_claim((select id from public.restaurant_claims limit 1), true)$q$,
    'ADMIN_REQUIRED', 'titolare: non può auto-approvarsi');
select pg_temp.expect_error(
    $q$select public.set_restaurant_live_status('10000000-0000-0000-0000-000000000005', 'AVAILABLE')$q$,
    'Not authorized', 'titolare: prima dell''approvazione non pubblica');
select pg_temp.expect_error(
    $q$update public.profiles set is_platform_admin = true where id = auth.uid()$q$,
    'permission denied', 'titolare: non può farsi amministratore');

select pg_temp.act_as(null);
select pg_temp.expect(
    (select partnership_status from public.nearby_restaurants(43.9125, 12.9138, 60000, null)
     where id = '10000000-0000-0000-0000-000000000005') = 'CLAIM_PENDING',
    'pubblico: il locale risulta "in verifica" (l''app lo mostra come non collegato)');

-- ---------------------------------------------------------------------------
-- 3. Amministratore: approva.
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-admin@haposto.test');
select pg_temp.expect((select ok from public.admin_unlock('test.admin', 'password-di-prova-123')),
    'admin: sblocca il pannello con la seconda password');
select pg_temp.expect((select count(*) from public.admin_pending_claims()) = 1, 'admin: vede le richieste in attesa');
select public.admin_review_claim(
    (select claim_id from public.admin_pending_claims() limit 1), true,
    'Verificato di persona con documento', true);

select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.expect((select role::text from public.my_restaurants() limit 1) = 'OWNER', 'titolare: ora è OWNER');
select pg_temp.expect((select partnership_status::text from public.my_restaurants() limit 1) = 'ACTIVE_PARTNER',
    'titolare: il locale è diventato partner attivo');

-- ---------------------------------------------------------------------------
-- 4. Pubblicazione, piano, staff.
-- ---------------------------------------------------------------------------
select pg_temp.expect((select plan_code from public.restaurant_entitlements('10000000-0000-0000-0000-000000000005')) = 'RESTAURANT_PRO',
    'titolare: in beta ha il piano Pro');
select pg_temp.expect((select source from public.restaurant_entitlements('10000000-0000-0000-0000-000000000005')) = 'BETA',
    'titolare: la fonte del piano è la beta');
select public.set_restaurant_live_status('10000000-0000-0000-0000-000000000005', 'AVAILABLE', 3::smallint, 5::smallint, 'Tavoli fuori');
select pg_temp.expect(
    (select available_tables from public.restaurant_live_status where restaurant_id = '10000000-0000-0000-0000-000000000005') = 3,
    'titolare: in Pro i tavoli liberi vengono salvati');
select public.add_restaurant_staff('10000000-0000-0000-0000-000000000005', 'test-staff@haposto.test');
select pg_temp.expect((select count(*) from public.restaurant_users where restaurant_id = '10000000-0000-0000-0000-000000000005') = 2,
    'titolare: vede sé stesso e lo staff');

select pg_temp.act_as('test-staff@haposto.test');
select public.set_restaurant_live_status('10000000-0000-0000-0000-000000000005', 'LIMITED');
select pg_temp.expect(
    (select updated_via from public.restaurant_live_status where restaurant_id = '10000000-0000-0000-0000-000000000005') = 'STAFF',
    'staff: pubblica e viene registrato come STAFF');
select pg_temp.expect_error(
    $q$select public.add_restaurant_staff('10000000-0000-0000-0000-000000000005', 'test-user@haposto.test')$q$,
    'OWNER_REQUIRED', 'staff: non può aggiungere altro staff');

-- Fine beta → piano Basic: niente dettagli, niente staff nuovo.
select pg_temp.act_as('postgres');
update public.app_config set value = '{"restaurants_all_pro_until": "2000-01-01T00:00:00Z"}' where key = 'beta';
select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.expect((select plan_code from public.restaurant_entitlements('10000000-0000-0000-0000-000000000005')) = 'RESTAURANT_BASIC',
    'titolare: finita la beta passa a Basic');
select public.set_restaurant_live_status('10000000-0000-0000-0000-000000000005', 'AVAILABLE', 4::smallint, 10::smallint, 'Nota');
select pg_temp.expect(
    (select available_tables is null and estimated_wait_minutes is null and note is null
     from public.restaurant_live_status where restaurant_id = '10000000-0000-0000-0000-000000000005'),
    'titolare Basic: lo stato si pubblica, tavoli/attesa/nota no (sono Pro)');
select pg_temp.expect_error(
    $q$select public.add_restaurant_staff('10000000-0000-0000-0000-000000000005', 'test-user@haposto.test')$q$,
    'PLAN_UPGRADE_REQUIRED', 'titolare Basic: lo staff richiede Pro');

-- Il server dei pagamenti (webhook Stripe) attiva Pro a pagamento.
select pg_temp.act_as('service_role');
select public.billing_log_event('STRIPE', 'evt_test_1', 'customer.subscription.created', '{}'::jsonb);
select pg_temp.expect(not public.billing_log_event('STRIPE', 'evt_test_1', 'customer.subscription.created', '{}'::jsonb),
    'server: un evento webhook ripetuto viene riconosciuto (idempotenza)');
select public.billing_upsert_restaurant_subscription(
    '10000000-0000-0000-0000-000000000005', 'RESTAURANT_PRO', 'ACTIVE', 'YEAR', 'STRIPE',
    'cus_test', 'sub_test', now(), now() + interval '1 year', false);
select public.billing_record_payment(
    'RESTAURANT', '10000000-0000-0000-0000-000000000005', null, 'STRIPE', 'in_test_1', 'RESTAURANT_PRO',
    12078, 2178, 'SUCCEEDED', 'HP-2026-0001', null, now());

select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.expect((select source from public.restaurant_entitlements('10000000-0000-0000-0000-000000000005')) = 'STRIPE',
    'titolare: Pro pagato con Stripe');
select pg_temp.expect((select count(*) from public.payments) = 1, 'titolare: vede il proprio pagamento');
select pg_temp.expect_error(
    $q$insert into public.payments (payer_kind, restaurant_id, provider, provider_payment_id, amount_cents, status)
       values ('RESTAURANT', '10000000-0000-0000-0000-000000000005', 'MANUAL', 'fake', 0, 'SUCCEEDED')$q$,
    'permission denied', 'titolare: non può inventarsi pagamenti');
select pg_temp.expect_error(
    $q$select public.billing_upsert_restaurant_subscription('10000000-0000-0000-0000-000000000005', 'RESTAURANT_PRO_PLUS',
       'ACTIVE', 'YEAR', 'STRIPE', 'x', 'y', now(), now() + interval '1 year', false)$q$,
    'permission denied', 'titolare: non può attivarsi un piano da solo');
insert into public.restaurant_billing_profiles (
    restaurant_id, legal_name, vat_number, sdi_code, billing_address, billing_city, billing_postal_code, billing_province
) values (
    '10000000-0000-0000-0000-000000000005', 'Riva 27 S.r.l.', '01234567890', 'ABC1234',
    'Lungomare Demo 27', 'Pesaro', '61121', 'PU'
);
select pg_temp.expect((select count(*) from public.restaurant_billing_profiles) = 1, 'titolare: salva i dati di fatturazione');
select pg_temp.expect_error(
    $q$update public.restaurant_billing_profiles set vat_number = '123' where restaurant_id = '10000000-0000-0000-0000-000000000005'$q$,
    'restaurant_billing_profiles_vat_number_check', 'titolare: partita IVA non valida rifiutata');

select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.expect((select count(*) from public.payments) = 0, 'staff: non vede i pagamenti');
select pg_temp.expect((select count(*) from public.restaurant_billing_profiles) = 0, 'staff: non vede i dati di fatturazione');

-- ---------------------------------------------------------------------------
-- 5. Utente: preferiti (Gratis max 5), avvisi (solo Plus), privacy tra utenti.
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-user@haposto.test');
insert into public.favorites (user_id, restaurant_id)
select auth.uid(), r.id from public.restaurants r order by r.id limit 5;
select pg_temp.expect((select count(*) from public.favorites) = 5, 'utente Gratis: salva 5 preferiti');
select pg_temp.expect_error(
    $q$insert into public.favorites (user_id, restaurant_id)
       select auth.uid(), r.id from public.restaurants r order by r.id offset 5 limit 1$q$,
    'FAVORITES_LIMIT_REACHED', 'utente Gratis: il sesto preferito richiede Plus');
select pg_temp.expect_error(
    $q$insert into public.availability_alerts (user_id, restaurant_id)
       values (auth.uid(), '10000000-0000-0000-0000-000000000005')$q$,
    'PLUS_REQUIRED', 'utente Gratis: gli avvisi richiedono Plus');
select pg_temp.expect_error(
    $q$insert into public.favorites (user_id, restaurant_id)
       values (pg_temp.uid('test-user2@haposto.test'), '10000000-0000-0000-0000-000000000001')$q$,
    'row-level security', 'utente: non può scrivere preferiti di un altro');

select pg_temp.act_as('test-user2@haposto.test');
select pg_temp.expect((select count(*) from public.favorites) = 0, 'altro utente: non vede i preferiti altrui');

-- Google Play conferma Plus (via server) → l'utente attiva un avviso → il locale torna libero.
select pg_temp.act_as('service_role');
select public.billing_upsert_consumer_subscription(
    pg_temp.uid('test-user@haposto.test'), 'CONSUMER_PLUS', 'ACTIVE', 'GOOGLE_PLAY', 'gpa.test-1',
    now() + interval '1 month', true);

select pg_temp.act_as('test-user@haposto.test');
select pg_temp.expect((select plan_code from public.my_entitlements()) = 'CONSUMER_PLUS', 'utente: ora ha Plus');
insert into public.availability_alerts (user_id, restaurant_id)
values (auth.uid(), '10000000-0000-0000-0000-000000000005');
select pg_temp.expect((select count(*) from public.availability_alerts where is_active) = 1, 'utente Plus: avviso attivo');

select pg_temp.act_as('test-owner@haposto.test');
select public.set_restaurant_live_status('10000000-0000-0000-0000-000000000005', 'FULL');
select public.set_restaurant_live_status('10000000-0000-0000-0000-000000000005', 'AVAILABLE');

select pg_temp.act_as('postgres');
select pg_temp.expect(
    (select count(*) from public.notification_outbox
     where kind = 'AVAILABILITY_ALERT' and user_id = pg_temp.uid('test-user@haposto.test')) = 1,
    'sistema: quando torna "c''è posto" viene accodata UNA notifica');
select pg_temp.expect(
    not (select is_active from public.availability_alerts where user_id = pg_temp.uid('test-user@haposto.test')),
    'sistema: l''avviso si spegne dopo la notifica');

-- Promemoria al ristoratore: stato in scadenza → una notifica, senza doppioni.
select pg_temp.act_as('test-owner@haposto.test');
select public.register_push_token('fcm-token-di-prova-owner', 'ANDROID', '8');
select pg_temp.act_as('postgres');
update public.restaurant_live_status
set valid_until = now() + interval '3 minutes'
where restaurant_id = '10000000-0000-0000-0000-000000000005';
select pg_temp.expect(public.enqueue_manager_reminders() = 1, 'sistema: promemoria al titolare quando lo stato sta per scadere');
select pg_temp.expect(public.enqueue_manager_reminders() = 0, 'sistema: nessun promemoria doppio entro 20 minuti');

-- ---------------------------------------------------------------------------
-- 6. Prenotazioni di sala sincronizzate: solo i membri del locale.
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-owner@haposto.test');
insert into public.reservations (restaurant_id, client_id, reservation_date, reservation_time, party_size, customer_name, created_by)
values ('10000000-0000-0000-0000-000000000005', gen_random_uuid(), current_date, '20:30', 4, 'Rossi', auth.uid());
select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.expect((select count(*) from public.reservations) = 1, 'staff: vede le prenotazioni del locale');
select pg_temp.act_as('test-user@haposto.test');
select pg_temp.expect((select count(*) from public.reservations) = 0, 'utente: non vede le prenotazioni dei locali');

-- ---------------------------------------------------------------------------
-- 7. Statistiche: solo membri; Basic limitato, Pro completo.
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.expect((select sum(live_updates) from public.restaurant_stats('10000000-0000-0000-0000-000000000005')) >= 5,
    'titolare: vede gli aggiornamenti pubblicati oggi');
select pg_temp.act_as('test-user@haposto.test');
select pg_temp.expect_error(
    $q$select * from public.restaurant_stats('10000000-0000-0000-0000-000000000005')$q$,
    'Not authorized', 'utente: non vede le statistiche di un locale');

-- ---------------------------------------------------------------------------
-- 8. Registrazione di un locale nuovo + annullamento.
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-user2@haposto.test');
select public.register_new_restaurant(
    'Nuova Trattoria Prova', 'Trattoria', 'Via di Prova 1', 'Pesaro', 'PU', 43.911, 12.915,
    '+39 0721 000999', 'titolare@esempio.it');
select pg_temp.expect(
    (select slug from public.restaurants where name = 'Nuova Trattoria Prova') = 'nuova-trattoria-prova-pesaro',
    'registrazione: il nuovo locale riceve uno slug per la pagina pubblica');
select pg_temp.act_as('postgres');
select pg_temp.expect(
    (select partnership_status::text || '/' || data_source from public.restaurants where name = 'Nuova Trattoria Prova')
        = 'CLAIM_PENDING/PARTNER_SIGNUP',
    'registrazione: resta in verifica finché un admin non approva');
select pg_temp.act_as('test-user2@haposto.test');
select public.cancel_my_claim((select id from public.restaurant_claims where status = 'PENDING' limit 1));
select pg_temp.expect(
    (select partnership_status::text from public.restaurants where name = 'Nuova Trattoria Prova') = 'DIRECTORY_ONLY',
    'registrazione annullata: il locale torna "solo directory"');

-- ---------------------------------------------------------------------------
-- 9. Import directory (es. OpenStreetMap).
-- ---------------------------------------------------------------------------
select pg_temp.act_as('postgres');
insert into public.directory_import_staging (source_ref, name, category, address, city, province, latitude, longitude)
values ('node/1001', 'Locale Importato Uno', 'Pizzeria', 'Via Import 1', 'Pesaro', 'PU', 43.9101, 12.9101),
       ('node/1002', 'Locale Importato Due', null, null, 'Fano', 'PU', 43.8431, 13.0191);
select pg_temp.expect((select inserted from public.admin_import_directory('OSM_IMPORT')) = 2, 'import: 2 locali nuovi');
select pg_temp.expect((select updated from public.admin_import_directory('OSM_IMPORT')) = 2,
    'import ripetuto: aggiorna invece di duplicare');
select pg_temp.act_as('test-user@haposto.test');
select pg_temp.expect_error($q$select * from public.admin_import_directory('OSM_IMPORT')$q$,
    'ADMIN_REQUIRED', 'utente: non può importare directory');

select pg_temp.act_as('postgres');
do $$ begin raise notice 'TUTTI I CONTROLLI SUPERATI'; end $$;

rollback;
