SELECT
  h_departure_station AS departure,
  h_arrival_station   AS arrival,
  SUM(count)          AS total_searches,   -- 検索回数の合計
  COUNT(*)            AS search_days,      -- 検索された日付の種類数
  MIN(h_target_date)  AS first_date,
  MAX(h_target_date)  AS last_date,
  MAX(COALESCE(updated_at, created_at::timestamp)) AS last_searched_at
FROM search_history
GROUP BY h_departure_station, h_arrival_station
ORDER BY total_searches DESC, search_days DESC
LIMIT 20;