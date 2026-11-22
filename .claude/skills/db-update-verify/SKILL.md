---
name: db-update-verify
description: Supabase のスキーマ変更や時刻表データの更新をローカル環境で検証し、本番に触れずに変更前後の結果を比較する。「DB更新」「時刻表データ更新」「ローカルDBで検証」と言われたときに使う。
---

# DB Update Verification (local Supabase)

Verify a DB change (schema migration or GTFS-JP timetable data swap) on the local Supabase stack, then compare before vs after. Production is never written to. Details in Japanese: `supabase/README.md`, `tools/db-compare/README.md`.

## Hard rules

- **Never write to production.** Do not run `supabase db push`, `supabase migration repair`, `--linked` writes, or `psql` against a hosted host. The guard hook blocks these; applying to production is the developer's manual step.
- **Calling the RPC writes to `search_history`.** `get_phase1_bus_schedule_3` inserts one row per call. Running `node fetch.mjs prod` with the real production URL, or `scripts/compare_dbs.py` with A = production, writes search history into the production DB. Use a local "before" snapshot instead (step 3). Only call production if the developer explicitly approves it for this run.
- Steps that need the production password or `supabase login` (`link`, `db pull`, `db dump --linked`) are run by the developer in their own terminal. Give them the commands; do not run them.

## Steps

### 1. Make sure local mirrors production (developer, first time or when stale)

Ask the developer to run in their terminal:

```bash
supabase link --project-ref <prod project ref>
supabase start
supabase db pull        # answer "n" to "Update remote migration history table?"
supabase db dump --linked --data-only --schema public -f supabase/seed/prod_data.sql
supabase db reset
python3 scripts/compare_row_counts.py   # all table counts must match (read-only on prod)
```

If `supabase/seed/prod_data.sql` exists and the developer says it is current, skip to step 2.

### 2. Reset local to the production copy

```bash
supabase start
supabase db reset
supabase status -o env   # LOCAL API_URL / ANON_KEY
```

### 3. Capture "before" from local (not production)

Inside `tools/db-compare/`, with `LOCAL_ANON_KEY` taken from `supabase status -o env`:

```bash
PROD_URL=http://127.0.0.1:54321 PROD_ANON_KEY=$LOCAL_ANON_KEY node fetch.mjs prod
```

Edit `cases.json` first if the change affects specific stop pairs or dates (weekday / Sat / Sun / holiday / around the timetable revision date).

### 4. Apply the change locally

- Schema change: `supabase migration new <name>`, write SQL into the new file under `supabase/migrations/`, then `supabase db reset`. Note: `db reset` restores the production copy, so re-run step 3 afterwards if "before" must exclude the migration.
- Data swap (not a migration): `psql postgresql://postgres:postgres@127.0.0.1:54322/postgres -f <update.sql>`

### 5. Capture "after" and diff

```bash
node fetch.mjs local && node diff.mjs
```

Read `out/report.md` (summary) and `out/diff.json` (details).

### 6. Check duplicates (dedup rules)

For RPC-result CSVs (`h_departure_station,h_arrival_station,h_result_json`):

```bash
python3 scripts/check_dedup.py <result.csv> [--sample N]
```

Output: `reports/dedup_report.md`. Rules mirror `SupabaseService.deduplicatedSchedules`.

### 7. Optional: check in the app

iOS Debug builds connect to the local stack (`127.0.0.1` from the simulator). Suggest the developer run the app against it.

## Report to the developer

- What changed (migration file name or SQL file), which cases were compared
- Summary from `out/report.md`: pairs/dates with differences, and whether each difference is expected
- Dedup result
- Known data facts to watch: `serviceId` values (`平日`, `日祝`, `平日メーグル`, `日祝メーグル`); the GTFS-JP 20260518 data renames `日祝` → `日休`
- The production apply commands (`supabase migration list`, then `supabase db push`) as text for the developer to run — never run them
