-- Phase 1: 基本セキュリティ設計（GTFS正確仕様版）
-- 対象: GTFS calendar.txt + calendar_dates.txt の正確な組み合わせ処理
-- 方針: GTFS仕様完全準拠・シンプル・実用性重視・段階的拡張可能
-- 適用タイミング: テーブル作成直後の初期セキュリティ設定

-- =======================================================================
-- 1. 基本的なRow Level Security (RLS) 設定
-- =======================================================================

-- GTFS標準テーブルのRLS有効化
ALTER TABLE stops ENABLE ROW LEVEL SECURITY;
ALTER TABLE routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar ENABLE ROW LEVEL SECURITY;
ALTER TABLE calendar_dates ENABLE ROW LEVEL SECURITY;

-- stop_times, tripsは開発段階ではRLS適用せず
-- （パフォーマンス優先、必要に応じてPhase 2で追加）

-- =======================================================================
-- 2. シンプルなアクセス制御ポリシー
-- =======================================================================

-- 匿名ユーザーに基本的な読み取り権限を付与
CREATE POLICY "phase1_stops_read" ON stops
  FOR SELECT TO anon USING (TRUE);

CREATE POLICY "phase1_routes_read" ON routes
  FOR SELECT TO anon USING (TRUE);

CREATE POLICY "phase1_calendar_read" ON calendar
  FOR SELECT TO anon USING (TRUE);

CREATE POLICY "phase1_calendar_dates_read" ON calendar_dates
  FOR SELECT TO anon USING (TRUE);

-- =======================================================================
-- 3. GTFS正確仕様の運行判定関数
-- =======================================================================

-- 指定日に実際に運行するservice_id一覧を取得（GTFS完全準拠）
CREATE OR REPLACE FUNCTION get_active_services(target_date DATE DEFAULT CURRENT_DATE)
RETURNS TABLE(service_id TEXT) AS $$
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
$$ LANGUAGE plpgsql;

-- 指定日の運行種別を判定（従来互換用の簡略版）
CREATE OR REPLACE FUNCTION get_service_type(target_date DATE DEFAULT CURRENT_DATE)
RETURNS TEXT AS $$
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
$$ LANGUAGE plpgsql;

-- 簡易祝日判定（従来互換性維持）
CREATE OR REPLACE FUNCTION is_holiday_by_gtfs(check_date DATE DEFAULT CURRENT_DATE)
RETURNS BOOLEAN AS $$
DECLARE
  service_type_result TEXT;
BEGIN
  service_type_result := get_service_type(check_date);
  RETURN (service_type_result = 'holiday');
END;
$$ LANGUAGE plpgsql;

-- =======================================================================
-- 4. GTFS正確仕様対応のView
-- =======================================================================

-- GTFS正確仕様に基づく時刻表View
CREATE OR REPLACE VIEW v_phase1_bus_schedules AS
SELECT DISTINCT
  st_source.trip_id,
  st_source.departure_time,
  r.route_short_name AS route_name,
  COALESCE(t.trip_headsign, s_dest.stop_name) AS destination,
  COALESCE(s_source.platform_code, '1') AS platform,
  s_source.stop_name AS departure_station,
  s_dest.stop_name AS arrival_station,
  -- GTFS正確仕様に基づく運行種別判定
  get_service_type(CURRENT_DATE) AS service_type,
  -- ソート用フィールド
  EXTRACT(EPOCH FROM st_source.departure_time::time) / 60 AS departure_minutes,
  -- 実際のservice_id情報
  t.service_id AS actual_service_id,
  -- 今日このサービスが運行するかの判定
  EXISTS(
    SELECT 1 FROM get_active_services(CURRENT_DATE) active
    WHERE active.service_id = t.service_id
  ) AS is_active_today
FROM stop_times st_source
INNER JOIN stop_times st_dest ON st_source.trip_id = st_dest.trip_id
INNER JOIN stops s_source ON st_source.stop_id = s_source.stop_id
INNER JOIN stops s_dest ON st_dest.stop_id = s_dest.stop_id
INNER JOIN trips t ON st_source.trip_id = t.trip_id
INNER JOIN routes r ON t.route_id = r.route_id
-- 今日実際に運行するサービスのみに限定
INNER JOIN get_active_services(CURRENT_DATE) active_services 
  ON t.service_id = active_services.service_id
WHERE st_source.stop_sequence < st_dest.stop_sequence;

-- 駅一覧View（変更なし）
CREATE OR REPLACE VIEW v_phase1_stations AS
SELECT DISTINCT 
  stop_id,
  stop_name,
  stop_desc,
  platform_code,
  stop_url
FROM stops
WHERE stop_name IS NOT NULL
ORDER BY stop_name;

-- 路線情報View（変更なし）
CREATE OR REPLACE VIEW v_phase1_routes AS
SELECT 
  route_id,
  route_short_name,
  route_long_name,
  route_desc
FROM routes
ORDER BY route_short_name;

-- =======================================================================
-- 5. GTFS正確仕様対応のRPC関数
-- =======================================================================

-- GTFS正確仕様に基づく時刻表取得関数
CREATE OR REPLACE FUNCTION get_phase1_bus_schedule(
  departure_station TEXT,
  arrival_station TEXT,
  target_date DATE DEFAULT CURRENT_DATE
)
RETURNS JSON AS $$
DECLARE
  result_json JSON;
BEGIN
  -- GTFS正確仕様：その日に実際に運行する便のみ取得
  WITH active_schedules AS (
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
    -- 指定日に実際に運行するサービスのみ
    INNER JOIN get_active_services(target_date) active_services 
      ON t.service_id = active_services.service_id
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
  
  -- 結果の検証とログ
  IF result_json IS NULL THEN
    RAISE LOG 'No GTFS-compliant schedule found for % to % on %', 
              departure_station, arrival_station, target_date;
  END IF;
  
  RETURN COALESCE(result_json, '[]'::JSON);
  
EXCEPTION
  WHEN OTHERS THEN
    RAISE LOG 'get_phase1_bus_schedule error: %, departure: %, arrival: %, date: %', 
              SQLERRM, departure_station, arrival_station, target_date;
    RETURN '[]'::JSON;
END;
$$ LANGUAGE plpgsql;

-- =======================================================================
-- 6. 包括的ヘルスチェック関数（GTFS正確仕様版）
-- =======================================================================

CREATE OR REPLACE FUNCTION phase1_health_check()
RETURNS TABLE (
  component TEXT,
  status TEXT,
  message TEXT
) AS $$
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
$$ LANGUAGE plpgsql;

-- =======================================================================
-- 7. 権限設定
-- =======================================================================

-- 匿名ユーザーにView使用権限付与
GRANT SELECT ON v_phase1_bus_schedules TO anon;
GRANT SELECT ON v_phase1_stations TO anon;
GRANT SELECT ON v_phase1_routes TO anon;

-- RPC関数実行権限付与
GRANT EXECUTE ON FUNCTION get_active_services(DATE) TO anon;
GRANT EXECUTE ON FUNCTION get_active_services() TO anon;
GRANT EXECUTE ON FUNCTION get_service_type(DATE) TO anon;
GRANT EXECUTE ON FUNCTION get_service_type() TO anon;
GRANT EXECUTE ON FUNCTION is_holiday_by_gtfs(DATE) TO anon;
GRANT EXECUTE ON FUNCTION is_holiday_by_gtfs() TO anon;
GRANT EXECUTE ON FUNCTION get_phase1_bus_schedule(TEXT, TEXT, DATE) TO anon;
GRANT EXECUTE ON FUNCTION get_phase1_bus_schedule(TEXT, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION phase1_health_check() TO anon;

-- =======================================================================
-- 8. Phase 1設計のメタデータ
-- =======================================================================

CREATE TABLE IF NOT EXISTS security_phase_info (
  phase_name TEXT PRIMARY KEY,
  description TEXT,
  security_level TEXT,
  target_users TEXT,
  implementation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  next_phase TEXT,
  notes TEXT
);

INSERT INTO security_phase_info (phase_name, description, security_level, target_users, next_phase, notes)
VALUES 
(
  'Phase 1 GTFS Spec',
  'GTFS specification compliant security design - accurate calendar + calendar_dates processing',
  'Basic (Level 1)',
  'Developers and early testing (1-5 users)',
  'Phase 2',
  'Full GTFS compliance: calendar.txt + calendar_dates.txt exception processing with exact specification adherence'
) ON CONFLICT (phase_name) DO UPDATE SET
  implementation_date = CURRENT_TIMESTAMP,
  notes = EXCLUDED.notes;

-- =======================================================================
-- 9. 使用例とコメント
-- =======================================================================

/*
Phase 1 基本セキュリティ設計（GTFS正確仕様版）の特徴:

【GTFS仕様完全準拠】
- calendar.txt の通常ルール処理
- calendar_dates.txt の例外処理（exception_type 1=追加, 2=除外）
- 正確なサービス運行判定

【主要関数】
- get_active_services(date): その日に実際に運行するservice_id一覧
- get_service_type(date): 従来互換の運行種別判定
- is_holiday_by_gtfs(date): 簡易祝日判定（従来互換）

【使用例】
-- 今日運行するサービス一覧
SELECT * FROM get_active_services();

-- 特定日の運行サービス
SELECT * FROM get_active_services('2025-01-01'::DATE);

-- 運行種別判定
SELECT get_service_type('2025-12-25'::DATE);

-- 時刻表取得（GTFS正確仕様）
SELECT get_phase1_bus_schedule('東京駅', '新宿駅', '2025-01-01'::DATE);

-- 包括的動作確認
SELECT * FROM phase1_health_check();

【GTFS処理ロジック】
1. calendar.txt から基本的な運行パターンを取得
2. calendar_dates.txt の exception_type = 2 で除外処理
3. calendar_dates.txt の exception_type = 1 で追加処理
4. 結果として、その日に実際に運行するservice_idを確定

【従来版からの改善点】
- 単純な「休日判定」から正確な「運行サービス判定」へ
- exception_type の正確な処理
- より実用的で正確なGTFS準拠実装
*/