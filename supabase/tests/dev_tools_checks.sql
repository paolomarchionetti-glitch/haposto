-- HAPOSTO — Controlli degli strumenti DEV (supabase/dev/dev_tools.sql). Solo DEV/CI.
--
-- Un locale di test rivendicato da un account vero (titolare o staff) lo aggiorna solo chi lo
-- gestisce: né il simulatore né dev_publish_live_status devono toccarlo.
-- Tutto in una transazione annullata alla fine: non lascia dati.

begin;

create function pg_temp.expect(p_ok boolean, p_what text) returns void language plpgsql as $$
begin
    if not coalesce(p_ok, false) then
        raise exception 'FAIL: %', p_what;
    end if;
    raise notice 'ok: %', p_what;
end;
$$;

-- Due locali simulati "non pigri" (il simulatore li aggiorna sempre quando lo stato manca):
-- A verrà rivendicato, B è il controllo.
create temp table picked on commit drop as
select r.id, row_number() over (order by r.id) as n
from public.restaurants r
where r.data_source = 'DEV_SEED'
  and r.partnership_status = 'ACTIVE_PARTNER'
  and coalesce(r.source_ref, '') not like 'field-test:%'
  and abs(hashtext(r.id::text)) % 5 <> 0
  and not exists (select 1 from public.restaurant_users ru where ru.restaurant_id = r.id)
order by r.id
limit 2;

select pg_temp.expect((select count(*) from picked) = 2, 'ci sono almeno due locali simulati per la prova');

insert into auth.users (id, email) values (gen_random_uuid(), 'dev-tools-owner@haposto.test');
insert into public.restaurant_users (restaurant_id, user_id, role)
select p.id, u.id, 'OWNER'
from picked p, auth.users u
where p.n = 1 and u.email = 'dev-tools-owner@haposto.test';

delete from public.restaurant_live_status where restaurant_id in (select id from picked);

select public.dev_simulate_live_activity();

select pg_temp.expect(
    not exists (select 1 from public.restaurant_live_status s join picked p on p.id = s.restaurant_id where p.n = 1),
    'il simulatore non tocca un locale con un titolare vero');

-- Di notte (23:00–10:30, ora italiana) il simulatore è fermo: il controllo B vale solo di giorno.
select pg_temp.expect(
    ((now() at time zone 'Europe/Rome')::time >= time '23:00'
        or (now() at time zone 'Europe/Rome')::time < time '10:30')
    or exists (select 1 from public.restaurant_live_status s join picked p on p.id = s.restaurant_id where p.n = 2),
    'il simulatore aggiorna ancora i locali di test senza gestore');

do $$
declare
    v_claimed uuid := (select id from picked where n = 1);
    v_free uuid := (select id from picked where n = 2);
begin
    begin
        perform public.dev_publish_live_status(v_claimed, 'FULL', null, null, null);
        raise exception 'FAIL: dev_publish_live_status doveva rifiutare un locale con un titolare vero';
    exception when others then
        if sqlerrm <> 'NOT_A_DEV_PARTNER' then
            raise;
        end if;
        raise notice 'ok: dev_publish_live_status rifiuta un locale con un titolare vero';
    end;
    perform public.dev_publish_live_status(v_free, 'AVAILABLE', 3::smallint, null, null);
    raise notice 'ok: dev_publish_live_status funziona ancora sui locali di test senza gestore';
end;
$$;

select 'STRUMENTI DEV OK' as esito;

rollback;
