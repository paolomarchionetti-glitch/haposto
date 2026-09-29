-- HAPOSTO — Tempo reale sugli stati dei locali (Supabase Realtime).
--
-- Quando un locale pubblica uno stato, le app aperte ricaricano la lista in 1–2 secondi invece di
-- aspettare il controllo periodico (ogni minuto). La tabella non contiene dati personali e chi
-- riceve gli aggiornamenti vede solo le righe che le regole RLS gli permettono già di leggere.
--
-- Esegui dopo 0004 (in pratica: dopo le altre migration). Rieseguibile.

do $$
begin
    if not exists (
        select 1
        from pg_publication_tables
        where pubname = 'supabase_realtime'
          and schemaname = 'public'
          and tablename = 'restaurant_live_status'
    ) then
        alter publication supabase_realtime add table public.restaurant_live_status;
    end if;
end;
$$;
