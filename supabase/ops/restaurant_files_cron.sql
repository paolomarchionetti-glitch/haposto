-- HAPOSTO — Pulizia notturna dei file dei locali (pg_cron).
--
-- Toglie le foto "solo per oggi" scadute e cancella dal contenitore i file che nessun locale usa
-- più (sostituiti, tolti dal titolare o dall'admin, locale tornato "solo directory").
--
-- Prerequisiti:
--   1. migration 0015 eseguita;
--   2. Edge Function restaurant-file pubblicata (deploy con --no-verify-jwt) e segreto
--      HAPOSTO_CRON_SECRET impostato (è lo stesso di push-dispatch);
--   3. vault con haposto_project_url e haposto_cron_secret (già fatti per push_dispatch_cron.sql).
--
-- Ogni notte alle 03:30 UTC (04:30 o 05:30 in Italia: dopo le 4, ora in cui scadono le foto
-- "solo per oggi"). Rieseguibile: cron.schedule con lo stesso nome aggiorna il job.

select cron.schedule(
    'haposto-restaurant-files-cleanup',
    '30 3 * * *',
    $$
    select net.http_post(
        url := (select decrypted_secret from vault.decrypted_secrets where name = 'haposto_project_url')
               || '/functions/v1/restaurant-file',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'x-haposto-cron', (select decrypted_secret from vault.decrypted_secrets where name = 'haposto_cron_secret')
        ),
        body := '{}'::jsonb,
        timeout_milliseconds := 60000
    );
    $$
);

-- Controllo: il job esiste ed è attivo.
select jobid, jobname, schedule, active from cron.job where jobname = 'haposto-restaurant-files-cleanup';
