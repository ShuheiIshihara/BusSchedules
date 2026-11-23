# BusNow(ばすみる)

## 概要
名古屋市営バスの非公式時刻表サービス。Supabase に格納した GTFS-JP データを、2つのクライアントが共通のバックエンドとして使う。

| クライアント | 場所 | 状況 |
|---|---|---|
| iOS アプリ(SwiftUI) | `20_Source/BusNow/` | App Store で公開中 |
| Web アプリ(Vite + React + TypeScript SPA) | `20_Source/Web/` | **保留中**(2026-11-15〜)。雛形のみ |

**現在の優先事項**(`10_Document/03_タスク/次期実装タスク一覧.md`): iOS 開発を継続する。時刻表データの更新も継続し、必ずローカルDBで先に検証する。Web アプリは保留中なので、依頼がない限り触らない。

領域ごとの規約はコードの近くに置いてあり、その配下で作業すると読み込まれる: `20_Source/BusNow/CLAUDE.md`(iOS)、`20_Source/Web/CLAUDE.md`(Web)、`supabase/CLAUDE.md`(DB検証)。

## 技術スタック
- iOS: Swift / SwiftUI(MVVM + Service層)
- Web: Vite、React 19、TypeScript(保留中)
- バックエンド: Supabase(PostgreSQL、GTFS-JP)。匿名・読み取り専用、RLS あり。メインの RPC は `get_phase1_bus_schedule_3`
- 開発用スクリプト: Python(`scripts/`)、Node(`tools/db-compare/`)

## 検証コマンド
各領域の CLAUDE.md を参照する(iOS のビルド・テストは `20_Source/BusNow/CLAUDE.md`)。

## リポジトリ構成

```
.
├── 10_Document/          # 仕様書・設計書(日本語)。「設計資料」を参照
├── 20_Source/
│   ├── BusNow/           # iOS アプリ(Xcode プロジェクト)
│   └── Web/              # Web アプリ(npm プロジェクト、保留中)
├── supabase/             # ローカルDB検証用の Supabase CLI プロジェクト
├── scripts/              # Python の開発用スクリプト(データ生成、DBチェック)
├── tools/db-compare/     # 本番とローカルの RPC 結果を比較する Node スクリプト
├── docs/                 # テスト仕様(例: supabase_test_spec.md)
├── reports/              # 生成されたチェックレポート
└── .claude/              # 共有ハーネス: settings.json(権限・hooks)、hooks/、skills/
```

## プロジェクト固有の規約
- **本番DBには絶対に書き込まない。** ホストされたDBは本番の1つだけで、ステージングはない。DBの変更はローカル環境で先に検証する(`supabase/CLAUDE.md`)。
- **秘密情報ファイルを読まない・コミットしない**: ルートの env ファイル、`20_Source/Web/.env.local`、`Config-Debug.xcconfig`、`Config-Release.xcconfig`。`.claude/settings.json` と `.claude/hooks/guard-bash.sh` で強制しているため、これらのファイル名がコマンドに含まれるだけで止まる(コミットメッセージも同様)。その場合は `git commit -F <ファイル>` を使う。
- UI文言・エラーメッセージ: 日本語
- DBスキーマの命名: 英語
- 技術ドキュメント: 英語
- 実装より古いドキュメントがある。コードとドキュメントが食い違うときはコードを正とし、食い違いを指摘する。

## スクリプトとツール

| パス | 用途 |
|---|---|
| `scripts/generate_stops_json.py` | `10_Document/05_多言語/translations.txt` から iOS(`BusNow/Resources/`)と Web(`public/data/`)両方の `stops.json` を生成する。リポジトリのルートで実行する。 |
| `scripts/check_dedup.py` | `SupabaseService.deduplicatedSchedules` と同じルールで、RPC 結果の CSV に重複便がないかを調べる。出力: `reports/dedup_report.md`。ルールが iOS と同じかは `scripts/test_dedup_rule.py` で検証する |
| `scripts/compare_dbs.py` | 本番(A)とローカル(B)の RPC を同じ入力で呼び、重複除外前の生データを比較する。 |
| `tools/db-compare/` | 本番とローカルの比較の Node 版(`fetch.mjs`、`diff.mjs`、`cases.json`)。README を参照。 |

## 設計資料(`10_Document/`、日本語)
機能を実装したり挙動を変えたりする前に、該当する資料を読む。

| 内容 | 資料 |
|---|---|
| プロジェクト計画 | `01_要検定義/10_プロジェクト計画書.md` |
| 機能仕様 | `02_基本設計/20_仕様書.md` |
| ディレクトリ構造 | `02_基本設計/21_ディレクトリ構造.md` |
| アーキテクチャ | `02_基本設計/22_アーキテクチャ設計書.md` |
| クラス設計 | `02_基本設計/23_クラス設計書.md` |
| UIデザイン仕様 | `02_基本設計/24_バス時刻表アプリ UIデザイン仕様書.md`、`02_基本設計/画面デザイン/` |
| 駅選択画面 | `02_基本設計/25_駅選択画面設計書.md` |
| GTFSデータ / Supabase の実装 | `02_基本設計/Phase1_GTFS正確仕様版_実装ガイド.md`、`99_備忘録/SupabaseIntegrationGuide.md` |
| セキュリティ移行 | `02_基本設計/段階的セキュリティ移行ガイド.md`、`02_基本設計/将来Phase移行準備計画.md` |
| タスク一覧 | `03_タスク/次期実装タスク一覧.md`、`03_タスク/11_開発タスク.md` |
| リリース / TestFlight | `04_リリース準備/` |
| Web版の方針・タスク | `06_Web版/01_Web化方針・作戦.md`、`06_Web版/02_作業タスクリスト.md` |
| Supabase のテスト仕様 | `docs/supabase_test_spec.md` |

## 主な機能
- 出発・到着バス停の選択と候補表示(漢字・ひらがな読み)
- 時刻表一覧: 発車時刻、路線名、行き先、のりば。発車済みの便はグレー表示
- リアルタイム時計(HH:MM:SS)
- 平日・休日ダイヤの自動選択
- 行き・帰りの切り替え
- バス接近情報のアプリ内ブラウザ表示
