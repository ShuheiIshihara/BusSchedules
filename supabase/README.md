# ローカル Supabase(DB更新の事前検証用)

本番DBの更新内容(スキーマ変更・時刻表データの入れ替え)を、本番に当てる前にローカルで検証するための環境。
Supabase CLI で Docker 上に Postgres / PostgREST / Auth を立て、本番と同じ RPC・RLS の経路で確認する。

- 必要なもの: Docker Desktop、Supabase CLI(`brew install supabase/tap/supabase`)
- 接続先: API `http://127.0.0.1:54321` / DB `postgresql://postgres:postgres@127.0.0.1:54322/postgres` / Studio `http://127.0.0.1:54323`
- 不要なサービス(realtime, storage, edge_runtime, analytics)は `config.toml` で無効化している

## 1. 初回: 本番のスキーマとデータを取り込む

本番への接続はログインとDBパスワードが必要なので、各自のターミナルで実行する(本番へは読み取りのみ)。

```bash
supabase login
supabase link --project-ref <本番のproject ref>
supabase start
supabase db pull                     # 本番スキーマを supabase/migrations/<日時>_remote_schema.sql として取り込む
supabase db dump --linked --data-only --schema public -f supabase/seed/prod_data.sql
supabase db reset                    # migrations → seed の順で適用
```

- 取り込み後、`python3 scripts/compare_row_counts.py` で本番とローカルの全テーブルのレコード数が一致することを確認する(本番へは読み取り専用で接続)
- `db pull` の最後に `Update remote migration history table? [Y/n]` と聞かれたら **n** と答える(Y は本番DBの履歴テーブルへの書き込みになる)
- ローカルの Postgres は本番と同じメジャーバージョンにする(`config.toml` の `major_version`、現在 15)
- `supabase/migrations/` は git 管理する(本番スキーマの履歴になる)
- `supabase/seed/` は本番データのダンプなので git 管理外

## 2. 更新内容を検証する

```bash
supabase migration new <変更内容>      # supabase/migrations/<日時>_<変更内容>.sql に更新SQLを書く
supabase db reset                    # 本番相当の状態から更新SQLまでを一括適用
```

時刻表データの入れ替えなど、マイグレーションにしないSQLは `psql` で直接流す。

```bash
psql postgresql://postgres:postgres@127.0.0.1:54322/postgres -f <更新SQL>
```

やり直すときは `supabase db reset` で本番相当の状態に戻る。

## 3. 本番(更新前)とローカル(更新後)を比較する

`supabase status -o env` の `API_URL` と `ANON_KEY` をローカルの接続先として使う。

- RPC単位の比較: [`tools/db-compare`](../tools/db-compare/README.md)
- 区間CSVでの生データ比較: `scripts/compare_dbs.py`(B=ローカル)
- 重複チェック: `scripts/check_dedup.py`

アプリで確認する場合は、iOS の `Config-Local.xcconfig` / Web の `.env.local` の接続先をローカルに向ける。
シミュレータからは `127.0.0.1` で届く。

## 4. 本番へ反映する

検証が済んだら本番に適用する。`supabase db push` は未適用のマイグレーションをすべて本番に流すので、
実行前に `supabase migration list` で対象を確認する。
取り込み時の `<日時>_remote_schema.sql` は本番に既にある内容なので、初回の push 前に
`supabase migration repair --status applied <日時>` で適用済みとして記録しておく。

## 停止

```bash
supabase stop
```
