-- Verifica di supabase/ops/import_osm_overpass.sql con un JSON di esempio (dati inventati).
-- Uso (CI o locale): prima si sostituisce il segnaposto con il JSON di esempio, poi
--   psql -v import_file=/percorso/import_pronto.sql -f supabase/tests/osm_import_check.sql
-- Tutto avviene in una transazione annullata: non lascia dati.
\set ON_ERROR_STOP 1
begin;

\i :import_file

do $$
declare
    v_count integer;
    v_row record;
begin
    select count(*) into v_count from public.restaurants where data_source = 'OSM_IMPORT';
    if v_count <> 2 then
        raise exception 'FAIL: attesi 2 locali importati (senza nome e dismessi esclusi), trovati %', v_count;
    end if;

    select * into v_row from public.restaurants where source_ref = 'osm:node/9000000001';
    if v_row.category <> 'Pizzeria' or v_row.address <> 'Via di Prova 1' or v_row.phone_public
       or v_row.partnership_status <> 'DIRECTORY_ONLY' or v_row.slug is null then
        raise exception 'FAIL: locale OSM con indirizzo importato in modo errato: %', row_to_json(v_row);
    end if;

    select * into v_row from public.restaurants where source_ref = 'osm:way/9000000002';
    if v_row.category <> 'Pesce' or v_row.city <> 'Pesaro' or v_row.address <> 'Pesaro' then
        raise exception 'FAIL: locale OSM senza indirizzo importato in modo errato: %', row_to_json(v_row);
    end if;
    raise notice 'ok: primo import';
end;
$$;

-- Un locale diventato partner non viene più toccato dagli import successivi.
update public.restaurants
set partnership_status = 'ACTIVE_PARTNER', name = 'Nome scelto dal titolare'
where source_ref = 'osm:node/9000000001';

-- Un locale corretto a mano (fonte MANUAL, stesso source_ref) resta com'è e non viene duplicato.
update public.restaurants
set data_source = 'MANUAL', address = 'Indirizzo corretto a mano 5'
where source_ref = 'osm:way/9000000002';

\i :import_file

do $$
declare
    v_count integer;
begin
    select count(*) into v_count from public.restaurants where source_ref like 'osm:%';
    if v_count <> 2 then
        raise exception 'FAIL: il secondo import ha creato doppioni (% locali)', v_count;
    end if;
    if (select address from public.restaurants where source_ref = 'osm:way/9000000002') <> 'Indirizzo corretto a mano 5' then
        raise exception 'FAIL: l''import ha sovrascritto una correzione manuale';
    end if;
    if (select name from public.restaurants where source_ref = 'osm:node/9000000001') <> 'Nome scelto dal titolare' then
        raise exception 'FAIL: l''import ha sovrascritto i dati di un partner';
    end if;
    raise notice 'ok: reimport senza doppioni, partner e correzioni manuali protetti';
end;
$$;

select 'IMPORT OSM OK' as esito;
rollback;
