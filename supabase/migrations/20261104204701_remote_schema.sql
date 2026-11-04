SET local check_function_bodies = off;

CREATE EXTENSION "pgjwt" SCHEMA "extensions";

CREATE SEQUENCE "public"."debug_logs_id_seq" AS integer INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1 NO CYCLE;

CREATE TABLE "public"."agency_jp" (
  "agency_id"             bigint NOT NULL,
  "agency_official_name"  text,
  "agency_zip_number"     text,
  "agency_address"        text,
  "agency_president_pos"  text,
  "agency_president_name" text,
  CONSTRAINT "agency_pkey" PRIMARY KEY (agency_id)
);

ALTER TABLE "public"."agency_jp"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."calendar_dates" (
  "service_id"     text    NOT NULL,
  "date"           date    NOT NULL,
  "exception_type" integer,
  CONSTRAINT "calendar_dates_pkey" PRIMARY KEY (service_id, date)
);

ALTER TABLE "public"."calendar_dates"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."calendar" (
  "service_id" text     NOT NULL,
  "monday"     smallint,
  "tuesday"    smallint,
  "wednesday"  smallint,
  "thursday"   smallint,
  "friday"     smallint,
  "saturday"   smallint,
  "sunday"     smallint,
  "start_date" date,
  "end_date"   date,
  CONSTRAINT "calendar_pkey" PRIMARY KEY (service_id)
);

ALTER TABLE "public"."calendar"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."debug_logs" (
  "id"            integer                  NOT NULL DEFAULT nextval('public.debug_logs_id_seq'::regclass),
  "timestamp"     timestamp with time zone DEFAULT now(),
  "function_name" text,
  "message"       text,
  "parameters"    jsonb,
  CONSTRAINT "debug_logs_pkey" PRIMARY KEY (id)
);

ALTER TABLE "public"."debug_logs"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."pattern_jp" (
  "jp_pattern_id"     bigint NOT NULL,
  "route_update_date" bigint,
  "origin_stop"       text,
  "via_stop"          text,
  "destination_stop"  text,
  CONSTRAINT "pattern_jp_pkey" PRIMARY KEY (jp_pattern_id)
);

ALTER TABLE "public"."pattern_jp"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."routes" (
  "route_id"           bigint NOT NULL,
  "agency_id"          bigint,
  "route_short_name"   text,
  "route_long_name"    text,
  "route_desc"         text,
  "route_type"         bigint,
  "route_url"          text,
  "route_color"        text,
  "route_text_color"   text,
  "jp_parent_route_id" text,
  CONSTRAINT "routes_pkey" PRIMARY KEY (route_id)
);

ALTER TABLE "public"."routes"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."search_history" (
  "h_target_date"       date                        NOT NULL,
  "h_departure_station" text                        NOT NULL,
  "h_arrival_station"   text                        NOT NULL,
  "h_result_json"       json                        NOT NULL,
  "count"               integer                     DEFAULT 1,
  "created_at"          timestamp with time zone    NOT NULL DEFAULT now(),
  "updated_at"          timestamp without time zone,
  CONSTRAINT "search_history_pkey" PRIMARY KEY (h_target_date, h_departure_station, h_arrival_station)
);

ALTER TABLE "public"."search_history"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."stop_times" (
  "trip_id"             text   NOT NULL,
  "arrival_time"        text,
  "departure_time"      text,
  "stop_id"             text,
  "stop_sequence"       bigint NOT NULL,
  "stop_headsign"       text,
  "pickup_type"         text,
  "drop_off_type"       text,
  "shape_dist_traveled" text,
  CONSTRAINT "stop_times_pkey" PRIMARY KEY (trip_id, stop_sequence)
);

ALTER TABLE "public"."stop_times"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."stops" (
  "stop_id"        text             NOT NULL,
  "stop_code"      text,
  "stop_name"      text,
  "stop_desc"      text,
  "stop_lat"       double precision,
  "stop_lon"       double precision,
  "zone_id"        text,
  "stop_url"       text,
  "location_type"  text,
  "parent_station" text,
  "platform_code"  text,
  CONSTRAINT "stop_pkey" PRIMARY KEY (stop_id)
);

ALTER TABLE "public"."stops"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."translations" (
  "table_name"    text NOT NULL,
  "field_name"    text NOT NULL,
  "language"      text NOT NULL,
  "translation"   text,
  "record_id"     text NOT NULL,
  "record_sub_id" text NOT NULL,
  "field_value"   text NOT NULL,
  CONSTRAINT "translations_pkey" PRIMARY KEY (table_name, field_name, LANGUAGE, record_id, record_sub_id, field_value)
);

ALTER TABLE "public"."translations"
  ENABLE ROW LEVEL SECURITY;

CREATE TABLE "public"."trips" (
  "route_id"              bigint NOT NULL,
  "service_id"            text,
  "trip_id"               text   NOT NULL,
  "trip_headsign"         text,
  "trip_short_name"       text,
  "direction_id"          text,
  "block_id"              text,
  "shape_id"              text,
  "wheelchair_accessible" text,
  "bikes_allowed"         text,
  "jp_trip_desc"          text,
  "jp_trip_desc_symbol"   text,
  "jp_office_id"          text,
  "jp_pattern_id"         bigint,
  CONSTRAINT "trips_pkey" PRIMARY KEY (trip_id)
);

ALTER TABLE "public"."trips"
  ENABLE ROW LEVEL SECURITY;

ALTER SEQUENCE "public"."debug_logs_id_seq" OWNED BY "public"."debug_logs"."id";

CREATE OR REPLACE FUNCTION public.get_active_services (
  target_date date DEFAULT CURRENT_DATE
)
  RETURNS TABLE (
    service_id text
  )
  LANGUAGE plpgsql
  AS $function$
DECLARE
  target_dow INTEGER;
BEGIN
  -- 曜日を取得（0=日曜, 1=月曜, ..., 6=土曜）
  target_dow := EXTRACT(DOW FROM target_date);
  
  RETURN QUERY
  -- Step 1: calendar.txtから通常運行するservice_id を取得
  SELECT DISTINCT c.service_id
  FROM calendar c
  WHERE target_date >= c.start_date 
    AND target_date <= c.end_date
    AND (
      (target_dow = 0 AND c.sunday = 1) OR
      (target_dow = 1 AND c.monday = 1) OR
      (target_dow = 2 AND c.tuesday = 1) OR
      (target_dow = 3 AND c.wednesday = 1) OR
      (target_dow = 4 AND c.thursday = 1) OR
      (target_dow = 5 AND c.friday = 1) OR
      (target_dow = 6 AND c.saturday = 1)
    )
    -- Step 2: calendar_dates.txtでexception_type=2（除外）されていないものに限定
    AND NOT EXISTS (
      SELECT 1 FROM calendar_dates cd
      WHERE cd.service_id = c.service_id
        AND cd.date = target_date
        AND cd.exception_type = 2  -- サービス除外
    )
  
  UNION
  
  -- Step 3: calendar_dates.txtでexception_type=1（追加）されたservice_id を追加
  SELECT DISTINCT cd.service_id
  FROM calendar_dates cd
  WHERE cd.date = target_date
    AND cd.exception_type = 1;  -- サービス追加
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_phase1_bus_schedule (
  departure_station text,
  arrival_station   text,
  target_date       date DEFAULT CURRENT_DATE
)
  RETURNS json
  LANGUAGE plpgsql
  SECURITY DEFINER
  AS $function$DECLARE
  result_json JSON;
  v_result JSON;
  target_dow INTEGER;
BEGIN

  -- まず UPDATE を試みて result_json を返す
  UPDATE search_history
  SET
    count = count + 1,
    updated_at = now()
  WHERE h_target_date = target_date
    AND h_departure_station = departure_station
    AND h_arrival_station = arrival_station
  RETURNING h_result_json INTO v_result;

  IF FOUND THEN
    -- レコードが存在した場合はその時点で終了
    RETURN v_result;
  END IF;

  -- 曜日を取得（0=日曜, 1=月曜, ..., 6=土曜）
  target_dow := EXTRACT(DOW FROM target_date);
  
  -- GTFS正確仕様：その日に実際に運行する便のみ取得
  WITH active_services AS (
    -- Step 1: calendar.txtから通常運行するservice_id を取得
    SELECT DISTINCT c.service_id
    FROM calendar c
    WHERE target_date >= c.start_date 
      AND target_date <= c.end_date
      AND (
        (target_dow = 0 AND c.sunday = 1) OR
        (target_dow = 1 AND c.monday = 1) OR
        (target_dow = 2 AND c.tuesday = 1) OR
        (target_dow = 3 AND c.wednesday = 1) OR
        (target_dow = 4 AND c.thursday = 1) OR
        (target_dow = 5 AND c.friday = 1) OR
        (target_dow = 6 AND c.saturday = 1)
      )
      -- Step 2: calendar_dates.txtでexception_type=2（除外）されていないものに限定
      AND NOT EXISTS (
        SELECT 1 FROM calendar_dates cd
        WHERE cd.service_id = c.service_id
          AND cd.date = target_date
          AND cd.exception_type = 2  -- サービス除外
      )
    
    UNION
    
    -- Step 3: calendar_dates.txtでexception_type=1（追加）されたservice_id を追加
    SELECT DISTINCT cd.service_id
    FROM calendar_dates cd
    WHERE cd.date = target_date
      AND cd.exception_type = 1  -- サービス追加
  ),
  active_schedules AS (
    SELECT DISTINCT
      st_source.departure_time,
      r.route_short_name AS route_name,
      COALESCE(t.trip_headsign, s_dest.stop_name) AS destination,
      COALESCE(s_source.platform_code, '1') AS platform,
      get_service_type(target_date) AS service_type,
      EXTRACT(EPOCH FROM st_source.departure_time::time) / 60 AS departure_minutes,
      t.service_id
    FROM stop_times st_source
    INNER JOIN stop_times st_dest ON st_source.trip_id = st_dest.trip_id
    INNER JOIN stops s_source ON st_source.stop_id = s_source.stop_id
    INNER JOIN stops s_dest ON st_dest.stop_id = s_dest.stop_id
    INNER JOIN trips t ON st_source.trip_id = t.trip_id
    INNER JOIN routes r ON t.route_id = r.route_id
    -- 指定日に実際に運行するサービスのみ（インライン展開）
    INNER JOIN active_services ON t.service_id = active_services.service_id
    WHERE st_source.stop_sequence < st_dest.stop_sequence
      AND s_source.stop_name = departure_station
      AND s_dest.stop_name = arrival_station
  )
  SELECT JSON_AGG(
    JSON_BUILD_OBJECT(
      'departureTime', departure_time,
      'routeName', route_name,
      'destination', destination,
      'platform', platform,
      'serviceType', service_type,
      'departureMinutes', departure_minutes,
      'serviceId', service_id
    ) ORDER BY departure_minutes ASC
  ) INTO result_json
  FROM active_schedules;
  
  -- 結果の検証
  IF result_json IS NULL THEN
    RAISE LOG 'No GTFS-compliant schedule found for % to % on %', 
              departure_station, arrival_station, target_date;
  END IF;

  -- 存在しなければ INSERT
  INSERT INTO search_history (
    h_target_date,
    h_departure_station,
    h_arrival_station,
    h_result_json,
    created_at,
    count,
    updated_at
  )
  VALUES (
    target_date,
    departure_station,
    arrival_station,
    result_json,
    now(),
    1,
    NULL
  );
  
  RETURN COALESCE(result_json, '[]'::JSON);
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE LOG 'get_phase1_bus_schedule error: %, departure: %, arrival: %, date: %', 
              SQLERRM, departure_station, arrival_station, target_date;
    RETURN '[]'::JSON;
END;$function$;

CREATE OR REPLACE FUNCTION public.get_phase1_bus_schedule_2 (
  departure_station text,
  arrival_station   text,
  target_date       date DEFAULT CURRENT_DATE
)
  RETURNS json
  LANGUAGE plpgsql
  SECURITY DEFINER
  AS $function$
DECLARE
  result_json JSON;
  v_result JSON;
  target_dow INTEGER;
BEGIN

  -- まず UPDATE を試みて result_json を返す
  UPDATE search_history
  SET
    count = count + 1,
    updated_at = now()
  WHERE h_target_date = target_date
    AND h_departure_station = departure_station
    AND h_arrival_station = arrival_station
  RETURNING h_result_json INTO v_result;

  IF FOUND THEN
    -- レコードが存在した場合はその時点で終了
    RETURN v_result;
  END IF;

  -- 曜日を取得（0=日曜, 1=月曜, ..., 6=土曜）
  target_dow := EXTRACT(DOW FROM target_date);
  
  -- GTFS正確仕様：その日に実際に運行する便のみ取得
  WITH active_services AS (
    -- Step 1: calendar.txtから通常運行するservice_id を取得
    SELECT DISTINCT c.service_id
    FROM calendar c
    WHERE target_date >= c.start_date 
      AND target_date <= c.end_date
      AND (
        (target_dow = 0 AND c.sunday = 1) OR
        (target_dow = 1 AND c.monday = 1) OR
        (target_dow = 2 AND c.tuesday = 1) OR
        (target_dow = 3 AND c.wednesday = 1) OR
        (target_dow = 4 AND c.thursday = 1) OR
        (target_dow = 5 AND c.friday = 1) OR
        (target_dow = 6 AND c.saturday = 1)
      )
      -- Step 2: calendar_dates.txtでexception_type=2（除外）されていないものに限定
      AND NOT EXISTS (
        SELECT 1 FROM calendar_dates cd
        WHERE cd.service_id = c.service_id
          AND cd.date = target_date
          AND cd.exception_type = 2  -- サービス除外
      )
    
    UNION
    
    -- Step 3: calendar_dates.txtでexception_type=1（追加）されたservice_id を追加
    SELECT DISTINCT cd.service_id
    FROM calendar_dates cd
    WHERE cd.date = target_date
      AND cd.exception_type = 1  -- サービス追加
  ),
  active_schedules AS (
    SELECT DISTINCT
      st_source.departure_time,
      r.route_short_name AS route_name,
      COALESCE(t.trip_headsign, s_dest.stop_name) AS destination,
      COALESCE(s_source.platform_code, '1') AS platform,
      get_service_type(target_date) AS service_type,
      EXTRACT(EPOCH FROM st_source.departure_time::time) / 60 AS departure_minutes,
      t.service_id,
      (SELECT ARRAY_AGG(stop_name) FROM stop_times AS st INNER JOIN stops AS s ON st.stop_id = s.stop_id WHERE st.trip_id = t.trip_id AND st_source.stop_sequence <= stop_sequence AND stop_sequence <= st_dest.stop_sequence) AS bus_stops,
      s_source.stop_url,
      ROW_NUMBER() OVER () AS row_num
    FROM stop_times st_source
    INNER JOIN stop_times st_dest ON st_source.trip_id = st_dest.trip_id
    INNER JOIN stops s_source ON st_source.stop_id = s_source.stop_id
    INNER JOIN stops s_dest ON st_dest.stop_id = s_dest.stop_id
    INNER JOIN trips t ON st_source.trip_id = t.trip_id
    INNER JOIN routes r ON t.route_id = r.route_id
    -- 指定日に実際に運行するサービスのみ（インライン展開）
    INNER JOIN active_services ON t.service_id = active_services.service_id
    WHERE st_source.stop_sequence < st_dest.stop_sequence
      AND s_source.stop_name = departure_station
      AND s_dest.stop_name = arrival_station
    ORDER BY row_num
  )
  SELECT JSON_AGG(
    JSON_BUILD_OBJECT(
      'departureTime', departure_time,
      'routeName', route_name,
      'destination', destination,
      'platform', platform,
      'serviceType', service_type,
      'departureMinutes', departure_minutes,
      'serviceId', service_id,
      'busStops', bus_stops,
      'stop_url', ''
    ) ORDER BY departure_minutes ASC
  ) INTO result_json
  FROM active_schedules;
  
  -- 結果の検証
  IF result_json IS NULL THEN
    RAISE LOG 'No GTFS-compliant schedule found for % to % on %', 
              departure_station, arrival_station, target_date;
  END IF;

  -- 存在しなければ INSERT
  INSERT INTO search_history (
    h_target_date,
    h_departure_station,
    h_arrival_station,
    h_result_json,
    created_at,
    count,
    updated_at
  )
  VALUES (
    target_date,
    departure_station,
    arrival_station,
    result_json,
    now(),
    1,
    NULL
  );
  
  RETURN COALESCE(result_json, '[]'::JSON);
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE LOG 'get_phase1_bus_schedule error: %, departure: %, arrival: %, date: %', 
              SQLERRM, departure_station, arrival_station, target_date;
    RETURN '[]'::JSON;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_phase1_bus_schedule_3 (
  departure_station text,
  arrival_station   text,
  target_date       date
)
  RETURNS json
  LANGUAGE plpgsql
  SECURITY DEFINER
  AS $function$DECLARE
    result_json JSON;
    v_result    JSON;
    target_dow  INTEGER;
BEGIN
    ------------------------------------------------------------------------
    -- 既存結果の検索
    ------------------------------------------------------------------------

    -- 既存の検索結果[search_history]を確認し、検索回数を加算する
    -- search_history.h_result_json(画面に描画する情報）を戻り値にセットする
    UPDATE search_history
    SET
        count      = count + 1,
        updated_at = now()
    WHERE h_target_date         = target_date
        AND h_departure_station = departure_station
        AND h_arrival_station   = arrival_station
    RETURNING h_result_json INTO v_result;

    -- 上の処理が成功した場合、後続の処理は不要
    -- 戻り値(検索結果)を返して処理を抜ける
    IF FOUND THEN
        -- レコードが存在した場合はその時点で終了
        RETURN v_result;
    END IF;

    ------------------------------------------------------------------------
    -- 新規検索
    ------------------------------------------------------------------------

    -- 引数の検索日付から曜日を取得（0=日曜, 1=月曜, ..., 6=土曜）
    target_dow := EXTRACT(DOW FROM target_date);

    ------------------------------------------------------------------------
    -- WITH句(検索日付に運行する運行区分の一覧を取得する)
    ------------------------------------------------------------------------
    WITH active_services AS (
        -- 検索日付に通常運行する運行区分の一覧を取得する
        -- 祝日等運行区分に基づかない例外的な運行をする日は別途取得するので除外している
        SELECT DISTINCT c.service_id
        FROM calendar c
        WHERE target_date >= c.start_date
            -- "end_date"を条件から除外(理由:1年に1回運行情報が更新される。その更新に気づかないと検索できなくなる)
            --AND target_date <= c.end_date
            AND (
                (target_dow = 0 AND c.sunday    = 1)
                OR (target_dow = 1 AND c.monday    = 1)
                OR (target_dow = 2 AND c.tuesday   = 1)
                OR (target_dow = 3 AND c.wednesday = 1)
                OR (target_dow = 4 AND c.thursday  = 1)
                OR (target_dow = 5 AND c.friday    = 1)
                OR (target_dow = 6 AND c.saturday  = 1)
            )
            -- calendar_dates.txtでexception_type=2（運行区分非適用）されているものを除外する
            AND NOT EXISTS (
                SELECT 1
                FROM calendar_dates cd
                WHERE cd.service_id     = c.service_id
                    AND cd.date         = target_date
                    AND cd.exception_type = 2 -- 運行区分非適用
            )

        UNION

        -- 祝日等運行区分に基づかない例外的な運行をする日の運行区分一覧を取得する
        SELECT DISTINCT cd.service_id
        FROM calendar_dates cd
        WHERE cd.date           = target_date
            AND cd.exception_type = 1 -- 運行区分適用
    ),
    ------------------------------------------------------------------------
    -- WITH句(引数の出発バス停と到着バス停から便情報のリストを取得する)
    ------------------------------------------------------------------------
    active_schedules AS (
        SELECT DISTINCT
            st_source.departure_time,
            st_dest.departure_time                          AS arrival_time,
            r.route_short_name                              AS route_name,
            COALESCE(t.trip_headsign, s_dest.stop_name)     AS destination, -- 到着バス停(終点 or 経由バス停)
            COALESCE(s_source.platform_code, '1')           AS platform,    -- 乗り場情報(設計上NULL許可なので初期値を設定している)
            CASE WHEN active_services.service_id LIKE '%平日%' THEN 'weekday' ELSE 'other' END AS service_type,
            EXTRACT(EPOCH FROM st_source.departure_time::time) / 60 AS departure_minutes,   -- 到着までの残り時間(分)
            t.service_id,
            (
                SELECT ARRAY_AGG(stop_name)
                FROM stop_times AS st
                INNER JOIN stops AS s ON st.stop_id = s.stop_id
                WHERE st.trip_id = t.trip_id
                    AND st_source.stop_sequence <= stop_sequence
                    AND stop_sequence           <= st_dest.stop_sequence
            ) AS bus_stops,     -- 経由するバス停の名称一覧
            ROW_NUMBER() OVER () AS row_num
        FROM stop_times st_source
        INNER JOIN stop_times st_dest ON st_source.trip_id = st_dest.trip_id
        INNER JOIN stops s_source     ON st_source.stop_id = s_source.stop_id
        INNER JOIN stops s_dest       ON st_dest.stop_id   = s_dest.stop_id
        INNER JOIN trips t            ON st_source.trip_id = t.trip_id
        INNER JOIN routes r           ON t.route_id        = r.route_id
        -- 検索日付に実際に運行する便情報に絞り込む
        INNER JOIN active_services    ON t.service_id      = active_services.service_id
        WHERE st_source.stop_sequence < st_dest.stop_sequence
            AND s_source.stop_name = departure_station  -- 引数の出発バス停
            AND s_dest.stop_name   = arrival_station    -- 引数の到着バス停
        ORDER BY row_num
    )
    ------------------------------------------------------------------------
    -- 検索結果をJSON形式に変換する
    ------------------------------------------------------------------------
    SELECT JSON_AGG(
        JSON_BUILD_OBJECT(
            'departureTime',    departure_time,
            'arrivalTime',    arrival_time,
            'routeName',        route_name,
            'destination',      destination,
            'platform',         platform,
            'serviceType',      service_type,
            'departureMinutes', departure_minutes,
            'serviceId',        service_id,
            'busStops',         bus_stops
        )
        ORDER BY departure_minutes ASC
    ) INTO result_json
    FROM active_schedules;

    -- 結果の検証
    IF result_json IS NULL THEN
        RAISE LOG 'No GTFS-compliant schedule found for % to % on %',
            departure_station,
            arrival_station,
            target_date;
    END IF;

    -- 検索結果を記録しておく。
    INSERT INTO search_history (
        h_target_date,
        h_departure_station,
        h_arrival_station,
        h_result_json,
        created_at,
        count,
        updated_at
    )
    VALUES (
        target_date,
        departure_station,
        arrival_station,
        result_json,
        now(),
        1,
        NULL
    );

    RETURN COALESCE(result_json, '[]'::JSON);

EXCEPTION
    WHEN OTHERS THEN
        RAISE LOG 'get_phase1_bus_schedule_3 error: %, departure: %, arrival: %, date: %',
            SQLERRM,
            departure_station,
            arrival_station,
            target_date;
        RETURN '[]'::JSON;
END;$function$;

CREATE OR REPLACE FUNCTION public.get_service_type (
  target_date date DEFAULT CURRENT_DATE
)
  RETURNS text
  LANGUAGE plpgsql
  AS $function$
DECLARE
  target_dow INTEGER;
  has_weekday_service BOOLEAN;
  has_weekend_service BOOLEAN;
  has_holiday_service BOOLEAN;
BEGIN
  target_dow := EXTRACT(DOW FROM target_date);
  
  -- アクティブなサービスから運行種別を推定
  SELECT 
    bool_or(service_id LIKE '%weekday%' OR service_id LIKE '%平日%'),
    bool_or(service_id LIKE '%weekend%' OR service_id LIKE '%土日%' OR service_id LIKE '%saturday%' OR service_id LIKE '%sunday%'),
    bool_or(service_id LIKE '%holiday%' OR service_id LIKE '%祝日%')
  INTO has_weekday_service, has_weekend_service, has_holiday_service
  FROM get_active_services(target_date);
  
  -- 運行種別の判定（従来の簡単な分類）
  IF has_holiday_service THEN
    RETURN 'holiday';
  ELSIF target_dow = 0 THEN
    RETURN 'sunday';
  ELSIF target_dow = 6 THEN
    RETURN 'saturday';
  ELSE
    RETURN 'weekday';
  END IF;
END;
$function$;

CREATE OR REPLACE FUNCTION public.is_holiday_by_gtfs (
  check_date date DEFAULT CURRENT_DATE
)
  RETURNS boolean
  LANGUAGE plpgsql
  AS $function$
DECLARE
  service_type_result TEXT;
BEGIN
  service_type_result := get_service_type(check_date);
  RETURN (service_type_result = 'holiday');
END;
$function$;

CREATE OR REPLACE FUNCTION public.phase1_health_check()
  RETURNS TABLE (
    component text,
    status    text,
    message   text
  )
  LANGUAGE plpgsql
  AS $function$
BEGIN
  -- View アクセステスト
  BEGIN
    PERFORM COUNT(*) FROM v_phase1_stations LIMIT 1;
    RETURN QUERY SELECT 'views'::TEXT, 'OK'::TEXT, 'Basic views accessible'::TEXT;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN QUERY SELECT 'views'::TEXT, 'ERROR'::TEXT, ('View access failed: ' || SQLERRM);
  END;
  
  -- GTFS calendar テーブル確認
  BEGIN
    PERFORM COUNT(*) FROM calendar LIMIT 1;
    RETURN QUERY SELECT 'gtfs_calendar'::TEXT, 'OK'::TEXT, 'GTFS calendar table accessible'::TEXT;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN QUERY SELECT 'gtfs_calendar'::TEXT, 'ERROR'::TEXT, 'calendar table not accessible'::TEXT;
  END;
  
  -- GTFS calendar_dates テーブル確認
  BEGIN
    PERFORM COUNT(*) FROM calendar_dates LIMIT 1;
    RETURN QUERY SELECT 'gtfs_calendar_dates'::TEXT, 'OK'::TEXT, 'GTFS calendar_dates table accessible'::TEXT;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN QUERY SELECT 'gtfs_calendar_dates'::TEXT, 'ERROR'::TEXT, 'calendar_dates table not accessible'::TEXT;
  END;
  
  -- アクティブサービス判定機能テスト
  BEGIN
    PERFORM get_active_services(CURRENT_DATE);
    RETURN QUERY SELECT 'active_services'::TEXT, 'OK'::TEXT, 'GTFS service detection working'::TEXT;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN QUERY SELECT 'active_services'::TEXT, 'ERROR'::TEXT, ('Active service detection failed: ' || SQLERRM);
  END;
  
  -- RPC関数テスト
  BEGIN
    PERFORM get_phase1_bus_schedule('test_station_a', 'test_station_b');
    RETURN QUERY SELECT 'rpc_functions'::TEXT, 'OK'::TEXT, 'RPC functions working'::TEXT;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN QUERY SELECT 'rpc_functions'::TEXT, 'ERROR'::TEXT, ('RPC function test failed: ' || SQLERRM);
  END;
  
  -- RLS状態チェック
  BEGIN
    IF (SELECT COUNT(*) FROM pg_tables WHERE rowsecurity = true AND schemaname = 'public') >= 4 THEN
      RETURN QUERY SELECT 'security'::TEXT, 'OK'::TEXT, 'GTFS-compliant RLS enabled'::TEXT;
    ELSE
      RETURN QUERY SELECT 'security'::TEXT, 'WARNING'::TEXT, 'RLS not fully enabled'::TEXT;
    END IF;
  END;
  
  -- 今日のアクティブサービス数確認
  BEGIN
    DECLARE
      service_count INTEGER;
    BEGIN
      SELECT COUNT(*) INTO service_count FROM get_active_services(CURRENT_DATE);
      RETURN QUERY SELECT 'today_services'::TEXT, 'INFO'::TEXT, 
                   FORMAT('Active services today: %s', service_count);
    END;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN QUERY SELECT 'today_services'::TEXT, 'WARNING'::TEXT, 'Could not count active services'::TEXT;
  END;
END;
$function$;

CREATE OR REPLACE FUNCTION public.update_updated_at_column()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  AS $function$
  BEGIN
      NEW.updated_at = NOW();
      RETURN NEW;
  END;
  $function$;

ALTER TABLE "public"."routes"
  ADD CONSTRAINT "routes_agency_id_fkey" FOREIGN KEY (agency_id) REFERENCES public.agency_jp(agency_id);

CREATE POLICY "phase1_calendar_read" ON "public"."calendar"
  FOR SELECT
  TO "anon"
  USING (true);

CREATE POLICY "phase1_calendar_dates_read" ON "public"."calendar_dates"
  FOR SELECT
  TO "anon"
  USING (true);

CREATE POLICY "phase1_routes_read" ON "public"."routes"
  FOR SELECT
  TO "anon"
  USING (true);

CREATE POLICY "phase1_stops_read" ON "public"."stops"
  FOR SELECT
  TO "anon"
  USING (true);

COMMENT ON EXTENSION "pgjwt" IS 'JSON Web Token API for Postgresql';

COMMENT ON TABLE "public"."agency_jp" IS '運行事業者情報';

COMMENT ON TABLE "public"."calendar" IS '運行区分情報';

COMMENT ON TABLE "public"."calendar_dates" IS '運行日情報';

COMMENT ON TABLE "public"."routes" IS '路線情報';

COMMENT ON TABLE "public"."search_history" IS '検索履歴兼効率化テーブル';

COMMENT ON TABLE "public"."stop_times" IS '停車時刻情報';

COMMENT ON TABLE "public"."stops" IS '停留所情報';

COMMENT ON TABLE "public"."translations" IS '多言語対応';

COMMENT ON TABLE "public"."trips" IS '運行情報';

GRANT EXECUTE ON FUNCTION "public"."get_active_services"(date) TO PUBLIC, "anon", "authenticated";

REVOKE ALL ON FUNCTION "public"."get_active_services"(date) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."get_active_services"(date) TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."get_active_services"(date) TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."get_phase1_bus_schedule"(text, text, date) TO PUBLIC, "anon", "authenticated";

REVOKE ALL ON FUNCTION "public"."get_phase1_bus_schedule"(text, text, date) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."get_phase1_bus_schedule"(text, text, date) TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."get_phase1_bus_schedule"(text, text, date) TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."get_phase1_bus_schedule_2"(text, text, date) TO PUBLIC, "anon", "authenticated";

REVOKE ALL ON FUNCTION "public"."get_phase1_bus_schedule_2"(text, text, date) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."get_phase1_bus_schedule_2"(text, text, date) TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."get_phase1_bus_schedule_2"(text, text, date) TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."get_phase1_bus_schedule_3"(text, text, date) TO PUBLIC, "anon", "authenticated";

REVOKE ALL ON FUNCTION "public"."get_phase1_bus_schedule_3"(text, text, date) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."get_phase1_bus_schedule_3"(text, text, date) TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."get_phase1_bus_schedule_3"(text, text, date) TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."get_service_type"(date) TO PUBLIC, "anon", "authenticated";

REVOKE ALL ON FUNCTION "public"."get_service_type"(date) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."get_service_type"(date) TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."get_service_type"(date) TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."is_holiday_by_gtfs"(date) TO PUBLIC, "anon", "authenticated";

REVOKE ALL ON FUNCTION "public"."is_holiday_by_gtfs"(date) FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."is_holiday_by_gtfs"(date) TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."is_holiday_by_gtfs"(date) TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."phase1_health_check"() TO PUBLIC, "anon", "authenticated";

REVOKE ALL ON FUNCTION "public"."phase1_health_check"() FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."phase1_health_check"() TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."phase1_health_check"() TO "service_role";

GRANT EXECUTE ON FUNCTION "public"."update_updated_at_column"() TO PUBLIC, "anon", "authenticated";

REVOKE ALL ON FUNCTION "public"."update_updated_at_column"() FROM "postgres";

GRANT EXECUTE ON FUNCTION "public"."update_updated_at_column"() TO "postgres";

GRANT EXECUTE ON FUNCTION "public"."update_updated_at_column"() TO "service_role";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."debug_logs_id_seq" TO "anon", "authenticated";

REVOKE ALL ON SEQUENCE "public"."debug_logs_id_seq" FROM "postgres";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."debug_logs_id_seq" TO "postgres";

GRANT SELECT, UPDATE, USAGE ON SEQUENCE "public"."debug_logs_id_seq" TO "service_role";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."agency_jp" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."agency_jp" FROM "postgres";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."agency_jp" TO "postgres";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."agency_jp" TO "service_role";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."calendar" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."calendar" FROM "postgres";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."calendar" TO "postgres";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."calendar" TO "service_role";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."calendar_dates" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."calendar_dates" FROM "postgres";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."calendar_dates" TO "postgres";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."calendar_dates" TO "service_role";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."debug_logs" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."debug_logs" FROM "postgres";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."debug_logs" TO "postgres";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."debug_logs" TO "service_role";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."pattern_jp" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."pattern_jp" FROM "postgres";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."pattern_jp" TO "postgres";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."pattern_jp" TO "service_role";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."routes" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."routes" FROM "postgres";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."routes" TO "postgres";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."routes" TO "service_role";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."search_history" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."search_history" FROM "postgres";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."search_history" TO "postgres";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."search_history" TO "service_role";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."stop_times" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."stop_times" FROM "postgres";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."stop_times" TO "postgres";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."stop_times" TO "service_role";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."stops" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."stops" FROM "postgres";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."stops" TO "postgres";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."stops" TO "service_role";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."translations" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."translations" FROM "postgres";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."translations" TO "postgres";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."translations" TO "service_role";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."trips" TO "anon", "authenticated";

REVOKE ALL ON TABLE "public"."trips" FROM "postgres";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."trips" TO "postgres";

GRANT DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."trips" TO "service_role";

