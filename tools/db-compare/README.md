# db-compare

本番と検証の Supabase に同じ条件で RPC を投げ、結果 JSON を比較する。

| 環境 | RPC |
|---|---|
| 本番 (prod) | `get_phase1_bus_schedule_3` |
| 検証 (staging) | `get_bus_schedule_2026` |

引数 (`departure_station`, `arrival_station`, `target_date`) とレスポンス形式は共通。

## 使い方
```
export PROD_URL=... PROD_ANON_KEY=... STG_URL=... STG_ANON_KEY=...
node fetch.mjs prod && node fetch.mjs staging && node diff.mjs
```
`out/report.md` (サマリ), `out/diff.json` (詳細), `out/{prod,staging}/*.json` (生データ) が出力される。

`cases.json` に検索頻度の高い停留所ペアと日付(平日/土/日/祝日/改正日前後)を書く。
CI: GitHub Actions の `DB Compare` を手動実行。Secrets: `PROD_URL` `PROD_ANON_KEY` `STG_URL` `STG_ANON_KEY`。差分があっても失敗にはしない。
