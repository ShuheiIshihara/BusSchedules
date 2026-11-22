# Supabase(ローカルDBでの検証)

`supabase/` 配下で作業すると読み込まれる。リポジトリ全体の規約はルートの `CLAUDE.md` にある。手順の詳細は `supabase/README.md`。

## 概要
DBの変更(スキーマ・時刻表データ)を本番に反映する前に、Supabase CLI + Docker のローカル環境で検証するためのプロジェクト。

## プロジェクト固有の規約
- **本番DBには絶対に書き込まない。** ホストされたDBは本番の1つだけで、ステージングはない。本番への反映(`supabase db push`、`supabase migration repair`、`--linked` での書き込み、ホストされたDBへの `psql`)は開発者が手作業で行う。これらのコマンドはハーネスの hook が止める。
- **本番の RPC も呼ばない。** `get_phase1_bus_schedule_3` は呼ぶたびに `search_history` へ1行 INSERT するため、本番に向けて呼ぶと本番DBへの書き込みになる。比較の「変更前」は、本番ではなく変更適用前のローカル(本番のコピー)から取る。hook が `node fetch.mjs prod`(PROD_URL がローカルでない場合)、`compare_dbs.py`(A がローカルでなく `--offline` でもない場合)、ホストされた RPC への直接呼び出しを止める。
- DBの変更はすべて、まずローカルで検証する: 本番のスキーマ・データを取り込む → ローカルを本番のコピーに戻して変更前を取得 → ローカルに変更を適用 → 変更後を取得して比較する。手順はスキル `db-update-verify`。
- `supabase/migrations/` は git 管理する。`supabase/seed/`(本番データのダンプ)と `supabase/snippets/` の作業用クエリは gitignore 対象。
- DBスキーマの命名は英語。

## データの仕様
- メインの RPC: `get_phase1_bus_schedule_3(departure_station, arrival_station, target_date)`。ほかに `phase1_health_check`、`security_phase_info`(予備のヘルスチェック)。
- `target_date` は `yyyy-MM-dd`。平日・休日は DB が `serviceId`(`平日`、`日祝`、`平日メーグル`、`日祝メーグル`)で判定する。GTFS-JP 20260518 版のデータ(ローカルにのみ投入済み、本番は未反映)では `日祝` が `日休` に変わる。
- 匿名の読み取り専用アクセスで、RLS(行レベルセキュリティ)あり。スキーマ / RLS の資料: `10_Document/02_基本設計/Phase1_GTFS正確仕様版_基本セキュリティ設計.sql`

## ローカル環境
- API: `http://127.0.0.1:54321`、Postgres: `postgresql://postgres:postgres@127.0.0.1:54322/postgres`。ローカルの anon キーは `supabase status -o env` で確認する。
- iOS の Debug ビルドはローカル環境に接続する。シミュレータからは `127.0.0.1` で届く。

## 検証コマンド(変更前と変更後の比較)
- RPC 単位: `tools/db-compare`。そのディレクトリで、変更前は `PROD_URL=http://127.0.0.1:54321 PROD_ANON_KEY=$LOCAL_ANON_KEY node fetch.mjs prod`、変更後は `node fetch.mjs local && node diff.mjs`
- 重複除外前の生データ: `scripts/compare_dbs.py`(既定は A = 本番なので、`SUPABASE_A_URL=http://127.0.0.1:54321` を付けるか `--offline` で取得済み CSV 同士を比べる)
- 重複便: `scripts/check_dedup.py` → `reports/dedup_report.md`
