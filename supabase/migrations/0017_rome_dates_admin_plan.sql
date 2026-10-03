-- HAPOSTO — Date "di oggi" in ora italiana e piano del locale nel pannello admin.
--
-- Esegui DOPO 0016. Rieseguibile.
--
-- Il database lavora in UTC (in Italia sono 1 o 2 ore in più). Dove serve "il giorno di oggi" si
-- usa ora sempre quello italiano, come già fanno statistiche, "di solito" e foto "solo per oggi":
--   - pulizia delle prenotazioni di sala più vecchie di 30 giorni;
--   - pulizia delle statistiche più vecchie di 2 anni;
--   - somma degli ultimi 30 giorni nella scheda del locale del pannello admin.
-- La differenza era al massimo di un paio d'ore a cavallo della mezzanotte: nessun dato è sbagliato.
-- In più la scheda del locale del pannello mostra fonte e scadenza del piano (beta, prova, Stripe,
-- regalato, nessuno) e da quando il locale è partner.

-- Il giorno di oggi in Italia.
create or replace function public.today_rome()
returns date
language sql
stable
set search_path = ''
as $$
    select (now() at time zone 'Europe/Rome')::date;
$$;

create or replace function public.purge_old_reservations(p_keep_days integer default 30)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_count integer;
begin
    delete from public.reservations
    where reservation_date < public.today_rome() - greatest(p_keep_days, 1);
    get diagnostics v_count = row_count;
    return v_count;
end;
$$;

create or replace function public.purge_operational_data()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_history integer;
    v_stats integer;
    v_audit integer;
    v_sessions integer;
begin
    delete from public.status_history where updated_at < now() - interval '180 days';
    get diagnostics v_history = row_count;
    delete from public.restaurant_daily_stats where day < public.today_rome() - 730;
    get diagnostics v_stats = row_count;
    delete from public.audit_log where created_at < now() - interval '730 days';
    get diagnostics v_audit = row_count;
    delete from public.admin_sessions where expires_at < now() - interval '7 days';
    get diagnostics v_sessions = row_count;
    return jsonb_build_object('status_history', v_history, 'daily_stats', v_stats,
                              'audit_log', v_audit, 'admin_sessions', v_sessions);
end;
$$;

create or replace function public.admin_restaurant_detail(p_restaurant_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_result jsonb;
begin
    perform public.assert_admin();
    select jsonb_build_object(
        'restaurant', jsonb_build_object(
            'id', r.id, 'name', r.name, 'category', r.category, 'address', r.address, 'city', r.city,
            'province', r.province, 'phone_number', r.phone_number, 'phone_public', r.phone_public,
            'partnership_status', r.partnership_status, 'data_source', r.data_source, 'slug', r.slug,
            'latitude', extensions.st_y(r.location::extensions.geometry),
            'longitude', extensions.st_x(r.location::extensions.geometry),
            'created_at', r.created_at),
        'plan_code', public.restaurant_plan_code(r.id),
        'plan_source', (select e.source from public.restaurant_entitlements(r.id) e),
        'plan_valid_until', (select e.valid_until from public.restaurant_entitlements(r.id) e),
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
            where st.restaurant_id = r.id and st.day > public.today_rome() - 30)
    ) into v_result
    from public.restaurants r
    where r.id = p_restaurant_id;

    if v_result is null then
        raise exception 'RESTAURANT_NOT_FOUND';
    end if;
    return v_result;
end;
$$;

-- Permessi (le funzioni esistenti mantengono i loro; quella nuova è solo per il database).
revoke execute on function public.today_rome() from public, anon, authenticated;
grant execute on function public.today_rome() to service_role;

-- Controllo: il giorno italiano di adesso (atteso: la data di oggi in Italia).
select public.today_rome() as oggi_in_italia,
       (select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
        where n.nspname = 'public' and p.proname = 'today_rome') as funzione_nuova;
