-- HAPOSTO — Permessi espliciti per il server (ruolo service_role) sulle tabelle.
--
-- Esegui DOPO 0013. Rieseguibile.
--
-- Perché: nei progetti Supabase creati dal 30 maggio 2026 (e, dal 30 ottobre 2026, per le tabelle
-- nuove di tutti i progetti) le tabelle di "public" non ricevono più da sole i permessi per i ruoli
-- delle API (anon, authenticated, service_role). Le migration 0004–0013 danno già in modo esplicito
-- ad anon e authenticated tutto quello che serve; mancava service_role, il ruolo con cui le Edge
-- Function dei pagamenti leggono e scrivono alcune tabelle direttamente (billing_events, plans,
-- consumer_subscriptions, restaurant_subscriptions). Senza, Plus e Pro fallirebbero in produzione.
-- Questi sono gli stessi permessi che service_role ha già in automatico sul progetto DEV: lì il file
-- non cambia nulla.
--
-- Regola per le migration future: ogni tabella nuova in "public" ha i suoi GRANT espliciti per
-- anon, authenticated e service_role, nella stessa migration che la crea.

grant select, insert, update, delete on all tables in schema public to service_role;
grant usage, select on all sequences in schema public to service_role;

-- Controllo: tabelle di "public" a cui il server non può leggere o scrivere. Atteso: 0.
select count(*) as tabelle_senza_permessi_del_server
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relkind in ('r', 'p')
  and not (has_table_privilege('service_role', c.oid, 'SELECT')
       and has_table_privilege('service_role', c.oid, 'INSERT')
       and has_table_privilege('service_role', c.oid, 'UPDATE')
       and has_table_privilege('service_role', c.oid, 'DELETE'));
