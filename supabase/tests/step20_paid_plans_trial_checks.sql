-- HAPOSTO — Verifica automatica della migration 0016: prezzi IVA inclusa, semestrale, prova per
-- locale modificabile dall'admin, "Non collegato" senza piano, avvisi prima della scadenza.
--
-- Come gli altri script: impersona i vari utenti e controlla che ognuno possa fare SOLO ciò che
-- deve. Tutto avviene in una transazione annullata alla fine: non lascia tracce.
--
-- Prerequisiti: migration 0001–0016, seed 900 caricato e gli stessi 6 utenti di prova di
-- step18_security_admin_checks.sql (in locale, se non esistono, lo script li crea da sé).
--
-- Esito atteso: righe "ok: …" e, in fondo, "CONTROLLI PIANI E PROVA SUPERATI".

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

-- Imposta da postgres beta, giorni di prova e inizio partner del locale 0006.
create function pg_temp.setup(p_beta text, p_days integer, p_since interval) returns void
language plpgsql as $$
begin
    update public.app_config set value = jsonb_build_object('restaurants_all_pro_until', p_beta) where key = 'beta';
    update public.app_config set value = jsonb_build_object('days', p_days) where key = 'restaurant_trial';
    update public.restaurants set partner_since = now() - p_since where id = '10000000-0000-0000-0000-000000000006';
end;
$$;

create function pg_temp.publish(p_status text) returns void language plpgsql as $$
begin
    perform public.set_restaurant_live_status('10000000-0000-0000-0000-000000000006',
        p_status::public.live_status, 2::smallint, 10::smallint, 'Nota', 'Dolce offerto');
end;
$$;

create temporary table test_values (key text primary key, value text) on commit drop;
grant all on test_values to anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 0. Preparazione: il locale 0006 ha un titolare e uno staff.
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
update public.restaurants set partnership_status = 'ACTIVE_PARTNER' where id = '10000000-0000-0000-0000-000000000006';
delete from public.restaurant_subscriptions where restaurant_id = '10000000-0000-0000-0000-000000000006';
delete from public.restaurant_users where restaurant_id = '10000000-0000-0000-0000-000000000006';
insert into public.restaurant_users (restaurant_id, user_id, role) values
    ('10000000-0000-0000-0000-000000000006', pg_temp.uid('test-owner@haposto.test'), 'OWNER'),
    ('10000000-0000-0000-0000-000000000006', pg_temp.uid('test-staff@haposto.test'), 'STAFF');
insert into test_values
select 'slug', slug from public.restaurants where id = '10000000-0000-0000-0000-000000000006';

-- ---------------------------------------------------------------------------
-- 1. Prezzi IVA inclusa e piani.
-- ---------------------------------------------------------------------------
select pg_temp.expect((select price_month_cents = 1990 and price_semester_cents = 9990 and price_year_cents = 19990
                              and prices_include_vat
                       from public.plans where code = 'RESTAURANT_PRO'),
    'Pro: 19,90 / 99,90 / 199,90 € IVA inclusa');
select pg_temp.expect((select price_month_cents = 99 and price_semester_cents = 499 and price_year_cents = 999
                              and prices_include_vat
                       from public.plans where code = 'CONSUMER_PLUS'),
    'Plus: 0,99 / 4,99 / 9,99 € IVA inclusa');
select pg_temp.expect((select not ('LIVE_STATUS' = any(features)) and not is_public
                       from public.plans where code = 'RESTAURANT_BASIC'),
    'senza piano: niente stato pubblicato, piano non in vendita');
select pg_temp.expect((select value ->> 'days' from public.app_config where key = 'restaurant_trial') is not null,
    'prova: durata nelle impostazioni');

select pg_temp.act_as(null);
select pg_temp.expect((select count(*) from public.plans where code = 'RESTAURANT_BASIC') = 0,
    'anon: il "piano" senza piano non compare nel catalogo');
select pg_temp.expect((select count(*) from public.plans where code = 'RESTAURANT_PRO') = 1,
    'anon: vede il piano Pro');
select pg_temp.expect_error($q$select public.enqueue_plan_expiry_notices()$q$,
    'permission denied', 'anon: non accoda avvisi');
select pg_temp.expect_error($q$select public.restaurant_trial_until('10000000-0000-0000-0000-000000000006')$q$,
    'permission denied', 'anon: non legge la prova di un locale');

-- ---------------------------------------------------------------------------
-- 2. Inizio partner: segnato la prima volta, non riparte uscendo e rientrando.
-- ---------------------------------------------------------------------------
select pg_temp.act_as('postgres');
update public.restaurants set partnership_status = 'DIRECTORY_ONLY', partner_since = null
where id = '10000000-0000-0000-0000-000000000007';
select pg_temp.expect((select partner_since is null from public.restaurants where id = '10000000-0000-0000-0000-000000000007'),
    'locale solo directory: nessuna data di partner');
update public.restaurants set partnership_status = 'ACTIVE_PARTNER' where id = '10000000-0000-0000-0000-000000000007';
select pg_temp.expect((select partner_since > now() - interval '1 minute' from public.restaurants
                       where id = '10000000-0000-0000-0000-000000000007'),
    'diventa partner: la prova parte adesso');
update public.restaurants set partner_since = now() - interval '100 days' where id = '10000000-0000-0000-0000-000000000007';
update public.restaurants set partnership_status = 'DIRECTORY_ONLY' where id = '10000000-0000-0000-0000-000000000007';
update public.restaurants set partnership_status = 'ACTIVE_PARTNER' where id = '10000000-0000-0000-0000-000000000007';
select pg_temp.expect((select partner_since < now() - interval '99 days' from public.restaurants
                       where id = '10000000-0000-0000-0000-000000000007'),
    'esce e rientra: nessuna prova nuova');

-- ---------------------------------------------------------------------------
-- 3. Durante la beta: Pro per tutti.
-- ---------------------------------------------------------------------------
select pg_temp.setup('2099-01-01T00:00:00Z', 30, interval '400 days');
select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.expect((select plan_code = 'RESTAURANT_PRO' and source = 'BETA' and valid_until > '2098-12-31'
                       from public.restaurant_entitlements('10000000-0000-0000-0000-000000000006')),
    'beta: Pro gratis fino alla fine della beta');
select pg_temp.publish('AVAILABLE');
select pg_temp.expect((select offer = 'Dolce offerto' from public.restaurant_live_status
                       where restaurant_id = '10000000-0000-0000-0000-000000000006'),
    'beta: il titolare pubblica stato e offerta');

-- ---------------------------------------------------------------------------
-- 4. Dopo la beta: prova del locale.
-- ---------------------------------------------------------------------------
select pg_temp.act_as('postgres');
select pg_temp.setup('2000-01-01T00:00:00Z', 30, interval '10 days');
select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.expect((select plan_code = 'RESTAURANT_PRO' and source = 'TRIAL'
                              and valid_until between now() + interval '19 days 23 hours' and now() + interval '20 days 1 hour'
                       from public.restaurant_entitlements('10000000-0000-0000-0000-000000000006')),
    'prova: Pro per 30 giorni da quando è partner (ne restano 20)');
select pg_temp.publish('LIMITED');
select pg_temp.expect((select status = 'LIMITED' from public.restaurant_live_status
                       where restaurant_id = '10000000-0000-0000-0000-000000000006'),
    'prova: si pubblica');

-- Entrato 3 giorni prima della fine della beta: ha comunque i suoi 30 giorni.
select pg_temp.act_as('postgres');
update public.app_config set value = jsonb_build_object('restaurants_all_pro_until', now() + interval '2 days')
where key = 'beta';
update public.restaurants set partner_since = now() - interval '3 days' where id = '10000000-0000-0000-0000-000000000006';
select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.expect((select source = 'TRIAL' and valid_until > now() + interval '26 days'
                       from public.restaurant_entitlements('10000000-0000-0000-0000-000000000006')),
    'entrato a fine beta: la prova dura comunque 30 giorni');

-- ---------------------------------------------------------------------------
-- 5. Prova finita senza abbonamento: "Non collegato".
-- ---------------------------------------------------------------------------
select pg_temp.act_as('postgres');
select pg_temp.setup('2000-01-01T00:00:00Z', 30, interval '40 days');
select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.expect((select plan_code = 'RESTAURANT_BASIC' and source = 'NONE' and valid_until is null
                       from public.restaurant_entitlements('10000000-0000-0000-0000-000000000006')),
    'prova finita: nessun piano');
select pg_temp.expect((select plan_source = 'NONE' from public.restaurant_manager_info('10000000-0000-0000-0000-000000000006')),
    'prova finita: la dashboard lo sa');
select pg_temp.expect_error($q$select pg_temp.publish('AVAILABLE')$q$,
    'SUBSCRIPTION_REQUIRED', 'titolare senza piano: non pubblica');
select pg_temp.expect_error(
    $q$select public.set_restaurant_live_status('10000000-0000-0000-0000-000000000006', 'FULL')$q$,
    'SUBSCRIPTION_REQUIRED', 'titolare senza piano: neppure con l''app vecchia');
select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.expect_error($q$select pg_temp.publish('FULL')$q$,
    'SUBSCRIPTION_REQUIRED', 'staff senza piano: non pubblica');

select pg_temp.act_as(null);
select pg_temp.expect((select partnership_status = 'DIRECTORY_ONLY' and live_status is null and offer is null
                       from public.nearby_restaurants(43.8411, 13.0178, 1000)
                       where id = '10000000-0000-0000-0000-000000000006'),
    'lista: il locale senza piano appare Non collegato, senza stato né offerta');
select pg_temp.expect((select partnership_status = 'DIRECTORY_ONLY' and live_status is null
                       from public.public_restaurant_page((select value from test_values where key = 'slug'))),
    'pagina del QR: Non collegato');
select pg_temp.expect((select count(*) from public.nearby_restaurants(43.8411, 13.0178, 1000)
                       where id = '10000000-0000-0000-0000-000000000006') = 1,
    'lista: il locale resta nella lista');

-- Le scritture senza utente (seed, strumenti DEV, server) non sono toccate.
select pg_temp.act_as('postgres');
update public.restaurant_live_status set status = 'FULL', available_tables = null, offer = null
where restaurant_id = '10000000-0000-0000-0000-000000000006';
select pg_temp.expect((select status = 'FULL' from public.restaurant_live_status
                       where restaurant_id = '10000000-0000-0000-0000-000000000006'),
    'server: può ancora scrivere lo stato (es. strumenti DEV)');

-- ---------------------------------------------------------------------------
-- 6. L'admin cambia i giorni di prova dal pannello.
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.expect_error($q$select public.admin_set_config('restaurant_trial', '{"days": 365}')$q$,
    null, 'titolare: non cambia la prova');
select pg_temp.act_as('test-admin@haposto.test');
select public.admin_unlock('test.admin', 'password-di-prova-123');
select pg_temp.expect_error($q$select public.admin_set_config('restaurant_trial', '{"days": -1}')$q$,
    'INVALID_CONFIG_VALUE', 'admin: giorni negativi rifiutati');
select pg_temp.expect_error($q$select public.admin_set_config('restaurant_trial', '{"days": 400}')$q$,
    'INVALID_CONFIG_VALUE', 'admin: più di un anno rifiutato');
select pg_temp.expect_error($q$select public.admin_set_config('restaurant_trial', '{"days": "30"}')$q$,
    'INVALID_CONFIG_VALUE', 'admin: giorni non numerici rifiutati');
select pg_temp.expect_error($q$select public.admin_set_config('restaurant_trial', '{"days": 1.5}')$q$,
    'INVALID_CONFIG_VALUE', 'admin: giorni non interi rifiutati');
select public.admin_set_config('restaurant_trial', '{"days": 60}');
select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.expect((select source = 'TRIAL' from public.restaurant_entitlements('10000000-0000-0000-0000-000000000006')),
    'admin porta la prova a 60 giorni: il locale torna collegato');
select pg_temp.publish('AVAILABLE');
select pg_temp.act_as(null);
select pg_temp.expect((select partnership_status = 'ACTIVE_PARTNER' and live_status = 'AVAILABLE'
                       from public.nearby_restaurants(43.8411, 13.0178, 1000)
                       where id = '10000000-0000-0000-0000-000000000006'),
    'lista: di nuovo collegato con lo stato');

-- ---------------------------------------------------------------------------
-- 7. Abbonamenti: mesi dati dall'admin, Stripe semestrale.
-- ---------------------------------------------------------------------------
select pg_temp.act_as('postgres');
select pg_temp.setup('2000-01-01T00:00:00Z', 30, interval '40 days');
select pg_temp.act_as('test-admin@haposto.test');
select public.admin_unlock('test.admin', 'password-di-prova-123');
select public.admin_grant_restaurant_plan('10000000-0000-0000-0000-000000000006', 'RESTAURANT_PRO', 1, 'Prova estesa');
select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.expect((select plan_code = 'RESTAURANT_PRO' and source = 'MANUAL'
                       from public.restaurant_entitlements('10000000-0000-0000-0000-000000000006')),
    'admin dà un mese di Pro: il locale è collegato');

select pg_temp.act_as('service_role');
select pg_temp.expect_error(
    $q$select public.billing_upsert_restaurant_subscription('10000000-0000-0000-0000-000000000006', 'RESTAURANT_PRO',
       'ACTIVE', 'WEEK', 'STRIPE', 'cus_x', 'sub_week', now(), now() + interval '7 days', false)$q$,
    'restaurant_subscriptions_billing_interval_check', 'server: periodo sconosciuto rifiutato');

-- ---------------------------------------------------------------------------
-- 8. Avvisi prima della scadenza (al titolare, una volta per scadenza).
-- ---------------------------------------------------------------------------
select pg_temp.act_as('postgres');
update public.restaurant_subscriptions set current_period_end = now() + interval '5 days'
where restaurant_id = '10000000-0000-0000-0000-000000000006' and status = 'ACTIVE';
delete from public.notification_outbox where data ->> 'type' = 'PLAN_EXPIRING';
select public.enqueue_plan_expiry_notices();
select pg_temp.expect((select count(*) from public.notification_outbox
                       where data ->> 'type' = 'PLAN_EXPIRING'
                         and restaurant_id = '10000000-0000-0000-0000-000000000006'
                         and user_id = pg_temp.uid('test-owner@haposto.test')) = 1,
    'avviso: il titolare riceve l''avviso 7 giorni prima');
select pg_temp.expect((select count(*) from public.notification_outbox
                       where data ->> 'type' = 'PLAN_EXPIRING'
                         and user_id = pg_temp.uid('test-staff@haposto.test')) = 0,
    'avviso: lo staff no');
select pg_temp.expect((select bool_and(char_length(body) <= 240 and body like '%Non collegato%')
                       from public.notification_outbox where data ->> 'type' = 'PLAN_EXPIRING'),
    'avviso: testo chiaro e nei limiti');
select public.enqueue_plan_expiry_notices();
select pg_temp.expect((select count(*) from public.notification_outbox
                       where data ->> 'type' = 'PLAN_EXPIRING'
                         and restaurant_id = '10000000-0000-0000-0000-000000000006') = 1,
    'avviso: rieseguito il giorno dopo non si ripete');
update public.restaurant_subscriptions set current_period_end = now() + interval '12 hours'
where restaurant_id = '10000000-0000-0000-0000-000000000006' and status = 'ACTIVE';
select public.enqueue_plan_expiry_notices();
select pg_temp.expect((select count(*) from public.notification_outbox
                       where data ->> 'type' = 'PLAN_EXPIRING'
                         and restaurant_id = '10000000-0000-0000-0000-000000000006'
                         and title like '%domani%') = 1,
    'avviso: l''ultimo giorno arriva il secondo avviso');

-- Stripe che si rinnova da solo: nessun avviso.
delete from public.notification_outbox where data ->> 'type' = 'PLAN_EXPIRING';
update public.restaurant_subscriptions set status = 'CANCELED'
where restaurant_id = '10000000-0000-0000-0000-000000000006' and status = 'ACTIVE';
select pg_temp.act_as('service_role');
select public.billing_upsert_restaurant_subscription(
    '10000000-0000-0000-0000-000000000006', 'RESTAURANT_PRO', 'ACTIVE', 'SEMESTER', 'STRIPE',
    'cus_semestre', 'sub_semestre', now(), now() + interval '3 days', false);
select pg_temp.act_as('postgres');
select public.enqueue_plan_expiry_notices();
select pg_temp.expect((select count(*) from public.notification_outbox where data ->> 'type' = 'PLAN_EXPIRING'
                       and restaurant_id = '10000000-0000-0000-0000-000000000006') = 0,
    'avviso: Stripe con rinnovo automatico non ne riceve');
select pg_temp.expect((select billing_interval = 'SEMESTER' from public.restaurant_subscriptions
                       where provider_subscription_id = 'sub_semestre'),
    'Stripe: abbonamento semestrale registrato');
update public.restaurant_subscriptions set cancel_at_period_end = true where provider_subscription_id = 'sub_semestre';
select public.enqueue_plan_expiry_notices();
select pg_temp.expect((select count(*) from public.notification_outbox where data ->> 'type' = 'PLAN_EXPIRING'
                       and restaurant_id = '10000000-0000-0000-0000-000000000006') = 1,
    'avviso: Stripe disdetto riceve l''avviso');

select pg_temp.act_as('postgres');
do $$ begin raise notice 'CONTROLLI PIANI E PROVA SUPERATI'; end $$;
select 'CONTROLLI PIANI E PROVA SUPERATI' as esito;

rollback;
