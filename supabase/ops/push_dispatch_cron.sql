-- HAPOSTO — Invio automatico delle notifiche push (ogni minuto).
--
-- Prerequisiti:
--   1. Edge Function push-dispatch pubblicata (deploy con --no-verify-jwt) e i suoi segreti
--      HAPOSTO_CRON_SECRET e FIREBASE_SERVICE_ACCOUNT impostati (guida configurazione, Parte 6).
--   2. Estensioni pg_cron e pg_net attive (Dashboard → Database → Extensions).
--   3. PRIMA di questo file, UNA SOLA VOLTA, nel SQL Editor (valori tuoi, MAI nel repository):
--        select vault.create_secret('https://<ref-progetto>.supabase.co', 'haposto_project_url');
--        select vault.create_secret('<stesso valore di HAPOSTO_CRON_SECRET>', 'haposto_cron_secret');
--      Per cambiarli: select vault.update_secret(id, '<nuovo valore>') con l'id da vault.secrets.
--
-- Rieseguibile: cron.schedule con lo stesso nome aggiorna il job.

select cron.schedule(
    'haposto-push-dispatch',
    '* * * * *',
    $$
    select net.http_post(
        url := (select decrypted_secret from vault.decrypted_secrets where name = 'haposto_project_url')
               || '/functions/v1/push-dispatch',
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'x-haposto-cron', (select decrypted_secret from vault.decrypted_secrets where name = 'haposto_cron_secret')
        ),
        body := '{}'::jsonb,
        timeout_milliseconds := 25000
    )
    where exists (select 1 from public.notification_outbox where sent_at is null and attempts < 5);
    $$
);

-- Controllo: il job esiste ed è attivo.
select jobid, jobname, schedule, active from cron.job where jobname = 'haposto-push-dispatch';

-- Diagnosi (dopo qualche minuto): ultime chiamate e risposte della funzione.
-- select status_code, content, created from net._http_response order by created desc limit 10;
-- select id, kind, attempts, sent_at, last_error from public.notification_outbox order by id desc limit 20;
