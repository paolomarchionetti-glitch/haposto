-- HAPOSTO — Verifica automatica della migration 0018: tessera fedeltà (funzione nascosta).
-- Le regole citate (T1–T61) sono nelle specifiche della tessera in docs/PR/PR22-30_tessera-fedelta/.
--
-- Tutto avviene in una transazione annullata alla fine: non lascia tracce.
-- Prerequisiti: migration 0001–0018, seed 900 caricato (in locale gli utenti di prova si creano da sé).
-- Dentro la transazione l'orologio (now()) è fermo: per far "passare il tempo" i test spostano
-- indietro le date salvate (pg_temp.travel).
--
-- Esito atteso: righe "ok: …" e, in fondo, "CONTROLLI TESSERA SUPERATI".

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

-- Valori fra un passo e l'altro (anche fra ruoli diversi).
create function pg_temp.put(p_key text, p_value jsonb) returns jsonb language sql as $$
    insert into test_values (key, value) values (p_key, p_value::text)
    on conflict (key) do update set value = excluded.value
    returning value::jsonb;
$$;
create function pg_temp.v(p_key text) returns jsonb language sql as $$
    select value::jsonb from test_values where key = p_key;
$$;

create function pg_temp.r6() returns uuid language sql as $$
    select '10000000-0000-0000-0000-000000000006'::uuid
$$;

create function pg_temp.loyal(p_n integer) returns text language sql as $$
    select format('test-loyal-%s@haposto.test', lpad(p_n::text, 2, '0'))
$$;

-- Regole di partenza (v1): 5 timbri, una consumazione fra pizza e primo, dolce offerto subito,
-- un premio per tavolo. p_patch sostituisce le chiavi di primo livello.
create function pg_temp.rules(p_patch jsonb default '{}') returns jsonb language sql as $$
    select '{
        "stamps_required": 5,
        "condition": {"kind": "ONE_OF", "types": ["PIZZA", "FIRST_COURSE"]},
        "double_day": null,
        "reward": {"kind": "GIFT", "gift": "DESSERT", "from": "SAME_VISIT", "weekdays": null,
                   "max_per_table": 1, "cumulable": false}
    }'::jsonb || p_patch;
$$;

-- QR personale dell'utente collegato, salvato con il nome p_key.
create function pg_temp.token(p_key text) returns jsonb language sql as $$
    select pg_temp.put(p_key, public.create_visit_token(pg_temp.r6()));
$$;

-- Scansione dello staff collegato del QR salvato con il nome p_key.
create function pg_temp.stamp(p_key text, p_result text) returns jsonb language sql as $$
    select pg_temp.put(p_result, public.register_stamp(pg_temp.r6(), pg_temp.v(p_key) ->> 'token'));
$$;

-- Da postgres: crea un QR all'utente e lo fa scansionare allo staff; restituisce l'esito.
create function pg_temp.visit(p_email text, p_result text) returns jsonb language plpgsql as $$
declare
    v_result jsonb;
begin
    perform pg_temp.act_as(p_email);
    perform pg_temp.token('qr_' || p_result);
    perform pg_temp.act_as('test-staff@haposto.test');
    v_result := pg_temp.stamp('qr_' || p_result, p_result);
    perform pg_temp.act_as('postgres');
    return v_result;
end;
$$;

-- Da postgres: "passa il tempo" spostando indietro tutte le date della tessera.
create function pg_temp.travel(p_by interval) returns void language plpgsql as $$
begin
    update public.visit_tokens set created_at = created_at - p_by, expires_at = expires_at - p_by,
        used_at = used_at - p_by;
    update public.loyalty_groups set created_at = created_at - p_by, join_until = join_until - p_by,
        expires_at = expires_at - p_by, used_at = used_at - p_by;
    update public.loyalty_group_members set joined_at = joined_at - p_by;
    update public.loyalty_scans set created_at = created_at - p_by, undone_at = undone_at - p_by;
    update public.loyalty_stamps set created_at = created_at - p_by, undone_at = undone_at - p_by,
        prev_last_stamp_at = prev_last_stamp_at - p_by;
    update public.loyalty_cards set started_at = started_at - p_by, last_stamp_at = last_stamp_at - p_by,
        closed_at = closed_at - p_by, reset_warned_at = reset_warned_at - p_by;
    update public.loyalty_rewards set unlocked_at = unlocked_at - p_by, usable_from = usable_from - p_by,
        expires_at = expires_at - p_by, used_at = used_at - p_by, closed_at = closed_at - p_by;
    update public.loyalty_reports set created_at = created_at - p_by;
    update public.loyalty_code_failures set created_at = created_at - p_by;
    update public.loyalty_programs set closing_until = closing_until - p_by,
        suspended_until = suspended_until - p_by, last_suspended_at = last_suspended_at - p_by,
        warned_at = warned_at - p_by, reports_since = reports_since - p_by,
        code_locked_until = code_locked_until - p_by;
end;
$$;

-- Testo di un risultato senza dati personali (nessuna email, nessun id di cliente).
create function pg_temp.no_personal_data(p_text text) returns boolean language sql security definer as $$
    select position('@' in p_text) = 0
       and not exists (select 1 from auth.users u
                       where u.email like 'test-%@haposto.test' and position(u.id::text in p_text) > 0);
$$;

-- ---------------------------------------------------------------------------
-- 0. Preparazione: utenti di prova (25 clienti in più), locale 0006 partner con Pro (beta),
--    titolare e staff.
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
    for i in 1 .. 25 loop
        v_email := pg_temp.loyal(i);
        if not exists (select 1 from auth.users where email = v_email) then
            insert into auth.users (id, email) values (gen_random_uuid(), v_email);
        end if;
    end loop;
end;
$$;
insert into public.profiles (id) select id from auth.users where email like 'test-%@haposto.test'
on conflict (id) do nothing;
select public.admin_set_credentials('test-admin@haposto.test', 'test.admin', 'password-di-prova-123');
update public.app_config set value = '{"restaurants_all_pro_until": "2099-01-01T00:00:00Z"}' where key = 'beta';
update public.restaurants set partnership_status = 'ACTIVE_PARTNER' where id = pg_temp.r6();
delete from public.restaurant_subscriptions where restaurant_id = pg_temp.r6();
delete from public.restaurant_users where restaurant_id = pg_temp.r6();
insert into public.restaurant_users (restaurant_id, user_id, role) values
    (pg_temp.r6(), pg_temp.uid('test-owner@haposto.test'), 'OWNER'),
    (pg_temp.r6(), pg_temp.uid('test-staff@haposto.test'), 'STAFF');
delete from public.notification_outbox where user_id in (select id from auth.users where email like 'test-%@haposto.test');

-- ---------------------------------------------------------------------------
-- 1. Interruttore spento (T7, T9): nessuno vede o fa niente.
-- ---------------------------------------------------------------------------
select pg_temp.expect((select value ->> 'mode' = 'OFF' and value ->> 'launched' = 'false'
                       from public.app_config where key = 'loyalty'),
    'T7: impostazione loyalty presente, spenta e mai lanciata');
select pg_temp.expect(public.loyalty_mode() = 'OFF', 'T7: modalità spenta');
select pg_temp.expect((select 'LOYALTY' = any(features) from public.plans where code = 'RESTAURANT_PRO')
                      and (select not ('LOYALTY' = any(features)) from public.plans where code = 'RESTAURANT_BASIC'),
    'piano: la tessera è una funzione di Pro');

select pg_temp.act_as('test-user@haposto.test');
select pg_temp.expect((public.loyalty_access() ->> 'level') = 'NONE' and not (public.loyalty_access() ->> 'visible')::boolean,
    'T9: spenta, l''app non mostra niente al cliente');
select pg_temp.expect_error($q$select public.create_visit_token(pg_temp.r6())$q$, 'FEATURE_DISABLED',
    'T9: spenta, niente QR');
select pg_temp.expect_error($q$select public.my_loyalty_cards()$q$, 'FEATURE_DISABLED', 'T9: spenta, niente «Le mie tessere»');
select pg_temp.expect_error($q$select public.create_loyalty_group(pg_temp.r6())$q$, 'FEATURE_DISABLED', 'T9: spenta, niente gruppi');
select pg_temp.expect(not (public.loyalty_restaurant_card(pg_temp.r6()) ->> 'available')::boolean,
    'T9: spenta, nessun riquadro nella scheda del locale');
select pg_temp.expect_error($q$select count(*) from public.loyalty_cards$q$, 'permission denied',
    'tabelle della tessera: nessun accesso diretto dall''app');
select pg_temp.expect_error($q$select count(*) from public.visit_tokens$q$, 'permission denied',
    'QR: nessun accesso diretto dall''app');
select pg_temp.expect_error($q$select public.loyalty_maintenance()$q$, 'permission denied',
    'lavoro pianificato: solo per il database');
select pg_temp.expect_error($q$select public.loyalty_cfg('stamps_min')$q$, 'permission denied',
    'funzioni interne: solo per il database');

select pg_temp.act_as(null);
select pg_temp.expect((public.loyalty_access() ->> 'level') = 'NONE', 'anon: spenta, niente tessera');
select pg_temp.expect(not (public.loyalty_restaurant_card(pg_temp.r6()) ->> 'available')::boolean,
    'anon: spenta, nessun riquadro');
select pg_temp.expect_error($q$select public.create_visit_token(pg_temp.r6())$q$, 'permission denied',
    'anon: niente QR senza account');

select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.expect(not (public.restaurant_loyalty_program(pg_temp.r6()) ->> 'visible')::boolean,
    'T9: spenta, nessun menù per il ristoratore');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules(), true)$q$,
    'FEATURE_DISABLED', 'T9: spenta, il ristoratore non attiva la tessera');
select pg_temp.expect_error($q$select public.register_stamp(pg_temp.r6(), 'abc')$q$, 'FEATURE_DISABLED',
    'T9: spenta, niente timbri');
select pg_temp.expect_error($q$select public.restaurant_loyalty_stats(pg_temp.r6(), 30)$q$, 'FEATURE_DISABLED',
    'T9: spenta, niente statistiche');

-- ---------------------------------------------------------------------------
-- 2. Impostazione dal pannello e tester (T7, T8, §13).
-- ---------------------------------------------------------------------------
select pg_temp.act_as('postgres');
select pg_temp.expect_error($q$select public.admin_set_config('loyalty', '{"mode": "ACCESA"}')$q$,
    'INVALID_CONFIG_VALUE', 'impostazione: modalità sconosciuta rifiutata');
select pg_temp.expect_error($q$select public.admin_set_config('loyalty', '{"mode": "TEST", "timbri": 3}')$q$,
    'INVALID_CONFIG_VALUE', 'impostazione: campo sconosciuto rifiutato');
select pg_temp.expect_error($q$select public.admin_set_config('loyalty', '{"mode": "TEST", "stamps_min": 4.5}')$q$,
    'INVALID_CONFIG_VALUE', 'impostazione: numeri interi');
select pg_temp.expect_error($q$select public.admin_set_config('loyalty', '{"mode": "TEST", "token_seconds": 5}')$q$,
    'INVALID_CONFIG_VALUE', 'impostazione: valore fuori dai limiti');
select pg_temp.expect_error($q$select public.admin_set_config('loyalty', '{"mode": "TEST", "stamps_min": 15, "stamps_max": 10}')$q$,
    'INVALID_CONFIG_VALUE', 'impostazione: minimo oltre il massimo');
select public.admin_set_config('loyalty', public.loyalty_defaults() || '{"mode": "TEST", "launched": true}');
select pg_temp.expect(public.loyalty_mode() = 'TEST'
                      and (select value ->> 'launched' = 'false' from public.app_config where key = 'loyalty'),
    'T8: modalità test; «launched» lo decide il server');
select pg_temp.expect(exists (select 1 from public.audit_log where action = 'CONFIG_CHANGED' and details ->> 'key' = 'loyalty'),
    'registro: cambio dell''impostazione');

select pg_temp.act_as('test-user@haposto.test');
select pg_temp.expect_error($q$select public.admin_set_restaurant_loyalty_tester(pg_temp.r6(), true)$q$, 'ADMIN_REQUIRED',
    'tester: solo l''admin sceglie i locali');
select pg_temp.expect_error($q$select public.admin_set_user_loyalty_tester(pg_temp.uid('test-user@haposto.test'), true)$q$,
    'ADMIN_REQUIRED', 'tester: un cliente non si fa tester da solo');
select pg_temp.expect_error($q$update public.profiles set loyalty_tester = true where id = auth.uid()$q$, 'permission denied',
    'tester: il profilo non si modifica dall''app');

select pg_temp.act_as('test-admin@haposto.test');
select public.admin_unlock('test.admin', 'password-di-prova-123');
select public.admin_set_restaurant_loyalty_tester(pg_temp.r6(), true);
select public.admin_set_user_loyalty_tester(pg_temp.uid('test-user@haposto.test'), true);
select public.admin_set_user_loyalty_tester(pg_temp.uid('test-user2@haposto.test'), true);
select pg_temp.expect((public.admin_restaurant_detail(pg_temp.r6()) -> 'loyalty' ->> 'tester')::boolean,
    'pannello: «Tester tessera» nella scheda del locale');
select pg_temp.expect((public.admin_user_detail(pg_temp.uid('test-user@haposto.test')) -> 'profile' ->> 'loyalty_tester')::boolean,
    'pannello: «Tester tessera» nella scheda dell''utente');
select pg_temp.expect(jsonb_array_length(public.admin_loyalty_overview() -> 'tester_restaurants') = 1,
    'pannello: elenco dei locali tester');
select pg_temp.act_as('postgres');
-- Dal SQL Editor (canale di emergenza) anche gli altri clienti di prova, titolare e staff compresi.
select public.admin_set_user_loyalty_tester(u.id, true)
from auth.users u where u.email like 'test-loyal-%@haposto.test'
   or u.email in ('test-owner@haposto.test', 'test-staff@haposto.test');
select pg_temp.expect((select count(*) from public.audit_log where action = 'LOYALTY_TESTER_SET') >= 30,
    'registro: tester scelti');

-- ---------------------------------------------------------------------------
-- 3. Modalità test: solo i tester (T8).
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-thief@haposto.test');
select pg_temp.expect((public.loyalty_access() ->> 'level') = 'NONE', 'T8: chi non è tester non vede niente');
select pg_temp.expect_error($q$select public.create_visit_token(pg_temp.r6())$q$, 'FEATURE_DISABLED',
    'T8: chi non è tester non ha il QR');
select pg_temp.act_as('test-admin@haposto.test');
select pg_temp.expect((public.loyalty_access() ->> 'level') = 'NEW', 'T8: gli admin sono sempre clienti tester');
select pg_temp.act_as('test-user@haposto.test');
select pg_temp.expect((public.loyalty_access() ->> 'visible')::boolean, 'T8: il cliente tester vede la tessera');
select pg_temp.expect_error($q$select public.create_visit_token(pg_temp.r6())$q$, 'LOYALTY_NOT_ACTIVE',
    'locale tester senza programma: niente QR');
select pg_temp.expect_error($q$select public.create_visit_token('10000000-0000-0000-0000-000000000001')$q$,
    'FEATURE_DISABLED', 'T8: locale non tester, niente tessera');
select pg_temp.act_as('test-owner@haposto.test');
insert into test_values select 'program0', public.restaurant_loyalty_program(pg_temp.r6())::text;
select pg_temp.expect((pg_temp.v('program0') ->> 'visible')::boolean and (pg_temp.v('program0') ->> 'can_publish')::boolean
                      and pg_temp.v('program0') ->> 'status' = 'NONE'
                      and (pg_temp.v('program0') -> 'limits' ->> 'stamps_min')::int = 5
                      and (pg_temp.v('program0') -> 'limits' ->> 'stamps_max')::int = 20,
    'T8: il locale tester vede «Tessera fedeltà» con i limiti');

-- ---------------------------------------------------------------------------
-- 4. Attivazione con il patto e versioni immutabili (T11–T19, T40–T47).
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules(), true)$q$,
    'OWNER_REQUIRED', 'T16: attiva solo il titolare');
select pg_temp.act_as('test-owner@haposto.test', 'aal1');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules(), true)$q$,
    'MFA_REQUIRED', 'T16: serve la verifica in due passaggi');
select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules(), false)$q$,
    'LOYALTY_PACT_REQUIRED', 'T16: senza «Accetto» non si attiva');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules('{"stamps_required": 4}'), true)$q$,
    'LOYALTY_INVALID_STAMPS', 'T11: almeno 5 timbri');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules('{"stamps_required": 21}'), true)$q$,
    'LOYALTY_INVALID_STAMPS', 'T11: al massimo 20 timbri');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules('{"stamps_required": "10"}'), true)$q$,
    'LOYALTY_INVALID_STAMPS', 'T11: i timbri sono un numero');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules('{"condition": {"kind": "SPEND", "min_spend_cents": 400}}'), true)$q$,
    'LOYALTY_INVALID_CONDITION', 'T12: spesa minima almeno 5 €');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules('{"condition": {"kind": "SPEND", "min_spend_cents": 5100}}'), true)$q$,
    'LOYALTY_INVALID_CONDITION', 'T12: spesa minima al massimo 50 €');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules('{"condition": {"kind": "SPEND", "min_spend_cents": 1500, "types": ["PIZZA"]}}'), true)$q$,
    'LOYALTY_INVALID_CONDITION', 'T12: con la spesa minima niente tipologie');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules('{"condition": {"kind": "ONE_OF", "types": []}}'), true)$q$,
    'LOYALTY_INVALID_CONDITION', 'T13: almeno una tipologia');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules('{"condition": {"kind": "TWO_OF", "types": ["PIZZA"]}}'), true)$q$,
    'LOYALTY_INVALID_CONDITION', 'T12: «due consumazioni» vuole almeno due tipologie');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules('{"condition": {"kind": "ONE_OF", "types": ["WINE"]}}'), true)$q$,
    'LOYALTY_INVALID_CONDITION', 'T13: solo tipologie della lista');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules('{"condition": {"kind": "TWO_OF", "types": ["PIZZA", "PIZZA"]}}'), true)$q$,
    'LOYALTY_INVALID_CONDITION', 'T12: tipologie senza doppioni');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules('{"double_day": {"weekday": 8, "slot": "ALL_DAY"}}'), true)$q$,
    'LOYALTY_INVALID_DOUBLE_DAY', 'T14: giorno della settimana valido');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules('{"double_day": {"weekday": 5, "slot": "NIGHT"}}'), true)$q$,
    'LOYALTY_INVALID_DOUBLE_DAY', 'T14: fascia tutto il giorno, pranzo o cena');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules('{"reward": {"kind": "GIFT", "gift": "BEER", "from": "SAME_VISIT", "cumulable": false}}'), true)$q$,
    'LOYALTY_INVALID_REWARD', 'T40: omaggio solo dalla lista, niente alcolici');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules('{"reward": {"kind": "GIFT", "gift": "DESSERT", "percent": 10, "from": "SAME_VISIT", "cumulable": false}}'), true)$q$,
    'LOYALTY_INVALID_REWARD', 'T40: l''omaggio non ha percentuali');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules('{"reward": {"kind": "MONEY", "amount_cents": 500, "from": "SAME_VISIT", "cumulable": false}}'), true)$q$,
    'LOYALTY_INVALID_REWARD', 'T5: nessun premio in denaro');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules('{"reward": {"kind": "DISCOUNT", "percent": 60, "cap_cents": 1000, "from": "SAME_VISIT", "cumulable": false}}'), true)$q$,
    'LOYALTY_INVALID_REWARD', 'T41: sconto al massimo del 50%');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules('{"reward": {"kind": "DISCOUNT", "percent": 20, "from": "SAME_VISIT", "cumulable": false}}'), true)$q$,
    'LOYALTY_INVALID_REWARD', 'T41: tetto dello sconto obbligatorio');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules('{"reward": {"kind": "DISCOUNT", "percent": 20, "cap_cents": 6000, "from": "SAME_VISIT", "cumulable": false}}'), true)$q$,
    'LOYALTY_INVALID_REWARD', 'T41: tetto dello sconto al massimo 50 €');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules('{"reward": {"kind": "VOUCHER", "amount_cents": 500, "min_spend_cents": 900, "from": "NEXT_VISIT", "cumulable": false}}'), true)$q$,
    'LOYALTY_INVALID_REWARD', 'T42: buono con spesa minima almeno doppia');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules('{"reward": {"kind": "VOUCHER", "amount_cents": 500, "min_spend_cents": 1000, "from": "SAME_VISIT", "cumulable": false}}'), true)$q$,
    'LOYALTY_INVALID_REWARD', 'T42: buono solo dalla visita successiva');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules('{"reward": {"kind": "VOUCHER", "amount_cents": 2500, "min_spend_cents": 5000, "from": "NEXT_VISIT", "cumulable": false}}'), true)$q$,
    'LOYALTY_INVALID_REWARD', 'T42: buono al massimo di 20 €');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules('{"reward": {"kind": "GIFT", "gift": "DESSERT", "from": "SAME_VISIT", "weekdays": [1, 2], "cumulable": false}}'), true)$q$,
    'LOYALTY_INVALID_REWARD', 'T44: almeno 3 giorni di utilizzo');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules('{"reward": {"kind": "GIFT", "gift": "DESSERT", "from": "SAME_VISIT", "weekdays": [1, 1, 2, 3], "cumulable": false}}'), true)$q$,
    'LOYALTY_INVALID_REWARD', 'T44: giorni senza doppioni');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules('{"reward": {"kind": "GIFT", "gift": "DESSERT", "from": "SAME_VISIT", "weekdays": [0, 1, 2], "cumulable": false}}'), true)$q$,
    'LOYALTY_INVALID_REWARD', 'T44: giorni da 1 (lunedì) a 7 (domenica)');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules('{"reward": {"kind": "GIFT", "gift": "DESSERT", "from": "SAME_VISIT", "max_per_table": 11, "cumulable": false}}'), true)$q$,
    'LOYALTY_INVALID_REWARD', 'T45: da 1 a 10 premi per tavolo (o senza limite)');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules('{"reward": {"kind": "GIFT", "gift": "DESSERT", "from": "SAME_VISIT"}}'), true)$q$,
    'LOYALTY_INVALID_REWARD', 'T46: cumulabile sì o no, da dichiarare');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules('{"reward": {"kind": "GIFT", "gift": "DESSERT", "cumulable": false}}'), true)$q$,
    'LOYALTY_INVALID_REWARD', 'T43: da quando si usa, da dichiarare');

select pg_temp.put('v1', public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules(), true));
select pg_temp.expect((pg_temp.v('v1') ->> 'version')::int = 1, 'T18: prima versione numerata');
select pg_temp.act_as('postgres');
select pg_temp.expect(exists (select 1 from public.consent_log
                              where user_id = pg_temp.uid('test-owner@haposto.test') and kind = 'LOYALTY_PACT'
                                and version = pg_temp.r6()::text || ':v1' and granted),
    'T17: patto registrato in consent_log (LOYALTY_PACT) con versione e account');
select pg_temp.expect(exists (select 1 from public.audit_log where action = 'LOYALTY_VERSION_PUBLISHED' and restaurant_id = pg_temp.r6()),
    'registro: versione pubblicata');
select pg_temp.expect_error($q$update public.loyalty_program_versions set stamps_required = 6 where restaurant_id = pg_temp.r6()$q$,
    'LOYALTY_VERSION_IMMUTABLE', 'T18: una versione non si modifica');
select pg_temp.expect_error($q$delete from public.loyalty_program_versions where restaurant_id = pg_temp.r6()$q$,
    'LOYALTY_VERSION_IMMUTABLE', 'T18: una versione non si cancella');
select pg_temp.act_as('test-staff@haposto.test');
insert into test_values select 'program1', public.restaurant_loyalty_program(pg_temp.r6())::text;
select pg_temp.expect(pg_temp.v('program1') ->> 'status' = 'ACTIVE' and pg_temp.v('program1') ->> 'level' = 'NEW'
                      and (pg_temp.v('program1') -> 'current' ->> 'version')::int = 1
                      and pg_temp.v('program1') -> 'current' -> 'reward' ->> 'gift' = 'DESSERT'
                      and (pg_temp.v('program1') -> 'current' -> 'reward' ->> 'valid_days')::int = 60,
    'T27: il collaboratore vede le regole della versione attiva (premio valido 60 giorni)');

-- ---------------------------------------------------------------------------
-- 5. Timbro con il QR personale (T23, T32, T35–T38, T55).
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-user@haposto.test');
select pg_temp.token('qr1');
select pg_temp.expect(pg_temp.v('qr1') ->> 'token' ~ '^[0-9a-f]{32}$' and pg_temp.v('qr1') ->> 'code' ~ '^[A-HJKMNP-Z2-9]{6}$'
                      and (pg_temp.v('qr1') ->> 'seconds')::int = 60,
    'T36: QR casuale da 128 bit, codice di riserva di 6 caratteri, 60 secondi');
select pg_temp.expect(public.visit_token_status(pg_temp.v('qr1') ->> 'token') ->> 'status' = 'WAITING',
    'schermata del cliente: in attesa della scansione');
select pg_temp.act_as('postgres');
select pg_temp.expect(exists (select 1 from public.visit_tokens
                              where token_hash = extensions.digest(pg_temp.v('qr1') ->> 'token', 'sha256')
                                and code_hash = extensions.digest(pg_temp.v('qr1') ->> 'code', 'sha256'))
                      and not exists (select 1 from public.visit_tokens t
                                      where position(pg_temp.v('qr1') ->> 'token' in to_jsonb(t)::text) > 0),
    'T56: il database conserva solo le impronte del QR e del codice');
select pg_temp.act_as('test-staff@haposto.test', 'aal1');
select pg_temp.expect_error($q$select public.register_stamp(pg_temp.r6(), pg_temp.v('qr1') ->> 'token')$q$, 'MFA_REQUIRED',
    'timbrare richiede la verifica in due passaggi');
select pg_temp.act_as('test-thief@haposto.test');
select pg_temp.expect_error($q$select public.register_stamp(pg_temp.r6(), pg_temp.v('qr1') ->> 'token')$q$,
    'Not authorized for this restaurant', 'timbra solo chi gestisce il locale');
select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.stamp('qr1', 's1');
select pg_temp.expect((pg_temp.v('s1') ->> 'ok')::boolean and (pg_temp.v('s1') ->> 'people')::int = 1
                      and pg_temp.v('s1') -> 'members' -> 0 ->> 'outcome' = 'STAMPED'
                      and (pg_temp.v('s1') -> 'members' -> 0 ->> 'stamps')::int = 1
                      and (pg_temp.v('s1') -> 'members' -> 0 ->> 'required')::int = 5
                      and pg_temp.v('s1') -> 'members' -> 0 -> 'condition' ->> 'kind' = 'ONE_OF',
    'T23, T32: primo timbro, tessera nata e aggiornata subito (1 su 5, con la condizione)');
select pg_temp.expect(pg_temp.v('s1') -> 'members' -> 0 ->> 'code' ~ '^[A-HJKMNP-Z2-9]{4}$'
                      and pg_temp.no_personal_data(pg_temp.v('s1')::text),
    'T55: lo staff vede solo il codice anonimo, mai email o id');
select pg_temp.expect(pg_temp.stamp('qr1', 's1b') ->> 'error' = 'TOKEN_USED', 'T35: il QR vale una volta sola');
select pg_temp.expect(public.register_stamp(pg_temp.r6(), repeat('ab', 16)) ->> 'error' = 'INVALID_TOKEN',
    'T36: un QR inventato non vale');
select pg_temp.act_as('test-user@haposto.test');
select pg_temp.expect(public.visit_token_status(pg_temp.v('qr1') ->> 'token') ->> 'status' = 'USED'
                      and (public.visit_token_status(pg_temp.v('qr1') ->> 'token') -> 'result' ->> 'stamps')::int = 1,
    'schermata del cliente: «✓ +1 timbro · 1 su 5»');
select pg_temp.token('qr2');
select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.stamp('qr2', 's2');
select pg_temp.expect(pg_temp.v('s2') -> 'members' -> 0 ->> 'outcome' = 'TOO_SOON'
                      and (pg_temp.v('s2') -> 'members' -> 0 ->> 'stamps_added')::int = 0
                      and (pg_temp.v('s2') -> 'members' -> 0 ->> 'stamps')::int = 1,
    'T37: un timbro ogni 4 ore per locale');
select pg_temp.act_as('test-user2@haposto.test');
select pg_temp.token('qr_wrong_place');
select pg_temp.token('qr_expired');
select pg_temp.act_as('postgres');
update public.visit_tokens set restaurant_id = '10000000-0000-0000-0000-000000000001'
where token_hash = extensions.digest(pg_temp.v('qr_wrong_place') ->> 'token', 'sha256');
update public.visit_tokens set expires_at = now() - interval '1 second'
where token_hash = extensions.digest(pg_temp.v('qr_expired') ->> 'token', 'sha256');
select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.expect(pg_temp.stamp('qr_wrong_place', 's_wrong') ->> 'error' = 'INVALID_TOKEN',
    'T35: il QR di un altro locale non vale');
select pg_temp.expect(pg_temp.stamp('qr_expired', 's_exp') ->> 'error' = 'TOKEN_EXPIRED', 'T35: dopo 60 secondi il QR non vale');
select pg_temp.act_as('test-user2@haposto.test');
select pg_temp.token('qr_code');
select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.put('s_code', public.register_stamp(pg_temp.r6(), null,
    lower(substr(pg_temp.v('qr_code') ->> 'code', 1, 3)) || '-' || lower(substr(pg_temp.v('qr_code') ->> 'code', 4))));
select pg_temp.expect(pg_temp.v('s_code') -> 'members' -> 0 ->> 'outcome' = 'STAMPED',
    '§6.1: «Inserisci codice» (anche minuscolo e con il trattino)');
select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.expect_error($q$select public.create_visit_token(pg_temp.r6())$q$, 'LOYALTY_OWN_RESTAURANT',
    'T38: il titolare non ha la tessera del suo locale');
select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.expect_error($q$select public.create_loyalty_group(pg_temp.r6())$q$, 'LOYALTY_OWN_RESTAURANT',
    'T38: lo staff non crea un tavolo nel suo locale');
select pg_temp.act_as('test-user@haposto.test');
select pg_temp.expect(jsonb_array_length(public.my_loyalty_cards()) = 1
                      and (public.my_loyalty_cards() -> 0 -> 'card' ->> 'stamps')::int = 1
                      and (public.my_loyalty_cards() -> 0 -> 'card' -> 'rules' ->> 'stamps_required')::int = 5
                      and public.my_loyalty_cards() -> 0 ->> 'code' = pg_temp.v('s1') -> 'members' -> 0 ->> 'code',
    'T27: «Le mie tessere» con timbri, regole e codice');
select pg_temp.expect((public.loyalty_restaurant_card(pg_temp.r6()) ->> 'available')::boolean
                      and (public.loyalty_restaurant_card(pg_temp.r6()) -> 'card' ->> 'stamps')::int = 1,
    'riquadro nella scheda del locale con la propria tessera');
select pg_temp.act_as(null);
select pg_temp.expect(not (public.loyalty_restaurant_card(pg_temp.r6()) ->> 'available')::boolean,
    'T8: in prova, senza account non si vede');
select pg_temp.act_as('test-staff@haposto.test');
insert into test_values select 'cards', public.restaurant_loyalty_cards(pg_temp.r6())::text;
select pg_temp.expect(jsonb_array_length(pg_temp.v('cards')) = 2 and pg_temp.no_personal_data(pg_temp.v('cards')::text)
                      and not (pg_temp.v('cards') -> 0 ? 'user_id'),
    'T55: elenco delle tessere con il solo codice anonimo');

-- ---------------------------------------------------------------------------
-- 6. Codice di riserva sbagliato (T36): 10 errori in 10 minuti bloccano per 10 minuti.
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.expect(public.register_stamp(pg_temp.r6(), null, 'ZZZZZZ') ->> 'error' = 'INVALID_CODE',
    'T36: codice sbagliato');
select public.register_stamp(pg_temp.r6(), null, 'ZZZZZZ') from generate_series(1, 8);
select pg_temp.expect(public.register_stamp(pg_temp.r6(), null, 'ZZZZZZ') ->> 'error' = 'CODE_LOCKED',
    'T36: al decimo codice sbagliato l''inserimento si blocca');
select pg_temp.act_as('test-user2@haposto.test');
select pg_temp.token('qr_locked');
select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.expect(public.register_stamp(pg_temp.r6(), null, pg_temp.v('qr_locked') ->> 'code') ->> 'error' = 'CODE_LOCKED',
    'T36: durante il blocco neanche il codice giusto passa');
select pg_temp.expect(pg_temp.stamp('qr_locked', 's_locked') ->> 'ok' = 'true',
    'T36: il QR si scansiona anche durante il blocco dei codici');
select pg_temp.act_as('postgres');
select pg_temp.expect((select count(*) from public.loyalty_code_failures where restaurant_id = pg_temp.r6()) = 0
                      and (select code_locked_until = now() + interval '10 minutes' from public.loyalty_programs
                           where restaurant_id = pg_temp.r6()),
    'T36: blocco di 10 minuti salvato (gli errori non annullano il conteggio)');
select pg_temp.travel(interval '11 minutes');
select pg_temp.act_as('test-user@haposto.test');
select pg_temp.token('qr_unlocked');
select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.expect(public.register_stamp(pg_temp.r6(), null, pg_temp.v('qr_unlocked') ->> 'code') ->> 'ok' = 'true',
    'T36: dopo 10 minuti il codice si inserisce di nuovo');

-- ---------------------------------------------------------------------------
-- 7. Tetti automatici di scansione (T39).
-- ---------------------------------------------------------------------------
select pg_temp.act_as('postgres');
insert into public.loyalty_scans (restaurant_id, kind) select pg_temp.r6(), 'PERSONAL' from generate_series(1, 60);
select pg_temp.act_as('test-user@haposto.test');
select pg_temp.token('qr_cap');
select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.expect_error($q$select pg_temp.stamp('qr_cap', 's_cap')$q$, 'SCAN_LIMIT', 'T39: al massimo 60 scansioni ogni 10 minuti');
select pg_temp.act_as('postgres');
delete from public.loyalty_scans where restaurant_id = pg_temp.r6() and token_id is null and scanned_by is null;
update public.app_config set value = value || '{"scans_per_day": 3}' where key = 'loyalty';
insert into public.loyalty_scans (restaurant_id, kind) select pg_temp.r6(), 'PERSONAL' from generate_series(1, 3);
select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.expect_error($q$select pg_temp.stamp('qr_cap', 's_cap')$q$, 'SCAN_LIMIT', 'T39: tetto giornaliero (qui 3 per la prova; di base 300)');
select pg_temp.act_as('postgres');
delete from public.loyalty_scans where restaurant_id = pg_temp.r6() and token_id is null and scanned_by is null;
update public.app_config set value = value - 'scans_per_day' where key = 'loyalty';

-- ---------------------------------------------------------------------------
-- 8. Timbro di gruppo: una sola scansione per il tavolo (T28–T31, T38).
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-user@haposto.test');
select pg_temp.put('g1', public.create_loyalty_group(pg_temp.r6()));
select pg_temp.expect((pg_temp.v('g1') ->> 'members')::int = 1 and pg_temp.v('g1') ->> 'token' ~ '^[0-9a-f]{32}$',
    '§6.2: «Siamo in gruppo» crea il QR del tavolo');
do $$
begin
    for i in 1 .. 5 loop
        perform pg_temp.act_as(pg_temp.loyal(i));
        perform public.join_loyalty_group(pg_temp.v('g1') ->> 'token');
    end loop;
end;
$$;
select pg_temp.act_as(pg_temp.loyal(1));
select pg_temp.expect((public.join_loyalty_group(pg_temp.v('g1') ->> 'token') ->> 'members')::int = 6,
    'T28: unirsi di nuovo allo stesso tavolo non conta due volte');
select pg_temp.act_as('test-thief@haposto.test');
select pg_temp.expect_error($q$select public.join_loyalty_group(pg_temp.v('g1') ->> 'token')$q$, 'FEATURE_DISABLED',
    'T8: chi non è tester non si unisce');
select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.expect_error($q$select public.join_loyalty_group(pg_temp.v('g1') ->> 'token')$q$, 'LOYALTY_OWN_RESTAURANT',
    'T38: lo staff non si unisce a un tavolo del suo locale');
select pg_temp.act_as('test-user@haposto.test');
select pg_temp.expect((public.loyalty_group_status((pg_temp.v('g1') ->> 'group_id')::uuid) ->> 'members')::int = 6,
    'T28: sul telefono del capogruppo «Tavolo: 6 persone»');
select pg_temp.put('g1_token2', public.loyalty_group_token((pg_temp.v('g1') ->> 'group_id')::uuid));
select pg_temp.expect(pg_temp.v('g1_token2') ->> 'token' <> pg_temp.v('g1') ->> 'token',
    'T28: il QR del tavolo si rinnova');
-- Un collaboratore finito nel gruppo (per esempio aggiunto prima di diventare staff): escluso.
select pg_temp.act_as('postgres');
insert into public.loyalty_group_members (group_id, user_id)
values ((pg_temp.v('g1') ->> 'group_id')::uuid, pg_temp.uid('test-staff@haposto.test'));
select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.put('sg1', public.register_stamp(pg_temp.r6(), pg_temp.v('g1_token2') ->> 'token'));
select pg_temp.expect((pg_temp.v('sg1') ->> 'people')::int = 7 and (pg_temp.v('sg1') ->> 'stamped')::int = 5
                      and pg_temp.v('sg1') ->> 'kind' = 'GROUP',
    'T29, T30: una scansione, lo staff vede 7 persone e 5 timbri');
select pg_temp.expect((select count(*) from jsonb_array_elements(pg_temp.v('sg1') -> 'members') m where m ->> 'outcome' = 'TOO_SOON') = 1
                      and (select count(*) from jsonb_array_elements(pg_temp.v('sg1') -> 'members') m where m ->> 'outcome' = 'SELF') = 1,
    'T29, T38: escluso chi ha già il timbro oggi e chi gestisce il locale');
select pg_temp.expect(pg_temp.no_personal_data(pg_temp.v('sg1')::text), 'T55: nel gruppo solo codici anonimi');
select pg_temp.expect(public.register_stamp(pg_temp.r6(), pg_temp.v('g1') ->> 'token') ->> 'error' = 'TOKEN_USED',
    'T35: il tavolo si timbra una volta sola (anche con un QR precedente)');
select pg_temp.act_as('postgres');
select pg_temp.expect((select count(*) from public.loyalty_scans where restaurant_id = pg_temp.r6() and kind = 'GROUP') = 1,
    'T39: la scansione di gruppo conta come una');
select pg_temp.act_as(pg_temp.loyal(1));
select pg_temp.expect(public.loyalty_group_status((pg_temp.v('g1') ->> 'group_id')::uuid) ->> 'status' = 'USED'
                      and public.loyalty_group_status((pg_temp.v('g1') ->> 'group_id')::uuid) -> 'result' ->> 'outcome' = 'STAMPED',
    'T29: ognuno vede il suo timbro sul proprio telefono');
select pg_temp.act_as('test-user@haposto.test');
select pg_temp.expect_error($q$select public.loyalty_group_token((pg_temp.v('g1') ->> 'group_id')::uuid)$q$, 'GROUP_CLOSED',
    'T28: un tavolo già timbrato non si riapre');
-- Fino a 20 persone.
select pg_temp.act_as(pg_temp.loyal(6));
select pg_temp.put('g2', public.create_loyalty_group(pg_temp.r6()));
do $$
begin
    for i in 7 .. 25 loop
        perform pg_temp.act_as(pg_temp.loyal(i));
        perform public.join_loyalty_group(pg_temp.v('g2') ->> 'token');
    end loop;
end;
$$;
select pg_temp.act_as('test-user2@haposto.test');
select pg_temp.expect_error($q$select public.join_loyalty_group(pg_temp.v('g2') ->> 'token')$q$, 'GROUP_FULL',
    'T28: al massimo 20 persone per tavolo');
-- Un gruppo alla volta: chi crea un altro tavolo esce dal primo; il capogruppo che esce lo chiude.
select pg_temp.act_as(pg_temp.loyal(7));
select pg_temp.put('g3', public.create_loyalty_group(pg_temp.r6()));
select pg_temp.act_as(pg_temp.loyal(6));
select pg_temp.expect((public.loyalty_group_status((pg_temp.v('g2') ->> 'group_id')::uuid) ->> 'members')::int = 19,
    'T28: si sta in un solo gruppo alla volta');
select pg_temp.act_as(pg_temp.loyal(7));
select public.leave_loyalty_group((pg_temp.v('g3') ->> 'group_id')::uuid);
select pg_temp.expect(public.loyalty_group_status((pg_temp.v('g3') ->> 'group_id')::uuid) ->> 'status' = 'CLOSED',
    'il capogruppo che esce chiude il tavolo');
-- Entro 10 minuti.
select pg_temp.act_as('postgres');
update public.loyalty_groups set join_until = now() - interval '1 second' where id = (pg_temp.v('g2') ->> 'group_id')::uuid;
select pg_temp.act_as('test-user2@haposto.test');
select pg_temp.expect_error($q$select public.join_loyalty_group(pg_temp.v('g2') ->> 'token')$q$, 'GROUP_CLOSED',
    'T28: ci si unisce solo entro 10 minuti');

-- ---------------------------------------------------------------------------
-- 9. Nuova versione, giorno doppio, premio (T2, T3, T14, T19, T25, T43–T47).
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.put('v2', public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules(jsonb_build_object(
    'condition', '{"kind": "SPEND", "min_spend_cents": 1500}'::jsonb,
    'double_day', jsonb_build_object('weekday', extract(isodow from (now() at time zone 'Europe/Rome'))::int, 'slot', 'ALL_DAY'),
    'reward', '{"kind": "DISCOUNT", "percent": 20, "cap_cents": 1000, "from": "NEXT_VISIT", "weekdays": null,
                "max_per_table": null, "cumulable": true}'::jsonb)), true));
select pg_temp.expect((pg_temp.v('v2') ->> 'version')::int = 2, 'T19: modificare = pubblicare la versione 2');
select pg_temp.act_as('test-user@haposto.test');
select pg_temp.expect((public.my_loyalty_cards() -> 0 -> 'card' -> 'rules' ->> 'version')::int = 1,
    'T2, T3: chi ha già iniziato resta sulla sua versione');
select pg_temp.act_as('postgres');
select pg_temp.visit(pg_temp.loyal(8), 's_new_v2');
select pg_temp.expect(pg_temp.v('s_new_v2') -> 'members' -> 0 ->> 'outcome' = 'STAMPED'
                      and (pg_temp.v('s_new_v2') -> 'members' -> 0 ->> 'stamps_added')::int = 2
                      and (pg_temp.v('s_new_v2') -> 'members' -> 0 ->> 'double_day')::boolean
                      and pg_temp.v('s_new_v2') -> 'members' -> 0 -> 'condition' ->> 'kind' = 'SPEND',
    'T14, T19: una tessera nuova nasce sulla versione 2, con il giorno doppio (+2)');
-- Il giorno doppio alle ore italiane: pranzo 11–15, cena 18–23.
select pg_temp.expect(
    public.loyalty_is_double(extract(isodow from make_timestamptz(2026, 10, 12, 12, 0, 0, 'Europe/Rome'))::smallint, 'LUNCH',
                             make_timestamptz(2026, 10, 12, 12, 0, 0, 'Europe/Rome'))
    and not public.loyalty_is_double(extract(isodow from make_timestamptz(2026, 10, 12, 12, 0, 0, 'Europe/Rome'))::smallint, 'LUNCH',
                                     make_timestamptz(2026, 10, 12, 16, 0, 0, 'Europe/Rome'))
    and public.loyalty_is_double(extract(isodow from make_timestamptz(2026, 10, 12, 12, 0, 0, 'Europe/Rome'))::smallint, 'DINNER',
                                 make_timestamptz(2026, 10, 12, 22, 30, 0, 'Europe/Rome'))
    and not public.loyalty_is_double(extract(isodow from make_timestamptz(2026, 10, 12, 12, 0, 0, 'Europe/Rome'))::smallint, 'DINNER',
                                     make_timestamptz(2026, 10, 12, 23, 30, 0, 'Europe/Rome'))
    and not public.loyalty_is_double((extract(isodow from make_timestamptz(2026, 10, 12, 12, 0, 0, 'Europe/Rome'))::smallint % 7 + 1)::smallint,
                                     'ALL_DAY', make_timestamptz(2026, 10, 12, 12, 0, 0, 'Europe/Rome')),
    'T14: giorno doppio solo nel giorno e nella fascia scelti (ora italiana)');
-- test-user completa la tessera v1 (5 timbri, una visita ogni 5 ore).
select pg_temp.travel(interval '5 hours');
select pg_temp.visit('test-user@haposto.test', 's_u2');
select pg_temp.travel(interval '5 hours');
select pg_temp.visit('test-user@haposto.test', 's_u3');
select pg_temp.travel(interval '5 hours');
select pg_temp.visit('test-user@haposto.test', 's_u4');
select pg_temp.expect((pg_temp.v('s_u4') -> 'members' -> 0 ->> 'stamps')::int = 4
                      and not (pg_temp.v('s_u4') -> 'members' -> 0 ->> 'double_day')::boolean,
    'T2: sulla versione 1 niente giorno doppio (4 su 5)');
select pg_temp.travel(interval '5 hours');
select pg_temp.visit('test-user@haposto.test', 's_u5');
select pg_temp.expect((pg_temp.v('s_u5') -> 'members' -> 0 ->> 'reward_unlocked')::boolean
                      and (pg_temp.v('s_u5') -> 'members' -> 0 ->> 'stamps')::int = 5
                      and jsonb_array_length(pg_temp.v('s_u5') -> 'rewards') = 1
                      and pg_temp.v('s_u5') -> 'rewards' -> 0 ->> 'gift' = 'DESSERT'
                      and (pg_temp.v('s_u5') -> 'rewards' -> 0 ->> 'usable_now')::boolean
                      and pg_temp.v('s_u5') -> 'rewards' -> 0 ->> 'code' = pg_temp.v('s_u5') -> 'members' -> 0 ->> 'code',
    'T25, T43: premio sbloccato, lo staff lo vede subito con le sue regole');
select pg_temp.put('r1', pg_temp.v('s_u5') -> 'rewards' -> 0);
select pg_temp.expect((select c.status = 'COMPLETED' from public.loyalty_cards c
                       join public.loyalty_rewards rw on rw.card_id = c.id
                       where rw.id = (pg_temp.v('r1') ->> 'reward_id')::uuid)
                      and (select expires_at = unlocked_at + interval '60 days' from public.loyalty_rewards
                           where id = (pg_temp.v('r1') ->> 'reward_id')::uuid),
    'T25, T47: tessera completata, premio valido 60 giorni');
-- Visita dopo: tessera nuova sulla versione 2; dopo tre visite col doppio (2+2+2 = 6 su 5) premio e
-- un timbro che passa alla tessera nuova.
select pg_temp.travel(interval '5 hours');
select pg_temp.visit('test-user@haposto.test', 's_u6');
select pg_temp.expect((pg_temp.v('s_u6') -> 'members' -> 0 ->> 'stamps')::int = 2
                      and (pg_temp.v('s_u6') -> 'members' -> 0 ->> 'stamps_added')::int = 2,
    'T25: alla visita dopo parte una tessera nuova, sulla versione attiva');
select pg_temp.travel(interval '5 hours');
select pg_temp.visit('test-user@haposto.test', 's_u7');
select pg_temp.travel(interval '5 hours');
select pg_temp.visit('test-user@haposto.test', 's_u8');
select pg_temp.expect((pg_temp.v('s_u8') -> 'members' -> 0 ->> 'reward_unlocked')::boolean
                      and (pg_temp.v('s_u8') -> 'members' -> 0 ->> 'carry')::int = 1
                      and (select count(*) from public.loyalty_cards
                           where user_id = pg_temp.uid('test-user@haposto.test') and status = 'ACTIVE' and stamps = 1) = 1,
    'T25: il timbro in più del giorno doppio passa alla tessera nuova');
select pg_temp.put('r2', (select x from jsonb_array_elements(pg_temp.v('s_u8') -> 'rewards') x where x ->> 'kind' = 'DISCOUNT'));
select pg_temp.expect(not (pg_temp.v('r2') ->> 'usable_now')::boolean,
    'T43: premio «dalla visita successiva» non usabile alla stessa visita');
select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.expect_error($q$select public.use_reward(pg_temp.r6(), (pg_temp.v('r2') ->> 'reward_id')::uuid)$q$, 'REWARD_NOT_YET',
    'T43: lo sconto si usa dalla visita successiva');
select pg_temp.act_as('postgres');
select pg_temp.travel(interval '5 hours');
select pg_temp.visit('test-user@haposto.test', 's_u9');
select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.expect_error($q$select public.use_reward(pg_temp.r6(), (pg_temp.v('r2') ->> 'reward_id')::uuid, 1500)$q$,
    'INVALID_DISCOUNT', 'T41: lo sconto riconosciuto non supera il tetto');
select pg_temp.expect((public.use_reward(pg_temp.r6(), (pg_temp.v('r2') ->> 'reward_id')::uuid, 800) ->> 'ok')::boolean,
    '§8.3: «Applicato» con lo sconto riconosciuto');
select pg_temp.expect_error($q$select public.use_reward(pg_temp.r6(), (pg_temp.v('r2') ->> 'reward_id')::uuid)$q$,
    'REWARD_NOT_AVAILABLE', 'T5: un premio si usa una volta sola');
select pg_temp.expect_error($q$select public.use_reward(pg_temp.r6(), (pg_temp.v('r1') ->> 'reward_id')::uuid)$q$,
    'REWARD_TABLE_LIMIT', 'T45: limite di premi per tavolo alla stessa visita (qui 1)');
select pg_temp.act_as('postgres');
select pg_temp.expect((select status from public.loyalty_rewards where id = (pg_temp.v('r1') ->> 'reward_id')::uuid) = 'AVAILABLE',
    'T45: il premio in più resta valido per un''altra visita');
select pg_temp.travel(interval '1 hour');
select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.expect_error($q$select public.use_reward(pg_temp.r6(), (pg_temp.v('r1') ->> 'reward_id')::uuid)$q$,
    'REWARD_NEEDS_SCAN', 'T4: il premio si consegna solo a chi è stato appena scansionato');
select pg_temp.act_as('postgres');
select pg_temp.expect(not public.loyalty_reward_usable_now('AVAILABLE', now() - interval '1 hour', now() + interval '1 day',
                          array(select ((extract(isodow from (now() at time zone 'Europe/Rome'))::int + d - 1) % 7 + 1)::smallint
                                from generate_series(1, 3) d))
                      and public.loyalty_reward_usable_now('AVAILABLE', now() - interval '1 hour', now() + interval '1 day',
                          array(select ((extract(isodow from (now() at time zone 'Europe/Rome'))::int + d - 1) % 7 + 1)::smallint
                                from generate_series(0, 2) d)),
    'T44: il premio si usa solo nei giorni scelti');
select pg_temp.expect((select discount_cents = 800 and used_by = pg_temp.uid('test-staff@haposto.test')
                       from public.loyalty_rewards where id = (pg_temp.v('r2') ->> 'reward_id')::uuid),
    '§11: sconto riconosciuto registrato');

-- ---------------------------------------------------------------------------
-- 10. Annullamento entro 2 minuti (T33).
-- ---------------------------------------------------------------------------
select pg_temp.travel(interval '5 hours');
select pg_temp.visit(pg_temp.loyal(1), 's_undo');
select pg_temp.expect((pg_temp.v('s_undo') -> 'members' -> 0 ->> 'stamps')::int = 2, 'secondo timbro prima dell''annullamento');
select pg_temp.act_as('test-thief@haposto.test');
select pg_temp.expect_error($q$select public.undo_stamp((pg_temp.v('s_undo') ->> 'scan_id')::uuid)$q$, 'SCAN_NOT_FOUND',
    'T33: annulla solo il locale che ha scansionato');
select pg_temp.act_as('test-staff@haposto.test');
select public.undo_stamp((pg_temp.v('s_undo') ->> 'scan_id')::uuid);
select pg_temp.act_as('postgres');
select pg_temp.expect((select stamps from public.loyalty_cards
                       where user_id = pg_temp.uid(pg_temp.loyal(1)) and status = 'ACTIVE') = 1
                      and exists (select 1 from public.loyalty_scans where id = (pg_temp.v('s_undo') ->> 'scan_id')::uuid
                                  and undone_at is not null)
                      and exists (select 1 from public.audit_log where action = 'LOYALTY_SCAN_UNDONE'),
    'T33: annullato e registrato, la tessera torna come prima');
select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.expect_error($q$select public.undo_stamp((pg_temp.v('s_undo') ->> 'scan_id')::uuid)$q$, 'ALREADY_UNDONE',
    'T33: non si annulla due volte');
select pg_temp.act_as('postgres');
select pg_temp.visit(pg_temp.loyal(1), 's_after_undo');
select pg_temp.expect(pg_temp.v('s_after_undo') -> 'members' -> 0 ->> 'outcome' = 'STAMPED',
    'T33: dopo l''annullamento il cliente giusto si timbra subito');
update public.loyalty_scans set created_at = created_at - interval '3 minutes'
where id = (pg_temp.v('s_after_undo') ->> 'scan_id')::uuid;
select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.expect_error($q$select public.undo_stamp((pg_temp.v('s_after_undo') ->> 'scan_id')::uuid)$q$, 'UNDO_EXPIRED',
    'T33: dopo 2 minuti non si annulla più');
-- Annullare il timbro che sblocca il premio toglie il premio; annullare il primo timbro toglie la tessera.
select pg_temp.act_as('postgres');
update public.loyalty_cards set stamps = 4 where user_id = pg_temp.uid(pg_temp.loyal(2)) and status = 'ACTIVE';
select pg_temp.travel(interval '5 hours');
select pg_temp.visit(pg_temp.loyal(2), 's_undo_reward');
select pg_temp.expect((pg_temp.v('s_undo_reward') -> 'members' -> 0 ->> 'reward_unlocked')::boolean, 'premio sbloccato da annullare');
select pg_temp.visit(pg_temp.loyal(11), 's_undo_first');
select pg_temp.act_as('test-staff@haposto.test');
select public.undo_stamp((pg_temp.v('s_undo_reward') ->> 'scan_id')::uuid);
select public.undo_stamp((pg_temp.v('s_undo_first') ->> 'scan_id')::uuid);
select pg_temp.act_as('postgres');
select pg_temp.expect((select count(*) from public.loyalty_rewards where user_id = pg_temp.uid(pg_temp.loyal(2))) = 0
                      and (select stamps = 4 and status = 'ACTIVE' from public.loyalty_cards
                           where user_id = pg_temp.uid(pg_temp.loyal(2)) and status = 'ACTIVE'),
    'T33: annullato il timbro del premio, premio tolto e tessera a 4 su 5');
select pg_temp.expect(not exists (select 1 from public.loyalty_cards where user_id = pg_temp.uid(pg_temp.loyal(11)))
                      and not exists (select 1 from public.loyalty_members where user_id = pg_temp.uid(pg_temp.loyal(11))),
    'T33: annullato il primo timbro, niente tessera e niente codice');

-- ---------------------------------------------------------------------------
-- 11. Statistiche senza dati personali (§11).
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-staff@haposto.test');
insert into test_values select 'stats', public.restaurant_loyalty_stats(pg_temp.r6(), 90)::text;
select pg_temp.expect((pg_temp.v('stats') ->> 'scans')::int >= 10 and (pg_temp.v('stats') ->> 'group_scans')::int = 1
                      and (pg_temp.v('stats') ->> 'stamps')::int > (pg_temp.v('stats') ->> 'people')::int
                      and (pg_temp.v('stats') ->> 'double_stamps')::int >= 4
                      and (pg_temp.v('stats') ->> 'rewards_unlocked')::int = 2
                      and (pg_temp.v('stats') ->> 'rewards_used')::int = 1
                      and (pg_temp.v('stats') ->> 'discount_cents')::int = 800
                      and jsonb_array_length(pg_temp.v('stats') -> 'by_hour') >= 1
                      and pg_temp.v('stats') -> 'near_reward' ? 'one',
    '§11: visite, gruppi, timbri doppi, premi, sconti riconosciuti, giorni e orari (annullamenti esclusi)');
select pg_temp.expect(pg_temp.no_personal_data(pg_temp.v('stats')::text)
                      and pg_temp.no_personal_data(public.restaurant_loyalty_program(pg_temp.r6())::text),
    'T55: statistiche e scheda della tessera senza dati personali');
select pg_temp.act_as('test-thief@haposto.test');
select pg_temp.expect_error($q$select public.restaurant_loyalty_stats(pg_temp.r6(), 30)$q$, 'Not authorized',
    'statistiche solo per chi gestisce il locale');

-- ---------------------------------------------------------------------------
-- 12. Segnalazioni e sanzioni automatiche (T48–T54).
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-thief@haposto.test');
select pg_temp.expect_error($q$select public.report_loyalty_problem(pg_temp.r6(), 'NO_STAMP')$q$, 'FEATURE_DISABLED',
    'T48: chi non ha la tessera non segnala');
select pg_temp.act_as(pg_temp.loyal(12));
select pg_temp.expect_error($q$select public.report_loyalty_problem(pg_temp.r6(), 'NO_STAMP')$q$, 'REPORT_NOT_ALLOWED',
    'T48: segnala solo chi ha avuto un timbro negli ultimi 60 giorni');
select pg_temp.act_as(pg_temp.loyal(1));
select pg_temp.expect_error($q$select public.report_loyalty_problem(pg_temp.r6(), 'ALTRO')$q$, 'INVALID_REPORT_KIND',
    'T48: due tasti, senza testo');
select public.report_loyalty_problem(pg_temp.r6(), 'NO_STAMP');
select pg_temp.expect_error($q$select public.report_loyalty_problem(pg_temp.r6(), 'REWARD_REFUSED')$q$, 'REPORT_TOO_SOON',
    'T48: una segnalazione ogni 90 giorni');
select pg_temp.act_as(pg_temp.loyal(2));
select public.report_loyalty_problem(pg_temp.r6(), 'REWARD_REFUSED');
select pg_temp.act_as(pg_temp.loyal(3));
select public.report_loyalty_problem(pg_temp.r6(), 'NO_STAMP');
select pg_temp.act_as('postgres');
select pg_temp.expect((select warned_at is not null and status = 'ACTIVE' from public.loyalty_programs where restaurant_id = pg_temp.r6())
                      and exists (select 1 from public.notification_outbox
                                  where user_id = pg_temp.uid('test-owner@haposto.test') and data ->> 'type' = 'LOYALTY_WARNING'),
    'T49: 3 clienti diversi → avviso al titolare, senza conseguenze');
select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.expect((public.restaurant_loyalty_program(pg_temp.r6()) -> 'reports' ->> 'count')::int = 3
                      and (public.restaurant_loyalty_program(pg_temp.r6()) -> 'reports' ->> 'suspend')::int = 5,
    'T53: il locale vede quante segnalazioni ha, senza sapere chi');
select pg_temp.act_as(pg_temp.loyal(4));
select public.report_loyalty_problem(pg_temp.r6(), 'NO_STAMP');
select pg_temp.act_as(pg_temp.loyal(5));
select public.report_loyalty_problem(pg_temp.r6(), 'NO_STAMP');
select pg_temp.act_as('postgres');
select pg_temp.expect((select status = 'SUSPENDED' and suspended_until > now() + interval '89 days'
                       from public.loyalty_programs where restaurant_id = pg_temp.r6())
                      and not exists (select 1 from public.loyalty_cards where restaurant_id = pg_temp.r6() and status = 'ACTIVE')
                      and not exists (select 1 from public.loyalty_rewards where restaurant_id = pg_temp.r6() and status = 'AVAILABLE')
                      and exists (select 1 from public.notification_outbox
                                  where user_id = pg_temp.uid('test-user@haposto.test') and data ->> 'type' = 'LOYALTY_ENDED'),
    'T50: 5 clienti diversi → tessera sospesa 90 giorni, tessere dei clienti finite con un avviso');
select pg_temp.expect((select partnership_status = 'ACTIVE_PARTNER' from public.restaurants where id = pg_temp.r6()),
    'T52: il locale resta su HAPOSTO');
select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules(), true)$q$, 'LOYALTY_SUSPENDED',
    'T50: durante la sospensione non si riattiva');
select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.expect_error($q$select public.register_stamp(pg_temp.r6(), 'abc')$q$, 'LOYALTY_NOT_ACTIVE',
    'T50: durante la sospensione non si timbra');
select pg_temp.act_as('test-admin@haposto.test');
select pg_temp.expect(jsonb_array_length(public.admin_loyalty_overview() -> 'sanctioned') = 1,
    'pannello: sospensioni automatiche in evidenza');
-- Dopo 90 giorni si riattiva accettando di nuovo il patto; una seconda sospensione entro 12 mesi la toglie.
select pg_temp.act_as('postgres');
select pg_temp.travel(interval '91 days');
select public.loyalty_maintenance();
select pg_temp.expect((select status from public.loyalty_programs where restaurant_id = pg_temp.r6()) = 'ENDED',
    'T50: finita la sospensione, il locale può riattivarla');
select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.put('v3', public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules(), true));
select pg_temp.act_as(pg_temp.loyal(13));
select pg_temp.put('g4', public.create_loyalty_group(pg_temp.r6()));
do $$
begin
    for i in 14 .. 17 loop
        perform pg_temp.act_as(pg_temp.loyal(i));
        perform public.join_loyalty_group(pg_temp.v('g4') ->> 'token');
    end loop;
end;
$$;
select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.expect((public.register_stamp(pg_temp.r6(), pg_temp.v('g4') ->> 'token') ->> 'stamped')::int = 5,
    'tessera riattivata: un tavolo di 5 timbrato');
do $$
begin
    for i in 13 .. 17 loop
        perform pg_temp.act_as(pg_temp.loyal(i));
        perform public.report_loyalty_problem(pg_temp.r6(), 'REWARD_REFUSED');
    end loop;
end;
$$;
select pg_temp.act_as('postgres');
select pg_temp.expect((select status from public.loyalty_programs where restaurant_id = pg_temp.r6()) = 'REMOVED'
                      and exists (select 1 from public.audit_log where action = 'LOYALTY_AUTO_REMOVED'),
    'T51: seconda sospensione entro 12 mesi → tessera tolta');
select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules(), true)$q$, 'LOYALTY_REMOVED',
    'T51: solo l''admin può ridarla');
select pg_temp.act_as('test-admin@haposto.test');
select public.admin_loyalty_restore(pg_temp.r6(), 'prova');
select pg_temp.expect_error($q$select public.admin_loyalty_restore(pg_temp.r6(), 'di nuovo')$q$, 'LOYALTY_NOT_SUSPENDED',
    'pannello: si ridà solo una tessera sospesa o tolta');
select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.put('v4', public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules(), true));
select pg_temp.expect((public.restaurant_loyalty_program(pg_temp.r6()) -> 'reports' ->> 'count')::int = 0
                      and public.restaurant_loyalty_program(pg_temp.r6()) ->> 'status' = 'ACTIVE',
    'T51: ridata dall''admin, si riattiva col patto e le segnalazioni ripartono da zero');

-- ---------------------------------------------------------------------------
-- 13. Chiusura con preavviso, Pro non pagato, uscita da HAPOSTO (T20–T22).
-- ---------------------------------------------------------------------------
select pg_temp.act_as('postgres');
select pg_temp.visit(pg_temp.loyal(18), 's_close_1');
update public.loyalty_cards set stamps = 3 where user_id = pg_temp.uid(pg_temp.loyal(18)) and status = 'ACTIVE';
select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.expect_error($q$select public.close_loyalty_program(pg_temp.r6())$q$, 'OWNER_REQUIRED', 'T20: chiude solo il titolare');
select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.put('closing', to_jsonb(public.close_loyalty_program(pg_temp.r6())));
select pg_temp.act_as('postgres');
select pg_temp.expect((select status = 'CLOSING' and closing_reason = 'OWNER'
                              and closing_until = now() + interval '30 days'
                       from public.loyalty_programs where restaurant_id = pg_temp.r6())
                      and exists (select 1 from public.notification_outbox
                                  where user_id = pg_temp.uid(pg_temp.loyal(18)) and data ->> 'type' = 'LOYALTY_CLOSING'),
    'T20: chiusura con 30 giorni di preavviso e avviso a chi ha la tessera');
select pg_temp.act_as(pg_temp.loyal(19));
select pg_temp.expect_error($q$select public.create_visit_token(pg_temp.r6())$q$, 'LOYALTY_NO_NEW_CARDS',
    'T20: durante il preavviso nessuna tessera nuova');
select pg_temp.act_as('postgres');
select pg_temp.travel(interval '5 hours');
select pg_temp.visit(pg_temp.loyal(18), 's_close_2');
select pg_temp.expect(pg_temp.v('s_close_2') -> 'members' -> 0 ->> 'outcome' = 'STAMPED'
                      and (pg_temp.v('s_close_2') -> 'members' -> 0 ->> 'stamps')::int = 4,
    'T20: durante il preavviso chi ha la tessera continua a timbrare');
select pg_temp.travel(interval '5 hours');
select pg_temp.visit(pg_temp.loyal(18), 's_close_3');
select pg_temp.expect((pg_temp.v('s_close_3') -> 'members' -> 0 ->> 'reward_unlocked')::boolean
                      and not exists (select 1 from public.loyalty_cards
                                      where user_id = pg_temp.uid(pg_temp.loyal(18)) and status = 'ACTIVE'),
    'T20: premio sbloccato durante il preavviso, nessuna tessera nuova dopo');
select pg_temp.travel(interval '31 days');
select public.loyalty_maintenance();
select pg_temp.expect((select status from public.loyalty_programs where restaurant_id = pg_temp.r6()) = 'ENDED'
                      and exists (select 1 from public.loyalty_rewards
                                  where user_id = pg_temp.uid(pg_temp.loyal(18)) and status = 'AVAILABLE'),
    'T20: finito il preavviso la tessera finisce, il premio resta valido fino alla scadenza');
select pg_temp.visit(pg_temp.loyal(18), 's_rewards_only');
select pg_temp.expect(pg_temp.v('s_rewards_only') -> 'members' -> 0 ->> 'outcome' = 'PROGRAM_ENDED'
                      and jsonb_array_length(pg_temp.v('s_rewards_only') -> 'rewards') = 1,
    'T20: a tessera finita si scansiona solo per consegnare il premio');
select pg_temp.act_as('test-staff@haposto.test');
select pg_temp.expect((public.use_reward(pg_temp.r6(), (pg_temp.v('s_rewards_only') -> 'rewards' -> 0 ->> 'reward_id')::uuid) ->> 'ok')::boolean,
    'T4: premio riconosciuto anche dopo la fine della tessera');
-- T21: senza Pro parte lo stesso preavviso; se Pro torna durante il preavviso, la tessera riparte.
select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.put('v5', public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules(), true));
select pg_temp.act_as('postgres');
update public.app_config set value = '{"restaurants_all_pro_until": "2000-01-01T00:00:00Z"}' where key = 'beta';
update public.restaurants set partner_since = now() - interval '400 days' where id = pg_temp.r6();
select pg_temp.expect(public.loyalty_restaurant_level(pg_temp.r6()) = 'EXISTING',
    'T21: senza Pro subito niente tessere nuove');
select public.loyalty_maintenance();
select pg_temp.expect((select status = 'CLOSING' and closing_reason = 'PLAN' from public.loyalty_programs
                       where restaurant_id = pg_temp.r6()),
    'T21: Pro non pagato → stesso preavviso di 30 giorni');
update public.app_config set value = '{"restaurants_all_pro_until": "2099-01-01T00:00:00Z"}' where key = 'beta';
select public.loyalty_maintenance();
select pg_temp.expect((select status from public.loyalty_programs where restaurant_id = pg_temp.r6()) = 'ACTIVE',
    'T21: Pro di nuovo attivo durante il preavviso → la tessera riparte');
-- T22: il locale esce da HAPOSTO → la tessera finisce subito, premi compresi.
select pg_temp.travel(interval '5 hours');
select pg_temp.visit(pg_temp.loyal(20), 's_exit');
update public.loyalty_cards set stamps = 4 where user_id = pg_temp.uid(pg_temp.loyal(20)) and status = 'ACTIVE';
select pg_temp.travel(interval '5 hours');
select pg_temp.visit(pg_temp.loyal(20), 's_exit_reward');
update public.restaurants set partnership_status = 'DIRECTORY_ONLY' where id = pg_temp.r6();
select pg_temp.expect(public.loyalty_restaurant_level(pg_temp.r6()) = 'NONE', 'T22: fuori da HAPOSTO subito niente timbri');
select public.loyalty_maintenance();
select pg_temp.expect((select status from public.loyalty_programs where restaurant_id = pg_temp.r6()) = 'ENDED'
                      and not exists (select 1 from public.loyalty_rewards
                                      where restaurant_id = pg_temp.r6() and status = 'AVAILABLE')
                      and exists (select 1 from public.notification_outbox
                                  where user_id = pg_temp.uid(pg_temp.loyal(20)) and data ->> 'type' = 'LOYALTY_ENDED'),
    'T22: uscito da HAPOSTO, tessera e premi finiti con un avviso');
update public.restaurants set partnership_status = 'ACTIVE_PARTNER' where id = pg_temp.r6();

-- ---------------------------------------------------------------------------
-- 14. Azzeramento dopo 6 mesi senza visite (T24) e scadenza dei premi (T47).
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.put('v6', public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules(), true));
select pg_temp.act_as('postgres');
select pg_temp.visit(pg_temp.loyal(21), 's_reset_1');
select pg_temp.visit(pg_temp.loyal(22), 's_reset_2');
update public.loyalty_cards set stamps = 3, last_stamp_at = now() - interval '6 months' + interval '10 days'
where user_id = pg_temp.uid(pg_temp.loyal(21)) and status = 'ACTIVE';
update public.loyalty_cards set last_stamp_at = now() - interval '6 months' + interval '10 days'
where user_id = pg_temp.uid(pg_temp.loyal(22)) and status = 'ACTIVE';
select public.loyalty_maintenance();
select pg_temp.expect(exists (select 1 from public.notification_outbox
                              where user_id = pg_temp.uid(pg_temp.loyal(21)) and data ->> 'type' = 'LOYALTY_RESET_SOON'
                                and title = 'Ti mancano 2 timbri')
                      and not exists (select 1 from public.notification_outbox
                                      where user_id = pg_temp.uid(pg_temp.loyal(22)) and data ->> 'type' = 'LOYALTY_RESET_SOON'),
    'T24: avviso 15 giorni prima solo se mancano 1–3 timbri');
select public.loyalty_maintenance();
select pg_temp.expect((select count(*) from public.notification_outbox
                       where user_id = pg_temp.uid(pg_temp.loyal(21)) and data ->> 'type' = 'LOYALTY_RESET_SOON') = 1,
    'T24: un solo avviso');
update public.loyalty_cards set last_stamp_at = now() - interval '6 months' - interval '1 day'
where user_id = pg_temp.uid(pg_temp.loyal(21)) and status = 'ACTIVE';
select public.loyalty_maintenance();
select pg_temp.expect((select status from public.loyalty_cards where user_id = pg_temp.uid(pg_temp.loyal(21))
                       order by started_at desc limit 1) = 'RESET'
                      and exists (select 1 from public.loyalty_cards where user_id = pg_temp.uid(pg_temp.loyal(22)) and status = 'ACTIVE'),
    'T24: dopo 6 mesi senza visite i timbri si azzerano');
update public.loyalty_cards set stamps = 4 where user_id = pg_temp.uid(pg_temp.loyal(22)) and status = 'ACTIVE';
select pg_temp.travel(interval '5 hours');
select pg_temp.visit(pg_temp.loyal(22), 's_expire');
select pg_temp.expect((pg_temp.v('s_expire') -> 'members' -> 0 ->> 'reward_unlocked')::boolean, 'premio da lasciar scadere');
select pg_temp.travel(interval '59 days');
select public.loyalty_maintenance();
select pg_temp.expect((select status from public.loyalty_rewards where user_id = pg_temp.uid(pg_temp.loyal(22))) = 'AVAILABLE',
    'T47: il premio vale ancora al 59° giorno');
select pg_temp.travel(interval '2 days');
select public.loyalty_maintenance();
select pg_temp.expect((select status from public.loyalty_rewards where user_id = pg_temp.uid(pg_temp.loyal(22))) = 'EXPIRED',
    'T47: dopo 60 giorni il premio scade');

-- ---------------------------------------------------------------------------
-- 15. Attiva per tutti e «solo esistenti» (T8, T10).
-- ---------------------------------------------------------------------------
select public.admin_set_config('loyalty', public.loyalty_defaults() || '{"mode": "ON"}');
select pg_temp.expect((select (value ->> 'launched')::boolean from public.app_config where key = 'loyalty'),
    'T10: accesa per tutti = lanciata');
select pg_temp.expect_error($q$select public.admin_set_config('loyalty', public.loyalty_defaults() || '{"mode": "OFF"}')$q$,
    'LOYALTY_ALREADY_LAUNCHED', 'T10: dopo il lancio non si spegne di colpo');
select pg_temp.expect_error($q$select public.admin_set_config('loyalty', public.loyalty_defaults() || '{"mode": "TEST", "launched": false}')$q$,
    'LOYALTY_ALREADY_LAUNCHED', 'T10: dopo il lancio non si torna in prova');
select pg_temp.act_as('test-thief@haposto.test');
select pg_temp.expect((public.loyalty_access() ->> 'level') = 'NEW', 'T8: attiva, tutti i clienti con account');
select pg_temp.put('qr_thief', public.create_visit_token(pg_temp.r6()));
select pg_temp.expect_error($q$select public.create_visit_token('10000000-0000-0000-0000-000000000001')$q$,
    'LOYALTY_NOT_ACTIVE', 'attiva: un locale senza programma non ha la tessera');
select pg_temp.act_as(null);
select pg_temp.expect((public.loyalty_restaurant_card(pg_temp.r6()) ->> 'available')::boolean
                      and (public.loyalty_restaurant_card(pg_temp.r6()) ->> 'can_start')::boolean
                      and public.loyalty_restaurant_card(pg_temp.r6()) -> 'rules' -> 'reward' ->> 'gift' = 'DESSERT',
    'T61: attiva, il riquadro con le regole si vede anche senza account');
select pg_temp.visit(pg_temp.loyal(23), 's_before_existing_only');
select public.admin_set_config('loyalty', public.loyalty_defaults() || '{"mode": "EXISTING_ONLY"}');
select pg_temp.expect((select (value ->> 'launched')::boolean from public.app_config where key = 'loyalty'),
    'T10: «solo esistenti» resta lanciata');
select pg_temp.act_as('test-thief@haposto.test');
select pg_temp.expect((public.loyalty_access() ->> 'level') = 'EXISTING' and not (public.loyalty_access() ->> 'visible')::boolean,
    'T8: «solo esistenti», chi non ha tessere non vede niente');
select pg_temp.expect_error($q$select public.create_visit_token(pg_temp.r6())$q$, 'LOYALTY_NO_NEW_CARDS',
    'T8: «solo esistenti», niente tessere nuove');
select pg_temp.act_as(pg_temp.loyal(23));
select pg_temp.expect((public.loyalty_access() ->> 'visible')::boolean and public.create_visit_token(pg_temp.r6()) ? 'token',
    'T8: «solo esistenti», chi ha la tessera la completa');
select pg_temp.act_as('test-owner@haposto.test');
select pg_temp.expect_error($q$select public.publish_loyalty_version(pg_temp.r6(), pg_temp.rules(), true)$q$,
    'LOYALTY_EXISTING_ONLY', 'T8: «solo esistenti», niente versioni nuove');
select pg_temp.act_as('postgres');
select public.admin_set_config('loyalty', public.loyalty_defaults() || '{"mode": "ON"}');

-- ---------------------------------------------------------------------------
-- 16. Pannello admin, lasciare la tessera, cancellazione dell'account, pulizia (T26, T58).
-- ---------------------------------------------------------------------------
select pg_temp.act_as('test-user@haposto.test');
select pg_temp.expect_error($q$select public.admin_loyalty_overview()$q$, 'ADMIN_REQUIRED', 'pannello: numeri della tessera solo per l''admin');
select pg_temp.act_as('test-admin@haposto.test');
insert into test_values select 'overview', public.admin_loyalty_overview()::text;
select pg_temp.expect(pg_temp.v('overview') ->> 'mode' = 'ON' and (pg_temp.v('overview') ->> 'versions')::int = 6
                      and (pg_temp.v('overview') ->> 'pacts')::int = 6
                      and (pg_temp.v('overview') -> 'programs' ->> 'ACTIVE')::int = 1
                      and jsonb_array_length(pg_temp.v('overview') -> 'tester_users') >= 27,
    'pannello: scheda Tessere con modalità, versioni, patti, programmi e tester');
select pg_temp.act_as('postgres');
select pg_temp.expect((public.admin_restaurant_detail(pg_temp.r6()) -> 'loyalty' ->> 'versions')::int = 6
                      and public.admin_restaurant_detail(pg_temp.r6()) ->> 'plan_source' = 'BETA',
    'correzione: la scheda del locale si apre anche dal SQL Editor');
select pg_temp.act_as(pg_temp.loyal(23));
select public.leave_loyalty_card(pg_temp.r6());
select pg_temp.act_as('postgres');
select pg_temp.expect(not exists (select 1 from public.loyalty_members where user_id = pg_temp.uid(pg_temp.loyal(23)))
                      and not exists (select 1 from public.loyalty_cards where user_id = pg_temp.uid(pg_temp.loyal(23)))
                      and not exists (select 1 from public.loyalty_stamps where user_id = pg_temp.uid(pg_temp.loyal(23))),
    'T26: lasciando la tessera timbri e codice si cancellano');
insert into test_values values ('deleted_user', to_jsonb(pg_temp.uid(pg_temp.loyal(1)))::text);
delete from auth.users where email = pg_temp.loyal(1);
select pg_temp.expect(not exists (select 1 from public.loyalty_members where user_id = (pg_temp.v('deleted_user') #>> '{}')::uuid)
                      and not exists (select 1 from public.loyalty_stamps where user_id = (pg_temp.v('deleted_user') #>> '{}')::uuid)
                      and not exists (select 1 from public.loyalty_reports where user_id = (pg_temp.v('deleted_user') #>> '{}')::uuid)
                      and not exists (select 1 from public.loyalty_group_members where user_id = (pg_temp.v('deleted_user') #>> '{}')::uuid),
    'T26: con la cancellazione dell''account sparisce tutto');
delete from auth.users where email = 'test-owner@haposto.test';
select pg_temp.expect((select count(*) from public.loyalty_program_versions where restaurant_id = pg_temp.r6() and accepted_by is null) = 6,
    'T18: cancellato l''account del titolare le versioni restano, senza collegamento alla persona');
select pg_temp.travel(interval '25 hours');
select public.loyalty_maintenance();
select pg_temp.expect(not exists (select 1 from public.visit_tokens) and not exists (select 1 from public.loyalty_groups)
                      and not exists (select 1 from public.loyalty_code_failures),
    'T58: QR, tavoli e tentativi si cancellano dopo un giorno');
select pg_temp.expect((select count(*) from public.loyalty_cards where status <> 'ACTIVE') > 0
                      and (select count(*) from public.loyalty_rewards where status <> 'AVAILABLE') > 0
                      and (select count(*) from public.loyalty_reports) > 0,
    'prima della pulizia: tessere, premi chiusi e segnalazioni presenti');
select pg_temp.travel(interval '13 months');
select public.loyalty_maintenance();
select pg_temp.expect(not exists (select 1 from public.loyalty_reports)
                      and not exists (select 1 from public.loyalty_rewards where status <> 'AVAILABLE' and closed_at < now() - interval '12 months')
                      and not exists (select 1 from public.loyalty_cards where status <> 'ACTIVE' and closed_at < now() - interval '12 months')
                      and (select coalesce(sum(loyalty_stamps), 0) from public.restaurant_daily_stats where restaurant_id = pg_temp.r6()) > 0,
    'T58: tessere e premi chiusi e segnalazioni via dopo 12 mesi; restano i conteggi anonimi');
select pg_temp.travel(interval '12 months');
select public.loyalty_maintenance();
select pg_temp.expect(not exists (select 1 from public.loyalty_scans) and not exists (select 1 from public.loyalty_stamps),
    'T58: scansioni e timbri via dopo 24 mesi');

select pg_temp.act_as('postgres');
do $$ begin raise notice 'CONTROLLI TESSERA SUPERATI'; end $$;
select 'CONTROLLI TESSERA SUPERATI' as esito;

rollback;
