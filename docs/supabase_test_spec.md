# Supabase 動作テスト仕様書

## 1. 目的・範囲

BusNow が利用する Supabase(GTFS-JP データ)の動作を、サンプリングで確認し、結果を記録に残す。
全区間の網羅は行わない(コストが高いため)。

対象:

| 区分 | 対象 | 呼び出し元 |
|---|---|---|
| RPC | `get_phase1_bus_schedule_3(departure_station, arrival_station, target_date)` | `SupabaseService.getBusSchedules` |
| RPC | `phase1_health_check` | `SupabaseService.testConnection` |
| REST | `security_phase_info`(ヘルスチェックのフォールバック) | `SupabaseService.testConnection` |

対象外: `getRouteSettings` / `getHolidays`(未実装)、UI、WebView。

## 2. 前提

- 匿名アクセス(anon key)。RLS により公開データのみ読み取り可。
- 認証情報は `.xcconfig` 管理。テスト記録・リポジトリに鍵を含めない。
- 日付は `yyyy-MM-dd`。平日/日祝の判定は DB 側の `serviceId`(`平日` / `日祝` / `平日メーグル` / `日祝メーグル`)で返る。
- 駅名は `normalizedForSearch()` を通して渡す。

## 3. サンプリング方針

1回のテストで 6〜8 区間を使う。次の層から抽出する。

| 層 | 件数 | 選定基準 | 例 |
|---|--:|---|---|
| A. 重複が出やすい区間 | 3〜5 | 環状線・折返し系、末尾停留所が二重の路線 | 上前津→栄、八事音聞山→八事、中島駅→六番町 |
| B. 重複が出ない通常区間 | 2 | 重複なしの平日 | 楽陶館→極楽 |
| C. 日祝 | 1〜2 | `target_date` に日祝を指定 | 八事→八事音聞山 |
| D. 異体字セレクタ(U+E0100)を含む結果 | 1 | 行先等にセレクタを含む区間 | ノリタケの森→上飯田 |

- 抽出は `scripts/check_dedup.py --sample N --seed S`(重複あり/なしを半々)を使うか、上の例を固定で使う。
- 実施ごとに seed と対象区間を記録する。

## 4. テストケース

### 4.1 接続

| ID | 内容 | 期待結果 |
|---|---|---|
| C-01 | `phase1_health_check` を実行 | 成功(HTTP 2xx) |
| C-02 | RPC 失敗時のフォールバック(`security_phase_info` を `limit 1` で取得) | 成功すれば `testConnection == true` |
| C-03 | 設定未完了(URL/キー無し)で `getBusSchedules` | `SupabaseError.connectionFailed` |

### 4.2 時刻表取得(`get_phase1_bus_schedule_3`)

| ID | 内容 | 期待結果 |
|---|---|---|
| S-01 | 層A/Bの各区間を平日で取得 | 1件以上返る。HTTP 2xx |
| S-02 | レスポンスの形式 | 全要素が `departureTime, arrivalTime, routeName, destination, platform, serviceType, departureMinutes, serviceId, busStops` を持つ(camelCase) |
| S-03 | 日祝日付で取得(層C) | `serviceId` が `日祝` 系になる。平日と件数が異なってよい |
| S-04 | 時刻形式 | `HH:mm:ss` で返り、アプリ側で `HH:mm` に整形される |
| S-05 | 存在しない駅名 | `[]` または空。アプリは `emptyResponse` 相当の扱い |
| S-06 | 異体字セレクタを含む結果(層D) | 表示用正規化後も文字化け・欠落がない |

### 4.3 重複除去(アプリ側規則)

規則: `(departureTime, routeName, destination)` が同じ便は `arrivalTime` が最も早いものだけ残す。

| ID | 内容 | 期待結果 |
|---|---|---|
| D-01 | 層A区間の除去後 | 同一キーの便が1件のみ |
| D-02 | 除去後の `busStops` | 末尾が到着駅で、到着駅を1回だけ含む |
| D-03 | 層B・C区間 | 件数が変わらない(除去0件) |
| D-04 | 並び順 | 出発時刻の昇順が維持される |

### 4.4 異常系

| ID | 内容 | 期待結果 |
|---|---|---|
| E-01 | ネットワーク遮断 | 最大3回リトライ(待機 1s×試行回数)後 `networkError` |
| E-02 | 空レスポンス(`null` / `[]` / `{}`) | 空配列を返す(`[]`)。空データ(0 byte)は `emptyResponse` |
| E-03 | JSON のキー不一致 | `jsonParsingFailed` |

## 5. 実施手順

1. 設定を確認する(URL・anon key。ここには記載しない)。
2. 層A〜Dから区間を決め、seed と区間を控える。
3. 各区間で RPC を実行し、結果を CSV(`h_departure_station,h_arrival_station,h_result_json`)に保存する。
4. 重複除去の確認:
   ```
   python3 scripts/check_dedup.py <結果.csv> --sample 12 --seed 1
   ```
5. 4.1・4.4 はアプリ(またはシミュレータ)で手動確認する。
6. 結果を `reports/` に残す(§6)。

## 6. 記録方法

- 重複除去の結果: `reports/dedup_report.md`(スクリプトが出力)。
- 手動確認の結果: 実施日、環境(ビルド/シミュレータ)、区間、ケース ID ごとの OK/NG、NG の内容を `reports/` に追記する。
- 差分を見たいときは、前回レポートと `git diff` で比較する。

## 7. 合格基準

- C-01 または C-02 が成功する。
- 層A〜Dの全区間で S-01/S-02 が成功する。
- D-01〜D-04 に NG がない(スクリプトの「到着駅検証NG: 0 行」)。
- 重大な NG(接続不可、JSON 解析失敗、結果欠落)がない。

## 8. 既知の事項

- 除去前の重複は、環状線の「1周して戻る」エントリと、末尾停留所の二重登録で発生する。
  根本対応は RPC 側で `trip_id` 単位に1行へ絞ること(DB 定義が未確認のため、現状はアプリ側で除去)。
- `testConnection` の `client.rpc("phase1_health_check")` に `await` / `execute()` が無く、RPC が実行されていない可能性がある。C-01 の結果は修正前後で意味が変わる。
- 検索用正規化(`convertToTwoPointShinnyou`)が表示用と同一実装で、セレクタを付与する。辻/込/迫/追を含む駅名で検索が合わない可能性がある(S-01 で該当駅名を追加確認する)。
