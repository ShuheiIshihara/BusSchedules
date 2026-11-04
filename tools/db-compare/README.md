# db-compare

本番 Supabase(更新前)とローカル Supabase(更新後、[`supabase/README.md`](../../supabase/README.md))に
同じ条件で RPC を投げ、結果 JSON を比較する。

| 環境 | 接続先 | RPC(既定) |
|---|---|---|
| 本番 (prod) | `PROD_URL` | `get_phase1_bus_schedule_3` |
| ローカル (local) | `LOCAL_URL`(既定 `http://127.0.0.1:54321`) | `get_phase1_bus_schedule_3` |

更新でRPC名が変わる場合は `PROD_RPC` / `LOCAL_RPC` で上書きする。
引数 (`departure_station`, `arrival_station`, `target_date`) とレスポンス形式は共通であること。

## 使い方
```
export PROD_URL=... PROD_ANON_KEY=... LOCAL_ANON_KEY=$(supabase status -o env | sed -n 's/^ANON_KEY="\(.*\)"/\1/p')
node fetch.mjs prod && node fetch.mjs local && node diff.mjs
```
`out/report.md` (サマリ), `out/diff.json` (詳細), `out/{prod,local}/*.json` (生データ) が出力される。

注意: RPC は呼ぶたびに `search_history` へ1行 INSERT する。本番に投げると本番DBに検索履歴が書き込まれる。
本番に触れずに比較するときは、更新を当てる前のローカル(`supabase db reset` 直後、本番のコピー)を Before にする:
```
PROD_URL=http://127.0.0.1:54321 PROD_ANON_KEY=$LOCAL_ANON_KEY node fetch.mjs prod   # 更新前のローカル
# ここで更新SQLを適用
node fetch.mjs local && node diff.mjs                                              # 更新後のローカル
```

`cases.json` に検索頻度の高い停留所ペアと日付(平日/土/日/祝日/改正日前後)を書く。
