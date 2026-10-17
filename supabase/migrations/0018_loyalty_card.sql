-- HAPOSTO — Tessera fedeltà (funzione nascosta, SPENTA di default).
--
-- Esegui DOPO 0017. Rieseguibile.
--
-- Regole: specifiche della tessera in docs/PR/PR22-30_tessera-fedelta/ (versione 3, regole T1–T61; qui citate fra parentesi).
-- Con l'interruttore spento (app_config 'loyalty', modalità OFF) ogni funzione della tessera
-- rifiuta con FEATURE_DISABLED (T9) e l'app non mostra nulla. Le modalità:
--   OFF            spenta (iniziale);
--   TEST           solo locali e clienti tester scelti dall'admin (gli admin sono sempre tester);
--   ON             attiva per tutti (locali con Pro);
--   EXISTING_ONLY  solo esistenti: si completano le tessere e si usano i premi, niente di nuovo.
-- Dopo il primo ON ("launched") si passa solo fra ON ed EXISTING_ONLY (T10).
--
-- Cosa aggiunge:
--   1. impostazione 'loyalty' con modalità, limiti e soglie (admin_set_config la valida);
--   2. tester (locali e utenti), funzione LOYALTY nel piano Pro, consenso LOYALTY_PACT,
--      contatori anonimi nelle statistiche giornaliere;
--   3. tabelle: programmi, versioni immutabili, codici anonimi, tessere, gruppi, QR, scansioni,
--      timbri, premi, segnalazioni;
--   4. funzioni per cliente, locale e admin, sempre con controllo della modalità;
--   5. lavoro pianificato loyalty_maintenance(): preavvisi, azzeramenti, scadenze, pulizia;
--   6. correzione: admin_restaurant_detail funziona anche dal SQL Editor (prima falliva con
--      "Not authorized for this restaurant").
--
-- Privacy (T55–T58): il locale vede solo un codice anonimo per cliente; i QR contengono solo
-- codici casuali e il database ne conserva le impronte (SHA-256).

-- ---------------------------------------------------------------------------
-- 1) Impostazione 'loyalty' (pubblica come tutta app_config: MAI segreti qui).
-- ---------------------------------------------------------------------------
create or replace function public.loyalty_defaults()
returns jsonb
language sql
immutable
set search_path = ''
as $$
    select '{
        "mode": "OFF",
        "launched": false,
        "stamps_min": 5, "stamps_max": 20,
        "spend_min_eur": 5, "spend_max_eur": 50,
        "discount_percent_min": 5, "discount_percent_max": 50,
        "discount_cap_min_eur": 5, "discount_cap_max_eur": 50,
        "voucher_min_eur": 2, "voucher_max_eur": 20,
        "reward_valid_days": 60,
        "inactivity_months": 6,
        "closing_notice_days": 30,
        "stamp_gap_hours": 4,
        "token_seconds": 60,
        "undo_minutes": 2,
        "reward_scan_minutes": 30,
        "group_max_people": 20,
        "group_join_minutes": 10,
        "group_valid_minutes": 60,
        "scans_per_10_min": 60,
        "scans_per_day": 300,
        "code_errors_max": 10,
        "code_lock_minutes": 10,
        "report_eligible_days": 60,
        "report_gap_days": 90,
        "report_window_days": 60,
        "report_warn": 3,
        "report_suspend": 5,
        "suspension_days": 90,
        "removal_window_months": 12
    }'::jsonb;
$$;

-- Valori ammessi per i numeri dell'impostazione (minimo, massimo).
create or replace function public.loyalty_config_ranges()
returns jsonb
language sql
immutable
set search_path = ''
as $$
    select '{
        "stamps_min": [2, 50], "stamps_max": [2, 50],
        "spend_min_eur": [1, 500], "spend_max_eur": [1, 500],
        "discount_percent_min": [1, 100], "discount_percent_max": [1, 100],
        "discount_cap_min_eur": [1, 500], "discount_cap_max_eur": [1, 500],
        "voucher_min_eur": [1, 100], "voucher_max_eur": [1, 100],
        "reward_valid_days": [7, 365],
        "inactivity_months": [1, 24],
        "closing_notice_days": [7, 90],
        "stamp_gap_hours": [1, 24],
        "token_seconds": [30, 300],
        "undo_minutes": [1, 10],
        "reward_scan_minutes": [5, 180],
        "group_max_people": [2, 50],
        "group_join_minutes": [1, 60],
        "group_valid_minutes": [5, 240],
        "scans_per_10_min": [1, 1000],
        "scans_per_day": [1, 10000],
        "code_errors_max": [3, 100],
        "code_lock_minutes": [1, 120],
        "report_eligible_days": [7, 365],
        "report_gap_days": [1, 365],
        "report_window_days": [7, 365],
        "report_warn": [1, 100],
        "report_suspend": [1, 100],
        "suspension_days": [1, 365],
        "removal_window_months": [1, 36]
    }'::jsonb;
$$;

insert into public.app_config (key, value, description) values
    ('loyalty', public.loyalty_defaults(),
     'Tessera fedeltà (funzione nascosta). mode: OFF (spenta), TEST (solo tester), ON (attiva), EXISTING_ONLY (solo tessere già iniziate). Dopo il primo ON si passa solo fra ON ed EXISTING_ONLY. Gli altri numeri sono limiti e soglie (vedi le specifiche della tessera in docs/PR/PR22-30_tessera-fedelta/).')
on conflict (key) do nothing;

-- Un numero dell'impostazione (valore dell'admin o valore di partenza).
create or replace function public.loyalty_cfg(p_field text)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
    select coalesce(
        (select case when jsonb_typeof(c.value -> p_field) = 'number'
                     then round((c.value ->> p_field)::numeric)::integer end
         from public.app_config c where c.key = 'loyalty'),
        (public.loyalty_defaults() ->> p_field)::integer);
$$;

create or replace function public.loyalty_mode()
returns text
language sql
stable
security definer
set search_path = ''
as $$
    select coalesce(
        (select c.value ->> 'mode' from public.app_config c
         where c.key = 'loyalty' and c.value ->> 'mode' in ('OFF', 'TEST', 'ON', 'EXISTING_ONLY')),
        'OFF');
$$;

-- admin_set_config: stessa funzione della 0016, più la chiave 'loyalty' con i suoi controlli.
create or replace function public.admin_set_config(p_key text, p_value jsonb)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_old jsonb;
    v_field text;
    v_range jsonb;
    v_launched boolean;
begin
    perform public.assert_admin();
    if p_key not in ('beta', 'security', 'min_supported_app_version', 'public_links', 'legal',
                     'dev_tools_enabled', 'restaurant_trial', 'loyalty') then
        raise exception 'CONFIG_KEY_NOT_EDITABLE';
    end if;
    if p_value is null then
        raise exception 'INVALID_CONFIG_VALUE';
    end if;
    if p_key = 'restaurant_trial' and (
        jsonb_typeof(p_value -> 'days') is distinct from 'number'
        or (p_value ->> 'days')::numeric not between 0 and 365
        or (p_value ->> 'days')::numeric <> trunc((p_value ->> 'days')::numeric)
    ) then
        raise exception 'INVALID_CONFIG_VALUE';
    end if;
    select c.value into v_old from public.app_config c where c.key = p_key for update;

    if p_key = 'loyalty' then
        if jsonb_typeof(p_value) is distinct from 'object'
           or coalesce(p_value ->> 'mode', '') not in ('OFF', 'TEST', 'ON', 'EXISTING_ONLY') then
            raise exception 'INVALID_CONFIG_VALUE';
        end if;
        for v_field in select jsonb_object_keys(p_value) loop
            if v_field in ('mode', 'launched') then
                continue;
            end if;
            v_range := public.loyalty_config_ranges() -> v_field;
            if v_range is null
               or jsonb_typeof(p_value -> v_field) is distinct from 'number'
               or (p_value ->> v_field)::numeric <> trunc((p_value ->> v_field)::numeric)
               or (p_value ->> v_field)::numeric not between (v_range ->> 0)::numeric and (v_range ->> 1)::numeric then
                raise exception 'INVALID_CONFIG_VALUE';
            end if;
        end loop;
        -- Coppie minimo/massimo coerenti (i campi mancanti valgono quanto il valore di partenza).
        if exists (
            select 1 from (values
                ('stamps_min', 'stamps_max'), ('spend_min_eur', 'spend_max_eur'),
                ('discount_percent_min', 'discount_percent_max'),
                ('discount_cap_min_eur', 'discount_cap_max_eur'), ('voucher_min_eur', 'voucher_max_eur'),
                ('report_warn', 'report_suspend'), ('group_join_minutes', 'group_valid_minutes')
            ) as pair(lo, hi)
            where coalesce((p_value ->> pair.lo)::numeric, (public.loyalty_defaults() ->> pair.lo)::numeric)
                > coalesce((p_value ->> pair.hi)::numeric, (public.loyalty_defaults() ->> pair.hi)::numeric)
        ) then
            raise exception 'INVALID_CONFIG_VALUE';
        end if;
        -- T10: dopo il lancio non si spegne e non si torna in prova. "launched" lo decide il server.
        v_launched := coalesce((v_old ->> 'launched')::boolean, false) or coalesce(v_old ->> 'mode', '') = 'ON';
        if v_launched and p_value ->> 'mode' in ('OFF', 'TEST') then
            raise exception 'LOYALTY_ALREADY_LAUNCHED';
        end if;
        p_value := p_value || jsonb_build_object('launched', v_launched or p_value ->> 'mode' = 'ON');
    end if;

    insert into public.app_config (key, value) values (p_key, p_value)
    on conflict (key) do update set value = excluded.value, updated_at = now();
    perform public.log_audit('CONFIG_CHANGED', null, null,
        jsonb_build_object('key', p_key, 'from', v_old, 'to', p_value));
end;
$$;

-- ---------------------------------------------------------------------------
-- 2) Tester, piano, consenso, statistiche.
-- ---------------------------------------------------------------------------
-- Clienti tester (T8). Non modificabile dal client: authenticated aggiorna solo
-- display_name e marketing_opt_in (0007).
alter table public.profiles add column if not exists loyalty_tester boolean not null default false;

-- La tessera è una funzione di Pro (durante beta e prova ce l'hanno tutti).
update public.plans
set features = array_append(features, 'LOYALTY'), updated_at = now()
where code in ('RESTAURANT_PRO', 'RESTAURANT_PRO_PLUS') and not ('LOYALTY' = any(features));

-- Accettazione del patto della tessera (T17).
alter table public.consent_log drop constraint if exists consent_log_kind_check;
alter table public.consent_log add constraint consent_log_kind_check
    check (kind in ('TERMS', 'PRIVACY', 'RESTAURANT_TERMS', 'RESTAURANT_SPECIFIC_CLAUSES', 'MARKETING',
                    'LOYALTY_PACT'));

-- Conteggi anonimi per giorno (restano dopo la pulizia dei dati, T58).
alter table public.restaurant_daily_stats
    add column if not exists loyalty_scans integer not null default 0,
    add column if not exists loyalty_group_scans integer not null default 0,
    add column if not exists loyalty_people integer not null default 0,
    add column if not exists loyalty_stamps integer not null default 0,
    add column if not exists loyalty_new_members integer not null default 0,
    add column if not exists loyalty_cards_started integer not null default 0,
    add column if not exists loyalty_rewards_unlocked integer not null default 0,
    add column if not exists loyalty_rewards_used integer not null default 0,
    add column if not exists loyalty_discount_cents integer not null default 0;

-- ---------------------------------------------------------------------------
-- 3) Tabelle. Nessun accesso diretto dalle app: tutto passa dalle funzioni qui sotto.
-- ---------------------------------------------------------------------------
-- Versioni del programma di un locale: immutabili (T18). Codici:
--   condizione (T12–T13): SPEND (spesa minima a persona), ONE_OF, TWO_OF fra
--     STARTER, FIRST_COURSE, MAIN_COURSE, PIZZA, SINGLE_DISH_OR_MENU, DESSERT, DRINK, COFFEE;
--   giorno doppio (T14): giorno ISO 1 (lunedì) – 7 (domenica), fascia ALL_DAY, LUNCH, DINNER;
--   premio (T40–T47): GIFT, DISCOUNT, VOUCHER; da SAME_VISIT o NEXT_VISIT; giorni ISO.
create table if not exists public.loyalty_program_versions (
    id uuid primary key default gen_random_uuid(),
    restaurant_id uuid not null references public.restaurants(id) on delete cascade,
    version integer not null check (version >= 1),
    stamps_required smallint not null check (stamps_required between 2 and 50),
    condition_kind text not null check (condition_kind in ('SPEND', 'ONE_OF', 'TWO_OF')),
    condition_min_spend_cents integer check (condition_min_spend_cents is null or condition_min_spend_cents > 0),
    condition_types text[] check (condition_types is null or condition_types <@ array[
        'STARTER', 'FIRST_COURSE', 'MAIN_COURSE', 'PIZZA', 'SINGLE_DISH_OR_MENU', 'DESSERT', 'DRINK', 'COFFEE']),
    double_weekday smallint check (double_weekday is null or double_weekday between 1 and 7),
    double_slot text check (double_slot is null or double_slot in ('ALL_DAY', 'LUNCH', 'DINNER')),
    reward_kind text not null check (reward_kind in ('GIFT', 'DISCOUNT', 'VOUCHER')),
    reward_gift text check (reward_gift is null or reward_gift in (
        'COFFEE', 'DESSERT', 'ICE_CREAM', 'FRUIT', 'STARTER', 'BRUSCHETTA', 'SIDE_DISH', 'FIRST_COURSE',
        'MAIN_COURSE', 'PIZZA', 'DISH_OF_THE_DAY', 'KIDS_MENU', 'SOFT_DRINK', 'WATER',
        'ALCOHOL_FREE_APERITIF', 'COVER_CHARGE')),
    reward_percent smallint check (reward_percent is null or reward_percent between 1 and 100),
    reward_cap_cents integer check (reward_cap_cents is null or reward_cap_cents > 0),
    reward_amount_cents integer check (reward_amount_cents is null or reward_amount_cents > 0),
    reward_min_spend_cents integer check (reward_min_spend_cents is null or reward_min_spend_cents > 0),
    reward_from text not null check (reward_from in ('SAME_VISIT', 'NEXT_VISIT')),
    reward_weekdays smallint[] check (reward_weekdays is null
        or (cardinality(reward_weekdays) between 3 and 6 and reward_weekdays <@ array[1, 2, 3, 4, 5, 6, 7]::smallint[])),
    reward_max_per_table smallint check (reward_max_per_table is null or reward_max_per_table between 1 and 10),
    reward_cumulable boolean not null,
    reward_valid_days smallint not null check (reward_valid_days between 1 and 365),
    inactivity_months smallint not null check (inactivity_months between 1 and 24),
    accepted_by uuid references auth.users(id) on delete set null,
    accepted_at timestamptz not null default now(),
    unique (restaurant_id, version),
    check ((condition_kind = 'SPEND') = (condition_min_spend_cents is not null)),
    check ((condition_kind = 'SPEND') = (condition_types is null)),
    check ((double_weekday is null) = (double_slot is null)),
    check ((reward_kind = 'GIFT') = (reward_gift is not null)),
    check ((reward_kind = 'DISCOUNT') = (reward_percent is not null and reward_cap_cents is not null)),
    check ((reward_kind = 'VOUCHER') = (reward_amount_cents is not null)),
    -- Buono: spesa minima almeno doppia e solo dalla visita successiva (T42).
    check (reward_kind <> 'VOUCHER'
        or (reward_min_spend_cents >= 2 * reward_amount_cents and reward_from = 'NEXT_VISIT')),
    check (reward_kind <> 'GIFT' or reward_min_spend_cents is null)
);

create or replace function public.loyalty_versions_immutable()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    if tg_op = 'UPDATE' then
        -- Unica eccezione: l'account che ha accettato viene cancellato (on delete set null).
        if new.accepted_by is null and old.accepted_by is not null
           and (to_jsonb(new) - 'accepted_by') = (to_jsonb(old) - 'accepted_by') then
            return new;
        end if;
        raise exception 'LOYALTY_VERSION_IMMUTABLE';
    end if;
    -- Cancellazione solo a cascata (locale cancellato), mai diretta.
    if pg_trigger_depth() <= 1 then
        raise exception 'LOYALTY_VERSION_IMMUTABLE';
    end if;
    return old;
end;
$$;

drop trigger if exists loyalty_versions_immutable on public.loyalty_program_versions;
create trigger loyalty_versions_immutable
    before update or delete on public.loyalty_program_versions
    for each row execute function public.loyalty_versions_immutable();

-- Un programma per locale. La riga nasce con l'interruttore "Tester tessera" o con la prima
-- versione. reports_since: da quando contano le segnalazioni (dopo una sospensione si riparte).
create table if not exists public.loyalty_programs (
    restaurant_id uuid primary key references public.restaurants(id) on delete cascade,
    status text not null default 'NONE'
        check (status in ('NONE', 'ACTIVE', 'CLOSING', 'SUSPENDED', 'REMOVED', 'ENDED')),
    current_version_id uuid references public.loyalty_program_versions(id) on delete set null,
    tester boolean not null default false,
    closing_reason text check (closing_reason is null or closing_reason in ('OWNER', 'PLAN')),
    closing_until timestamptz,
    suspended_until timestamptz,
    last_suspended_at timestamptz,
    warned_at timestamptz,
    reports_since timestamptz,
    code_locked_until timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- Codice anonimo del cliente in quel locale (T55): casuale, stabile, diverso per ogni locale.
create table if not exists public.loyalty_members (
    restaurant_id uuid not null references public.restaurants(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    code text not null check (code ~ '^[A-HJKMNP-Z2-9]{4}$'),
    created_at timestamptz not null default now(),
    primary key (restaurant_id, user_id),
    unique (restaurant_id, code)
);
create index if not exists loyalty_members_user_idx on public.loyalty_members (user_id);

-- Tessere (T23–T27): al massimo una attiva per locale e per cliente.
create table if not exists public.loyalty_cards (
    id uuid primary key default gen_random_uuid(),
    restaurant_id uuid not null,
    user_id uuid not null,
    version_id uuid not null references public.loyalty_program_versions(id) on delete cascade,
    stamps smallint not null default 0 check (stamps >= 0),
    status text not null default 'ACTIVE' check (status in ('ACTIVE', 'COMPLETED', 'RESET', 'ENDED')),
    started_at timestamptz not null default now(),
    last_stamp_at timestamptz,
    closed_at timestamptz,
    reset_warned_at timestamptz,
    foreign key (restaurant_id, user_id)
        references public.loyalty_members(restaurant_id, user_id) on delete cascade
);
create unique index if not exists loyalty_cards_one_active
    on public.loyalty_cards (restaurant_id, user_id) where status = 'ACTIVE';
create index if not exists loyalty_cards_user_idx on public.loyalty_cards (user_id, status);
create index if not exists loyalty_cards_restaurant_idx on public.loyalty_cards (restaurant_id, status);

-- Tavoli di gruppo (T28): ci si unisce entro group_join_minutes, la scansione entro
-- group_valid_minutes dalla creazione.
create table if not exists public.loyalty_groups (
    id uuid primary key default gen_random_uuid(),
    restaurant_id uuid not null references public.restaurants(id) on delete cascade,
    leader_id uuid not null references auth.users(id) on delete cascade,
    created_at timestamptz not null default now(),
    join_until timestamptz not null,
    expires_at timestamptz not null,
    used_at timestamptz
);
create index if not exists loyalty_groups_leader_idx on public.loyalty_groups (leader_id, expires_at desc);

create table if not exists public.loyalty_group_members (
    group_id uuid not null references public.loyalty_groups(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    joined_at timestamptz not null default now(),
    primary key (group_id, user_id)
);
create index if not exists loyalty_group_members_user_idx on public.loyalty_group_members (user_id);

-- QR personali e del tavolo (T35–T36): 60 secondi, una volta sola, solo impronte.
create table if not exists public.visit_tokens (
    id uuid primary key default gen_random_uuid(),
    kind text not null check (kind in ('PERSONAL', 'GROUP')),
    restaurant_id uuid not null references public.restaurants(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    group_id uuid references public.loyalty_groups(id) on delete cascade,
    token_hash bytea not null unique,
    code_hash bytea not null,
    created_at timestamptz not null default now(),
    expires_at timestamptz not null,
    used_at timestamptz,
    used_by uuid references auth.users(id) on delete set null,
    result jsonb,
    check ((kind = 'GROUP') = (group_id is not null))
);
create index if not exists visit_tokens_code_idx on public.visit_tokens (restaurant_id, code_hash) where used_at is null;
create index if not exists visit_tokens_user_idx on public.visit_tokens (user_id, created_at desc);
create index if not exists visit_tokens_created_idx on public.visit_tokens (created_at);

-- Una scansione dello staff (una sola anche per un tavolo, T39).
create table if not exists public.loyalty_scans (
    id uuid primary key default gen_random_uuid(),
    restaurant_id uuid not null references public.restaurants(id) on delete cascade,
    kind text not null check (kind in ('PERSONAL', 'GROUP')),
    token_id uuid references public.visit_tokens(id) on delete set null,
    group_id uuid references public.loyalty_groups(id) on delete set null,
    scanned_by uuid references auth.users(id) on delete set null,
    people smallint not null default 0,
    stamped smallint not null default 0,
    created_at timestamptz not null default now(),
    undone_at timestamptz,
    undone_by uuid references auth.users(id) on delete set null
);
create index if not exists loyalty_scans_restaurant_idx on public.loyalty_scans (restaurant_id, created_at desc);

-- Esito della scansione per ogni persona. stamps 0 = nessun timbro (outcome dice perché):
--   STAMPED, TOO_SOON (4 ore, T37), SELF (chi gestisce il locale, T38), NO_ACCESS (modalità o
--   account bloccato), NO_NEW_CARDS (niente tessere nuove), PROGRAM_ENDED (solo premi).
-- I campi prev_*, *_created, reward_id e carry_card_id servono all'annullamento (T33).
create table if not exists public.loyalty_stamps (
    id bigint generated always as identity primary key,
    scan_id uuid not null references public.loyalty_scans(id) on delete cascade,
    restaurant_id uuid not null references public.restaurants(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    card_id uuid references public.loyalty_cards(id) on delete set null,
    outcome text not null
        check (outcome in ('STAMPED', 'TOO_SOON', 'SELF', 'NO_ACCESS', 'NO_NEW_CARDS', 'PROGRAM_ENDED')),
    stamps smallint not null default 0 check (stamps between 0 and 2),
    double_day boolean not null default false,
    member_created boolean not null default false,
    card_created boolean not null default false,
    reward_id uuid,
    carry_card_id uuid references public.loyalty_cards(id) on delete set null,
    prev_stamps smallint,
    prev_last_stamp_at timestamptz,
    created_at timestamptz not null default now(),
    undone_at timestamptz
);
create index if not exists loyalty_stamps_user_idx on public.loyalty_stamps (restaurant_id, user_id, created_at desc);
create index if not exists loyalty_stamps_scan_idx on public.loyalty_stamps (scan_id);

-- Premi (T40–T47): le regole sono quelle della versione (immutabile) a cui rimanda la riga.
create table if not exists public.loyalty_rewards (
    id uuid primary key default gen_random_uuid(),
    restaurant_id uuid not null,
    user_id uuid not null,
    card_id uuid references public.loyalty_cards(id) on delete set null,
    version_id uuid not null references public.loyalty_program_versions(id) on delete cascade,
    status text not null default 'AVAILABLE' check (status in ('AVAILABLE', 'USED', 'EXPIRED', 'ENDED')),
    unlocked_at timestamptz not null default now(),
    usable_from timestamptz not null,
    expires_at timestamptz not null,
    used_at timestamptz,
    used_by uuid references auth.users(id) on delete set null,
    used_scan_id uuid references public.loyalty_scans(id) on delete set null,
    discount_cents integer check (discount_cents is null or discount_cents >= 0),
    closed_at timestamptz,
    foreign key (restaurant_id, user_id)
        references public.loyalty_members(restaurant_id, user_id) on delete cascade
);
create index if not exists loyalty_rewards_user_idx on public.loyalty_rewards (restaurant_id, user_id, status);
create index if not exists loyalty_rewards_scan_idx on public.loyalty_rewards (used_scan_id);

alter table public.loyalty_stamps drop constraint if exists loyalty_stamps_reward_id_fkey;
alter table public.loyalty_stamps add constraint loyalty_stamps_reward_id_fkey
    foreign key (reward_id) references public.loyalty_rewards(id) on delete set null;

-- Segnalazioni dei clienti (T48): due tipi, senza testo.
create table if not exists public.loyalty_reports (
    id bigint generated always as identity primary key,
    restaurant_id uuid not null references public.restaurants(id) on delete cascade,
    user_id uuid not null references auth.users(id) on delete cascade,
    kind text not null check (kind in ('NO_STAMP', 'REWARD_REFUSED')),
    created_at timestamptz not null default now()
);
create index if not exists loyalty_reports_restaurant_idx on public.loyalty_reports (restaurant_id, created_at desc);
create index if not exists loyalty_reports_user_idx on public.loyalty_reports (user_id, restaurant_id, created_at desc);

-- Codici di riserva sbagliati (T36), per il blocco temporaneo.
create table if not exists public.loyalty_code_failures (
    id bigint generated always as identity primary key,
    restaurant_id uuid not null references public.restaurants(id) on delete cascade,
    created_at timestamptz not null default now()
);
create index if not exists loyalty_code_failures_idx on public.loyalty_code_failures (restaurant_id, created_at desc);

-- Accessi: RLS senza policy e nessun permesso per anon e authenticated; il server (service_role)
-- ha i permessi espliciti (regola della 0014).
do $$
declare
    v_table text;
begin
    foreach v_table in array array[
        'loyalty_program_versions', 'loyalty_programs', 'loyalty_members', 'loyalty_cards',
        'loyalty_groups', 'loyalty_group_members', 'visit_tokens', 'loyalty_scans', 'loyalty_stamps',
        'loyalty_rewards', 'loyalty_reports', 'loyalty_code_failures'
    ] loop
        execute format('alter table public.%I enable row level security', v_table);
        execute format('revoke all on table public.%I from public, anon, authenticated', v_table);
        execute format('grant select, insert, update, delete on table public.%I to service_role', v_table);
    end loop;
end;
$$;
grant usage, select on all sequences in schema public to service_role;

-- ---------------------------------------------------------------------------
-- 4) Regole di accesso (T7–T10) e funzioni di servizio.
-- ---------------------------------------------------------------------------
-- Cliente: NEW (può iniziare tessere), EXISTING (solo quelle iniziate), NONE.
create or replace function public.loyalty_user_level(p_user_id uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $$
    select case
        when public.loyalty_mode() = 'OFF' then 'NONE'
        when p_user_id is not null and public.is_user_blocked(p_user_id) then 'NONE'
        when public.loyalty_mode() = 'TEST' then
            case when exists (select 1 from public.profiles p
                              where p.id = p_user_id and (p.loyalty_tester or p.is_platform_admin))
                 then 'NEW' else 'NONE' end
        when public.loyalty_mode() = 'ON' then 'NEW'
        else 'EXISTING'
    end;
$$;

-- Locale: la tessera esiste per lui (modalità accesa; in prova solo se tester).
create or replace function public.loyalty_restaurant_enabled(p_restaurant_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select case public.loyalty_mode()
        when 'OFF' then false
        when 'TEST' then coalesce((select lp.tester from public.loyalty_programs lp
                                   where lp.restaurant_id = p_restaurant_id), false)
        else true
    end;
$$;

-- Locale: NEW (timbra e apre tessere nuove), EXISTING (solo tessere iniziate: preavviso, modalità
-- "solo esistenti" o Pro scaduto in attesa del preavviso), REWARDS (programma finito, restano
-- premi da usare), NONE.
create or replace function public.loyalty_restaurant_level(p_restaurant_id uuid)
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_partnership public.partnership_status;
    v_status text;
begin
    if not public.loyalty_restaurant_enabled(p_restaurant_id) then
        return 'NONE';
    end if;
    select r.partnership_status, lp.status into v_partnership, v_status
    from public.restaurants r
    left join public.loyalty_programs lp on lp.restaurant_id = r.id
    where r.id = p_restaurant_id;
    if v_partnership is distinct from 'ACTIVE_PARTNER' then
        return 'NONE';
    end if;
    if v_status = 'ACTIVE' then
        return case when public.loyalty_mode() in ('ON', 'TEST')
                         and public.restaurant_has_feature(p_restaurant_id, 'LOYALTY')
                    then 'NEW' else 'EXISTING' end;
    elsif v_status = 'CLOSING' then
        return 'EXISTING';
    elsif v_status = 'ENDED' and exists (
        select 1 from public.loyalty_rewards rw
        where rw.restaurant_id = p_restaurant_id and rw.status = 'AVAILABLE' and rw.expires_at > now()) then
        return 'REWARDS';
    end if;
    return 'NONE';
end;
$$;

-- Perché il titolare non può pubblicare una versione (null = può).
create or replace function public.loyalty_publish_blocker(p_restaurant_id uuid)
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_partnership public.partnership_status;
    v_status text;
    v_suspended_until timestamptz;
begin
    if not public.loyalty_restaurant_enabled(p_restaurant_id) then
        return 'FEATURE_DISABLED';
    end if;
    if public.loyalty_mode() = 'EXISTING_ONLY' then
        return 'LOYALTY_EXISTING_ONLY';
    end if;
    select r.partnership_status, lp.status, lp.suspended_until
    into v_partnership, v_status, v_suspended_until
    from public.restaurants r
    left join public.loyalty_programs lp on lp.restaurant_id = r.id
    where r.id = p_restaurant_id;
    if v_partnership is distinct from 'ACTIVE_PARTNER' then
        return 'RESTAURANT_NOT_PARTNER';
    end if;
    if not public.restaurant_has_feature(p_restaurant_id, 'LOYALTY') then
        return 'SUBSCRIPTION_REQUIRED';
    end if;
    if v_status = 'REMOVED' then
        return 'LOYALTY_REMOVED';
    end if;
    if v_status = 'SUSPENDED' and v_suspended_until > now() then
        return 'LOYALTY_SUSPENDED';
    end if;
    return null;
end;
$$;

-- Codice casuale dall'alfabeto senza caratteri ambigui (niente I, L, O, 0, 1): 31 simboli.
create or replace function public.loyalty_random_code(p_length integer)
returns text
language plpgsql
volatile
set search_path = ''
as $$
declare
    v_alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    v_bytes bytea;
    v_code text := '';
    v_byte integer;
begin
    while char_length(v_code) < p_length loop
        v_bytes := extensions.gen_random_bytes(16);
        for i in 0 .. 15 loop
            v_byte := get_byte(v_bytes, i);
            -- 248 = 8 × 31: i byte oltre si scartano, così ogni simbolo ha la stessa probabilità.
            if v_byte < 248 and char_length(v_code) < p_length then
                v_code := v_code || substr(v_alphabet, v_byte % 31 + 1, 1);
            end if;
        end loop;
    end loop;
    return v_code;
end;
$$;

-- Nuovo QR: 128 bit casuali + codice di riserva di 6 caratteri (31^6 ≈ 887 milioni, T36).
create or replace function public.loyalty_new_token(p_kind text, p_restaurant_id uuid, p_user_id uuid, p_group_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
    v_token text := encode(extensions.gen_random_bytes(16), 'hex');
    v_code text;
    v_seconds integer := public.loyalty_cfg('token_seconds');
    v_expires timestamptz := now() + make_interval(secs => public.loyalty_cfg('token_seconds'));
begin
    loop
        v_code := public.loyalty_random_code(6);
        exit when not exists (
            select 1 from public.visit_tokens t
            where t.restaurant_id = p_restaurant_id and t.code_hash = extensions.digest(v_code, 'sha256')
              and t.used_at is null and t.expires_at > now());
    end loop;
    insert into public.visit_tokens (kind, restaurant_id, user_id, group_id, token_hash, code_hash, expires_at)
    values (p_kind, p_restaurant_id, p_user_id, p_group_id,
            extensions.digest(v_token, 'sha256'), extensions.digest(v_code, 'sha256'), v_expires);
    return jsonb_build_object('token', v_token, 'code', v_code, 'expires_at', v_expires, 'seconds', v_seconds);
end;
$$;

-- Il cliente collegato può usare la tessera di questo locale? Restituisce il livello del locale.
create or replace function public.loyalty_assert_customer(p_restaurant_id uuid)
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_user_level text;
    v_level text;
begin
    perform public.assert_active_user();
    v_user_level := public.loyalty_user_level(auth.uid());
    if v_user_level = 'NONE' or not public.loyalty_restaurant_enabled(p_restaurant_id) then
        raise exception 'FEATURE_DISABLED';
    end if;
    v_level := public.loyalty_restaurant_level(p_restaurant_id);
    if v_level = 'NONE' then
        raise exception 'LOYALTY_NOT_ACTIVE';
    end if;
    -- T38: chi gestisce il locale non ha la tessera di quel locale.
    if exists (select 1 from public.restaurant_users ru
               where ru.restaurant_id = p_restaurant_id and ru.user_id = auth.uid()) then
        raise exception 'LOYALTY_OWN_RESTAURANT';
    end if;
    if not (v_level = 'NEW' and v_user_level = 'NEW')
       and not exists (select 1 from public.loyalty_cards c
                       where c.restaurant_id = p_restaurant_id and c.user_id = auth.uid() and c.status = 'ACTIVE')
       and not exists (select 1 from public.loyalty_rewards rw
                       where rw.restaurant_id = p_restaurant_id and rw.user_id = auth.uid()
                         and rw.status = 'AVAILABLE' and rw.expires_at > now()) then
        raise exception 'LOYALTY_NO_NEW_CARDS';
    end if;
    return v_level;
end;
$$;

-- Un gruppo alla volta (T28): esce dai gruppi aperti e chiude quelli che guida.
create or replace function public.loyalty_leave_open_groups(p_user_id uuid)
returns void
language sql
security definer
set search_path = ''
as $$
    update public.loyalty_groups
    set expires_at = now(), join_until = least(join_until, now())
    where leader_id = p_user_id and used_at is null and expires_at > now();
    delete from public.loyalty_group_members m
    using public.loyalty_groups g
    where m.group_id = g.id and m.user_id = p_user_id
      and g.used_at is null and g.expires_at > now() and g.leader_id <> p_user_id;
$$;

-- Giorno doppio (T14) all'ora italiana: pranzo 11–15, cena 18–23.
create or replace function public.loyalty_is_double(p_weekday smallint, p_slot text, p_at timestamptz)
returns boolean
language sql
stable
set search_path = ''
as $$
    select coalesce(
        p_weekday = extract(isodow from (p_at at time zone 'Europe/Rome'))::smallint
        and case p_slot
            when 'ALL_DAY' then true
            when 'LUNCH' then extract(hour from (p_at at time zone 'Europe/Rome')) between 11 and 14
            when 'DINNER' then extract(hour from (p_at at time zone 'Europe/Rome')) between 18 and 22
            else false
        end,
        false);
$$;

create or replace function public.loyalty_reward_usable_now(
    p_status text, p_usable_from timestamptz, p_expires_at timestamptz, p_weekdays smallint[])
returns boolean
language sql
stable
set search_path = ''
as $$
    select p_status = 'AVAILABLE' and p_usable_from <= now() and p_expires_at > now()
       and (p_weekdays is null
            or extract(isodow from (now() at time zone 'Europe/Rome'))::smallint = any(p_weekdays));
$$;

-- Regole di una versione, come le mostrano app e pannello (T27).
create or replace function public.loyalty_version_json(p_version_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
    select jsonb_build_object(
        'version_id', v.id,
        'version', v.version,
        'stamps_required', v.stamps_required,
        'condition', jsonb_build_object('kind', v.condition_kind,
                                        'min_spend_cents', v.condition_min_spend_cents,
                                        'types', to_jsonb(v.condition_types)),
        'double_day', case when v.double_weekday is not null
                           then jsonb_build_object('weekday', v.double_weekday, 'slot', v.double_slot) end,
        'reward', jsonb_build_object('kind', v.reward_kind, 'gift', v.reward_gift,
                                     'percent', v.reward_percent, 'cap_cents', v.reward_cap_cents,
                                     'amount_cents', v.reward_amount_cents,
                                     'min_spend_cents', v.reward_min_spend_cents,
                                     'from', v.reward_from, 'weekdays', to_jsonb(v.reward_weekdays),
                                     'max_per_table', v.reward_max_per_table,
                                     'cumulable', v.reward_cumulable, 'valid_days', v.reward_valid_days),
        'inactivity_months', v.inactivity_months,
        'accepted_at', v.accepted_at)
    from public.loyalty_program_versions v
    where v.id = p_version_id;
$$;

create or replace function public.loyalty_reward_json(p_reward_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
    select jsonb_build_object(
        'reward_id', rw.id, 'status', rw.status, 'kind', v.reward_kind, 'gift', v.reward_gift,
        'percent', v.reward_percent, 'cap_cents', v.reward_cap_cents,
        'amount_cents', v.reward_amount_cents, 'min_spend_cents', v.reward_min_spend_cents,
        'weekdays', to_jsonb(v.reward_weekdays), 'max_per_table', v.reward_max_per_table,
        'cumulable', v.reward_cumulable, 'unlocked_at', rw.unlocked_at,
        'usable_from', rw.usable_from, 'expires_at', rw.expires_at,
        'usable_now', public.loyalty_reward_usable_now(rw.status, rw.usable_from, rw.expires_at, v.reward_weekdays))
    from public.loyalty_rewards rw
    join public.loyalty_program_versions v on v.id = rw.version_id
    where rw.id = p_reward_id;
$$;

-- Contatori del giorno (anche negativi, per l'annullamento).
create or replace function public.loyalty_add_stats(
    p_restaurant_id uuid,
    p_day date,
    p_scans integer default 0,
    p_group_scans integer default 0,
    p_people integer default 0,
    p_stamps integer default 0,
    p_new_members integer default 0,
    p_cards_started integer default 0,
    p_rewards_unlocked integer default 0,
    p_rewards_used integer default 0,
    p_discount_cents integer default 0
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    update public.restaurant_daily_stats st set
        loyalty_scans = greatest(st.loyalty_scans + p_scans, 0),
        loyalty_group_scans = greatest(st.loyalty_group_scans + p_group_scans, 0),
        loyalty_people = greatest(st.loyalty_people + p_people, 0),
        loyalty_stamps = greatest(st.loyalty_stamps + p_stamps, 0),
        loyalty_new_members = greatest(st.loyalty_new_members + p_new_members, 0),
        loyalty_cards_started = greatest(st.loyalty_cards_started + p_cards_started, 0),
        loyalty_rewards_unlocked = greatest(st.loyalty_rewards_unlocked + p_rewards_unlocked, 0),
        loyalty_rewards_used = greatest(st.loyalty_rewards_used + p_rewards_used, 0),
        loyalty_discount_cents = greatest(st.loyalty_discount_cents + p_discount_cents, 0)
    where st.restaurant_id = p_restaurant_id and st.day = p_day;
    if not found then
        insert into public.restaurant_daily_stats as st (
            restaurant_id, day, loyalty_scans, loyalty_group_scans, loyalty_people, loyalty_stamps,
            loyalty_new_members, loyalty_cards_started, loyalty_rewards_unlocked, loyalty_rewards_used,
            loyalty_discount_cents
        ) values (
            p_restaurant_id, p_day, greatest(p_scans, 0), greatest(p_group_scans, 0), greatest(p_people, 0),
            greatest(p_stamps, 0), greatest(p_new_members, 0), greatest(p_cards_started, 0),
            greatest(p_rewards_unlocked, 0), greatest(p_rewards_used, 0), greatest(p_discount_cents, 0)
        )
        on conflict (restaurant_id, day) do update set
            loyalty_scans = st.loyalty_scans + excluded.loyalty_scans,
            loyalty_group_scans = st.loyalty_group_scans + excluded.loyalty_group_scans,
            loyalty_people = st.loyalty_people + excluded.loyalty_people,
            loyalty_stamps = st.loyalty_stamps + excluded.loyalty_stamps,
            loyalty_new_members = st.loyalty_new_members + excluded.loyalty_new_members,
            loyalty_cards_started = st.loyalty_cards_started + excluded.loyalty_cards_started,
            loyalty_rewards_unlocked = st.loyalty_rewards_unlocked + excluded.loyalty_rewards_unlocked,
            loyalty_rewards_used = st.loyalty_rewards_used + excluded.loyalty_rewards_used,
            loyalty_discount_cents = st.loyalty_discount_cents + excluded.loyalty_discount_cents;
    end if;
end;
$$;

-- Avvisi (notifiche push di sistema, gratuite).
create or replace function public.loyalty_notify(
    p_users uuid[], p_restaurant_id uuid, p_title text, p_body text, p_type text)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_count integer;
begin
    insert into public.notification_outbox (user_id, kind, restaurant_id, title, body, data)
    select distinct u.id, 'SYSTEM', p_restaurant_id, left(p_title, 80), left(p_body, 240),
           jsonb_build_object('type', p_type, 'restaurant_id', p_restaurant_id)
    from unnest(coalesce(p_users, array[]::uuid[])) as u(id)
    where u.id is not null;
    get diagnostics v_count = row_count;
    return v_count;
end;
$$;

create or replace function public.loyalty_owner_ids(p_restaurant_id uuid)
returns uuid[]
language sql
stable
security definer
set search_path = ''
as $$
    select coalesce(array_agg(ru.user_id), array[]::uuid[])
    from public.restaurant_users ru
    where ru.restaurant_id = p_restaurant_id and ru.role = 'OWNER';
$$;

-- Chiude le tessere attive (e, se richiesto, i premi da usare) e restituisce i clienti toccati.
create or replace function public.loyalty_close_cards(p_restaurant_id uuid, p_end_rewards boolean)
returns uuid[]
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_users uuid[];
    v_reward_users uuid[] := array[]::uuid[];
begin
    with closed as (
        update public.loyalty_cards set status = 'ENDED', closed_at = now()
        where restaurant_id = p_restaurant_id and status = 'ACTIVE'
        returning user_id
    )
    select coalesce(array_agg(user_id), array[]::uuid[]) into v_users from closed;
    if p_end_rewards then
        with ended as (
            update public.loyalty_rewards set status = 'ENDED', closed_at = now()
            where restaurant_id = p_restaurant_id and status = 'AVAILABLE'
            returning user_id
        )
        select coalesce(array_agg(user_id), array[]::uuid[]) into v_reward_users from ended;
    end if;
    return array(select distinct x from unnest(v_users || v_reward_users) as x);
end;
$$;

-- Sanzioni automatiche (T49–T51) dopo ogni segnalazione.
create or replace function public.loyalty_evaluate_reports(p_restaurant_id uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_program public.loyalty_programs;
    v_name text;
    v_count integer;
    v_users uuid[];
    v_window interval := make_interval(days => public.loyalty_cfg('report_window_days'));
begin
    select * into v_program from public.loyalty_programs where restaurant_id = p_restaurant_id for update;
    if v_program.status is null or v_program.status not in ('ACTIVE', 'CLOSING') then
        return 'NONE';
    end if;
    select left(r.name, 60) into v_name from public.restaurants r where r.id = p_restaurant_id;
    select count(distinct rp.user_id) into v_count
    from public.loyalty_reports rp
    where rp.restaurant_id = p_restaurant_id
      and rp.created_at > greatest(now() - v_window, coalesce(v_program.reports_since, '-infinity'::timestamptz));

    if v_count >= public.loyalty_cfg('report_suspend') then
        v_users := public.loyalty_close_cards(p_restaurant_id, true);
        if v_program.last_suspended_at > now() - make_interval(months => public.loyalty_cfg('removal_window_months')) then
            -- T51: seconda sospensione in 12 mesi → tessera tolta (solo l'admin la ridà).
            update public.loyalty_programs
            set status = 'REMOVED', suspended_until = null, closing_reason = null, closing_until = null,
                reports_since = now(), warned_at = null, updated_at = now()
            where restaurant_id = p_restaurant_id;
            perform public.log_audit('LOYALTY_AUTO_REMOVED', p_restaurant_id, null,
                jsonb_build_object('reports', v_count));
            perform public.loyalty_notify(public.loyalty_owner_ids(p_restaurant_id), p_restaurant_id,
                'Tessera fedeltà tolta',
                v_name || ': troppe segnalazioni dei clienti, la tessera è stata tolta. Il locale resta su HAPOSTO. Info: info@haposto.app',
                'LOYALTY_REMOVED');
        else
            -- T50: sospensione automatica.
            update public.loyalty_programs
            set status = 'SUSPENDED',
                suspended_until = now() + make_interval(days => public.loyalty_cfg('suspension_days')),
                last_suspended_at = now(), closing_reason = null, closing_until = null,
                reports_since = now(), warned_at = null, updated_at = now()
            where restaurant_id = p_restaurant_id;
            perform public.log_audit('LOYALTY_AUTO_SUSPENDED', p_restaurant_id, null,
                jsonb_build_object('reports', v_count));
            perform public.loyalty_notify(public.loyalty_owner_ids(p_restaurant_id), p_restaurant_id,
                'Tessera fedeltà sospesa',
                v_name || ': troppe segnalazioni dei clienti, la tessera è sospesa per '
                    || public.loyalty_cfg('suspension_days') || ' giorni. Il locale resta su HAPOSTO.',
                'LOYALTY_SUSPENDED');
        end if;
        perform public.loyalty_notify(v_users, p_restaurant_id,
            'Tessera fedeltà finita',
            'La tessera di ' || v_name || ' non è più attiva: timbri e premi da usare sono stati chiusi.',
            'LOYALTY_ENDED');
        return 'SUSPENDED';
    end if;

    if v_count >= public.loyalty_cfg('report_warn')
       and (v_program.warned_at is null or v_program.warned_at < now() - v_window) then
        -- T49: avviso al titolare, senza conseguenze.
        update public.loyalty_programs set warned_at = now(), updated_at = now()
        where restaurant_id = p_restaurant_id;
        perform public.log_audit('LOYALTY_AUTO_WARNING', p_restaurant_id, null,
            jsonb_build_object('reports', v_count));
        perform public.loyalty_notify(public.loyalty_owner_ids(p_restaurant_id), p_restaurant_id,
            'Tessera fedeltà: segnalazioni',
            v_name || ': ' || v_count || ' clienti hanno segnalato un problema con la tessera. A '
                || public.loyalty_cfg('report_suspend') || ' la tessera si sospende da sola.',
            'LOYALTY_WARNING');
        return 'WARNED';
    end if;
    return 'NONE';
end;
$$;

-- ---------------------------------------------------------------------------
-- 5) Il programma del locale (T11–T22).
-- ---------------------------------------------------------------------------
-- Numero intero da un campo JSON (null se manca o non è intero).
create or replace function public.loyalty_json_int(p_value jsonb, p_field text)
returns integer
language sql
immutable
set search_path = ''
as $$
    select case when jsonb_typeof(p_value -> p_field) = 'number'
                     and (p_value ->> p_field)::numeric = trunc((p_value ->> p_field)::numeric)
                     and abs((p_value ->> p_field)::numeric) < 1000000
                then (p_value ->> p_field)::integer end;
$$;

-- Scheda "Tessera fedeltà" in Gestisci il locale (titolare e collaboratori).
create or replace function public.restaurant_loyalty_program(p_restaurant_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_program public.loyalty_programs;
    v_blocker text;
    v_window interval := make_interval(days => public.loyalty_cfg('report_window_days'));
begin
    if public.restaurant_role(p_restaurant_id) is null and not public.is_platform_admin() then
        raise exception 'Not authorized for this restaurant';
    end if;
    if not public.loyalty_restaurant_enabled(p_restaurant_id) then
        return jsonb_build_object('visible', false);
    end if;
    select * into v_program from public.loyalty_programs where restaurant_id = p_restaurant_id;
    v_blocker := public.loyalty_publish_blocker(p_restaurant_id);
    if v_blocker is not null and coalesce(v_program.status, 'NONE') = 'NONE' then
        -- Nessun menù da mostrare (per esempio senza Pro): la funzione resta nascosta.
        return jsonb_build_object('visible', false);
    end if;
    return jsonb_build_object(
        'visible', true,
        'level', public.loyalty_restaurant_level(p_restaurant_id),
        'can_publish', v_blocker is null,
        'publish_blocker', v_blocker,
        'status', coalesce(v_program.status, 'NONE'),
        'current', public.loyalty_version_json(v_program.current_version_id),
        'versions', coalesce((
            select jsonb_agg(jsonb_build_object('version', v.version, 'accepted_at', v.accepted_at) order by v.version desc)
            from public.loyalty_program_versions v where v.restaurant_id = p_restaurant_id), '[]'::jsonb),
        'closing_until', v_program.closing_until,
        'closing_reason', v_program.closing_reason,
        'suspended_until', v_program.suspended_until,
        'active_cards', (select count(*) from public.loyalty_cards c
                         where c.restaurant_id = p_restaurant_id and c.status = 'ACTIVE'),
        'rewards_available', (select count(*) from public.loyalty_rewards rw
                              where rw.restaurant_id = p_restaurant_id and rw.status = 'AVAILABLE'
                                and rw.expires_at > now()),
        -- T53: quante segnalazioni, senza sapere chi.
        'reports', jsonb_build_object(
            'count', (select count(distinct rp.user_id) from public.loyalty_reports rp
                      where rp.restaurant_id = p_restaurant_id
                        and rp.created_at > greatest(now() - v_window,
                                                     coalesce(v_program.reports_since, '-infinity'::timestamptz))),
            'warn', public.loyalty_cfg('report_warn'),
            'suspend', public.loyalty_cfg('report_suspend'),
            'window_days', public.loyalty_cfg('report_window_days')),
        'limits', jsonb_build_object(
            'stamps_min', public.loyalty_cfg('stamps_min'), 'stamps_max', public.loyalty_cfg('stamps_max'),
            'spend_min_cents', public.loyalty_cfg('spend_min_eur') * 100,
            'spend_max_cents', public.loyalty_cfg('spend_max_eur') * 100,
            'discount_percent_min', public.loyalty_cfg('discount_percent_min'),
            'discount_percent_max', public.loyalty_cfg('discount_percent_max'),
            'discount_cap_min_cents', public.loyalty_cfg('discount_cap_min_eur') * 100,
            'discount_cap_max_cents', public.loyalty_cfg('discount_cap_max_eur') * 100,
            'voucher_min_cents', public.loyalty_cfg('voucher_min_eur') * 100,
            'voucher_max_cents', public.loyalty_cfg('voucher_max_eur') * 100,
            'reward_valid_days', public.loyalty_cfg('reward_valid_days'),
            'inactivity_months', public.loyalty_cfg('inactivity_months'),
            'closing_notice_days', public.loyalty_cfg('closing_notice_days'),
            'stamp_gap_hours', public.loyalty_cfg('stamp_gap_hours'),
            'undo_minutes', public.loyalty_cfg('undo_minutes'),
            'group_max_people', public.loyalty_cfg('group_max_people'))
    );
end;
$$;

-- Attivare o cambiare il programma = pubblicare una nuova versione con il patto (T16–T19).
-- p_rules: {"stamps_required", "condition": {"kind", "min_spend_cents", "types"},
--           "double_day": null | {"weekday", "slot"},
--           "reward": {"kind", "gift", "percent", "cap_cents", "amount_cents", "min_spend_cents",
--                      "from", "weekdays", "max_per_table", "cumulable"}}
create or replace function public.publish_loyalty_version(
    p_restaurant_id uuid,
    p_rules jsonb,
    p_pact_accepted boolean
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_blocker text;
    v_stamps integer;
    v_condition jsonb := p_rules -> 'condition';
    v_double jsonb := p_rules -> 'double_day';
    v_reward jsonb := p_rules -> 'reward';
    v_condition_kind text;
    v_min_spend integer;
    v_types text[];
    v_weekday integer;
    v_slot text;
    v_kind text;
    v_gift text;
    v_percent integer;
    v_cap integer;
    v_amount integer;
    v_reward_min integer;
    v_from text;
    v_weekdays smallint[];
    v_max_table integer;
    v_cumulable boolean;
    v_number integer;
    v_version_id uuid;
begin
    perform public.assert_active_user();
    if not public.is_restaurant_owner(p_restaurant_id) then
        raise exception 'OWNER_REQUIRED';
    end if;
    perform public.assert_restaurant_mfa();
    v_blocker := public.loyalty_publish_blocker(p_restaurant_id);
    if v_blocker is not null then
        raise exception '%', v_blocker;
    end if;
    if not coalesce(p_pact_accepted, false) then
        raise exception 'LOYALTY_PACT_REQUIRED';
    end if;
    if jsonb_typeof(p_rules) is distinct from 'object' then
        raise exception 'LOYALTY_INVALID_RULES';
    end if;

    -- T11: timbri per il premio.
    v_stamps := public.loyalty_json_int(p_rules, 'stamps_required');
    if v_stamps is null or v_stamps not between public.loyalty_cfg('stamps_min') and public.loyalty_cfg('stamps_max') then
        raise exception 'LOYALTY_INVALID_STAMPS';
    end if;

    -- T12–T13: condizione del timbro.
    v_condition_kind := v_condition ->> 'kind';
    if jsonb_typeof(v_condition) is distinct from 'object' or v_condition_kind is null
       or v_condition_kind not in ('SPEND', 'ONE_OF', 'TWO_OF') then
        raise exception 'LOYALTY_INVALID_CONDITION';
    end if;
    if v_condition_kind = 'SPEND' then
        v_min_spend := public.loyalty_json_int(v_condition, 'min_spend_cents');
        if v_min_spend is null
           or v_min_spend not between public.loyalty_cfg('spend_min_eur') * 100 and public.loyalty_cfg('spend_max_eur') * 100
           or jsonb_typeof(v_condition -> 'types') not in ('null') and v_condition ? 'types' then
            raise exception 'LOYALTY_INVALID_CONDITION';
        end if;
    else
        if jsonb_typeof(v_condition -> 'types') is distinct from 'array'
           or jsonb_typeof(v_condition -> 'min_spend_cents') not in ('null') and v_condition ? 'min_spend_cents' then
            raise exception 'LOYALTY_INVALID_CONDITION';
        end if;
        select array_agg(distinct t order by t) into v_types
        from jsonb_array_elements_text(v_condition -> 'types') as t;
        if v_types is null
           or not (v_types <@ array['STARTER', 'FIRST_COURSE', 'MAIN_COURSE', 'PIZZA', 'SINGLE_DISH_OR_MENU',
                                    'DESSERT', 'DRINK', 'COFFEE'])
           or cardinality(v_types) < (v_condition_kind = 'TWO_OF')::integer + 1
           or cardinality(v_types) <> jsonb_array_length(v_condition -> 'types') then
            raise exception 'LOYALTY_INVALID_CONDITION';
        end if;
    end if;

    -- T14: giorno doppio, nessuno o uno a settimana.
    if v_double is not null and jsonb_typeof(v_double) <> 'null' then
        v_weekday := public.loyalty_json_int(v_double, 'weekday');
        v_slot := v_double ->> 'slot';
        if jsonb_typeof(v_double) <> 'object' or v_weekday is null or v_weekday not between 1 and 7
           or v_slot is null or v_slot not in ('ALL_DAY', 'LUNCH', 'DINNER') then
            raise exception 'LOYALTY_INVALID_DOUBLE_DAY';
        end if;
    end if;

    -- T40–T46: premio e regole di utilizzo.
    if jsonb_typeof(v_reward) is distinct from 'object' then
        raise exception 'LOYALTY_INVALID_REWARD';
    end if;
    v_kind := v_reward ->> 'kind';
    v_gift := nullif(v_reward ->> 'gift', '');
    v_percent := public.loyalty_json_int(v_reward, 'percent');
    v_cap := public.loyalty_json_int(v_reward, 'cap_cents');
    v_amount := public.loyalty_json_int(v_reward, 'amount_cents');
    v_reward_min := public.loyalty_json_int(v_reward, 'min_spend_cents');
    v_from := v_reward ->> 'from';
    v_max_table := public.loyalty_json_int(v_reward, 'max_per_table');
    if jsonb_typeof(v_reward -> 'cumulable') is distinct from 'boolean'
       or v_from is null or v_from not in ('SAME_VISIT', 'NEXT_VISIT')
       or (jsonb_typeof(v_reward -> 'max_per_table') not in ('null') and v_reward ? 'max_per_table'
           and (v_max_table is null or v_max_table not between 1 and 10))
       or (jsonb_typeof(v_reward -> 'min_spend_cents') not in ('null') and v_reward ? 'min_spend_cents'
           and (v_reward_min is null or v_reward_min not between 1 and 50000)) then
        raise exception 'LOYALTY_INVALID_REWARD';
    end if;
    v_cumulable := (v_reward ->> 'cumulable')::boolean;
    if v_kind = 'GIFT' then
        -- T40: un prodotto della lista (§8.2), niente alcolici.
        if v_gift is null or v_gift not in ('COFFEE', 'DESSERT', 'ICE_CREAM', 'FRUIT', 'STARTER', 'BRUSCHETTA',
                                            'SIDE_DISH', 'FIRST_COURSE', 'MAIN_COURSE', 'PIZZA',
                                            'DISH_OF_THE_DAY', 'KIDS_MENU', 'SOFT_DRINK', 'WATER',
                                            'ALCOHOL_FREE_APERITIF', 'COVER_CHARGE')
           or v_percent is not null or v_cap is not null or v_amount is not null or v_reward_min is not null then
            raise exception 'LOYALTY_INVALID_REWARD';
        end if;
    elsif v_kind = 'DISCOUNT' then
        -- T41: sconto personale con tetto obbligatorio.
        if v_gift is not null or v_amount is not null
           or v_percent is null
           or v_percent not between public.loyalty_cfg('discount_percent_min') and public.loyalty_cfg('discount_percent_max')
           or v_cap is null
           or v_cap not between public.loyalty_cfg('discount_cap_min_eur') * 100 and public.loyalty_cfg('discount_cap_max_eur') * 100 then
            raise exception 'LOYALTY_INVALID_REWARD';
        end if;
    elsif v_kind = 'VOUCHER' then
        -- T42: buono con spesa minima almeno doppia, solo dalla visita successiva.
        if v_gift is not null or v_percent is not null or v_cap is not null
           or v_amount is null
           or v_amount not between public.loyalty_cfg('voucher_min_eur') * 100 and public.loyalty_cfg('voucher_max_eur') * 100
           or v_reward_min is null or v_reward_min < 2 * v_amount
           or v_from <> 'NEXT_VISIT' then
            raise exception 'LOYALTY_INVALID_REWARD';
        end if;
    else
        raise exception 'LOYALTY_INVALID_REWARD';
    end if;
    -- T44: tutti i giorni (null) o almeno 3 giorni scelti.
    if jsonb_typeof(v_reward -> 'weekdays') = 'array' then
        if exists (select 1 from jsonb_array_elements(v_reward -> 'weekdays') as d
                   where jsonb_typeof(d) <> 'number' or d::text !~ '^[1-7]$') then
            raise exception 'LOYALTY_INVALID_REWARD';
        end if;
        select array_agg(distinct d::smallint order by d::smallint) into v_weekdays
        from jsonb_array_elements_text(v_reward -> 'weekdays') as d;
        if v_weekdays is null or cardinality(v_weekdays) <> jsonb_array_length(v_reward -> 'weekdays')
           or cardinality(v_weekdays) < 3 then
            raise exception 'LOYALTY_INVALID_REWARD';
        end if;
        if cardinality(v_weekdays) = 7 then
            v_weekdays := null;
        end if;
    elsif v_reward ? 'weekdays' and jsonb_typeof(v_reward -> 'weekdays') <> 'null' then
        raise exception 'LOYALTY_INVALID_REWARD';
    end if;

    insert into public.loyalty_programs (restaurant_id) values (p_restaurant_id)
    on conflict (restaurant_id) do nothing;
    perform 1 from public.loyalty_programs where restaurant_id = p_restaurant_id for update;
    select coalesce(max(v.version), 0) + 1 into v_number
    from public.loyalty_program_versions v where v.restaurant_id = p_restaurant_id;

    insert into public.loyalty_program_versions (
        restaurant_id, version, stamps_required, condition_kind, condition_min_spend_cents, condition_types,
        double_weekday, double_slot, reward_kind, reward_gift, reward_percent, reward_cap_cents,
        reward_amount_cents, reward_min_spend_cents, reward_from, reward_weekdays, reward_max_per_table,
        reward_cumulable, reward_valid_days, inactivity_months, accepted_by
    ) values (
        p_restaurant_id, v_number, v_stamps, v_condition_kind, v_min_spend, v_types,
        v_weekday, v_slot, v_kind, v_gift, v_percent, v_cap,
        v_amount, v_reward_min, v_from, v_weekdays, v_max_table,
        v_cumulable, public.loyalty_cfg('reward_valid_days'), public.loyalty_cfg('inactivity_months'), auth.uid()
    )
    returning id into v_version_id;

    -- Attiva (anche dopo un preavviso, che così si annulla, o dopo una sospensione finita).
    update public.loyalty_programs
    set status = 'ACTIVE', current_version_id = v_version_id, closing_reason = null, closing_until = null,
        suspended_until = null, updated_at = now()
    where restaurant_id = p_restaurant_id;

    -- T17: patto registrato con data, versione e account.
    insert into public.consent_log (user_id, kind, version, granted)
    values (auth.uid(), 'LOYALTY_PACT', p_restaurant_id::text || ':v' || v_number, true);
    perform public.log_audit('LOYALTY_VERSION_PUBLISHED', p_restaurant_id, null,
        jsonb_build_object('version', v_number, 'rules', public.loyalty_version_json(v_version_id)));
    return jsonb_build_object('version_id', v_version_id, 'version', v_number);
end;
$$;

-- T20: il locale smette, con preavviso. Niente tessere nuove; chi le ha può completarle.
create or replace function public.close_loyalty_program(p_restaurant_id uuid)
returns timestamptz
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_status text;
    v_until timestamptz := now() + make_interval(days => public.loyalty_cfg('closing_notice_days'));
    v_name text;
begin
    perform public.assert_active_user();
    if not public.is_restaurant_owner(p_restaurant_id) then
        raise exception 'OWNER_REQUIRED';
    end if;
    perform public.assert_restaurant_mfa();
    if not public.loyalty_restaurant_enabled(p_restaurant_id) then
        raise exception 'FEATURE_DISABLED';
    end if;
    select lp.status into v_status from public.loyalty_programs lp where lp.restaurant_id = p_restaurant_id for update;
    if v_status is distinct from 'ACTIVE' then
        raise exception 'LOYALTY_NOT_ACTIVE';
    end if;
    update public.loyalty_programs
    set status = 'CLOSING', closing_reason = 'OWNER', closing_until = v_until, updated_at = now()
    where restaurant_id = p_restaurant_id;
    select left(r.name, 60) into v_name from public.restaurants r where r.id = p_restaurant_id;
    perform public.loyalty_notify(
        array(select c.user_id from public.loyalty_cards c where c.restaurant_id = p_restaurant_id and c.status = 'ACTIVE'),
        p_restaurant_id, 'La tessera sta per finire',
        'La tessera di ' || v_name || ' finisce il ' || to_char(v_until at time zone 'Europe/Rome', 'DD/MM/YYYY')
            || '. Fino ad allora puoi completarla; i premi sbloccati valgono fino alla loro scadenza.',
        'LOYALTY_CLOSING');
    perform public.log_audit('LOYALTY_CLOSING', p_restaurant_id, null,
        jsonb_build_object('reason', 'OWNER', 'until', v_until));
    return v_until;
end;
$$;

-- ---------------------------------------------------------------------------
-- 6) Il cliente (T23–T31, T48, T55–T61).
-- ---------------------------------------------------------------------------
-- Cosa mostrare nell'app: NEW (tessere nuove), EXISTING (solo quelle iniziate), NONE (niente).
create or replace function public.loyalty_access()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_level text := public.loyalty_user_level(auth.uid());
    v_has_cards boolean := false;
begin
    if auth.uid() is not null and v_level <> 'NONE' then
        select exists (
            select 1 from public.loyalty_members m
            where m.user_id = auth.uid()
              and public.loyalty_restaurant_enabled(m.restaurant_id)
              and (exists (select 1 from public.loyalty_cards c
                           where c.restaurant_id = m.restaurant_id and c.user_id = m.user_id and c.status = 'ACTIVE')
                   or exists (select 1 from public.loyalty_rewards rw
                              where rw.restaurant_id = m.restaurant_id and rw.user_id = m.user_id
                                and rw.status = 'AVAILABLE' and rw.expires_at > now()))
        ) into v_has_cards;
    end if;
    return jsonb_build_object(
        'level', v_level,
        'has_cards', v_has_cards,
        'visible', v_level = 'NEW' or (v_level = 'EXISTING' and v_has_cards));
end;
$$;

-- Riquadro della tessera nella scheda del locale (anche senza account, T61).
create or replace function public.loyalty_restaurant_card(p_restaurant_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_user_level text := public.loyalty_user_level(auth.uid());
    v_level text;
    v_program public.loyalty_programs;
    v_card public.loyalty_cards;
    v_rewards jsonb := '[]'::jsonb;
    v_code text;
begin
    if v_user_level = 'NONE' or not public.loyalty_restaurant_enabled(p_restaurant_id) then
        return jsonb_build_object('available', false);
    end if;
    v_level := public.loyalty_restaurant_level(p_restaurant_id);
    if v_level = 'NONE' then
        return jsonb_build_object('available', false);
    end if;
    select * into v_program from public.loyalty_programs where restaurant_id = p_restaurant_id;
    if auth.uid() is not null then
        select m.code into v_code from public.loyalty_members m
        where m.restaurant_id = p_restaurant_id and m.user_id = auth.uid();
        select * into v_card from public.loyalty_cards c
        where c.restaurant_id = p_restaurant_id and c.user_id = auth.uid() and c.status = 'ACTIVE';
        select coalesce(jsonb_agg(public.loyalty_reward_json(rw.id) order by rw.unlocked_at), '[]'::jsonb)
        into v_rewards
        from public.loyalty_rewards rw
        where rw.restaurant_id = p_restaurant_id and rw.user_id = auth.uid()
          and rw.status = 'AVAILABLE' and rw.expires_at > now();
    end if;
    if not (v_level = 'NEW' and v_user_level = 'NEW') and v_card.id is null and jsonb_array_length(v_rewards) = 0 then
        return jsonb_build_object('available', false);
    end if;
    return jsonb_build_object(
        'available', true,
        'can_start', v_level = 'NEW' and v_user_level = 'NEW',
        'status', v_program.status,
        'closing_until', v_program.closing_until,
        'rules', case when v_level <> 'REWARDS' then public.loyalty_version_json(v_program.current_version_id) end,
        'code', v_code,
        'card', case when v_card.id is not null then jsonb_build_object(
                    'stamps', v_card.stamps, 'started_at', v_card.started_at,
                    'last_stamp_at', v_card.last_stamp_at,
                    'rules', public.loyalty_version_json(v_card.version_id)) end,
        'rewards', v_rewards);
end;
$$;

-- QR personale (§6.1): 60 secondi, una volta sola. I QR ancora validi restano validi.
create or replace function public.create_visit_token(p_restaurant_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
begin
    perform public.loyalty_assert_customer(p_restaurant_id);
    if (select count(*) from public.visit_tokens t
        where t.user_id = auth.uid() and t.created_at > now() - interval '10 minutes') >= 40 then
        raise exception 'TOO_MANY_CODES';
    end if;
    return public.loyalty_new_token('PERSONAL', p_restaurant_id, auth.uid(), null);
end;
$$;

-- Esito del proprio QR, per la schermata del cliente («✓ +1 timbro · 4 su 10»).
create or replace function public.visit_token_status(p_token text)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_token public.visit_tokens;
    v_hex text := substring(lower(coalesce(p_token, '')) from '([0-9a-f]{32})');
begin
    perform public.assert_active_user();
    select * into v_token from public.visit_tokens t
    where t.token_hash = extensions.digest(coalesce(v_hex, ''), 'sha256') and t.user_id = auth.uid();
    if v_token.id is null then
        raise exception 'INVALID_TOKEN';
    end if;
    return jsonb_build_object(
        'status', case when v_token.used_at is not null then 'USED'
                       when v_token.expires_at <= now() then 'EXPIRED' else 'WAITING' end,
        'expires_at', v_token.expires_at,
        'result', v_token.result);
end;
$$;

-- Tavolo di gruppo (§6.2): il capogruppo crea il gruppo e mostra il «QR del tavolo».
create or replace function public.create_loyalty_group(p_restaurant_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
    v_group public.loyalty_groups;
begin
    perform public.loyalty_assert_customer(p_restaurant_id);
    if (select count(*) from public.visit_tokens t
        where t.user_id = auth.uid() and t.created_at > now() - interval '10 minutes') >= 40 then
        raise exception 'TOO_MANY_CODES';
    end if;
    perform public.loyalty_leave_open_groups(auth.uid());
    insert into public.loyalty_groups (restaurant_id, leader_id, join_until, expires_at)
    values (p_restaurant_id, auth.uid(),
            now() + make_interval(mins => public.loyalty_cfg('group_join_minutes')),
            now() + make_interval(mins => public.loyalty_cfg('group_valid_minutes')))
    returning * into v_group;
    insert into public.loyalty_group_members (group_id, user_id) values (v_group.id, auth.uid());
    return public.loyalty_new_token('GROUP', p_restaurant_id, auth.uid(), v_group.id)
        || jsonb_build_object('group_id', v_group.id, 'join_until', v_group.join_until,
                              'group_expires_at', v_group.expires_at, 'members', 1);
end;
$$;

-- Nuovo QR del tavolo ogni 60 secondi (solo il capogruppo, finché il gruppo è aperto).
create or replace function public.loyalty_group_token(p_group_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
    v_group public.loyalty_groups;
begin
    perform public.assert_active_user();
    select * into v_group from public.loyalty_groups g where g.id = p_group_id and g.leader_id = auth.uid();
    if v_group.id is null then
        raise exception 'GROUP_NOT_FOUND';
    end if;
    if v_group.used_at is not null or v_group.expires_at <= now() then
        raise exception 'GROUP_CLOSED';
    end if;
    perform public.loyalty_assert_customer(v_group.restaurant_id);
    if (select count(*) from public.visit_tokens t
        where t.user_id = auth.uid() and t.created_at > now() - interval '10 minutes') >= 40 then
        raise exception 'TOO_MANY_CODES';
    end if;
    return public.loyalty_new_token('GROUP', v_group.restaurant_id, auth.uid(), v_group.id)
        || jsonb_build_object('group_id', v_group.id, 'join_until', v_group.join_until,
                              'group_expires_at', v_group.expires_at,
                              'members', (select count(*) from public.loyalty_group_members m where m.group_id = v_group.id));
end;
$$;

-- «Unisciti a un tavolo»: inquadrando il QR del tavolo (entro 10 minuti, fino a 20 persone).
create or replace function public.join_loyalty_group(p_token text)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
    v_token public.visit_tokens;
    v_group public.loyalty_groups;
    v_hex text := substring(lower(coalesce(p_token, '')) from '([0-9a-f]{32})');
begin
    perform public.assert_active_user();
    select * into v_token from public.visit_tokens t
    where t.token_hash = extensions.digest(coalesce(v_hex, ''), 'sha256') and t.kind = 'GROUP';
    if v_token.id is null then
        raise exception 'INVALID_TOKEN';
    end if;
    if v_token.used_at is not null or v_token.expires_at <= now() then
        raise exception 'TOKEN_EXPIRED';
    end if;
    select * into v_group from public.loyalty_groups g where g.id = v_token.group_id for update;
    perform public.loyalty_assert_customer(v_group.restaurant_id);
    if not exists (select 1 from public.loyalty_group_members m where m.group_id = v_group.id and m.user_id = auth.uid()) then
        if v_group.used_at is not null or v_group.join_until <= now() or v_group.expires_at <= now() then
            raise exception 'GROUP_CLOSED';
        end if;
        if (select count(*) from public.loyalty_group_members m where m.group_id = v_group.id)
           >= public.loyalty_cfg('group_max_people') then
            raise exception 'GROUP_FULL';
        end if;
        perform public.loyalty_leave_open_groups(auth.uid());
        insert into public.loyalty_group_members (group_id, user_id) values (v_group.id, auth.uid());
    end if;
    return jsonb_build_object(
        'group_id', v_group.id,
        'restaurant_id', v_group.restaurant_id,
        'restaurant_name', (select r.name from public.restaurants r where r.id = v_group.restaurant_id),
        'members', (select count(*) from public.loyalty_group_members m where m.group_id = v_group.id),
        'expires_at', v_group.expires_at);
end;
$$;

-- Uscire da un tavolo (il capogruppo lo chiude per tutti).
create or replace function public.leave_loyalty_group(p_group_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    perform public.assert_active_user();
    update public.loyalty_groups set expires_at = now(), join_until = least(join_until, now())
    where id = p_group_id and leader_id = auth.uid() and used_at is null and expires_at > now();
    if not found then
        delete from public.loyalty_group_members m
        using public.loyalty_groups g
        where m.group_id = g.id and g.id = p_group_id and m.user_id = auth.uid() and g.used_at is null;
    end if;
end;
$$;

-- Stato del tavolo per ogni membro: quante persone e, dopo la scansione, il proprio esito.
create or replace function public.loyalty_group_status(p_group_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_group public.loyalty_groups;
begin
    perform public.assert_active_user();
    select g.* into v_group from public.loyalty_groups g
    join public.loyalty_group_members m on m.group_id = g.id and m.user_id = auth.uid()
    where g.id = p_group_id;
    if v_group.id is null then
        raise exception 'GROUP_NOT_FOUND';
    end if;
    return jsonb_build_object(
        'group_id', v_group.id,
        'restaurant_id', v_group.restaurant_id,
        'leader', v_group.leader_id = auth.uid(),
        'members', (select count(*) from public.loyalty_group_members m where m.group_id = v_group.id),
        'join_until', v_group.join_until,
        'expires_at', v_group.expires_at,
        'status', case when v_group.used_at is not null then 'USED'
                       when v_group.expires_at <= now() then 'CLOSED' else 'OPEN' end,
        'result', (select jsonb_build_object('outcome', s.outcome, 'stamps_added', s.stamps,
                                             'double_day', s.double_day, 'undone', s.undone_at is not null,
                                             'reward_unlocked', s.reward_id is not null)
                   from public.loyalty_stamps s
                   join public.loyalty_scans sc on sc.id = s.scan_id
                   where sc.group_id = v_group.id and s.user_id = auth.uid()
                   order by s.id desc limit 1));
end;
$$;

-- «Le mie tessere» (T27): tessere attive e premi da usare, con le regole della propria versione.
create or replace function public.my_loyalty_cards()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
    perform public.assert_active_user();
    if public.loyalty_user_level(auth.uid()) = 'NONE' then
        raise exception 'FEATURE_DISABLED';
    end if;
    return coalesce((
        select jsonb_agg(jsonb_build_object(
            'restaurant_id', r.id,
            'restaurant_name', r.name,
            'city', r.city,
            'code', m.code,
            'program_status', lp.status,
            'closing_until', lp.closing_until,
            'card', (select jsonb_build_object(
                        'stamps', c.stamps, 'started_at', c.started_at, 'last_stamp_at', c.last_stamp_at,
                        'reset_at', coalesce(c.last_stamp_at, c.started_at) + make_interval(months => v.inactivity_months),
                        'rules', public.loyalty_version_json(c.version_id))
                     from public.loyalty_cards c
                     join public.loyalty_program_versions v on v.id = c.version_id
                     where c.restaurant_id = m.restaurant_id and c.user_id = m.user_id and c.status = 'ACTIVE'),
            'rewards', coalesce((select jsonb_agg(public.loyalty_reward_json(rw.id) order by rw.unlocked_at)
                                 from public.loyalty_rewards rw
                                 where rw.restaurant_id = m.restaurant_id and rw.user_id = m.user_id
                                   and rw.status = 'AVAILABLE' and rw.expires_at > now()), '[]'::jsonb)
        ) order by r.name)
        from public.loyalty_members m
        join public.restaurants r on r.id = m.restaurant_id
        left join public.loyalty_programs lp on lp.restaurant_id = m.restaurant_id
        where m.user_id = auth.uid()
          and public.loyalty_restaurant_enabled(m.restaurant_id)
          and (exists (select 1 from public.loyalty_cards c
                       where c.restaurant_id = m.restaurant_id and c.user_id = m.user_id and c.status = 'ACTIVE')
               or exists (select 1 from public.loyalty_rewards rw
                          where rw.restaurant_id = m.restaurant_id and rw.user_id = m.user_id
                            and rw.status = 'AVAILABLE' and rw.expires_at > now()))
    ), '[]'::jsonb);
end;
$$;

-- T26: lasciare la tessera di un locale (timbri, premi e codice si cancellano). Sempre possibile.
create or replace function public.leave_loyalty_card(p_restaurant_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    perform public.assert_active_user();
    delete from public.loyalty_stamps where restaurant_id = p_restaurant_id and user_id = auth.uid();
    delete from public.loyalty_members where restaurant_id = p_restaurant_id and user_id = auth.uid();
end;
$$;

-- T48: segnalazione (NO_STAMP «Non hanno voluto timbrare», REWARD_REFUSED «Non mi hanno
-- riconosciuto il premio»). Solo con un timbro negli ultimi 60 giorni, una ogni 90 giorni.
create or replace function public.report_loyalty_problem(p_restaurant_id uuid, p_kind text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    perform public.assert_active_user();
    if public.loyalty_user_level(auth.uid()) = 'NONE' or not public.loyalty_restaurant_enabled(p_restaurant_id) then
        raise exception 'FEATURE_DISABLED';
    end if;
    if p_kind is null or p_kind not in ('NO_STAMP', 'REWARD_REFUSED') then
        raise exception 'INVALID_REPORT_KIND';
    end if;
    if not exists (select 1 from public.loyalty_stamps s
                   where s.restaurant_id = p_restaurant_id and s.user_id = auth.uid()
                     and s.stamps > 0 and s.undone_at is null
                     and s.created_at > now() - make_interval(days => public.loyalty_cfg('report_eligible_days'))) then
        raise exception 'REPORT_NOT_ALLOWED';
    end if;
    if exists (select 1 from public.loyalty_reports rp
               where rp.restaurant_id = p_restaurant_id and rp.user_id = auth.uid()
                 and rp.created_at > now() - make_interval(days => public.loyalty_cfg('report_gap_days'))) then
        raise exception 'REPORT_TOO_SOON';
    end if;
    insert into public.loyalty_reports (restaurant_id, user_id, kind) values (p_restaurant_id, auth.uid(), p_kind);
    perform public.loyalty_evaluate_reports(p_restaurant_id);
end;
$$;

-- ---------------------------------------------------------------------------
-- 7) Il locale timbra (T32–T39) e consegna i premi (§8.3).
-- ---------------------------------------------------------------------------
-- Scansione del QR personale o del tavolo (p_token), oppure codice di riserva (p_code).
-- Gli errori sui codici rispondono ok=false (senza eccezione) così il conteggio dei tentativi
-- sbagliati resta salvato.
create or replace function public.register_stamp(p_restaurant_id uuid, p_token text default null, p_code text default null)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $$
declare
    v_level text;
    v_program public.loyalty_programs;
    v_token public.visit_tokens;
    v_group public.loyalty_groups;
    v_hex text;
    v_code text;
    v_errors integer;
    v_scan_id uuid;
    v_people uuid[];
    v_present uuid[] := array[]::uuid[];
    v_user uuid;
    v_user_level text;
    v_outcome text;
    v_card public.loyalty_cards;
    v_version public.loyalty_program_versions;
    v_member_code text;
    v_member_created boolean;
    v_card_created boolean;
    v_double boolean;
    v_added integer;
    v_carry integer;
    v_reward_id uuid;
    v_carry_id uuid;
    v_prev_stamps smallint;
    v_prev_last timestamptz;
    v_gap interval := make_interval(hours => public.loyalty_cfg('stamp_gap_hours'));
    v_entry jsonb;
    v_members jsonb := '[]'::jsonb;
    v_stamped integer := 0;
    v_stamps_total integer := 0;
    v_new_members integer := 0;
    v_cards_started integer := 0;
    v_rewards_unlocked integer := 0;
begin
    perform public.assert_active_user();
    if public.restaurant_role(p_restaurant_id) is null then
        raise exception 'Not authorized for this restaurant';
    end if;
    perform public.assert_restaurant_mfa();
    if not public.loyalty_restaurant_enabled(p_restaurant_id) then
        raise exception 'FEATURE_DISABLED';
    end if;
    v_level := public.loyalty_restaurant_level(p_restaurant_id);
    if v_level = 'NONE' then
        raise exception 'LOYALTY_NOT_ACTIVE';
    end if;
    -- Una scansione alla volta per locale (tetti e tentativi contati bene).
    select * into v_program from public.loyalty_programs where restaurant_id = p_restaurant_id for update;

    -- T39: tetti automatici.
    if (select count(*) from public.loyalty_scans s
        where s.restaurant_id = p_restaurant_id and s.created_at > now() - interval '10 minutes')
       >= public.loyalty_cfg('scans_per_10_min')
       or (select count(*) from public.loyalty_scans s
           where s.restaurant_id = p_restaurant_id and s.created_at > now() - interval '1 day'
             and (s.created_at at time zone 'Europe/Rome')::date = public.today_rome())
          >= public.loyalty_cfg('scans_per_day') then
        raise exception 'SCAN_LIMIT';
    end if;

    if p_token is not null then
        v_hex := substring(lower(p_token) from '([0-9a-f]{32})');
        select * into v_token from public.visit_tokens t
        where t.token_hash = extensions.digest(coalesce(v_hex, ''), 'sha256') for update;
        if v_token.id is null or v_token.restaurant_id <> p_restaurant_id then
            return jsonb_build_object('ok', false, 'error', 'INVALID_TOKEN');
        end if;
    elsif p_code is not null then
        -- T36: dopo 10 codici sbagliati in 10 minuti, l'inserimento si blocca per 10 minuti.
        if v_program.code_locked_until > now() then
            return jsonb_build_object('ok', false, 'error', 'CODE_LOCKED', 'locked_until', v_program.code_locked_until);
        end if;
        v_code := upper(regexp_replace(p_code, '[^A-Za-z0-9]', '', 'g'));
        select * into v_token from public.visit_tokens t
        where t.restaurant_id = p_restaurant_id and t.code_hash = extensions.digest(v_code, 'sha256')
          and t.used_at is null and t.expires_at > now()
        order by t.created_at desc
        limit 1
        for update;
        if v_token.id is null then
            insert into public.loyalty_code_failures (restaurant_id) values (p_restaurant_id);
            select count(*) into v_errors from public.loyalty_code_failures f
            where f.restaurant_id = p_restaurant_id and f.created_at > now() - interval '10 minutes';
            if v_errors >= public.loyalty_cfg('code_errors_max') then
                update public.loyalty_programs
                set code_locked_until = now() + make_interval(mins => public.loyalty_cfg('code_lock_minutes'))
                where restaurant_id = p_restaurant_id
                returning code_locked_until into v_program.code_locked_until;
                delete from public.loyalty_code_failures where restaurant_id = p_restaurant_id;
                perform public.log_audit('LOYALTY_CODE_LOCKED', p_restaurant_id, null, '{}');
                return jsonb_build_object('ok', false, 'error', 'CODE_LOCKED', 'locked_until', v_program.code_locked_until);
            end if;
            return jsonb_build_object('ok', false, 'error', 'INVALID_CODE',
                                      'attempts_left', public.loyalty_cfg('code_errors_max') - v_errors);
        end if;
    else
        raise exception 'TOKEN_REQUIRED';
    end if;

    -- T35: 60 secondi, una volta sola.
    if v_token.used_at is not null then
        return jsonb_build_object('ok', false, 'error', 'TOKEN_USED');
    end if;
    if v_token.expires_at <= now() then
        return jsonb_build_object('ok', false, 'error', 'TOKEN_EXPIRED');
    end if;

    if v_token.kind = 'PERSONAL' then
        v_people := array[v_token.user_id];
    else
        select * into v_group from public.loyalty_groups g where g.id = v_token.group_id for update;
        if v_group.used_at is not null then
            return jsonb_build_object('ok', false, 'error', 'TOKEN_USED');
        end if;
        if v_group.expires_at <= now() then
            return jsonb_build_object('ok', false, 'error', 'TOKEN_EXPIRED');
        end if;
        select array_agg(m.user_id order by m.joined_at) into v_people
        from public.loyalty_group_members m where m.group_id = v_group.id;
        if v_people is null then
            return jsonb_build_object('ok', false, 'error', 'TOKEN_EXPIRED');
        end if;
        update public.loyalty_groups set used_at = now() where id = v_group.id;
    end if;
    update public.visit_tokens set used_at = now(), used_by = auth.uid() where id = v_token.id;
    insert into public.loyalty_scans (restaurant_id, kind, token_id, group_id, scanned_by, people)
    values (p_restaurant_id, v_token.kind, v_token.id, v_token.group_id, auth.uid(), cardinality(v_people))
    returning id into v_scan_id;

    foreach v_user in array v_people loop
        v_outcome := null;
        v_card := null;
        v_version := null;
        v_member_code := null;
        v_member_created := false;
        v_card_created := false;
        v_double := false;
        v_added := 0;
        v_carry := 0;
        v_reward_id := null;
        v_carry_id := null;
        v_prev_stamps := null;
        v_prev_last := null;
        v_user_level := public.loyalty_user_level(v_user);

        if exists (select 1 from public.restaurant_users ru
                   where ru.restaurant_id = p_restaurant_id and ru.user_id = v_user) then
            v_outcome := 'SELF';                      -- T38
        elsif v_user_level = 'NONE' then
            v_outcome := 'NO_ACCESS';
        else
            v_present := v_present || v_user;
            select m.code into v_member_code from public.loyalty_members m
            where m.restaurant_id = p_restaurant_id and m.user_id = v_user;
            select * into v_card from public.loyalty_cards c
            where c.restaurant_id = p_restaurant_id and c.user_id = v_user and c.status = 'ACTIVE'
            for update;
            if v_level = 'REWARDS' then
                v_outcome := 'PROGRAM_ENDED';
            elsif exists (select 1 from public.loyalty_stamps s
                          where s.restaurant_id = p_restaurant_id and s.user_id = v_user
                            and s.stamps > 0 and s.undone_at is null and s.created_at > now() - v_gap) then
                v_outcome := 'TOO_SOON';              -- T37
            elsif v_card.id is null and not (v_level = 'NEW' and v_user_level = 'NEW') then
                v_outcome := 'NO_NEW_CARDS';
            end if;
        end if;

        if v_outcome is null then
            if v_card.id is null then
                -- T23: la tessera nasce al primo timbro, sulla versione attiva oggi.
                if v_member_code is null then
                    loop
                        v_member_code := public.loyalty_random_code(4);
                        insert into public.loyalty_members (restaurant_id, user_id, code)
                        values (p_restaurant_id, v_user, v_member_code)
                        on conflict (restaurant_id, code) do nothing;
                        exit when found;
                    end loop;
                    v_member_created := true;
                    v_new_members := v_new_members + 1;
                end if;
                insert into public.loyalty_cards (restaurant_id, user_id, version_id)
                values (p_restaurant_id, v_user, v_program.current_version_id)
                returning * into v_card;
                v_card_created := true;
                v_cards_started := v_cards_started + 1;
            end if;
            select * into v_version from public.loyalty_program_versions v where v.id = v_card.version_id;
            v_double := public.loyalty_is_double(v_version.double_weekday, v_version.double_slot, now());
            v_added := case when v_double then 2 else 1 end;
            v_prev_stamps := v_card.stamps;
            v_prev_last := v_card.last_stamp_at;
            if v_card.stamps + v_added >= v_version.stamps_required then
                -- T25: premio sbloccato; il timbro in più passa alla tessera nuova.
                insert into public.loyalty_rewards (restaurant_id, user_id, card_id, version_id, usable_from, expires_at)
                values (p_restaurant_id, v_user, v_card.id, v_version.id,
                        case when v_version.reward_from = 'SAME_VISIT' then now() else now() + v_gap end,
                        now() + make_interval(days => v_version.reward_valid_days))
                returning id into v_reward_id;
                v_rewards_unlocked := v_rewards_unlocked + 1;
                v_carry := v_card.stamps + v_added - v_version.stamps_required;
                update public.loyalty_cards
                set stamps = v_version.stamps_required, last_stamp_at = now(), status = 'COMPLETED', closed_at = now()
                where id = v_card.id
                returning * into v_card;
                if v_carry > 0 and v_level = 'NEW' and v_user_level = 'NEW' then
                    insert into public.loyalty_cards (restaurant_id, user_id, version_id, stamps, last_stamp_at)
                    values (p_restaurant_id, v_user, v_program.current_version_id, v_carry, now())
                    returning id into v_carry_id;
                    v_cards_started := v_cards_started + 1;
                else
                    v_carry := 0;
                end if;
            else
                update public.loyalty_cards
                set stamps = stamps + v_added, last_stamp_at = now(), reset_warned_at = null
                where id = v_card.id
                returning * into v_card;
            end if;
            v_outcome := 'STAMPED';
            v_stamped := v_stamped + 1;
            v_stamps_total := v_stamps_total + v_added;
        end if;

        insert into public.loyalty_stamps (
            scan_id, restaurant_id, user_id, card_id, outcome, stamps, double_day, member_created,
            card_created, reward_id, carry_card_id, prev_stamps, prev_last_stamp_at
        ) values (
            v_scan_id, p_restaurant_id, v_user, v_card.id, v_outcome, v_added, v_double, v_member_created,
            v_card_created, v_reward_id, v_carry_id, v_prev_stamps, v_prev_last
        );

        -- Esito per persona: solo il codice anonimo, mai dati personali (T55).
        if v_card.id is not null and v_version.id is null then
            select * into v_version from public.loyalty_program_versions v where v.id = v_card.version_id;
        end if;
        v_entry := jsonb_build_object(
            'code', case when v_outcome in ('SELF', 'NO_ACCESS') then null else v_member_code end,
            'outcome', v_outcome,
            'stamps_added', v_added,
            'double_day', v_double,
            'stamps', v_card.stamps,
            'required', v_version.stamps_required,
            'reward_unlocked', v_reward_id is not null,
            'carry', v_carry,
            'condition', case when v_version.id is not null then jsonb_build_object(
                             'kind', v_version.condition_kind,
                             'min_spend_cents', v_version.condition_min_spend_cents,
                             'types', to_jsonb(v_version.condition_types)) end);
        v_members := v_members || jsonb_build_array(v_entry);
        if v_token.kind = 'PERSONAL' then
            update public.visit_tokens set result = v_entry where id = v_token.id;
        end if;
    end loop;

    update public.loyalty_scans set stamped = v_stamped where id = v_scan_id;
    perform public.loyalty_add_stats(p_restaurant_id, public.today_rome(),
        p_scans => 1, p_group_scans => (v_token.kind = 'GROUP')::integer, p_people => v_stamped,
        p_stamps => v_stamps_total, p_new_members => v_new_members, p_cards_started => v_cards_started,
        p_rewards_unlocked => v_rewards_unlocked);

    return jsonb_build_object(
        'ok', true,
        'scan_id', v_scan_id,
        'kind', v_token.kind,
        'people', cardinality(v_people),
        'stamped', v_stamped,
        'stamps', v_stamps_total,
        'undo_until', now() + make_interval(mins => public.loyalty_cfg('undo_minutes')),
        'members', v_members,
        -- Premi da consegnare, con le loro regole (§8.3): di chi è presente a questa scansione.
        'rewards', coalesce((
            select jsonb_agg(public.loyalty_reward_json(rw.id) || jsonb_build_object('code', m.code)
                             order by rw.unlocked_at)
            from public.loyalty_rewards rw
            join public.loyalty_members m on m.restaurant_id = rw.restaurant_id and m.user_id = rw.user_id
            where rw.restaurant_id = p_restaurant_id and rw.user_id = any(v_present)
              and rw.status = 'AVAILABLE' and rw.expires_at > now()), '[]'::jsonb));
end;
$$;

-- T33: annullamento di una scansione sbagliata, solo entro 2 minuti; registrato.
create or replace function public.undo_stamp(p_scan_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_scan public.loyalty_scans;
    v_stamp public.loyalty_stamps;
    v_reward public.loyalty_rewards;
    v_day date;
    v_people integer := 0;
    v_stamps integer := 0;
    v_new_members integer := 0;
    v_cards_started integer := 0;
    v_rewards_unlocked integer := 0;
begin
    perform public.assert_active_user();
    select * into v_scan from public.loyalty_scans s where s.id = p_scan_id;
    if v_scan.id is null or public.restaurant_role(v_scan.restaurant_id) is null then
        raise exception 'SCAN_NOT_FOUND';
    end if;
    perform public.assert_restaurant_mfa();
    perform 1 from public.loyalty_programs where restaurant_id = v_scan.restaurant_id for update;
    select * into v_scan from public.loyalty_scans s where s.id = p_scan_id for update;
    if v_scan.undone_at is not null then
        raise exception 'ALREADY_UNDONE';
    end if;
    if v_scan.created_at < now() - make_interval(mins => public.loyalty_cfg('undo_minutes')) then
        raise exception 'UNDO_EXPIRED';
    end if;
    v_day := (v_scan.created_at at time zone 'Europe/Rome')::date;

    for v_stamp in
        select * from public.loyalty_stamps s where s.scan_id = p_scan_id and s.stamps > 0 order by s.id desc
    loop
        if v_stamp.carry_card_id is not null then
            delete from public.loyalty_cards where id = v_stamp.carry_card_id;
            v_cards_started := v_cards_started + 1;
        end if;
        if v_stamp.reward_id is not null then
            select * into v_reward from public.loyalty_rewards where id = v_stamp.reward_id;
            if v_reward.used_at is not null then
                perform public.loyalty_add_stats(v_scan.restaurant_id, (v_reward.used_at at time zone 'Europe/Rome')::date,
                    p_rewards_used => -1, p_discount_cents => -coalesce(v_reward.discount_cents, 0));
            end if;
            delete from public.loyalty_rewards where id = v_stamp.reward_id;
            v_rewards_unlocked := v_rewards_unlocked + 1;
        end if;
        if v_stamp.card_created then
            delete from public.loyalty_cards where id = v_stamp.card_id;
            v_cards_started := v_cards_started + 1;
        else
            update public.loyalty_cards
            set stamps = v_stamp.prev_stamps, last_stamp_at = v_stamp.prev_last_stamp_at,
                status = 'ACTIVE', closed_at = null
            where id = v_stamp.card_id;
        end if;
        if v_stamp.member_created then
            delete from public.loyalty_members m
            where m.restaurant_id = v_scan.restaurant_id and m.user_id = v_stamp.user_id
              and not exists (select 1 from public.loyalty_cards c
                              where c.restaurant_id = m.restaurant_id and c.user_id = m.user_id)
              and not exists (select 1 from public.loyalty_rewards rw
                              where rw.restaurant_id = m.restaurant_id and rw.user_id = m.user_id);
            v_new_members := v_new_members + 1;
        end if;
        v_people := v_people + 1;
        v_stamps := v_stamps + v_stamp.stamps;
    end loop;

    update public.loyalty_stamps set undone_at = now() where scan_id = p_scan_id;
    update public.loyalty_scans set undone_at = now(), undone_by = auth.uid() where id = p_scan_id;
    perform public.loyalty_add_stats(v_scan.restaurant_id, v_day,
        p_scans => -1, p_group_scans => -((v_scan.kind = 'GROUP')::integer), p_people => -v_people,
        p_stamps => -v_stamps, p_new_members => -v_new_members, p_cards_started => -v_cards_started,
        p_rewards_unlocked => -v_rewards_unlocked);
    perform public.log_audit('LOYALTY_SCAN_UNDONE', v_scan.restaurant_id, null,
        jsonb_build_object('scan_id', p_scan_id, 'people', v_scan.people, 'stamps', v_stamps));
end;
$$;

-- Consegna di un premio (T4, T43–T46): il cliente deve essere stato appena scansionato in
-- questo locale (prova che è presente: il locale non può segnare premi «usati» a distanza).
-- p_discount_cents: per sconti e buoni, l'importo riconosciuto (facoltativo, per le statistiche).
create or replace function public.use_reward(p_restaurant_id uuid, p_reward_id uuid, p_discount_cents integer default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_reward public.loyalty_rewards;
    v_version public.loyalty_program_versions;
    v_scan_id uuid;
    v_used_in_scan integer;
begin
    perform public.assert_active_user();
    if public.restaurant_role(p_restaurant_id) is null then
        raise exception 'Not authorized for this restaurant';
    end if;
    perform public.assert_restaurant_mfa();
    if not public.loyalty_restaurant_enabled(p_restaurant_id) then
        raise exception 'FEATURE_DISABLED';
    end if;
    if public.loyalty_restaurant_level(p_restaurant_id) = 'NONE' then
        raise exception 'LOYALTY_NOT_ACTIVE';
    end if;
    perform 1 from public.loyalty_programs where restaurant_id = p_restaurant_id for update;
    select * into v_reward from public.loyalty_rewards rw
    where rw.id = p_reward_id and rw.restaurant_id = p_restaurant_id for update;
    if v_reward.id is null then
        raise exception 'REWARD_NOT_FOUND';
    end if;
    if v_reward.status <> 'AVAILABLE' then
        raise exception 'REWARD_NOT_AVAILABLE';
    end if;
    if v_reward.expires_at <= now() then
        raise exception 'REWARD_EXPIRED';
    end if;
    if v_reward.usable_from > now() then
        raise exception 'REWARD_NOT_YET';             -- T43: dalla visita successiva
    end if;
    select * into v_version from public.loyalty_program_versions v where v.id = v_reward.version_id;
    if not public.loyalty_reward_usable_now(v_reward.status, v_reward.usable_from, v_reward.expires_at,
                                            v_version.reward_weekdays) then
        raise exception 'REWARD_NOT_TODAY';           -- T44
    end if;
    select s.scan_id into v_scan_id
    from public.loyalty_stamps s
    join public.loyalty_scans sc on sc.id = s.scan_id
    where s.restaurant_id = p_restaurant_id and s.user_id = v_reward.user_id
      and s.undone_at is null and s.outcome not in ('SELF', 'NO_ACCESS')
      and sc.created_at > now() - make_interval(mins => public.loyalty_cfg('reward_scan_minutes'))
    order by s.id desc
    limit 1;
    if v_scan_id is null then
        raise exception 'REWARD_NEEDS_SCAN';
    end if;
    -- T45: quanti premi per tavolo alla stessa visita.
    select count(*) into v_used_in_scan from public.loyalty_rewards rw where rw.used_scan_id = v_scan_id;
    if v_version.reward_max_per_table is not null and v_used_in_scan >= v_version.reward_max_per_table then
        raise exception 'REWARD_TABLE_LIMIT';
    end if;
    if p_discount_cents is not null and (
        p_discount_cents < 0
        or v_version.reward_kind = 'GIFT'
        or (v_version.reward_kind = 'DISCOUNT' and p_discount_cents > v_version.reward_cap_cents)
        or (v_version.reward_kind = 'VOUCHER' and p_discount_cents > v_version.reward_amount_cents)) then
        raise exception 'INVALID_DISCOUNT';
    end if;
    update public.loyalty_rewards
    set status = 'USED', used_at = now(), used_by = auth.uid(), used_scan_id = v_scan_id,
        discount_cents = p_discount_cents, closed_at = now()
    where id = p_reward_id;
    perform public.loyalty_add_stats(p_restaurant_id, public.today_rome(),
        p_rewards_used => 1, p_discount_cents => coalesce(p_discount_cents, 0));
    return jsonb_build_object('ok', true, 'reward_id', p_reward_id);
end;
$$;

-- Statistiche della tessera per il locale (§11): solo numeri, mai dati personali.
create or replace function public.restaurant_loyalty_stats(p_restaurant_id uuid, p_days integer default 30)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_days integer := least(greatest(coalesce(p_days, 30), 1), 90);
    v_from date := public.today_rome() - least(greatest(coalesce(p_days, 30), 1), 90) + 1;
    v_since timestamptz;
    v_totals jsonb;
begin
    if public.restaurant_role(p_restaurant_id) is null and not public.is_platform_admin() then
        raise exception 'Not authorized for this restaurant';
    end if;
    if not public.loyalty_restaurant_enabled(p_restaurant_id) then
        raise exception 'FEATURE_DISABLED';
    end if;
    v_since := (v_from::timestamp at time zone 'Europe/Rome');
    select jsonb_build_object(
        'scans', coalesce(sum(st.loyalty_scans), 0),
        'group_scans', coalesce(sum(st.loyalty_group_scans), 0),
        'people', coalesce(sum(st.loyalty_people), 0),
        'stamps', coalesce(sum(st.loyalty_stamps), 0),
        'double_stamps', greatest(coalesce(sum(st.loyalty_stamps), 0) - coalesce(sum(st.loyalty_people), 0), 0),
        'new_customers', coalesce(sum(st.loyalty_new_members), 0),
        'returning_people', greatest(coalesce(sum(st.loyalty_people), 0) - coalesce(sum(st.loyalty_new_members), 0), 0),
        'cards_started', coalesce(sum(st.loyalty_cards_started), 0),
        'rewards_unlocked', coalesce(sum(st.loyalty_rewards_unlocked), 0),
        'rewards_used', coalesce(sum(st.loyalty_rewards_used), 0),
        'discount_cents', coalesce(sum(st.loyalty_discount_cents), 0))
    into v_totals
    from public.restaurant_daily_stats st
    where st.restaurant_id = p_restaurant_id and st.day >= v_from;
    return v_totals || jsonb_build_object(
        'days', v_days,
        'rewards_expired', (select count(*) from public.loyalty_rewards rw
                            where rw.restaurant_id = p_restaurant_id and rw.status = 'EXPIRED'
                              and rw.expires_at >= v_since),
        'active_cards', (select count(*) from public.loyalty_cards c
                         where c.restaurant_id = p_restaurant_id and c.status = 'ACTIVE'),
        -- Clienti vicini al premio (a 1 e a 2 timbri), senza sapere chi sono.
        'near_reward', (select jsonb_build_object(
                            'one', count(*) filter (where v.stamps_required - c.stamps = 1),
                            'two', count(*) filter (where v.stamps_required - c.stamps = 2))
                        from public.loyalty_cards c
                        join public.loyalty_program_versions v on v.id = c.version_id
                        where c.restaurant_id = p_restaurant_id and c.status = 'ACTIVE'),
        -- Giorni (ISO, 1 = lunedì) e ore italiane delle visite timbrate.
        'by_hour', coalesce((
            select jsonb_agg(jsonb_build_object('weekday', x.weekday, 'hour', x.hour, 'scans', x.scans)
                             order by x.weekday, x.hour)
            from (select extract(isodow from (s.created_at at time zone 'Europe/Rome'))::integer as weekday,
                         extract(hour from (s.created_at at time zone 'Europe/Rome'))::integer as hour,
                         count(*) as scans
                  from public.loyalty_scans s
                  where s.restaurant_id = p_restaurant_id and s.undone_at is null and s.stamped > 0
                    and s.created_at >= v_since
                  group by 1, 2) x), '[]'::jsonb));
end;
$$;

-- Elenco delle tessere attive con il solo codice anonimo (§11).
create or replace function public.restaurant_loyalty_cards(p_restaurant_id uuid, p_limit integer default 100, p_offset integer default 0)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
    if public.restaurant_role(p_restaurant_id) is null and not public.is_platform_admin() then
        raise exception 'Not authorized for this restaurant';
    end if;
    if not public.loyalty_restaurant_enabled(p_restaurant_id) then
        raise exception 'FEATURE_DISABLED';
    end if;
    return coalesce((
        select jsonb_agg(x.card order by x.last_at desc nulls last)
        from (
            select jsonb_build_object(
                       'code', m.code, 'stamps', c.stamps, 'required', v.stamps_required,
                       'version', v.version, 'started_at', c.started_at, 'last_stamp_at', c.last_stamp_at,
                       'rewards_available', (select count(*) from public.loyalty_rewards rw
                                             where rw.restaurant_id = c.restaurant_id and rw.user_id = c.user_id
                                               and rw.status = 'AVAILABLE' and rw.expires_at > now())) as card,
                   c.last_stamp_at as last_at
            from public.loyalty_cards c
            join public.loyalty_members m on m.restaurant_id = c.restaurant_id and m.user_id = c.user_id
            join public.loyalty_program_versions v on v.id = c.version_id
            where c.restaurant_id = p_restaurant_id and c.status = 'ACTIVE'
            order by c.last_stamp_at desc nulls last
            limit least(greatest(coalesce(p_limit, 100), 1), 500)
            offset greatest(coalesce(p_offset, 0), 0)
        ) x), '[]'::jsonb);
end;
$$;

-- ---------------------------------------------------------------------------
-- 8) Lavoro pianificato (supabase/ops/scheduled_jobs.sql): preavvisi, azzeramenti, scadenze,
--    pulizia. A interruttore spento fa solo scadenze e pulizia.
-- ---------------------------------------------------------------------------
create or replace function public.loyalty_maintenance()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_program record;
    v_users uuid[];
    v_ended integer := 0;
    v_closing integer := 0;
    v_reactivated integer := 0;
    v_closed integer := 0;
    v_unsuspended integer := 0;
    v_warned integer := 0;
    v_reset integer := 0;
    v_expired integer := 0;
    v_purged integer := 0;
    v_count integer;
begin
    if public.loyalty_mode() <> 'OFF' then
        -- T22: il locale esce da HAPOSTO → la tessera finisce subito, premi compresi.
        for v_program in
            select lp.restaurant_id, left(r.name, 60) as name
            from public.loyalty_programs lp join public.restaurants r on r.id = lp.restaurant_id
            where (lp.status in ('ACTIVE', 'CLOSING')
                   or (lp.status = 'ENDED' and exists (select 1 from public.loyalty_rewards rw
                                                       where rw.restaurant_id = lp.restaurant_id and rw.status = 'AVAILABLE')))
              and r.partnership_status in ('SUSPENDED', 'DIRECTORY_ONLY')
        loop
            v_users := public.loyalty_close_cards(v_program.restaurant_id, true);
            update public.loyalty_programs
            set status = 'ENDED', closing_reason = null, closing_until = null, updated_at = now()
            where restaurant_id = v_program.restaurant_id;
            perform public.loyalty_notify(v_users, v_program.restaurant_id, 'Tessera fedeltà finita',
                'La tessera di ' || v_program.name || ' è finita: il locale non è più su HAPOSTO.', 'LOYALTY_ENDED');
            perform public.log_audit('LOYALTY_ENDED', v_program.restaurant_id, null, '{"reason": "EXIT"}');
            v_ended := v_ended + 1;
        end loop;

        -- T21: Pro non più pagato → stesso preavviso; se torna Pro durante il preavviso, riparte.
        for v_program in
            select lp.restaurant_id, left(r.name, 60) as name
            from public.loyalty_programs lp join public.restaurants r on r.id = lp.restaurant_id
            where lp.status = 'ACTIVE' and r.partnership_status = 'ACTIVE_PARTNER'
              and not public.restaurant_has_feature(lp.restaurant_id, 'LOYALTY')
        loop
            update public.loyalty_programs
            set status = 'CLOSING', closing_reason = 'PLAN',
                closing_until = now() + make_interval(days => public.loyalty_cfg('closing_notice_days')),
                updated_at = now()
            where restaurant_id = v_program.restaurant_id;
            perform public.loyalty_notify(
                array(select c.user_id from public.loyalty_cards c
                      where c.restaurant_id = v_program.restaurant_id and c.status = 'ACTIVE'),
                v_program.restaurant_id, 'La tessera sta per finire',
                'La tessera di ' || v_program.name || ' finisce tra ' || public.loyalty_cfg('closing_notice_days')
                    || ' giorni. Fino ad allora puoi completarla; i premi sbloccati valgono fino alla loro scadenza.',
                'LOYALTY_CLOSING');
            perform public.loyalty_notify(public.loyalty_owner_ids(v_program.restaurant_id), v_program.restaurant_id,
                'Tessera fedeltà in chiusura',
                v_program.name || ': senza Pro la tessera finisce tra ' || public.loyalty_cfg('closing_notice_days')
                    || ' giorni. Info: info@haposto.app',
                'LOYALTY_CLOSING');
            perform public.log_audit('LOYALTY_CLOSING', v_program.restaurant_id, null, '{"reason": "PLAN"}');
            v_closing := v_closing + 1;
        end loop;
        update public.loyalty_programs lp
        set status = 'ACTIVE', closing_reason = null, closing_until = null, updated_at = now()
        where lp.status = 'CLOSING' and lp.closing_reason = 'PLAN' and lp.closing_until > now()
          and public.restaurant_has_feature(lp.restaurant_id, 'LOYALTY');
        get diagnostics v_reactivated = row_count;

        -- T20: fine del preavviso → finisce; i premi già sbloccati valgono fino alla scadenza.
        for v_program in
            select lp.restaurant_id, left(r.name, 60) as name
            from public.loyalty_programs lp join public.restaurants r on r.id = lp.restaurant_id
            where lp.status = 'CLOSING' and lp.closing_until <= now()
        loop
            v_users := public.loyalty_close_cards(v_program.restaurant_id, false);
            update public.loyalty_programs
            set status = 'ENDED', closing_until = null, updated_at = now()
            where restaurant_id = v_program.restaurant_id;
            perform public.loyalty_notify(v_users, v_program.restaurant_id, 'Tessera fedeltà finita',
                'La tessera di ' || v_program.name || ' è finita. I premi già sbloccati valgono fino alla loro scadenza.',
                'LOYALTY_ENDED');
            perform public.log_audit('LOYALTY_ENDED', v_program.restaurant_id, null, '{"reason": "CLOSING"}');
            v_closed := v_closed + 1;
        end loop;

        -- T50: dopo la sospensione il locale può riattivarla accettando di nuovo il patto.
        update public.loyalty_programs
        set status = 'ENDED', suspended_until = null, updated_at = now()
        where status = 'SUSPENDED' and suspended_until <= now();
        get diagnostics v_unsuspended = row_count;

        -- T24: avviso 15 giorni prima dell'azzeramento, solo se mancano 1–3 timbri.
        for v_program in
            select c.id, c.user_id, c.restaurant_id, left(r.name, 60) as name,
                   v.stamps_required - c.stamps as missing
            from public.loyalty_cards c
            join public.loyalty_program_versions v on v.id = c.version_id
            join public.loyalty_programs lp on lp.restaurant_id = c.restaurant_id and lp.status = 'ACTIVE'
            join public.restaurants r on r.id = c.restaurant_id
            where c.status = 'ACTIVE' and c.reset_warned_at is null
              and v.stamps_required - c.stamps between 1 and 3
              and coalesce(c.last_stamp_at, c.started_at)
                  < now() - make_interval(months => v.inactivity_months) + interval '15 days'
              and coalesce(c.last_stamp_at, c.started_at) >= now() - make_interval(months => v.inactivity_months)
        loop
            update public.loyalty_cards set reset_warned_at = now() where id = v_program.id;
            perform public.loyalty_notify(array[v_program.user_id], v_program.restaurant_id,
                case when v_program.missing = 1 then 'Ti manca 1 timbro'
                     else 'Ti mancano ' || v_program.missing || ' timbri' end,
                'La tua tessera di ' || v_program.name || ' si azzera tra 15 giorni se non torni: '
                    || case when v_program.missing = 1 then 'ti manca 1 timbro'
                            else 'ti mancano ' || v_program.missing || ' timbri' end || ' al premio.',
                'LOYALTY_RESET_SOON');
            v_warned := v_warned + 1;
        end loop;
        -- T24: azzeramento dopo 6 mesi senza visite.
        update public.loyalty_cards c
        set status = 'RESET', closed_at = now()
        from public.loyalty_program_versions v
        where v.id = c.version_id and c.status = 'ACTIVE'
          and coalesce(c.last_stamp_at, c.started_at) < now() - make_interval(months => v.inactivity_months);
        get diagnostics v_reset = row_count;
    end if;

    -- T47: premi scaduti.
    update public.loyalty_rewards set status = 'EXPIRED', closed_at = now()
    where status = 'AVAILABLE' and expires_at <= now();
    get diagnostics v_expired = row_count;

    -- T58: conservazione. QR e gruppi 1 giorno; scansioni e timbri 24 mesi; tessere e premi
    -- chiusi 12 mesi (restano i conteggi anonimi in restaurant_daily_stats); segnalazioni 12 mesi.
    delete from public.visit_tokens where created_at < now() - interval '1 day';
    get diagnostics v_count = row_count; v_purged := v_purged + v_count;
    delete from public.loyalty_groups where created_at < now() - interval '1 day';
    get diagnostics v_count = row_count; v_purged := v_purged + v_count;
    delete from public.loyalty_code_failures where created_at < now() - interval '1 day';
    get diagnostics v_count = row_count; v_purged := v_purged + v_count;
    delete from public.loyalty_scans where created_at < now() - interval '24 months';
    get diagnostics v_count = row_count; v_purged := v_purged + v_count;
    delete from public.loyalty_rewards where status <> 'AVAILABLE' and closed_at < now() - interval '12 months';
    get diagnostics v_count = row_count; v_purged := v_purged + v_count;
    delete from public.loyalty_cards where status <> 'ACTIVE' and closed_at < now() - interval '12 months';
    get diagnostics v_count = row_count; v_purged := v_purged + v_count;
    delete from public.loyalty_reports where created_at < now() - interval '12 months';
    get diagnostics v_count = row_count; v_purged := v_purged + v_count;
    -- Codici anonimi rimasti senza tessere, premi e timbri.
    delete from public.loyalty_members m
    where not exists (select 1 from public.loyalty_cards c where c.restaurant_id = m.restaurant_id and c.user_id = m.user_id)
      and not exists (select 1 from public.loyalty_rewards rw where rw.restaurant_id = m.restaurant_id and rw.user_id = m.user_id)
      and not exists (select 1 from public.loyalty_stamps s where s.restaurant_id = m.restaurant_id and s.user_id = m.user_id);
    get diagnostics v_count = row_count; v_purged := v_purged + v_count;

    return jsonb_build_object('ended', v_ended, 'closing', v_closing, 'reactivated', v_reactivated,
                              'closed', v_closed, 'unsuspended', v_unsuspended, 'reset_warnings', v_warned,
                              'reset', v_reset, 'rewards_expired', v_expired, 'purged', v_purged);
end;
$$;

-- ---------------------------------------------------------------------------
-- 9) Pannello admin (§13).
-- ---------------------------------------------------------------------------
create or replace function public.admin_set_restaurant_loyalty_tester(p_restaurant_id uuid, p_tester boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    perform public.assert_admin();
    if not exists (select 1 from public.restaurants r where r.id = p_restaurant_id) then
        raise exception 'RESTAURANT_NOT_FOUND';
    end if;
    insert into public.loyalty_programs (restaurant_id, tester) values (p_restaurant_id, coalesce(p_tester, false))
    on conflict (restaurant_id) do update set tester = excluded.tester, updated_at = now();
    perform public.log_audit('LOYALTY_TESTER_SET', p_restaurant_id, null,
        jsonb_build_object('tester', coalesce(p_tester, false)));
end;
$$;

create or replace function public.admin_set_user_loyalty_tester(p_user_id uuid, p_tester boolean)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    perform public.assert_admin();
    if not exists (select 1 from auth.users u where u.id = p_user_id) then
        raise exception 'USER_NOT_FOUND';
    end if;
    insert into public.profiles (id) values (p_user_id) on conflict (id) do nothing;
    update public.profiles set loyalty_tester = coalesce(p_tester, false) where id = p_user_id;
    perform public.log_audit('LOYALTY_TESTER_SET', null, p_user_id,
        jsonb_build_object('tester', coalesce(p_tester, false)));
end;
$$;

-- Togliere una sospensione o ridare la tessera tolta (facoltativo: il sistema non lo richiede).
-- Il locale la riattiva accettando di nuovo il patto; le segnalazioni ripartono da zero.
create or replace function public.admin_loyalty_restore(p_restaurant_id uuid, p_note text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_status text;
begin
    perform public.assert_admin();
    select lp.status into v_status from public.loyalty_programs lp where lp.restaurant_id = p_restaurant_id for update;
    if v_status is null or v_status not in ('SUSPENDED', 'REMOVED') then
        raise exception 'LOYALTY_NOT_SUSPENDED';
    end if;
    update public.loyalty_programs
    set status = 'ENDED', suspended_until = null, last_suspended_at = null, warned_at = null,
        reports_since = now(), updated_at = now()
    where restaurant_id = p_restaurant_id;
    perform public.log_audit('LOYALTY_RESTORED', p_restaurant_id, null,
        jsonb_build_object('from', v_status, 'note', p_note));
end;
$$;

-- Numeri della tessera per la scheda «Tessere» del pannello (solo lettura).
create or replace function public.admin_loyalty_overview()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
    perform public.assert_admin();
    return jsonb_build_object(
        'mode', public.loyalty_mode(),
        'config', (select c.value from public.app_config c where c.key = 'loyalty'),
        'programs', coalesce((select jsonb_object_agg(x.status, x.n)
                              from (select lp.status, count(*) as n from public.loyalty_programs lp group by lp.status) x),
                             '{}'::jsonb),
        'tester_restaurants', coalesce((
            select jsonb_agg(jsonb_build_object('restaurant_id', r.id, 'name', r.name, 'city', r.city,
                                                'status', lp.status) order by r.name)
            from public.loyalty_programs lp join public.restaurants r on r.id = lp.restaurant_id
            where lp.tester), '[]'::jsonb),
        'tester_users', coalesce((
            select jsonb_agg(jsonb_build_object('user_id', u.id, 'email', u.email) order by u.email)
            from public.profiles p join auth.users u on u.id = p.id
            where p.loyalty_tester), '[]'::jsonb),
        'cards', (select jsonb_build_object(
                     'active', count(*) filter (where c.status = 'ACTIVE'),
                     'completed', count(*) filter (where c.status = 'COMPLETED'),
                     'reset', count(*) filter (where c.status = 'RESET'),
                     'ended', count(*) filter (where c.status = 'ENDED'))
                  from public.loyalty_cards c),
        'last_30_days', (select jsonb_build_object(
                            'scans', coalesce(sum(st.loyalty_scans), 0),
                            'group_scans', coalesce(sum(st.loyalty_group_scans), 0),
                            'people', coalesce(sum(st.loyalty_people), 0),
                            'stamps', coalesce(sum(st.loyalty_stamps), 0),
                            'rewards_unlocked', coalesce(sum(st.loyalty_rewards_unlocked), 0),
                            'rewards_used', coalesce(sum(st.loyalty_rewards_used), 0),
                            'discount_cents', coalesce(sum(st.loyalty_discount_cents), 0))
                         from public.restaurant_daily_stats st where st.day > public.today_rome() - 30),
        'rewards', (select jsonb_build_object(
                       'available', count(*) filter (where rw.status = 'AVAILABLE'),
                       'used', count(*) filter (where rw.status = 'USED'),
                       'expired', count(*) filter (where rw.status = 'EXPIRED'),
                       'ended', count(*) filter (where rw.status = 'ENDED'))
                    from public.loyalty_rewards rw),
        'reward_kinds', coalesce((
            select jsonb_object_agg(x.reward_kind, x.n)
            from (select v.reward_kind, count(*) as n
                  from public.loyalty_programs lp join public.loyalty_program_versions v on v.id = lp.current_version_id
                  where lp.status in ('ACTIVE', 'CLOSING') group by v.reward_kind) x), '{}'::jsonb),
        'versions', (select count(*) from public.loyalty_program_versions),
        'pacts', (select count(*) from public.consent_log cl where cl.kind = 'LOYALTY_PACT'),
        'reports_60_days', (select count(*) from public.loyalty_reports rp where rp.created_at > now() - interval '60 days'),
        'sanctioned', coalesce((
            select jsonb_agg(jsonb_build_object('restaurant_id', r.id, 'name', r.name, 'status', lp.status,
                                                'suspended_until', lp.suspended_until) order by r.name)
            from public.loyalty_programs lp join public.restaurants r on r.id = lp.restaurant_id
            where lp.status in ('SUSPENDED', 'REMOVED')), '[]'::jsonb));
end;
$$;

-- Scheda del locale nel pannello: come nella 0017 più la tessera; fonte e scadenza del piano
-- calcolate qui, così funziona anche dal SQL Editor (restaurant_entitlements lo rifiutava).
create or replace function public.admin_restaurant_detail(p_restaurant_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_result jsonb;
    v_sub public.restaurant_subscriptions;
    v_trial timestamptz;
    v_beta timestamptz;
    v_source text;
    v_until timestamptz;
begin
    perform public.assert_admin();
    v_sub := public.restaurant_live_subscription(p_restaurant_id);
    v_trial := public.restaurant_trial_until(p_restaurant_id);
    v_beta := public.config_value('beta', 'restaurants_all_pro_until')::timestamptz;
    v_source := case
        when v_sub.id is not null then v_sub.provider
        when v_trial > now() then case when v_beta is not null and v_beta >= v_trial then 'BETA' else 'TRIAL' end
        else 'NONE'
    end;
    v_until := case when v_sub.id is not null then v_sub.current_period_end when v_trial > now() then v_trial end;

    select jsonb_build_object(
        'restaurant', jsonb_build_object(
            'id', r.id, 'name', r.name, 'category', r.category, 'address', r.address, 'city', r.city,
            'province', r.province, 'phone_number', r.phone_number, 'phone_public', r.phone_public,
            'partnership_status', r.partnership_status, 'data_source', r.data_source, 'slug', r.slug,
            'latitude', extensions.st_y(r.location::extensions.geometry),
            'longitude', extensions.st_x(r.location::extensions.geometry),
            'created_at', r.created_at),
        'plan_code', public.restaurant_plan_code(r.id),
        'plan_source', v_source,
        'plan_valid_until', v_until,
        'partner_since', r.partner_since,
        'live', (select to_jsonb(s) - 'restaurant_id' from public.restaurant_live_status s where s.restaurant_id = r.id),
        'members', coalesce((
            select jsonb_agg(jsonb_build_object('user_id', ru.user_id, 'email', u.email, 'role', ru.role,
                                                'since', ru.created_at) order by ru.role, ru.created_at)
            from public.restaurant_users ru join auth.users u on u.id = ru.user_id
            where ru.restaurant_id = r.id), '[]'::jsonb),
        'claims', coalesce((
            select jsonb_agg(jsonb_build_object('claim_id', c.id, 'status', c.status, 'email', u.email,
                                                'created_at', c.created_at, 'phone_verified_at', c.phone_verified_at,
                                                'review_note', c.review_note) order by c.created_at desc)
            from public.restaurant_claims c left join auth.users u on u.id = c.user_id
            where c.restaurant_id = r.id), '[]'::jsonb),
        'subscriptions', coalesce((
            select jsonb_agg(jsonb_build_object('id', s.id, 'plan_code', s.plan_code, 'status', s.status,
                                                'provider', s.provider, 'period_end', s.current_period_end,
                                                'note', s.note) order by s.created_at desc)
            from public.restaurant_subscriptions s where s.restaurant_id = r.id), '[]'::jsonb),
        'recent_publishes', coalesce((
            select jsonb_agg(x order by x.updated_at desc) from (
                select h.status, h.updated_at, h.updated_via, u.email as by_email
                from public.status_history h left join auth.users u on u.id = h.updated_by
                where h.restaurant_id = r.id order by h.updated_at desc limit 20) x), '[]'::jsonb),
        'stats_30_days', (
            select jsonb_build_object('detail_views', coalesce(sum(st.detail_views), 0),
                                      'directions_taps', coalesce(sum(st.directions_taps), 0),
                                      'call_taps', coalesce(sum(st.call_taps), 0),
                                      'live_updates', coalesce(sum(st.live_updates), 0))
            from public.restaurant_daily_stats st
            where st.restaurant_id = r.id and st.day > public.today_rome() - 30),
        'loyalty', jsonb_build_object(
            'tester', coalesce(lp.tester, false),
            'status', coalesce(lp.status, 'NONE'),
            'current', public.loyalty_version_json(lp.current_version_id),
            'versions', (select count(*) from public.loyalty_program_versions v where v.restaurant_id = r.id),
            'closing_until', lp.closing_until,
            'suspended_until', lp.suspended_until,
            'active_cards', (select count(*) from public.loyalty_cards c
                             where c.restaurant_id = r.id and c.status = 'ACTIVE'),
            'reports_60_days', (select count(distinct rp.user_id) from public.loyalty_reports rp
                                where rp.restaurant_id = r.id and rp.created_at > now() - interval '60 days'))
    ) into v_result
    from public.restaurants r
    left join public.loyalty_programs lp on lp.restaurant_id = r.id
    where r.id = p_restaurant_id;

    if v_result is null then
        raise exception 'RESTAURANT_NOT_FOUND';
    end if;
    return v_result;
end;
$$;

-- ---------------------------------------------------------------------------
-- 10) Permessi sulle funzioni.
-- ---------------------------------------------------------------------------
do $$
declare
    v_fn text;
begin
    -- Interne: solo per il database (e per il server dove serve).
    foreach v_fn in array array[
        'public.loyalty_defaults()',
        'public.loyalty_config_ranges()',
        'public.loyalty_cfg(text)',
        'public.loyalty_mode()',
        'public.loyalty_versions_immutable()',
        'public.loyalty_user_level(uuid)',
        'public.loyalty_restaurant_enabled(uuid)',
        'public.loyalty_restaurant_level(uuid)',
        'public.loyalty_publish_blocker(uuid)',
        'public.loyalty_random_code(integer)',
        'public.loyalty_new_token(text, uuid, uuid, uuid)',
        'public.loyalty_assert_customer(uuid)',
        'public.loyalty_leave_open_groups(uuid)',
        'public.loyalty_is_double(smallint, text, timestamptz)',
        'public.loyalty_reward_usable_now(text, timestamptz, timestamptz, smallint[])',
        'public.loyalty_version_json(uuid)',
        'public.loyalty_reward_json(uuid)',
        'public.loyalty_add_stats(uuid, date, integer, integer, integer, integer, integer, integer, integer, integer, integer)',
        'public.loyalty_notify(uuid[], uuid, text, text, text)',
        'public.loyalty_owner_ids(uuid)',
        'public.loyalty_close_cards(uuid, boolean)',
        'public.loyalty_evaluate_reports(uuid)',
        'public.loyalty_json_int(jsonb, text)',
        'public.loyalty_maintenance()'
    ] loop
        execute format('revoke execute on function %s from public, anon, authenticated', v_fn);
    end loop;
    grant execute on function public.loyalty_maintenance() to service_role;

    -- Per chi ha un account (cliente, locale, admin: i controlli veri sono dentro).
    foreach v_fn in array array[
        'public.create_visit_token(uuid)',
        'public.visit_token_status(text)',
        'public.create_loyalty_group(uuid)',
        'public.loyalty_group_token(uuid)',
        'public.join_loyalty_group(text)',
        'public.leave_loyalty_group(uuid)',
        'public.loyalty_group_status(uuid)',
        'public.my_loyalty_cards()',
        'public.leave_loyalty_card(uuid)',
        'public.report_loyalty_problem(uuid, text)',
        'public.restaurant_loyalty_program(uuid)',
        'public.publish_loyalty_version(uuid, jsonb, boolean)',
        'public.close_loyalty_program(uuid)',
        'public.register_stamp(uuid, text, text)',
        'public.undo_stamp(uuid)',
        'public.use_reward(uuid, uuid, integer)',
        'public.restaurant_loyalty_stats(uuid, integer)',
        'public.restaurant_loyalty_cards(uuid, integer, integer)',
        'public.admin_set_restaurant_loyalty_tester(uuid, boolean)',
        'public.admin_set_user_loyalty_tester(uuid, boolean)',
        'public.admin_loyalty_restore(uuid, text)',
        'public.admin_loyalty_overview()',
        'public.admin_restaurant_detail(uuid)',
        'public.admin_set_config(text, jsonb)'
    ] loop
        execute format('revoke execute on function %s from public, anon', v_fn);
        execute format('grant execute on function %s to authenticated', v_fn);
    end loop;

    -- Anche senza account: cosa mostrare nell'app e il riquadro nella scheda del locale (T61).
    foreach v_fn in array array[
        'public.loyalty_access()',
        'public.loyalty_restaurant_card(uuid)'
    ] loop
        execute format('revoke execute on function %s from public', v_fn);
        execute format('grant execute on function %s to anon, authenticated', v_fn);
    end loop;
end;
$$;

-- Controllo finale: interruttore spento, tabelle e funzione nel piano Pro.
select
    public.loyalty_mode() as modalita_tessera,
    (select count(*) from pg_tables where schemaname = 'public'
       and tablename in ('loyalty_program_versions', 'loyalty_programs', 'loyalty_members', 'loyalty_cards',
                         'loyalty_groups', 'loyalty_group_members', 'visit_tokens', 'loyalty_scans',
                         'loyalty_stamps', 'loyalty_rewards', 'loyalty_reports', 'loyalty_code_failures')) as tabelle_tessera,
    (select 'LOYALTY' = any(features) from public.plans where code = 'RESTAURANT_PRO') as tessera_in_pro;
