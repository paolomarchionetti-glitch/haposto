-- HAPOSTO STEP 7 — server-side rules and geo/search RPCs.

create or replace function public.is_restaurant_member(target_restaurant_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1
        from public.restaurant_users ru
        where ru.restaurant_id = target_restaurant_id
          and ru.user_id = auth.uid()
    );
$$;

create or replace function public.set_restaurant_live_status(
    p_restaurant_id uuid,
    p_status public.live_status,
    p_available_tables smallint default null,
    p_estimated_wait_minutes smallint default null,
    p_note varchar(80) default null
)
returns public.restaurant_live_status
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_now timestamptz := now();
    v_available_tables smallint := case when p_status = 'FULL' then null else p_available_tables end;
    v_row public.restaurant_live_status;
begin
    if not public.is_restaurant_member(p_restaurant_id) then
        raise exception 'Not authorized for this restaurant';
    end if;

    if not exists (
        select 1
        from public.restaurants r
        where r.id = p_restaurant_id
          and r.partnership_status = 'ACTIVE_PARTNER'
    ) then
        raise exception 'Restaurant is not an active partner';
    end if;

    if v_available_tables is not null and v_available_tables not between 0 and 99 then
        raise exception 'available_tables must be between 0 and 99';
    end if;

    if p_estimated_wait_minutes is not null and p_estimated_wait_minutes not between 0 and 240 then
        raise exception 'estimated_wait_minutes must be between 0 and 240';
    end if;

    insert into public.restaurant_live_status (
        restaurant_id,
        status,
        available_tables,
        estimated_wait_minutes,
        note,
        updated_at,
        valid_until
    ) values (
        p_restaurant_id,
        p_status,
        v_available_tables,
        p_estimated_wait_minutes,
        nullif(trim(p_note), ''),
        v_now,
        v_now + interval '30 minutes'
    )
    on conflict (restaurant_id) do update set
        status = excluded.status,
        available_tables = excluded.available_tables,
        estimated_wait_minutes = excluded.estimated_wait_minutes,
        note = excluded.note,
        updated_at = excluded.updated_at,
        valid_until = excluded.valid_until
    returning * into v_row;

    insert into public.status_history (
        restaurant_id,
        status,
        available_tables,
        estimated_wait_minutes,
        note,
        updated_at,
        valid_until,
        updated_by
    ) values (
        v_row.restaurant_id,
        v_row.status,
        v_row.available_tables,
        v_row.estimated_wait_minutes,
        v_row.note,
        v_row.updated_at,
        v_row.valid_until,
        auth.uid()
    );

    return v_row;
end;
$$;

create or replace function public.nearby_restaurants(
    lat double precision,
    long double precision,
    radius_meters integer default 60000,
    search_text text default null
)
returns table (
    id uuid,
    name text,
    category text,
    address text,
    city text,
    province text,
    phone_number text,
    phone_public boolean,
    partnership_status public.partnership_status,
    live_status public.live_status,
    live_updated_at timestamptz,
    live_valid_until timestamptz,
    available_tables smallint,
    estimated_wait_minutes smallint,
    note varchar(80),
    latitude double precision,
    longitude double precision,
    distance_meters double precision
)
language sql
stable
security definer
set search_path = ''
as $$
    select
        r.id,
        r.name,
        r.category,
        r.address,
        r.city,
        r.province,
        case when r.phone_public then r.phone_number else null end as phone_number,
        r.phone_public,
        r.partnership_status,
        case when r.partnership_status = 'ACTIVE_PARTNER' then s.status else null end as live_status,
        case when r.partnership_status = 'ACTIVE_PARTNER' then s.updated_at else null end as live_updated_at,
        case when r.partnership_status = 'ACTIVE_PARTNER' then s.valid_until else null end as live_valid_until,
        case when r.partnership_status = 'ACTIVE_PARTNER' then s.available_tables else null end as available_tables,
        case when r.partnership_status = 'ACTIVE_PARTNER' then s.estimated_wait_minutes else null end as estimated_wait_minutes,
        case when r.partnership_status = 'ACTIVE_PARTNER' then s.note else null end as note,
        extensions.st_y(r.location::extensions.geometry) as latitude,
        extensions.st_x(r.location::extensions.geometry) as longitude,
        extensions.st_distance(
            r.location,
            extensions.st_point(long, lat)::extensions.geography
        ) as distance_meters
    from public.restaurants r
    left join public.restaurant_live_status s on s.restaurant_id = r.id
    where r.partnership_status <> 'SUSPENDED'
      and extensions.st_dwithin(
          r.location,
          extensions.st_point(long, lat)::extensions.geography,
          least(greatest(radius_meters, 0), 100000)
      )
      and (
          search_text is null
          or btrim(search_text) = ''
          or lower(r.name) like '%' || lower(btrim(search_text)) || '%'
          or lower(r.category) like '%' || lower(btrim(search_text)) || '%'
          or lower(r.city) like '%' || lower(btrim(search_text)) || '%'
          or extensions.similarity(r.name, btrim(search_text)) >= 0.25
          or extensions.similarity(r.category, btrim(search_text)) >= 0.25
      )
    order by r.location operator(extensions.<->)
        extensions.st_point(long, lat)::extensions.geography;
$$;
