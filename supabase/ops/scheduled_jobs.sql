-- HAPOSTO — Lavori pianificati di produzione (pg_cron).
--
-- Prerequisiti: migration 0006–0011 eseguite; estensione pg_cron attiva
-- (Dashboard → Database → Extensions → "pg_cron" → Enable).
-- Rieseguibile: cron.schedule con lo stesso nome aggiorna il job esistente.
-- Orari cron in UTC (Supabase): 02:30 UTC = 03:30 o 04:30 in Italia.

-- Promemoria "come siete messi?" quando lo stato di un locale sta per scadere (Step 11).
select cron.schedule(
    'haposto-manager-reminders',
    '*/5 * * * *',
    'select public.enqueue_manager_reminders()'
);

-- Prenotazioni di sala: si conservano 30 giorni, poi si cancellano (minimizzazione dati).
select cron.schedule(
    'haposto-purge-reservations',
    '30 2 * * *',
    'select public.purge_old_reservations(30)'
);

-- Coda notifiche: via i messaggi già inviati da più di 30 giorni.
select cron.schedule(
    'haposto-clean-outbox',
    '45 2 * * *',
    $$delete from public.notification_outbox where sent_at < now() - interval '30 days'$$
);

-- Abbonamenti manuali/beta scaduti: stato allineato (i diritti li ignorano già dopo 3 giorni).
select cron.schedule(
    'haposto-expire-manual-subscriptions',
    '0 3 * * *',
    $$update public.restaurant_subscriptions set status = 'EXPIRED'
      where provider in ('MANUAL', 'BETA')
        and status in ('TRIALING', 'ACTIVE', 'PAST_DUE')
        and current_period_end < now() - interval '3 days'$$
);

-- Controllo: elenco dei job attivi.
select jobid, jobname, schedule, active from cron.job order by jobname;
