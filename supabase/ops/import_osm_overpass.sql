-- HAPOSTO — Import della directory reale da OpenStreetMap (Overpass Turbo).
-- Guida completa: docs/HAPOSTO_GUIDA_APP_E_DATI_REALI.md, capitolo 3.
--
-- Cosa fa, in un solo Run:
--   1. legge il JSON esportato da Overpass Turbo (lo incolli qui sotto al posto della riga segnaposto);
--   2. lo carica in public.directory_import_staging;
--   3. crea i locali nuovi come "solo directory" (DIRECTORY_ONLY, telefono NON pubblico);
--   4. aggiorna nome/indirizzo/posizione dei locali già importati che nessuno gestisce ancora.
-- Non tocca mai i locali partner, quelli creati a mano né i dati di prova.
-- Rieseguibile: importare due volte la stessa zona non crea doppioni.
--
-- Prima di eseguire cambia, se serve, città e provincia di riserva (usate quando OSM non le indica).
-- Dati © OpenStreetMap contributors, licenza ODbL: l'attribuzione va mostrata nell'app e nella pagina web.

truncate table public.directory_import_staging;

with params as (
    select 'Pesaro'::text as default_city,   -- ← città di riserva
           'PU'::text as default_province    -- ← sigla provincia
),
raw as (
    select $osm$
INCOLLA_QUI_IL_JSON_DI_OVERPASS
$osm$::jsonb as doc
),
elements as (
    select e
    from raw, jsonb_array_elements(raw.doc -> 'elements') as e
    where e -> 'tags' ? 'name'
      and coalesce(e -> 'tags' ->> 'disused:amenity', '') = ''
),
rows as (
    select
        'osm:' || (e ->> 'type') || '/' || (e ->> 'id') as source_ref,
        btrim(e -> 'tags' ->> 'name') as name,
        lower(coalesce(e -> 'tags' ->> 'cuisine', '')) as cuisine,
        e -> 'tags' ->> 'amenity' as amenity,
        nullif(btrim(concat_ws(' ', e -> 'tags' ->> 'addr:street', e -> 'tags' ->> 'addr:housenumber')), '') as address,
        coalesce(nullif(btrim(e -> 'tags' ->> 'addr:city'), ''), p.default_city) as city,
        upper(coalesce(nullif(btrim(e -> 'tags' ->> 'addr:province'), ''), p.default_province)) as province,
        coalesce((e ->> 'lat')::double precision, (e -> 'center' ->> 'lat')::double precision) as latitude,
        coalesce((e ->> 'lon')::double precision, (e -> 'center' ->> 'lon')::double precision) as longitude,
        nullif(btrim(coalesce(e -> 'tags' ->> 'phone', e -> 'tags' ->> 'contact:phone')), '') as phone_number
    from elements, params p
)
insert into public.directory_import_staging (
    source_ref, name, category, address, city, province, latitude, longitude, phone_number
)
select distinct on (source_ref)
    source_ref,
    left(name, 160),
    case
        when cuisine ~ 'pizza' then 'Pizzeria'
        when cuisine ~ '(seafood|fish)' then 'Pesce'
        when cuisine ~ '(sushi|japanese)' then 'Sushi'
        when cuisine ~ 'burger' then 'Hamburger'
        when cuisine ~ '(piadina|piadineria)' then 'Piadineria'
        when cuisine ~ '(vegetarian|vegan)' then 'Vegetariana'
        when cuisine ~ '(chinese|indian|thai|kebab|mexican|asian|greek|turkish)' then 'Etnico'
        when cuisine ~ '(regional|marche)' then 'Cucina marchigiana'
        when amenity = 'fast_food' then 'Solo asporto'
        when name ~* '^osteria' then 'Osteria'
        when name ~* '^trattoria' then 'Trattoria'
        else 'Ristorante'
    end,
    left(coalesce(address, city), 240),
    left(city, 100),
    left(province, 8),
    latitude,
    longitude,
    left(phone_number, 40)
from rows
where name <> ''
  and latitude is not null
  and longitude is not null
order by source_ref;

-- Risultato: quanti locali nuovi, aggiornati e saltati (già partner o già uguali).
select * from public.admin_import_directory('OSM_IMPORT');
