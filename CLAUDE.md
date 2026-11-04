# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**BusNow** (display name: **ばすみる**) is an unofficial bus timetable service for Nagoya City Bus, built on GTFS-JP data stored in Supabase. It has two clients that share the same backend:

| Client | Location | Status |
|---|---|---|
| iOS app (SwiftUI) | `20_Source/BusNow/` | Released on the App Store |
| Web app (Vite + React + TypeScript SPA) | `20_Source/Web/` | Early scaffold; planned for Cloudflare Pages |

The web app is a parallel channel, not a replacement for the iOS app. Feature parity with iOS is the goal; shareable URLs (station pair in the query string) and PWA support are web-specific additions.

## Repository Layout

```
.
├── 10_Document/          # Specs and design docs (Japanese) — see "Design Documents"
├── 20_Source/
│   ├── BusNow/           # iOS app (Xcode project)
│   └── Web/              # Web app (npm project)
├── supabase/             # Supabase CLI project for local DB verification (see its README)
├── scripts/              # Python dev scripts (data generation, DB checks)
├── tools/db-compare/     # Node scripts comparing prod vs local RPC results
├── docs/                 # Test specs (e.g. supabase_test_spec.md)
├── reports/              # Generated check reports
└── .github/workflows/    # claude.yml (@claude action)
```

## iOS App (`20_Source/BusNow/`)

- **Pattern**: MVVM + Service layer, SwiftUI
- **Models**: `StationPair`, `Stop`
- **ViewModels**: `StationSelectionViewModel`, `BusScheduleViewModel`
- **Services**:
  - `SupabaseService` — calls RPCs and deduplicates trips (`deduplicatedSchedules`)
  - `SupabaseConfig` — reads `SUPABASE_DOMAIN` / `SUPABASE_ANON_KEY` from xcconfig
  - `StopNameRepository` — stop-name autocomplete backed by `Resources/stops.json`
  - `AppUpdateService` — App Store update check
- **Views**: `StationSelectionView`, `Schedule/BusScheduleView`, `Common/` (WebView, settings, legal pages, `StopSuggestionList`), `Debug/`
- **Utils**: `StringNormalization` (`normalizedForSearch()` — Japanese text normalization; mirrored in the web app)
- **Localization**: `ja.lproj`, `en.lproj`
- **Config**: copy `Config-Local.xcconfig.template` to `Config-Local.xcconfig` (git-ignored). Never commit real keys.

### Commands

```bash
cd 20_Source/BusNow && xcodebuild -scheme BusNow -destination 'platform=iOS Simulator,name=iPhone 16' build
cd 20_Source/BusNow && xcodebuild test -scheme BusNow -destination 'platform=iOS Simulator,name=iPhone 16'
cd 20_Source/BusNow && xcodebuild test -scheme BusNow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BusNowTests/StringNormalizationTests
```

### Tests

- `BusNowTests/`: `BusNowTests`, `StringNormalizationTests`, `StopNameRepositoryTests`
- `BusNowUITests/`: launch and navigation flows
- There are **no mock objects yet** (no `Mocks/` directory). `SupabaseService` is used directly, so ViewModel logic that depends on it cannot currently be unit-tested in isolation. When adding mocks, put them in `BusNowTests/Mocks/` behind a protocol extracted from `SupabaseService`.

## Web App (`20_Source/Web/`)

- **Stack**: Vite, React 19, TypeScript, react-router-dom, `@supabase/supabase-js`, Vitest, ESLint
- **Env**: copy `.env.example` to `.env.local` and set `VITE_SUPABASE_URL` / `VITE_SUPABASE_ANON_KEY`. The anon key is public by design (RLS); never use the service role key.
- **Shared logic**: `src/utils/stringNormalization.ts` must stay behaviorally identical to the Swift `StringNormalization`. Change both together and update tests on both sides.
- **Static data**: `public/data/stops.json` (generated, see `scripts/generate_stops_json.py`)
- Status: scaffold only (`App.tsx` + normalization util). The plan and task list are in `10_Document/06_Web版/`.

### Commands (run inside `20_Source/Web/`)

```bash
npm run typecheck
npm run lint
npm test
npm run build
```

Run `typecheck`, `lint` and `test` after every web change. Do not start `npm run dev` (long-lived).

## Backend: Supabase (GTFS-JP)

- Anonymous access with Row Level Security; public read-only data.
- There is a single hosted database (production). There is **no staging database**.
- Main RPC: `get_phase1_bus_schedule_3(departure_station, arrival_station, target_date)`, used by the iOS app (and the web app, per plan).
- DB changes (schema or timetable data) are verified first on a local Supabase stack (`supabase/`, Supabase CLI + Docker). Workflow: pull prod schema/data → apply the change locally → compare prod (before) vs local (after) with `tools/db-compare` / `scripts/compare_dbs.py`. See `supabase/README.md`.
- `supabase/migrations/` is tracked in git; `supabase/seed/` holds the prod data dump and is git-ignored.

- Other RPC/REST: `phase1_health_check`, `security_phase_info` (fallback health check).
- `target_date` is `yyyy-MM-dd`. Weekday/holiday is resolved by the DB via `serviceId` (`平日`, `日祝`, `平日メーグル`, `日祝メーグル`).
- Station names must be passed through `normalizedForSearch()` before calling the RPC.
- Schema / RLS reference: `10_Document/02_基本設計/Phase1_GTFS正確仕様版_基本セキュリティ設計.sql`
- Never write to the production database. Never commit `.env`, `.env.local`, or `Config-Local.xcconfig`.

## Scripts and Tools

| Path | Purpose |
|---|---|
| `scripts/generate_stops_json.py` | Builds `stops.json` for both iOS (`BusNow/Resources/`) and Web (`public/data/`) from `10_Document/05_多言語/translations.txt`. Run from repo root. |
| `scripts/check_dedup.py` | Checks RPC-result CSVs for duplicate trips using the same rules as `SupabaseService.deduplicatedSchedules`. Output: `reports/dedup_report.md` |
| `scripts/compare_dbs.py` | Calls prod (A) and local (B) RPCs with the same inputs and compares raw pre-dedup results. Reads `SUPABASE_A_*` / `SUPABASE_B_*` from root `.env` (see `.env.example`). |
| `tools/db-compare/` | Node version of the prod/local comparison (`fetch.mjs`, `diff.mjs`, `cases.json`). See its README. |

If the dedup rules in `SupabaseService` change, update `scripts/check_dedup.py` to match.

## Design Documents (`10_Document/`, Japanese)

Read the relevant document before implementing a feature or changing behavior.

| Topic | Document |
|---|---|
| Project plan | `01_要検定義/10_プロジェクト計画書.md` |
| Functional spec | `02_基本設計/20_仕様書.md` |
| Directory structure | `02_基本設計/21_ディレクトリ構造.md` |
| Architecture | `02_基本設計/22_アーキテクチャ設計書.md` |
| Class design | `02_基本設計/23_クラス設計書.md` |
| UI design spec | `02_基本設計/24_バス時刻表アプリ UIデザイン仕様書.md`, `02_基本設計/画面デザイン/` |
| Station selection screen | `02_基本設計/25_駅選択画面設計書.md` |
| GTFS data / Supabase implementation | `02_基本設計/Phase1_GTFS正確仕様版_実装ガイド.md`, `99_備忘録/SupabaseIntegrationGuide.md` |
| Security migration | `02_基本設計/段階的セキュリティ移行ガイド.md`, `02_基本設計/将来Phase移行準備計画.md` |
| Task lists | `03_タスク/次期実装タスク一覧.md`, `03_タスク/11_開発タスク.md` |
| Release / TestFlight | `04_リリース準備/` |
| Web version plan and tasks | `06_Web版/01_Web化方針・作戦.md`, `06_Web版/02_作業タスクリスト.md` |
| Supabase test spec | `docs/supabase_test_spec.md` |

Some documents predate the current implementation. If code and a document disagree, trust the code and point out the discrepancy.

## Key Features

- Departure/arrival stop selection with autocomplete (kanji and hiragana reading)
- Timetable list: departure time, route name, destination, platform; past departures grayed out
- Real-time clock (HH:MM:SS)
- Automatic weekday/holiday timetable selection
- Outbound (行き) / inbound (帰り) direction toggle
- In-app browser for bus approach (proximity) information
