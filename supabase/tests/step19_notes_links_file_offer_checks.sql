-- HAPOSTO — Verifica automatica della migration 0015: note pronte, link e file del locale,
-- offerta della serata, controllo dell'admin.
--
-- Come gli altri script: impersona i vari utenti e controlla che ognuno possa fare SOLO ciò che
-- deve. Tutto avviene in una transazione annullata alla fine: non lascia tracce.
--
-- Prerequisiti: migration 0001–0015, seed 900 caricato e gli stessi 6 utenti di prova di
-- step18_security_admin_checks.sql (in locale, se non esistono, lo script li crea da sé).
--
-- Esito atteso: righe "ok: …" e, in fondo, "CONTROLLI NOTE, LINK, FILE E OFFERTA SUPERATI".

begin;

create function pg_temp.act_as(p_email text, p_aal text default 'aal2')
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

create temporary table test_values (key text primary key, value text) on commit drop;
grant all on test_values to anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 0. Preparazione: il locale 0006 ha un titolare e uno staff; Pro attivo (beta).
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
update public.restaurants set partnership_status = 'ACTIVE_PARTNER' where id = '10000000-0000-0000-0000-000000000006';
delete from public.restaurant_users where restaurant_id = '10000000-0000-0000-0000-000000000006';
insert into public.restaurant_users (restaurant_id, user_id, role) values
    ('10000000-0000-0000-0000-000000000006', pg_temp.uid('test-owner@haposto.test'), 'OWNER'),
    ('10000000-0000-0000-0000-000000000006', pg_temp.uid('test-staff@haposto.test'), 'STAFF');

-- ---------------------------------------------------------------------------
-- 1. Visitatore anonimo.
-- ---------------------------------------------------------------------------
select pg_temp.act_as(null);
select pg_temp.expect_error($q$select * from public.restaurant_extras('10000000-0000-0000-0000-000000000006')$q$,
    'permission denied', 'anon: non legge le note pronte');
select pg_temp.expect_error($q$select public.set_restaurant_links('10000000-0000-0000-0000-000000000006', 'https://a.it', null)$q$,
    'permission denied', 'anon: non cambia i link');
select pg_temp.expect_error($q$select public.restaurant_file_attach('10000000-0000-0000-0000-000000000006', null, 'x', 'image/jpeg', 1, false)$q$,
    'permission denied', 'anon: non registra file');
select pg_temp.expect((select count(*) from public.restaurant_public_details('10000000-0000-0000-0000-000000000006')
                       where website_url is null and file_path is null) = 1,
    'anon: dettagli pubblici con link e file (ancora vuoti)');

-- ---------------------------------------------------------------------------
-- 2. Note pronte: titolare e staff con 2FA; pulite, senza doppioni, al massimo 8.
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-owner@haposto.test', 'aal1');
select pg_temp.expect_error($q$select public.set_restaurant_quick_notes('10000000-0000-0000-0000-000000000006', array['Solo esterni'])$q$,
    'MFA_REQUIRED', 'titolare senza 2FA: niente note pronte');
select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.expect(
    public.set_restaurant_quick_notes('10000000-0000-0000-0000-000000000006',
        array['  Solo   esterni ', 'Bancone', 'solo esterni', '', 'Cucina fino alle 23']) =
        array['Solo esterni', 'Bancone', 'Cucina fino alle 23'],
    'titolare: note pronte pulite e senza doppioni, nell''ordine dato');
select pg_temp.expect_error($q$select public.set_restaurant_quick_notes('10000000-0000-0000-0000-000000000006',
        array['1','2','3','4','5','6','7','8','9'])$q$, 'QUICK_NOTES_LIMIT', 'titolare: al massimo 8 note pronte');
select pg_temp.expect_error($q$select public.set_restaurant_quick_notes('10000000-0000-0000-0000-000000000006',
        array[repeat('x', 81)])$q$, 'NOTE_TOO_LONG', 'titolare: nota pronta di 81 caratteri rifiutata');
select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.expect(
    cardinality(public.set_restaurant_quick_notes('10000000-0000-0000-0000-000000000006',
        array['Solo esterni', 'Bancone', 'Cucina fino alle 23', 'Menù del giorno'])) = 4,
    'staff: può aggiornare le note pronte');
select pg_temp.expect((select quick_notes[4] from public.restaurant_extras('10000000-0000-0000-0000-000000000006')) = 'Menù del giorno',
    'staff: legge le note pronte (accenti compresi)');
select pg_temp.act_as('test-user@haposto.test');
select pg_temp.expect_error($q$select * from public.restaurant_extras('10000000-0000-0000-0000-000000000006')$q$,
    'Not authorized', 'utente qualsiasi: non legge le note pronte');
select pg_temp.expect_error($q$select public.set_restaurant_quick_notes('10000000-0000-0000-0000-000000000006', array['x'])$q$,
    'Not authorized', 'utente qualsiasi: non cambia le note pronte');

-- ---------------------------------------------------------------------------
-- 3. Link: solo il titolare; https aggiunto se manca; niente indirizzi strani.
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.expect_error($q$select public.set_restaurant_links('10000000-0000-0000-0000-000000000006', 'https://sito.it', null)$q$,
    'OWNER_REQUIRED', 'staff: non cambia i link');
select pg_temp.act_as('test-owner@haposto.test');
select public.set_restaurant_links('10000000-0000-0000-0000-000000000006', ' www.osteria-esempio.it ', 'https://instagram.com/osteria.esempio/');
select pg_temp.expect((select website_url = 'https://www.osteria-esempio.it' and menu_url = 'https://instagram.com/osteria.esempio/'
                       from public.restaurant_extras('10000000-0000-0000-0000-000000000006')),
    'titolare: link salvati, "https://" aggiunto dove mancava');
select pg_temp.expect_error($q$select public.set_restaurant_links('10000000-0000-0000-0000-000000000006', 'javascript:alert(1)', null)$q$,
    'INVALID_LINK', 'titolare: un indirizzo che non è un sito viene rifiutato');
select pg_temp.expect_error($q$select public.set_restaurant_links('10000000-0000-0000-0000-000000000006', 'https://sito .it', null)$q$,
    'INVALID_LINK', 'titolare: spazi nell''indirizzo rifiutati');
select pg_temp.act_as(null);
select pg_temp.expect((select menu_url from public.restaurant_public_details('10000000-0000-0000-0000-000000000006'))
                      = 'https://instagram.com/osteria.esempio/', 'anon: vede i link nei dettagli');
select pg_temp.expect((select website_url from public.public_restaurant_page(
                           (select slug from public.restaurants where id = '10000000-0000-0000-0000-000000000006')))
                      = 'https://www.osteria-esempio.it', 'anon: vede i link nella pagina del QR');

-- ---------------------------------------------------------------------------
-- 4. Offerta della serata: con lo stato, solo se c'è posto, scade con lo stato.
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-owner@haposto.test');
select public.set_restaurant_live_status('10000000-0000-0000-0000-000000000006', 'AVAILABLE', 3::smallint, 0::smallint,
    'Solo esterni', 'Dolce offerto a chi arriva entro le 21');
select pg_temp.act_as(null);
select pg_temp.expect((select offer from public.nearby_restaurants(43.91, 12.91, 60000)
                       where id = '10000000-0000-0000-0000-000000000006') = 'Dolce offerto a chi arriva entro le 21',
    'anon: vede l''offerta nella lista');
select pg_temp.act_as('test-owner@haposto.test');
select public.set_restaurant_live_status('10000000-0000-0000-0000-000000000006', 'FULL', null, null, null, 'Calice offerto');
select pg_temp.expect((select offer is null from public.restaurant_live_status
                       where restaurant_id = '10000000-0000-0000-0000-000000000006'),
    'titolare: con "Completo" l''offerta non si pubblica');
select public.set_restaurant_live_status('10000000-0000-0000-0000-000000000006', 'LIMITED', null, null, null, '  ');
select pg_temp.expect((select offer is null from public.restaurant_live_status
                       where restaurant_id = '10000000-0000-0000-0000-000000000006'),
    'titolare: offerta vuota = nessuna offerta');
select public.set_restaurant_live_status('10000000-0000-0000-0000-000000000006', 'AVAILABLE', null, null, null, 'Calice offerto');
select public.set_restaurant_live_status('10000000-0000-0000-0000-000000000006', 'AVAILABLE');
select pg_temp.expect((select offer is null from public.restaurant_live_status
                       where restaurant_id = '10000000-0000-0000-0000-000000000006'),
    'app vecchia (5 parametri): la nuova pubblicazione non porta con sé l''offerta precedente');
select pg_temp.expect_error($q$select public.set_restaurant_live_status('10000000-0000-0000-0000-000000000006', 'AVAILABLE',
        null, null, null, repeat('x', 61))$q$, 'OFFER_TOO_LONG', 'titolare: offerta oltre 60 caratteri rifiutata');
select public.set_restaurant_live_status('10000000-0000-0000-0000-000000000006', 'AVAILABLE', null, null, null, 'Calice offerto');
select pg_temp.act_as('postgres');
update public.restaurant_live_status set updated_at = now() - interval '2 hours', valid_until = now() - interval '90 minutes'
where restaurant_id = '10000000-0000-0000-0000-000000000006';
select pg_temp.act_as(null);
select pg_temp.expect((select offer is null from public.nearby_restaurants(43.91, 12.91, 60000)
                       where id = '10000000-0000-0000-0000-000000000006'),
    'anon: l''offerta scade insieme allo stato');

-- ---------------------------------------------------------------------------
-- 5. File: controllo come titolare, registrazione solo dal server, "solo per oggi".
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-owner@haposto.test');
select public.restaurant_file_check('10000000-0000-0000-0000-000000000006');
select pg_temp.expect(true, 'titolare con 2FA: può caricare il file');
select pg_temp.expect_error($q$select public.restaurant_file_attach('10000000-0000-0000-0000-000000000006', auth.uid(),
        '10000000-0000-0000-0000-000000000006/menu.jpg', 'image/jpeg', 1000, false)$q$,
    'permission denied', 'titolare: non registra il file da solo (lo fa solo il server)');
select pg_temp.act_as('test-owner@haposto.test', 'aal1');
select pg_temp.expect_error($q$select public.restaurant_file_check('10000000-0000-0000-0000-000000000006')$q$,
    'MFA_REQUIRED', 'titolare senza 2FA: niente file');
select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.expect_error($q$select public.restaurant_file_check('10000000-0000-0000-0000-000000000006')$q$,
    'OWNER_REQUIRED', 'staff: niente file');

select pg_temp.act_as('service_role');
select pg_temp.expect(public.restaurant_file_attach('10000000-0000-0000-0000-000000000006', pg_temp.uid('test-owner@haposto.test'),
        '10000000-0000-0000-0000-000000000006/a1b2c3.jpg', 'image/jpeg', 480000, false) is null,
    'server: primo file registrato (nessun file vecchio da cancellare)');
select pg_temp.expect(public.restaurant_file_attach('10000000-0000-0000-0000-000000000006', pg_temp.uid('test-owner@haposto.test'),
        '10000000-0000-0000-0000-000000000006/d4e5f6.pdf', 'application/pdf', 1500000, true)
        = '10000000-0000-0000-0000-000000000006/a1b2c3.jpg',
    'server: il file nuovo sostituisce il vecchio, che va cancellato');
select pg_temp.expect((select file_expires_at > now() and file_expires_at < now() + interval '30 hours'
                       from public.restaurants where id = '10000000-0000-0000-0000-000000000006'),
    'server: "solo per oggi" scade la notte dopo');
select pg_temp.expect_error($q$select public.restaurant_file_attach('10000000-0000-0000-0000-000000000006', null,
        '10000000-0000-0000-0000-000000000006/grande.jpg', 'image/jpeg', 3000000, false)$q$,
    'restaurants_file_check', 'database: immagine oltre 1 MB rifiutata');
select pg_temp.expect_error($q$select public.restaurant_file_attach('10000000-0000-0000-0000-000000000006', null,
        '10000000-0000-0000-0000-000000000006/x.gif', 'image/gif', 1000, false)$q$,
    'restaurants_file_check', 'database: tipo di file non ammesso rifiutato');
select pg_temp.act_as(null);
select pg_temp.expect((select file_today_only and file_mime = 'application/pdf'
                       from public.restaurant_public_details('10000000-0000-0000-0000-000000000006')),
    'anon: vede il file del giorno');
select pg_temp.act_as('postgres');
update public.restaurants set file_expires_at = now() - interval '1 minute'
where id = '10000000-0000-0000-0000-000000000006';
select pg_temp.act_as(null);
select pg_temp.expect((select file_path is null from public.restaurant_public_details('10000000-0000-0000-0000-000000000006')),
    'anon: il file scaduto non si vede più');
select pg_temp.act_as('service_role');
select public.restaurant_files_cleanup();
select pg_temp.expect((select file_path is null and file_mime is null from public.restaurants
                       where id = '10000000-0000-0000-0000-000000000006'),
    'pulizia: il file scaduto viene tolto dal locale');
select public.restaurant_file_attach('10000000-0000-0000-0000-000000000006', pg_temp.uid('test-owner@haposto.test'),
    '10000000-0000-0000-0000-000000000006/a1b2c3.webp', 'image/webp', 300000, false);
select pg_temp.expect(public.restaurant_file_detach('10000000-0000-0000-0000-000000000006', pg_temp.uid('test-owner@haposto.test'))
                      = '10000000-0000-0000-0000-000000000006/a1b2c3.webp',
    'server: il titolare toglie il file');
select public.restaurant_file_attach('10000000-0000-0000-0000-000000000006', pg_temp.uid('test-owner@haposto.test'),
    '10000000-0000-0000-0000-000000000006/a1b2c3.webp', 'image/webp', 300000, false);

-- ---------------------------------------------------------------------------
-- 6. Admin: elenco da controllare, Visto, Rimuovi.
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-user@haposto.test');
select pg_temp.expect_error($q$select * from public.admin_list_restaurant_extras()$q$, 'ADMIN_REQUIRED',
    'utente qualsiasi: niente elenco admin');
select pg_temp.act_as('test-admin@haposto.test');
select public.admin_unlock('test.admin', 'password-di-prova-123');
select pg_temp.expect((select count(*) from public.admin_list_restaurant_extras()
                       where restaurant_id = '10000000-0000-0000-0000-000000000006') = 1,
    'admin: il locale con link e file nuovi è da controllare');
select public.admin_review_restaurant_extras('10000000-0000-0000-0000-000000000006', 'REMOVE_LINKS', 'Link non pertinente');
select pg_temp.expect((select count(*) from public.admin_list_restaurant_extras()
                       where restaurant_id = '10000000-0000-0000-0000-000000000006') = 0,
    'admin: dopo il controllo il locale non è più da controllare');
select pg_temp.expect((select website_url is null and menu_url is null and file_path is not null
                       from public.admin_list_restaurant_extras(false) where restaurant_id = '10000000-0000-0000-0000-000000000006'),
    'admin: toglie i link e lascia il file');
select pg_temp.expect_error($q$select public.admin_review_restaurant_extras('10000000-0000-0000-0000-000000000006', 'CANCELLA')$q$,
    'INVALID_ACTION', 'admin: azione sconosciuta rifiutata');
select pg_temp.act_as('postgres');
select pg_temp.expect((select count(*) from public.audit_log
                       where action = 'ADMIN_EXTRAS_REMOVE_LINKS'
                         and restaurant_id = '10000000-0000-0000-0000-000000000006') = 1,
    'admin: la rimozione è nel registro operazioni');

-- ---------------------------------------------------------------------------
-- 7. Il locale torna "solo directory": via note, link e file.
-- ---------------------------------------------------------------------------
select pg_temp.act_as('postgres');
update public.restaurants set website_url = 'https://sito.it' where id = '10000000-0000-0000-0000-000000000006';
update public.restaurants set partnership_status = 'DIRECTORY_ONLY' where id = '10000000-0000-0000-0000-000000000006';
select pg_temp.expect((select quick_notes = '{}'::text[] and website_url is null and file_path is null
                       from public.restaurants where id = '10000000-0000-0000-0000-000000000006'),
    'locale senza titolare: note, link e file tolti');

select pg_temp.act_as('postgres');
do $$ begin raise notice 'CONTROLLI NOTE, LINK, FILE E OFFERTA SUPERATI'; end $$;
select 'CONTROLLI NOTE, LINK, FILE E OFFERTA SUPERATI' as esito;

rollback;
