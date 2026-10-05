# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**BusNow / ばすみる** is an unofficial bus timetable app for **Nagoya City Bus only**. Timetable data is GTFS-JP, stored in Supabase (PostgreSQL) and read anonymously via RPC.

The repo holds two clients that share one Supabase backend:

| Client | Path | Status |
|---|---|---|
| iOS app (SwiftUI) | `20_Source/BusNow/` | Released (App Store; `AppUpdateService` checks the iTunes lookup API) |
| Web app "busmiru" (Vite + React + TS) | `20_Source/Web/` | In progress. `App.tsx` is still the Vite template; only `utils/stringNormalization.ts` is ported. Plan: `10_Document/06_Web版/` |

Display names: `ばすみる` (ja, Release), `ばすみる_dev` (Debug), `BusNow` (en).

## Repository Layout

```
10_Document/            # Specs & plans (Japanese). 02_基本設計 = design, 03_タスク = tasks, 06_Web版 = Web plan
20_Source/
├── BusNow/             # iOS Xcode project (BusNow.xcodeproj)
│   ├── BusNow/
│   │   ├── Models/         # StationPair, Stop
│   │   ├── ViewModels/     # StationSelectionViewModel, BusScheduleViewModel
│   │   ├── Views/          # StationSelectionView, Schedule/, Common/ (WebView, settings, suggestions…), Debug/
│   │   ├── Services/       # SupabaseService, SupabaseConfig, StopNameRepository, AppUpdateService
│   │   ├── Utils/          # StringNormalization
│   │   └── Resources/      # stops.json (GENERATED)
│   ├── BusNowTests/        # StringNormalizationTests, StopNameRepositoryTests (no Mocks/ dir yet)
│   └── BusNowUITests/
└── Web/                # Vite + React + TS (package name "busmiru")
    ├── src/utils/stringNormalization.ts (+ .test.ts)
    └── public/data/stops.json (GENERATED)
scripts/                # Python dev scripts (stops.json generation, dedup check, DB compare)
tools/db-compare/       # Node script: compare prod vs staging RPC output (also a manual GitHub Action)
reports/, docs/         # Generated reports, Supabase test spec
```

## Development Commands

### iOS (macOS + Xcode only)
- Build: `cd 20_Source/BusNow && xcodebuild -scheme BusNow -destination 'platform=iOS Simulator,name=iPhone 16' build`
- Test: `cd 20_Source/BusNow && xcodebuild test -scheme BusNow -destination 'platform=iOS Simulator,name=iPhone 16'`
- Single test class: append `-only-testing:BusNowTests/StringNormalizationTests`
- Requires `20_Source/BusNow/Config-Local.xcconfig` (copy from `Config-Local.xcconfig.template`; git-ignored). `SUPABASE_DOMAIN` is the bare domain — `https://` is added in code.

### Web
- `cd 20_Source/Web && npm ci`
- `npm test` (vitest), `npm run lint`, `npm run typecheck`, `npm run build`, `npm run dev`
- Env: `20_Source/Web/.env` from `.env.example` (`VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`)

### Scripts (run from repo root)
- `python3 scripts/generate_stops_json.py` — regenerate both `stops.json` files from `10_Document/05_多言語/translations.txt`
- `python3 scripts/check_dedup.py <csv>` — verify dedup rule against RPC result CSV
- `python3 scripts/compare_dbs.py <pairs.csv> --date YYYY-MM-DD` — compare prod (A) vs staging (B) raw RPC output; reads `./.env` (see root `.env.example`)

## Cloud / Linux Sessions

Claude Code cloud sessions run on Linux: **`swift` and `xcodebuild` are not available**. For Swift changes:
- You cannot compile or run tests — re-read the diff carefully, keep changes minimal, and state in the PR that the change is unbuilt and needs verification in Xcode.
- Do not edit `project.pbxproj` by hand unless unavoidable (adding a new Swift file requires it; mention this in the PR).

Web (`npm test` / `lint` / `typecheck`) and Python scripts can be run and should be run before pushing Web/script changes.

## Backend (Supabase)

- Anonymous access with RLS. Only the **anon key** is used in clients; never use or commit a `service_role` key.
- Two databases:

  | Env | Main RPC | Used by |
  |---|---|---|
  | Production | `get_phase1_bus_schedule_3` | iOS app (`SupabaseService.getBusSchedules`) |
  | Staging | `get_bus_schedule_2026` | Verification of next data revision |

  Both take `departure_station`, `arrival_station`, `target_date` (`yyyy-MM-dd`) and return the same keys. Health check RPC: `phase1_health_check`.
- Station names are passed through `normalizedForSearch()` before the RPC call.
- **Dedup rule** (`SupabaseService.deduplicatedSchedules`): the RPC can return the same trip multiple times (loop lines / stops passed twice). Rows with the same `(departureTime, routeName, destination)` are collapsed, keeping the earliest `arrivalTime`; original order is kept. `scripts/check_dedup.py` implements the same rule — change both together.
- SQL schema/security reference: `10_Document/02_基本設計/Phase1_GTFS正確仕様版_基本セキュリティ設計.sql`.

## Japanese Text Normalization (important)

Stop names contain しんにょう variants. The DB stores `辻` **with** variation selector U+E0100 (`辻󠄀`).
- `normalizeForSearch`: NFC → append U+E0100 to `辻` only (matching DB notation; `込・迫・追` DB notation unconfirmed) → whitespace normalization.
- `normalizeForDisplay`: NFC → append U+E0100 to all of `辻・込・迫・追` → whitespace normalization.
- The Swift (`Utils/StringNormalization.swift`) and TS (`src/utils/stringNormalization.ts`) implementations **must produce identical output**. When changing one, change the other and its tests. `scripts/compare_dbs.py` also has a `search_form` copy.
- Files contain invisible characters (U+E0100, U+3000). Edit with care; don't let editors strip them.

## Generated Files — do not hand-edit

- `20_Source/BusNow/BusNow/Resources/stops.json` and `20_Source/Web/public/data/stops.json` → regenerate with `scripts/generate_stops_json.py`.
- `tools/db-compare/out/`, `reports/compare/raw_*.csv` are git-ignored outputs.

## Conventions

- **Language**: Code comments, docs, commit messages, and PR descriptions are in **Japanese**.
- **Commit messages**: one-line Japanese summary describing the change (e.g. `時刻表RPC結果の重複便を除去`). The `git-commit` skill in `.claude/skills/` generates these.
- **Secrets**: never commit `Config-Local.xcconfig`, `.env`, or real Supabase URLs/keys. Scripts must not print key values.
- **Debug logging** in Swift is wrapped in `#if DEBUG`.
- Keep `10_Document` design docs in sync when changing behavior they describe.

## CI

- `.github/workflows/claude.yml`: runs Claude Code on `@claude` mentions in issues/PRs (label `opus` switches model).
- `.github/workflows/db-compare.yml`: manual (`workflow_dispatch`) prod vs staging comparison; never fails on diffs.
- There is **no CI build/test** for iOS or Web yet.
