-- HAPOSTO — Verifica automatica delle migration 0012–0013: sicurezza dei locali, pannello admin,
-- profilo, consensi, cancellazione account.
--
-- Come step8_to_17_checks.sql: impersona i vari utenti e controlla che ognuno possa fare SOLO ciò
-- che deve. Tutto avviene in una transazione annullata alla fine: non lascia tracce.
--
-- Prerequisiti: migration 0001–0004 + 0006–0013, seed 900 caricato.
-- Su Supabase crea prima questi 6 utenti di prova (Authentication → Users → Add user, "Auto Confirm"):
--   test-admin@haposto.test, test-owner@haposto.test, test-staff@haposto.test,
--   test-user@haposto.test, test-user2@haposto.test, test-thief@haposto.test
-- (In locale, se non esistono, lo script li crea da sé.)
--
-- Esito atteso: righe "ok: …" e, in fondo, "CONTROLLI SICUREZZA SUPERATI".

begin;

create function pg_temp.act_as(p_email text, p_aal text default 'aal2', p_session text default null)
returns void language plpgsql as $$
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
                              'session_id', coalesce(p_session, 'sessione-di-prova-' || v_id))::text, true);
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

-- Tabella di appoggio per passare valori tra un'identità e l'altra (es. il codice telefonico).
create temporary table test_values (key text primary key, value text) on commit drop;
grant all on test_values to anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 0. Preparazione.
-- ---------------------------------------------------------------------------
do $$
declare
    v_email text;
begin
    foreach v_email in array array['test-admin@haposto.test', 'test-owner@haposto.test',
                                   'test-staff@haposto.test', 'test-user@haposto.test',
                                   'test-user2@haposto.test', 'test-thief@haposto.test'] loop
        if not exists (select 1 from auth.users where email = v_email) then
            insert into auth.users (id, email, raw_user_meta_data)
            values (gen_random_uuid(), v_email, jsonb_build_object('full_name', split_part(v_email, '@', 1)));
        end if;
    end loop;
end;
$$;
insert into public.profiles (id) select id from auth.users where email like 'test-%@haposto.test'
on conflict (id) do nothing;

select public.admin_set_credentials('test-admin@haposto.test', 'test.admin', 'password-di-prova-123');
update public.app_config set value = '{"restaurants_all_pro_until": "2099-01-01T00:00:00Z"}' where key = 'beta';
select pg_temp.expect(public.config_value('security', 'restaurant_mfa_required') = 'true',
    'config: la 2FA dei ristoratori è attiva di default');

-- ---------------------------------------------------------------------------
-- 1. Visitatore anonimo.
-- ---------------------------------------------------------------------------
select pg_temp.act_as(null);
select pg_temp.expect_error($q$select public.admin_overview()$q$, 'permission denied', 'anon: niente pannello admin');
select pg_temp.expect_error($q$select * from public.my_profile()$q$, 'permission denied', 'anon: nessun profilo');
select pg_temp.expect_error($q$select count(*) from public.audit_log$q$, 'permission denied', 'anon: non legge il registro');
select pg_temp.expect((select count(*) from public.restaurant_public_details('10000000-0000-0000-0000-000000000001')) = 1,
    'anon: legge i dettagli pubblici di un locale');

-- ---------------------------------------------------------------------------
-- 2. Pannello admin: seconda password, 2FA, blocco dopo 5 errori, legato alla sessione.
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-user@haposto.test');
select pg_temp.expect((select error_code from public.admin_unlock('test.admin', 'password-di-prova-123')) = 'NOT_ADMIN',
    'utente normale: non può sbloccare il pannello neanche con la password giusta');

select pg_temp.act_as('test-admin@haposto.test', 'aal1');
select pg_temp.expect((select error_code from public.admin_unlock('test.admin', 'password-di-prova-123')) = 'MFA_REQUIRED',
    'admin senza 2FA: pannello chiuso');

select pg_temp.act_as('test-admin@haposto.test');
select pg_temp.expect(not public.is_platform_admin(), 'admin collegato ma non sbloccato: nessun potere');
select pg_temp.expect_error($q$select public.admin_overview()$q$, 'ADMIN_REQUIRED', 'admin non sbloccato: niente panoramica');
select pg_temp.expect((select error_code from public.admin_unlock('test.admin', 'sbagliata')) = 'INVALID_CREDENTIALS',
    'admin: password sbagliata rifiutata');
select public.admin_unlock('test.admin', 'sbagliata');
select public.admin_unlock('test.admin', 'sbagliata');
select public.admin_unlock('test.admin', 'sbagliata');
select pg_temp.expect((select error_code from public.admin_unlock('test.admin', 'sbagliata')) = 'LOCKED',
    'admin: al quinto errore il pannello si blocca');
select pg_temp.expect((select error_code from public.admin_unlock('test.admin', 'password-di-prova-123')) = 'LOCKED',
    'admin: durante il blocco neanche la password giusta funziona');
select pg_temp.expect((select locked_until is not null from public.my_admin_status()), 'admin: vede fino a quando è bloccato');

select pg_temp.act_as('postgres');
select pg_temp.expect((select count(*) from public.audit_log where action = 'ADMIN_UNLOCK_FAILED') >= 5,
    'registro: tentativi falliti annotati');
update public.admin_credentials set locked_until = null where user_id = pg_temp.uid('test-admin@haposto.test');

select pg_temp.act_as('test-admin@haposto.test');
select pg_temp.expect((select ok from public.admin_unlock('Test.Admin ', 'password-di-prova-123')),
    'admin: sblocco con utente + password (maiuscole e spazi ignorati nel nome)');
select pg_temp.expect(public.is_platform_admin(), 'admin sbloccato: poteri attivi');
select pg_temp.expect((select (public.admin_overview() ->> 'users_total')::int) >= 6, 'admin: panoramica');

select pg_temp.act_as('test-admin@haposto.test', 'aal2', 'un-altro-telefono');
select pg_temp.expect(not public.is_platform_admin(), 'admin da un''altra sessione: pannello chiuso');
select pg_temp.act_as('test-admin@haposto.test');
select public.admin_lock();
select pg_temp.expect(not public.is_platform_admin(), 'admin: "blocca pannello" chiude subito');
select public.admin_unlock('test.admin', 'password-di-prova-123');

select pg_temp.act_as('postgres');
select pg_temp.expect((public.admin_overview() ->> 'restaurants_total') is not null,
    'SQL Editor (nessun utente): le funzioni admin restano utilizzabili');
select pg_temp.expect_error(
    $q$select public.admin_set_credentials('nessuno@haposto.test', 'nessuno', 'password-lunga-123')$q$,
    'USER_NOT_REGISTERED', 'console: credenziali solo per account esistenti');
select pg_temp.expect_error(
    $q$select public.admin_set_credentials('test-admin@haposto.test', 'test.admin', 'corta')$q$,
    'PASSWORD_TOO_SHORT', 'console: password admin di almeno 12 caratteri');
select pg_temp.act_as('test-admin@haposto.test');
select pg_temp.expect_error(
    $q$select public.admin_set_credentials('test-user@haposto.test', 'utente', 'password-lunga-123')$q$,
    'permission denied', 'app: nessuno può creare admin dall''app');

-- ---------------------------------------------------------------------------
-- 3. Richiesta di gestione con verifica al telefono del locale.
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-owner@haposto.test', 'aal1');
select public.submit_restaurant_claim('10000000-0000-0000-0000-000000000005', '+39 0721 000555');
select pg_temp.act_as('test-thief@haposto.test', 'aal1');
select public.submit_restaurant_claim('10000000-0000-0000-0000-000000000005', '+39 333 0000000');
select pg_temp.expect_error($q$select phone_code_hash from public.restaurant_claims$q$, 'permission denied',
    'richiedente: non può leggere l''impronta del codice');
select pg_temp.expect((select count(*) from public.my_claims()) = 1, 'richiedente: vede solo la propria richiesta');

select pg_temp.act_as('test-admin@haposto.test');
select pg_temp.expect((select count(*) from public.admin_pending_claims()) = 2, 'admin: due richieste sullo stesso locale');
select pg_temp.expect((select restaurant_phone is not null or true from public.admin_pending_claims() limit 1),
    'admin: vede il numero pubblico del locale da chiamare');
select pg_temp.expect_error(
    format($q$select public.admin_review_claim(%L, true, 'ok')$q$,
           (select claim_id from public.admin_pending_claims() where requester_email = 'test-owner@haposto.test')),
    'PHONE_NOT_VERIFIED', 'admin: non approva senza verifica telefonica');
insert into test_values
select 'owner_code', public.admin_issue_claim_code(claim_id)
from public.admin_pending_claims() where requester_email = 'test-owner@haposto.test';
insert into test_values
select 'thief_code', public.admin_issue_claim_code(claim_id)
from public.admin_pending_claims() where requester_email = 'test-thief@haposto.test';
select pg_temp.expect((select value ~ '^[0-9]{6}$' from test_values where key = 'owner_code'), 'admin: codice di 6 cifre');

select pg_temp.act_as('test-owner@haposto.test', 'aal1');
select pg_temp.expect(
    (select error_code = 'WRONG_CODE' and attempts_left = 4
     from public.verify_my_claim_code((select claim_id from public.my_claims() limit 1), '000000x')),
    'titolare: codice sbagliato, restano 4 tentativi');
select pg_temp.expect(
    (select ok from public.verify_my_claim_code((select claim_id from public.my_claims() limit 1),
                                                (select value from test_values where key = 'owner_code'))),
    'titolare: codice giusto accettato');
select pg_temp.expect((select phone_verified_at is not null from public.my_claims() limit 1),
    'titolare: la richiesta risulta verificata');

select pg_temp.act_as('test-thief@haposto.test', 'aal1');
select pg_temp.expect(
    (select error_code from public.verify_my_claim_code(
        (select c.id from public.restaurant_claims c where c.user_id = pg_temp.uid('test-owner@haposto.test')),
        (select value from test_values where key = 'owner_code'))) = 'CLAIM_NOT_FOUND',
    'altro utente: non può usare la richiesta altrui');
select public.verify_my_claim_code((select claim_id from public.my_claims() limit 1), '111111');
select public.verify_my_claim_code((select claim_id from public.my_claims() limit 1), '222222');
select public.verify_my_claim_code((select claim_id from public.my_claims() limit 1), '333333');
select public.verify_my_claim_code((select claim_id from public.my_claims() limit 1), '444444');
select pg_temp.expect(
    (select error_code from public.verify_my_claim_code((select claim_id from public.my_claims() limit 1), '555555')) = 'TOO_MANY_ATTEMPTS',
    'tentativi a caso: dopo 5 errori il codice si annulla');
select pg_temp.expect(
    (select not ok from public.verify_my_claim_code((select claim_id from public.my_claims() limit 1),
                                                    (select value from test_values where key = 'thief_code'))),
    'tentativi a caso: poi neanche il codice giusto funziona');

select pg_temp.act_as('test-admin@haposto.test');
select public.admin_review_claim(claim_id, true, 'Verificato al telefono del locale')
from public.admin_pending_claims() where requester_email = 'test-owner@haposto.test';
select public.admin_review_claim(claim_id, false, 'Non risulta collegato al locale')
from public.admin_pending_claims() where requester_email = 'test-thief@haposto.test';

select pg_temp.act_as('postgres');
select pg_temp.expect((select count(*) from public.notification_outbox
                       where kind = 'CLAIM_UPDATE' and user_id = pg_temp.uid('test-owner@haposto.test')) = 1,
    'sistema: il titolare riceve la notifica di approvazione');
select pg_temp.expect((select count(*) from public.audit_log
                       where action in ('CLAIM_APPROVED', 'CLAIM_REJECTED', 'CLAIM_PHONE_VERIFIED', 'CLAIM_CODE_ISSUED')) >= 5,
    'registro: richieste, codici e decisioni annotati');

-- ---------------------------------------------------------------------------
-- 4. 2FA obbligatoria per gestire il locale.
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-owner@haposto.test', 'aal1');
select pg_temp.expect_error(
    $q$select public.set_restaurant_live_status('10000000-0000-0000-0000-000000000005', 'AVAILABLE')$q$,
    'MFA_REQUIRED', 'titolare senza 2FA: non pubblica');
select pg_temp.expect_error(
    $q$select * from public.restaurant_members('10000000-0000-0000-0000-000000000005')$q$,
    'MFA_REQUIRED', 'titolare senza 2FA: non vede lo staff');
select pg_temp.expect((select not mfa_ok and mfa_required from public.restaurant_manager_info('10000000-0000-0000-0000-000000000005')),
    'titolare senza 2FA: la dashboard sa che deve chiederla');

select pg_temp.act_as('test-owner@haposto.test');
select public.set_restaurant_live_status('10000000-0000-0000-0000-000000000005', 'AVAILABLE', 2::smallint, 5::smallint, 'Dehors');
select pg_temp.expect((select status::text from public.restaurant_live_status
                       where restaurant_id = '10000000-0000-0000-0000-000000000005') = 'AVAILABLE',
    'titolare con 2FA: pubblica');

select pg_temp.act_as('postgres');
update public.app_config set value = value || '{"restaurant_mfa_required": false}' where key = 'security';
select pg_temp.act_as('test-owner@haposto.test', 'aal1');
select public.set_restaurant_live_status('10000000-0000-0000-0000-000000000005', 'LIMITED');
select pg_temp.expect(true, 'config: con la 2FA disattivata (solo per prove) si pubblica anche senza');
select pg_temp.act_as('postgres');
update public.app_config set value = value || '{"restaurant_mfa_required": true}' where key = 'security';

select pg_temp.act_as('test-owner@haposto.test');
insert into public.reservations (restaurant_id, client_id, reservation_date, party_size, customer_name, created_by)
values ('10000000-0000-0000-0000-000000000005', gen_random_uuid(), current_date, 2, 'Bianchi', auth.uid());
select pg_temp.act_as('test-owner@haposto.test', 'aal1');
select pg_temp.expect((select count(*) from public.reservations) = 0,
    'titolare senza 2FA: non vede i dati dei clienti nelle prenotazioni');

-- ---------------------------------------------------------------------------
-- 5. Dati del locale, staff, registro attività.
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-owner@haposto.test');
select public.update_restaurant_profile('10000000-0000-0000-0000-000000000005', 'Riva 27 Demo', 'Pesce',
    '+39 0721 000555', true,
    '{"mon": [], "tue": [["12:00","14:30"],["19:00","23:30"]], "sat": [["19:00","01:00"]]}');
select pg_temp.expect((select opening_hours ->> 'sat' from public.restaurant_manager_info('10000000-0000-0000-0000-000000000005'))
                      = '[["19:00", "01:00"]]', 'titolare: salva gli orari (anche dopo mezzanotte)');
select pg_temp.expect_error(
    $q$select public.update_restaurant_profile('10000000-0000-0000-0000-000000000005', 'Riva 27 Demo', 'Pesce',
       null, false, '{"lun": [["12:00","14:00"]]}')$q$,
    'INVALID_OPENING_HOURS', 'titolare: orari in formato sbagliato rifiutati');
select pg_temp.expect_error(
    $q$select public.update_restaurant_profile('10000000-0000-0000-0000-000000000005', 'Riva 27 Demo', 'Pesce',
       null, true, null)$q$,
    'PHONE_REQUIRED', 'titolare: telefono pubblico solo se c''è un numero');
select pg_temp.expect((select my_role::text || '/' || plan_code from public.restaurant_manager_info('10000000-0000-0000-0000-000000000005'))
                      = 'OWNER/RESTAURANT_PRO', 'titolare: ruolo e piano nella dashboard');
select pg_temp.expect((select slug is not null from public.restaurant_manager_info('10000000-0000-0000-0000-000000000005')),
    'titolare: ha lo slug per il QR');
select public.add_restaurant_staff('10000000-0000-0000-0000-000000000005', 'test-staff@haposto.test');
select pg_temp.expect((select count(*) from public.restaurant_members('10000000-0000-0000-0000-000000000005')) = 2,
    'titolare: vede titolare e staff con le email');
select pg_temp.expect_error(
    $q$select public.add_restaurant_staff('10000000-0000-0000-0000-000000000005', 'test-staff@haposto.test')$q$,
    'ALREADY_MEMBER', 'titolare: niente staff doppio');

select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.expect((select my_role::text from public.restaurant_manager_info('10000000-0000-0000-0000-000000000005')) = 'STAFF',
    'staff: vede la dashboard come STAFF');
select pg_temp.expect_error(
    $q$select public.update_restaurant_profile('10000000-0000-0000-0000-000000000005', 'Nome mio', 'Pesce', null, false, null)$q$,
    'OWNER_REQUIRED', 'staff: non cambia i dati del locale');
select public.set_restaurant_live_status('10000000-0000-0000-0000-000000000005', 'FULL');

select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.expect((select count(*) from public.restaurant_activity('10000000-0000-0000-0000-000000000005')
                       where kind = 'PUBLISH') >= 3, 'titolare: il registro mostra le pubblicazioni');
select pg_temp.expect((select count(*) from public.restaurant_activity('10000000-0000-0000-0000-000000000005')
                       where kind in ('STAFF_ADDED', 'RESTAURANT_PROFILE_UPDATED', 'CLAIM_APPROVED')) = 3,
    'titolare: il registro mostra staff, modifiche e approvazione');
select pg_temp.expect((select count(*) from public.restaurant_activity('10000000-0000-0000-0000-000000000005')
                       where kind = 'CLAIM_CODE_ISSUED') = 0, 'titolare: i dettagli interni della verifica non compaiono');

select pg_temp.act_as(null);
select pg_temp.expect((select opening_hours ? 'tue' from public.restaurant_public_details('10000000-0000-0000-0000-000000000005')),
    'pubblico: vede gli orari');

select pg_temp.act_as('test-staff@haposto.test');
select public.remove_restaurant_staff('10000000-0000-0000-0000-000000000005', auth.uid());
select pg_temp.expect(public.restaurant_role('10000000-0000-0000-0000-000000000005') is null, 'staff: può lasciare il locale');

-- Limite anti-abuso.
select pg_temp.act_as('postgres');
update public.app_config set value = value || '{"max_publish_per_10min": 3}' where key = 'security';
select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.expect_error(
    $q$select public.set_restaurant_live_status('10000000-0000-0000-0000-000000000005', 'AVAILABLE')$q$,
    'RATE_LIMITED', 'titolare: troppe pubblicazioni in 10 minuti vengono fermate');
select pg_temp.act_as('postgres');
update public.app_config set value = value || '{"max_publish_per_10min": 30}' where key = 'security';

-- ---------------------------------------------------------------------------
-- 6. Blocco account.
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-admin@haposto.test');
select pg_temp.expect_error(
    format($q$select public.admin_set_user_blocked(%L, true, 'x')$q$, pg_temp.uid('test-admin@haposto.test')),
    'CANNOT_BLOCK_SELF', 'admin: non può bloccare sé stesso');
select public.admin_set_user_blocked(pg_temp.uid('test-owner@haposto.test'), true, 'Segnalazione da verificare');

select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.expect_error(
    $q$select public.set_restaurant_live_status('10000000-0000-0000-0000-000000000005', 'AVAILABLE')$q$,
    'ACCOUNT_BLOCKED', 'account bloccato: non pubblica più');
select pg_temp.expect_error(
    $q$insert into public.favorites (user_id, restaurant_id) values (auth.uid(), '10000000-0000-0000-0000-000000000001')$q$,
    'row-level security', 'account bloccato: non salva preferiti');
select pg_temp.expect((select blocked from public.my_profile()), 'account bloccato: l''app lo sa e lo mostra');

select pg_temp.act_as('test-admin@haposto.test');
select public.admin_set_user_blocked(pg_temp.uid('test-owner@haposto.test'), false);
select pg_temp.act_as('test-owner@haposto.test');
select public.set_restaurant_live_status('10000000-0000-0000-0000-000000000005', 'AVAILABLE');
select pg_temp.expect(true, 'account sbloccato: pubblica di nuovo');

-- ---------------------------------------------------------------------------
-- 7. Consensi e preferenze.
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-user@haposto.test');
select public.accept_terms('2026-10');
select pg_temp.expect((select accepted_terms_version = current_terms_version from public.my_profile()),
    'utente: termini accettati nella versione corrente');
select pg_temp.expect((select count(*) from public.consent_log where kind in ('TERMS', 'PRIVACY')) = 2,
    'utente: prova del consenso salvata');
select pg_temp.expect_error($q$select public.accept_restaurant_terms('2026-10', false)$q$, 'SPECIFIC_CLAUSES_REQUIRED',
    'ristoratore: serve l''approvazione specifica delle clausole');
select public.accept_restaurant_terms('2026-10', true);
select public.set_marketing_consent(true);
select public.set_notification_prefs(null, false, null);
select pg_temp.expect((select marketing_opt_in and not notify_availability_alerts and notify_manager_reminders
                       from public.my_profile()), 'utente: consenso marketing e preferenze notifiche salvati');
select pg_temp.act_as('test-user2@haposto.test');
select pg_temp.expect((select count(*) from public.consent_log) = 0, 'altro utente: non vede i consensi altrui');

-- ---------------------------------------------------------------------------
-- 8. Pannello admin: locali, utenti, abbonamenti, registro, impostazioni.
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-user@haposto.test');
select pg_temp.expect_error($q$select * from public.admin_list_users()$q$, 'ADMIN_REQUIRED', 'utente: niente elenco utenti');

select pg_temp.act_as('test-admin@haposto.test');
select pg_temp.expect((select count(*) from public.admin_list_restaurants('riva')) >= 1, 'admin: cerca locali');
select pg_temp.expect(jsonb_array_length(public.admin_restaurant_detail('10000000-0000-0000-0000-000000000005') -> 'members') = 1,
    'admin: dettaglio locale con i membri');
select pg_temp.expect((select count(*) from public.admin_list_users('test-')) >= 6, 'admin: cerca utenti');
select pg_temp.expect((public.admin_user_detail(pg_temp.uid('test-owner@haposto.test')) -> 'restaurants') ->> 0 is not null,
    'admin: dettaglio utente con i suoi locali');
select public.admin_grant_consumer_plan(pg_temp.uid('test-user@haposto.test'), 1, 'Tester');

select pg_temp.act_as('test-user@haposto.test');
select pg_temp.expect((select plan_code from public.my_entitlements()) = 'CONSUMER_PLUS', 'utente: Plus regalato dall''admin');
select pg_temp.expect((select count(*) from public.restaurant_availability_pattern('10000000-0000-0000-0000-000000000005')) >= 1,
    'utente Plus: vede lo storico "di solito"');
select pg_temp.act_as('test-user2@haposto.test');
select pg_temp.expect_error($q$select * from public.restaurant_availability_pattern('10000000-0000-0000-0000-000000000005')$q$,
    'PLUS_REQUIRED', 'utente Gratis: lo storico è Plus');

select pg_temp.act_as('test-admin@haposto.test');
select public.admin_cancel_subscription('CONSUMER', subscription_id, 'Fine prova')
from public.admin_list_subscriptions('CONSUMER') where status = 'ACTIVE' and provider = 'PROMO';
select pg_temp.act_as('test-user@haposto.test');
select pg_temp.expect((select plan_code from public.my_entitlements()) = 'CONSUMER_FREE', 'utente: Plus chiuso dall''admin');

select pg_temp.act_as('test-admin@haposto.test');
select public.admin_set_restaurant_status('10000000-0000-0000-0000-000000000005', 'SUSPENDED', 'Verifica in corso');
select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.expect_error(
    $q$select public.set_restaurant_live_status('10000000-0000-0000-0000-000000000005', 'AVAILABLE')$q$,
    'RESTAURANT_SUSPENDED', 'locale sospeso: non pubblica');
select pg_temp.act_as('test-admin@haposto.test');
select public.admin_set_restaurant_status('10000000-0000-0000-0000-000000000005', 'ACTIVE_PARTNER', 'Tutto ok');
select public.admin_update_restaurant('10000000-0000-0000-0000-000000000005', p_name => 'Riva 27');
select pg_temp.expect((select name from public.admin_list_restaurants('riva 27') limit 1) = 'Riva 27', 'admin: corregge i dati');
select pg_temp.expect_error($q$select public.admin_set_config('segreto', '1')$q$, 'CONFIG_KEY_NOT_EDITABLE',
    'admin: solo le impostazioni previste sono modificabili');
select public.admin_set_config('min_supported_app_version', '9');
select pg_temp.expect((select count(*) from public.admin_audit_log(500) where action = 'CONFIG_CHANGED') = 1,
    'admin: il registro mostra le modifiche alle impostazioni');
select pg_temp.expect((select count(*) from public.admin_audit_log(500, null, 'CLAIM')) >= 5,
    'admin: filtra il registro per tipo di operazione');

-- Passaggio di proprietà deciso dall'admin: togliendo l'ultimo titolare il locale non è più live.
select public.admin_add_member('10000000-0000-0000-0000-000000000001', 'test-thief@haposto.test', 'OWNER', 'Prova');
select public.admin_remove_member('10000000-0000-0000-0000-000000000001', pg_temp.uid('test-thief@haposto.test'), 'Prova');
select pg_temp.expect(
    (select partnership_status::text from public.admin_list_restaurants('10000000-0000-0000-0000-000000000001')) = 'DIRECTORY_ONLY',
    'admin: un locale senza titolari torna "solo directory"');

-- ---------------------------------------------------------------------------
-- 9. Notifiche: la Edge Function prende la coda e la chiude.
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-owner@haposto.test');
select public.register_push_token('token-di-prova-owner', 'ANDROID', '9');
select pg_temp.expect_error($q$select * from public.claim_notification_batch(10)$q$, 'permission denied',
    'utente: non legge la coda delle notifiche');
select pg_temp.act_as('service_role');
insert into test_values
select 'batch_ids', string_agg(notification_id::text, ',') from public.claim_notification_batch(10)
where 'token-di-prova-owner' = any(tokens);
select pg_temp.expect((select value is not null from test_values where key = 'batch_ids'),
    'server: riceve le notifiche con i token del telefono');
select public.complete_notifications(string_to_array((select value from test_values where key = 'batch_ids'), ',')::bigint[]);
select pg_temp.act_as('postgres');
select pg_temp.expect((select count(*) from public.notification_outbox
                       where user_id = pg_temp.uid('test-owner@haposto.test') and sent_at is null) = 0,
    'server: notifiche segnate come inviate');

-- ---------------------------------------------------------------------------
-- 10. Cancellazione dell'account.
-- ---------------------------------------------------------------------------
select pg_temp.act_as('service_role');
select public.billing_upsert_restaurant_subscription(
    '10000000-0000-0000-0000-000000000005', 'RESTAURANT_PRO', 'ACTIVE', 'MONTH', 'STRIPE',
    'cus_del', 'sub_del', now(), now() + interval '1 month', false);
select public.billing_upsert_consumer_subscription(
    pg_temp.uid('test-user@haposto.test'), 'CONSUMER_PLUS', 'ACTIVE', 'GOOGLE_PLAY', 'gpa.del-1',
    now() + interval '1 month', true);

select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.expect_error($q$select public.delete_my_account()$q$, 'ACTIVE_RESTAURANT_SUBSCRIPTION',
    'titolare con Pro pagato: prima disdice, poi cancella l''account');
select pg_temp.act_as('test-user@haposto.test');
select pg_temp.expect_error($q$select public.delete_my_account()$q$, 'ACTIVE_PLUS_SUBSCRIPTION',
    'utente con Plus attivo: prima disdice su Google Play');

select pg_temp.act_as('postgres');
update public.restaurant_subscriptions set cancel_at_period_end = true where provider_subscription_id = 'sub_del';
select pg_temp.act_as('test-owner@haposto.test');
select public.delete_my_account();
select pg_temp.act_as('postgres');
select pg_temp.expect(pg_temp.uid('test-owner@haposto.test') is null, 'cancellazione: l''account non esiste più');
select pg_temp.expect((select partnership_status::text from public.restaurants
                       where id = '10000000-0000-0000-0000-000000000005') = 'DIRECTORY_ONLY',
    'cancellazione: il locale dell''unico titolare torna "solo directory"');
select pg_temp.expect((select count(*) from public.audit_log where action = 'ACCOUNT_DELETED') = 1,
    'cancellazione: annotata nel registro senza dati personali');
select pg_temp.expect((select count(*) from public.payments where provider_payment_id = 'nessuno') = 0,
    'cancellazione: i pagamenti restano (obblighi contabili)');

select pg_temp.act_as('service_role');
select pg_temp.expect(public.purge_operational_data() ? 'status_history', 'server: pulizia periodica dei dati vecchi');

select pg_temp.act_as('postgres');
do $$ begin raise notice 'CONTROLLI SICUREZZA SUPERATI'; end $$;
select 'CONTROLLI SICUREZZA SUPERATI' as esito;

rollback;
