-- HAPOSTO — Query di controllo e KPI (SOLO LETTURA: non modificano nulla).
-- Eseguile una alla volta nel SQL Editor. Orari in ora italiana.
-- Richiedono le migration 0006–0011.

-- 1) Salute del dato ADESSO: quanti partner hanno uno stato valido (il KPI esistenziale).
select
    count(*) filter (where r.partnership_status = 'ACTIVE_PARTNER') as partner_attivi,
    count(*) filter (where s.valid_until > now()) as con_stato_valido,
    round(100.0 * count(*) filter (where s.valid_until > now())
          / nullif(count(*) filter (where r.partnership_status = 'ACTIVE_PARTNER'), 0), 1) as percentuale_valida
from public.restaurants r
left join public.restaurant_live_status s on s.restaurant_id = r.id
where r.partnership_status = 'ACTIVE_PARTNER'
  and r.data_source <> 'DEV_SEED';

-- 2) Aggiornamenti per servizio negli ultimi 14 giorni (pranzo 11:30–14:45, cena 18:45–23:00).
select
    (h.updated_at at time zone 'Europe/Rome')::date as giorno,
    case when (h.updated_at at time zone 'Europe/Rome')::time between '11:30' and '14:45' then 'pranzo'
         when (h.updated_at at time zone 'Europe/Rome')::time between '18:45' and '23:00' then 'cena'
         else 'altro' end as servizio,
    count(*) as aggiornamenti,
    count(distinct h.restaurant_id) as locali_che_hanno_aggiornato
from public.status_history h
join public.restaurants r on r.id = h.restaurant_id and r.data_source <> 'DEV_SEED'
where h.updated_at > now() - interval '14 days'
group by 1, 2
order by 1 desc, 2;

-- 3) Locali "silenziosi": partner che non aggiornano da più di 3 giorni (da chiamare).
select r.name, r.city,
       max(h.updated_at) at time zone 'Europe/Rome' as ultimo_aggiornamento
from public.restaurants r
left join public.status_history h on h.restaurant_id = r.id
where r.partnership_status = 'ACTIVE_PARTNER'
  and r.data_source <> 'DEV_SEED'
group by r.id, r.name, r.city
having max(h.updated_at) is null or max(h.updated_at) < now() - interval '3 days'
order by ultimo_aggiornamento nulls first;

-- 4) Directory per città e stato di partnership (densità: la metrica che crea valore).
select city,
       count(*) filter (where partnership_status = 'ACTIVE_PARTNER') as partner,
       count(*) filter (where partnership_status = 'CLAIM_PENDING') as in_verifica,
       count(*) filter (where partnership_status = 'DIRECTORY_ONLY') as solo_directory,
       count(*) as totale
from public.restaurants
where data_source <> 'DEV_SEED'
group by city
order by partner desc, totale desc;

-- 5) Richieste di gestione da verificare (le più vecchie prima).
select c.created_at at time zone 'Europe/Rome' as inviata, r.name, r.city, u.email, c.contact_info
from public.restaurant_claims c
join public.restaurants r on r.id = c.restaurant_id
left join auth.users u on u.id = c.user_id
where c.status = 'PENDING'
order by c.created_at;

-- 6) Abbonamenti ristoranti per piano e fonte.
select plan_code, provider, status, count(*) as abbonamenti
from public.restaurant_subscriptions
group by 1, 2, 3
order by 1, 2, 3;

-- 7) Ricavo ricorrente mensile stimato (MRR, al netto IVA per i ristoranti) dagli abbonamenti attivi.
select
    round(sum(case s.billing_interval
                  when 'YEAR' then p.price_year_cents / 12.0
                  else p.price_month_cents end) / 100.0, 2) as mrr_euro,
    count(*) as abbonamenti_paganti
from public.restaurant_subscriptions s
join public.plans p on p.code = s.plan_code
where s.status in ('ACTIVE', 'PAST_DUE')
  and s.provider = 'STRIPE';

-- 8) Incassi degli ultimi 12 mesi per mese (ristoranti e Plus).
select date_trunc('month', paid_at at time zone 'Europe/Rome')::date as mese,
       payer_kind,
       round(sum(amount_cents) / 100.0, 2) as incassato_euro,
       count(*) as pagamenti
from public.payments
where status = 'SUCCEEDED' and paid_at > now() - interval '12 months'
group by 1, 2
order by 1 desc, 2;

-- 9) Utenti: registrati, Plus attivi, con preferiti, con avvisi attivi.
select
    (select count(*) from public.profiles) as utenti_registrati,
    (select count(*) from public.consumer_subscriptions
     where plan_code = 'CONSUMER_PLUS' and status in ('TRIALING', 'ACTIVE', 'PAST_DUE')) as plus_attivi,
    (select count(distinct user_id) from public.favorites) as con_preferiti,
    (select count(*) from public.availability_alerts where is_active and expires_at > now()) as avvisi_attivi;

-- 10) Statistiche di visibilità per locale negli ultimi 30 giorni (argomento di vendita di Pro).
select r.name,
       sum(st.detail_views) as schede_viste,
       sum(st.directions_taps) as indicazioni,
       sum(st.call_taps) as chiamate,
       sum(st.public_page_views) as pagina_pubblica,
       sum(st.live_updates) as aggiornamenti
from public.restaurant_daily_stats st
join public.restaurants r on r.id = st.restaurant_id
where st.day > (now() at time zone 'Europe/Rome')::date - 30
group by r.name
order by schede_viste desc nulls last
limit 20;

-- 11) Notifiche in coda non ancora inviate (se crescono, la Edge Function non gira).
select kind, count(*) as da_inviare, min(created_at) at time zone 'Europe/Rome' as piu_vecchia
from public.notification_outbox
where sent_at is null
group by kind;
