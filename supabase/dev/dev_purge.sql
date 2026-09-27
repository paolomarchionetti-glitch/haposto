-- HAPOSTO — PULIZIA PRIMA DELLA PRODUZIONE (o per ripartire da zero in DEV).
--
-- Cosa fa:
--   1. ferma il simulatore pianificato;
--   2. spegne e cancella gli strumenti DEV (dev_publish_live_status, simulatore);
--   3. cancella TUTTI i locali di test (data_source = 'DEV_SEED') con stati, storico, statistiche,
--      preferiti, avvisi e prenotazioni collegati.
-- NON tocca i locali reali (MANUAL, OSM_IMPORT, PARTNER_SIGNUP) né gli account.
-- Esegui tutto il file in una volta. Irreversibile: fai prima un backup se hai dubbi.

begin;

do $$
begin
    if exists (select 1 from pg_extension where extname = 'pg_cron') then
        execute $cron$select cron.unschedule(jobid) from cron.job where jobname = 'haposto-dev-simulator'$cron$;
    end if;
end;
$$;

update public.app_config set value = 'false', updated_at = now() where key = 'dev_tools_enabled';

drop function if exists public.dev_publish_live_status(uuid, public.live_status, smallint, smallint, varchar);
drop function if exists public.dev_simulate_live_activity();
drop function if exists public.dev_tools_enabled();

-- I pagamenti di prova bloccherebbero la cancellazione (i pagamenti veri si conservano per legge).
delete from public.payments
where restaurant_id in (select id from public.restaurants where data_source = 'DEV_SEED');

delete from public.restaurants where data_source = 'DEV_SEED';

select data_source, count(*) as locali_rimasti from public.restaurants group by data_source;

commit;
