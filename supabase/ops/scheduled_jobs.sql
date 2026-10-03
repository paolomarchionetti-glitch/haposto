-- HAPOSTO — Lavori pianificati di produzione (pg_cron).
--
-- Prerequisiti: migration 0006–0016 eseguite; estensione pg_cron attiva
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

-- Plus regalati dall'admin (PROMO) scaduti: stato allineato.
select cron.schedule(
    'haposto-expire-promo-plus',
    '5 3 * * *',
    $$update public.consumer_subscriptions set status = 'EXPIRED'
      where provider = 'PROMO'
        and status in ('TRIALING', 'ACTIVE', 'PAST_DUE')
        and current_period_end < now()$$
);

-- Conservazione dei dati dichiarata nella privacy: storico stati 180 giorni, statistiche e
-- registro operazioni 2 anni, sessioni admin scadute (ogni domenica).
select cron.schedule(
    'haposto-purge-operational-data',
    '15 3 * * 0',
    'select public.purge_operational_data()'
);

-- Avvisi al titolare 7 giorni e 1 giorno prima della fine della prova o del piano (migration
-- 0016): finiscono nella coda delle notifiche push. Ogni giorno alle 08:00 UTC (9 o 10 in Italia).
select cron.schedule(
    'haposto-plan-expiry-notices',
    '0 8 * * *',
    'select public.enqueue_plan_expiry_notices()'
);

-- Controllo: elenco dei job attivi.
select jobid, jobname, schedule, active from cron.job order by jobname;
