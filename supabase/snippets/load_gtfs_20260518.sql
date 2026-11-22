-- =============================================================================
-- GTFS-JP 20260518 (feed_version 202603_02, valid 2026-03-28 .. 2027-04-30)
-- Replace timetable data on the LOCAL Supabase DB.
--
-- NEVER run this against production.
--
-- Prerequisites (run from the repository root):
--   unzip -o "10_Document/07_DB情報/20260518_bus-gtfs-jp.zip" -d supabase/seed/gtfs_20260518
--
-- Run:
--   psql postgresql://postgres:postgres@127.0.0.1:54322/postgres \
--     -v ON_ERROR_STOP=1 -f supabase/snippets/load_gtfs_20260518.sql
--
-- Everything runs in one transaction. Any error (including the checks at the
-- end) aborts the whole load and leaves the DB unchanged.
-- Undo after commit: `supabase db reset` (back to the prod snapshot).
--
-- Conventions (matching the current prod data):
--   - Empty CSV fields become '' for text columns, except `trips` where they
--     stay NULL (the RPC relies on COALESCE(t.trip_headsign, ...)).
--   - route_id / jp_pattern_id are bigint, so leading zeros are dropped
--     ("0001" -> 1, "0001001" -> 1001). trip_id keeps the original text.
--   - Dates are converted from YYYYMMDD to date.
--   - Files are CRLF; COPY ... CSV handles that.
--   - Not loaded (no table in the DB): agency, fare_attributes, fare_rules,
--     feed_info, office_jp.
-- =============================================================================

\set ON_ERROR_STOP on
\timing on

BEGIN;

-- -----------------------------------------------------------------------------
-- 1. Staging tables (all text, column order = CSV header order)
-- -----------------------------------------------------------------------------
CREATE TEMP TABLE stg_agency_jp (
  agency_id text, agency_official_name text, agency_zip_number text,
  agency_address text, agency_president_pos text, agency_president_name text
) ON COMMIT DROP;

CREATE TEMP TABLE stg_calendar (
  service_id text, monday text, tuesday text, wednesday text, thursday text,
  friday text, saturday text, sunday text, start_date text, end_date text
) ON COMMIT DROP;

CREATE TEMP TABLE stg_calendar_dates (
  service_id text, date text, exception_type text
) ON COMMIT DROP;

CREATE TEMP TABLE stg_pattern_jp (
  jp_pattern_id text, route_update_date text, origin_stop text,
  via_stop text, destination_stop text
) ON COMMIT DROP;

CREATE TEMP TABLE stg_routes (
  route_id text, agency_id text, route_short_name text, route_long_name text,
  route_desc text, route_type text, route_url text, route_color text,
  route_text_color text, jp_parent_route_id text
) ON COMMIT DROP;

CREATE TEMP TABLE stg_stops (
  stop_id text, stop_code text, stop_name text, stop_desc text,
  stop_lat text, stop_lon text, zone_id text, stop_url text,
  location_type text, parent_station text, platform_code text
) ON COMMIT DROP;

CREATE TEMP TABLE stg_stop_times (
  trip_id text, arrival_time text, departure_time text, stop_id text,
  stop_sequence text, stop_headsign text, pickup_type text,
  drop_off_type text, shape_dist_traveled text
) ON COMMIT DROP;

CREATE TEMP TABLE stg_translations (
  table_name text, field_name text, language text, translation text,
  record_id text, record_sub_id text, field_value text
) ON COMMIT DROP;

CREATE TEMP TABLE stg_trips (
  route_id text, service_id text, trip_id text, trip_headsign text,
  trip_short_name text, direction_id text, block_id text, shape_id text,
  wheelchair_accessible text, bikes_allowed text, jp_trip_desc text,
  jp_trip_desc_symbol text, jp_office_id text, jp_pattern_id text
) ON COMMIT DROP;

-- -----------------------------------------------------------------------------
-- 2. Load CSV files (paths are relative to the directory psql runs in)
-- -----------------------------------------------------------------------------
\copy stg_agency_jp      FROM 'supabase/seed/gtfs_20260518/agency_jp.txt'      WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg_calendar       FROM 'supabase/seed/gtfs_20260518/calendar.txt'       WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg_calendar_dates FROM 'supabase/seed/gtfs_20260518/calendar_dates.txt' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg_pattern_jp     FROM 'supabase/seed/gtfs_20260518/pattern_jp.txt'     WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg_routes         FROM 'supabase/seed/gtfs_20260518/routes.txt'         WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg_stops          FROM 'supabase/seed/gtfs_20260518/stops.txt'          WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg_stop_times     FROM 'supabase/seed/gtfs_20260518/stop_times.txt'     WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg_translations   FROM 'supabase/seed/gtfs_20260518/translations.txt'   WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')
\copy stg_trips          FROM 'supabase/seed/gtfs_20260518/trips.txt'          WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

-- -----------------------------------------------------------------------------
-- 3. Clear current data
--    routes -> agency_jp has a FK, so they are truncated together.
--    search_history and debug_logs are left as is.
-- -----------------------------------------------------------------------------
TRUNCATE TABLE
  public.stop_times,
  public.trips,
  public.routes,
  public.agency_jp,
  public.pattern_jp,
  public.stops,
  public.translations,
  public.calendar_dates,
  public.calendar;

-- -----------------------------------------------------------------------------
-- 4. Insert with type conversion
-- -----------------------------------------------------------------------------
INSERT INTO public.agency_jp (
  agency_id, agency_official_name, agency_zip_number, agency_address,
  agency_president_pos, agency_president_name
)
SELECT
  agency_id::bigint,
  COALESCE(agency_official_name, ''),
  COALESCE(agency_zip_number, ''),
  COALESCE(agency_address, ''),
  COALESCE(agency_president_pos, ''),
  COALESCE(agency_president_name, '')
FROM stg_agency_jp;

INSERT INTO public.calendar (
  service_id, monday, tuesday, wednesday, thursday, friday, saturday, sunday,
  start_date, end_date
)
SELECT
  service_id,
  NULLIF(monday, '')::smallint,
  NULLIF(tuesday, '')::smallint,
  NULLIF(wednesday, '')::smallint,
  NULLIF(thursday, '')::smallint,
  NULLIF(friday, '')::smallint,
  NULLIF(saturday, '')::smallint,
  NULLIF(sunday, '')::smallint,
  to_date(start_date, 'YYYYMMDD'),
  to_date(end_date, 'YYYYMMDD')
FROM stg_calendar;

INSERT INTO public.calendar_dates (service_id, date, exception_type)
SELECT
  service_id,
  to_date(date, 'YYYYMMDD'),
  NULLIF(exception_type, '')::integer
FROM stg_calendar_dates;

INSERT INTO public.pattern_jp (
  jp_pattern_id, route_update_date, origin_stop, via_stop, destination_stop
)
SELECT
  jp_pattern_id::bigint,
  NULLIF(route_update_date, '')::bigint,
  COALESCE(origin_stop, ''),
  COALESCE(via_stop, ''),
  COALESCE(destination_stop, '')
FROM stg_pattern_jp;

INSERT INTO public.routes (
  route_id, agency_id, route_short_name, route_long_name, route_desc,
  route_type, route_url, route_color, route_text_color, jp_parent_route_id
)
SELECT
  route_id::bigint,
  NULLIF(agency_id, '')::bigint,
  COALESCE(route_short_name, ''),
  COALESCE(route_long_name, ''),
  COALESCE(route_desc, ''),
  NULLIF(route_type, '')::bigint,
  COALESCE(route_url, ''),
  COALESCE(route_color, ''),
  COALESCE(route_text_color, ''),
  COALESCE(jp_parent_route_id, '')
FROM stg_routes;

INSERT INTO public.stops (
  stop_id, stop_code, stop_name, stop_desc, stop_lat, stop_lon, zone_id,
  stop_url, location_type, parent_station, platform_code
)
SELECT
  stop_id,
  COALESCE(stop_code, ''),
  COALESCE(stop_name, ''),
  COALESCE(stop_desc, ''),
  NULLIF(stop_lat, '')::double precision,
  NULLIF(stop_lon, '')::double precision,
  COALESCE(zone_id, ''),
  COALESCE(stop_url, ''),
  COALESCE(location_type, ''),
  COALESCE(parent_station, ''),
  COALESCE(platform_code, '')
FROM stg_stops;

INSERT INTO public.trips (
  route_id, service_id, trip_id, trip_headsign, trip_short_name, direction_id,
  block_id, shape_id, wheelchair_accessible, bikes_allowed, jp_trip_desc,
  jp_trip_desc_symbol, jp_office_id, jp_pattern_id
)
SELECT
  route_id::bigint,
  NULLIF(service_id, ''),
  trip_id,
  NULLIF(trip_headsign, ''),
  NULLIF(trip_short_name, ''),
  NULLIF(direction_id, ''),
  NULLIF(block_id, ''),
  NULLIF(shape_id, ''),
  NULLIF(wheelchair_accessible, ''),
  NULLIF(bikes_allowed, ''),
  NULLIF(jp_trip_desc, ''),
  NULLIF(jp_trip_desc_symbol, ''),
  NULLIF(jp_office_id, ''),
  NULLIF(jp_pattern_id, '')::bigint
FROM stg_trips;

INSERT INTO public.stop_times (
  trip_id, arrival_time, departure_time, stop_id, stop_sequence,
  stop_headsign, pickup_type, drop_off_type, shape_dist_traveled
)
SELECT
  trip_id,
  COALESCE(arrival_time, ''),
  COALESCE(departure_time, ''),
  COALESCE(stop_id, ''),
  stop_sequence::bigint,
  COALESCE(stop_headsign, ''),
  COALESCE(pickup_type, ''),
  COALESCE(drop_off_type, ''),
  COALESCE(shape_dist_traveled, '')
FROM stg_stop_times;

INSERT INTO public.translations (
  table_name, field_name, language, translation, record_id, record_sub_id,
  field_value
)
SELECT
  table_name,
  field_name,
  language,
  COALESCE(translation, ''),
  COALESCE(record_id, ''),       -- part of the PK (NOT NULL)
  COALESCE(record_sub_id, ''),   -- part of the PK (NOT NULL)
  COALESCE(field_value, '')
FROM stg_translations;

-- -----------------------------------------------------------------------------
-- 5. Checks (any failure raises and rolls back the whole transaction)
-- -----------------------------------------------------------------------------
DO $check$
DECLARE
  -- Expected row counts = data lines in each file of the zip
  expected CONSTANT jsonb := '{
    "agency_jp": 1,
    "calendar": 9,
    "calendar_dates": 96,
    "pattern_jp": 685,
    "routes": 185,
    "stops": 3886,
    "stop_times": 592164,
    "translations": 6681,
    "trips": 30417
  }';
  t      text;
  actual bigint;
  n      bigint;
BEGIN
  -- Row counts
  FOR t IN SELECT jsonb_object_keys(expected) LOOP
    EXECUTE format('SELECT count(*) FROM public.%I', t) INTO actual;
    IF actual <> (expected ->> t)::bigint THEN
      RAISE EXCEPTION 'row count mismatch: % expected % got %',
        t, expected ->> t, actual;
    END IF;
    RAISE NOTICE 'ok  % = %', t, actual;
  END LOOP;

  -- Referential integrity (no FKs exist for these, so check explicitly)
  SELECT count(*) INTO n
  FROM public.stop_times st
  LEFT JOIN public.trips t ON t.trip_id = st.trip_id
  WHERE t.trip_id IS NULL;
  IF n > 0 THEN RAISE EXCEPTION 'stop_times without trip: %', n; END IF;

  SELECT count(*) INTO n
  FROM public.stop_times st
  LEFT JOIN public.stops s ON s.stop_id = st.stop_id
  WHERE s.stop_id IS NULL;
  IF n > 0 THEN RAISE EXCEPTION 'stop_times without stop: %', n; END IF;

  SELECT count(*) INTO n
  FROM public.trips t
  LEFT JOIN public.routes r ON r.route_id = t.route_id
  WHERE r.route_id IS NULL;
  IF n > 0 THEN RAISE EXCEPTION 'trips without route: %', n; END IF;

  SELECT count(*) INTO n
  FROM public.trips t
  LEFT JOIN public.calendar c ON c.service_id = t.service_id
  WHERE c.service_id IS NULL;
  IF n > 0 THEN RAISE EXCEPTION 'trips without calendar service_id: %', n; END IF;

  SELECT count(*) INTO n
  FROM public.trips t
  LEFT JOIN public.pattern_jp p ON p.jp_pattern_id = t.jp_pattern_id
  WHERE t.jp_pattern_id IS NOT NULL AND p.jp_pattern_id IS NULL;
  IF n > 0 THEN RAISE EXCEPTION 'trips without pattern_jp: %', n; END IF;

  -- Every trip must have stop_times
  SELECT count(*) INTO n
  FROM public.trips t
  WHERE NOT EXISTS (SELECT 1 FROM public.stop_times st WHERE st.trip_id = t.trip_id);
  IF n > 0 THEN RAISE EXCEPTION 'trips without stop_times: %', n; END IF;

  -- Feed period
  SELECT count(*) INTO n
  FROM public.calendar
  WHERE start_date <> DATE '2026-03-28' OR end_date <> DATE '2027-04-30';
  IF n > 0 THEN RAISE EXCEPTION 'unexpected calendar period rows: %', n; END IF;

  RAISE NOTICE 'all checks passed';
END
$check$;

COMMIT;

ANALYZE public.agency_jp, public.calendar, public.calendar_dates,
        public.pattern_jp, public.routes, public.stops, public.stop_times,
        public.translations, public.trips;

-- -----------------------------------------------------------------------------
-- 6. Summary after load (read-only)
-- -----------------------------------------------------------------------------
-- Active service_ids for sample dates (weekday / Sat / Sun / holiday / new year)
SELECT d::date AS target_date,
       to_char(d, 'Dy') AS dow,
       (SELECT string_agg(service_id, ', ' ORDER BY service_id)
          FROM public.get_active_services(d::date)) AS active_services
FROM unnest(ARRAY[
  DATE '2026-11-09',  -- Mon
  DATE '2026-11-14',  -- Sat
  DATE '2026-11-15',  -- Sun
  DATE '2026-11-23',  -- holiday (Labor Thanksgiving Day)
  DATE '2026-12-31',
  DATE '2027-01-01'
]) AS d;

-- Trips per service_id
SELECT service_id, count(*) AS trips
FROM public.trips
GROUP BY service_id
ORDER BY trips DESC;
