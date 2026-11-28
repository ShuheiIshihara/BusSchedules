# iOS アプリ(BusNow)

`20_Source/BusNow/` 配下で作業すると読み込まれる。リポジトリ全体の規約はルートの `CLAUDE.md` にある。

## 概要
ばすみるの iOS アプリ(App Store で公開中)。表示名は Release が `ばすみる`、Debug が `ばすみる_dev`。

## 技術スタック
- Swift / SwiftUI。MVVM + Service層
- 最低対応 iOS: 18.6(全ターゲットの `IPHONEOS_DEPLOYMENT_TARGET`)
- Supabase Swift SDK

### 構成
- **Models**: `StationPair`、`Stop`
- **ViewModels**: `StationSelectionViewModel`、`BusScheduleViewModel`
- **Services**:
  - `SupabaseService` — RPC を呼び、重複便を除外する(`deduplicatedSchedules`)
  - `SupabaseConfig` — Info.plist から `SUPABASE_DOMAIN` / `SUPABASE_ANON_KEY` を読む(ビルド構成ごとの xcconfig から `Info-Supabase.plist` 経由で埋め込まれる)
  - `StopNameRepository` — `Resources/stops.json` を元にしたバス停名の候補表示
  - `AppUpdateService` — App Store のアップデート確認
- **Views**: `StationSelectionView`、`Schedule/BusScheduleView`、`Common/`(WebView、設定、規約類、`StopSuggestionList`)、`Debug/`
- バス停名の候補表示: `StopNameRepository` と `StopSuggestionList` はあるが、`StationSelectionView` にはまだ組み込んでいない。仕様: `10_Document/02_基本設計/25_駅選択画面設計書.md` §3.2.3
- **Utils**: `StringNormalization`(`normalizedForSearch()` — 日本語テキストの正規化)
- **ローカライズ**: `ja.lproj`、`en.lproj`

## 検証コマンド(`20_Source/BusNow/` で実行)
この Mac のシミュレータは iOS 26.0 以上を使う(18.6 のランタイムは入っておらず、iPhone 16 のシミュレータは iOS 18.x のため使えない)。

```bash
xcodebuild -scheme BusNow -destination 'generic/platform=iOS Simulator' build
xcodebuild test -scheme BusNow -destination 'platform=iOS Simulator,name=iPhone 17'
xcodebuild test -scheme BusNow -destination 'platform=iOS Simulator,name=iPhone 17' -only-testing:BusNowTests/StringNormalizationTests
```

- **Claude は `xcodebuild` を自分で実行しない。**
- ビルド: Swift の変更があると、ターン終了時に Stop hook(`.claude/hooks/build-on-stop.sh`)が自動でビルドし、失敗したらエラーを返す。手動ではビルドしない
- テスト: 実行せず、コピー可能なコマンドを開発者に提示する。テスト一式より、変更に関係するテストクラス単位のコマンドを優先する
- レビュー: Swift を変更したら、コミット前にサブエージェント `ios-reviewer`(読み取り専用)に差分をレビューさせ、指摘を開発者に伝える
- `xcodebuild test` は、テストが終わったあとも10分以上プロセスが終了しないことがある。`Test Suite 'Selected tests' passed|failed` の行が出たら結果とみなし、プロセスは止めてよいと開発者に伝える

## プロジェクト固有の規約
- **最低対応 iOS は 18.6。** 機能追加・修正では最新の iOS の API を使う。必要な API が 18.6 で使えない場合は、最低対応を勝手に上げたり古い API で代替したりせず、その場で開発者に iOS の足切りを提案する(切り捨てる範囲も示す)。
- RPC を呼ぶ前に、駅名は必ず `normalizedForSearch()` を通す。
- `SupabaseService.deduplicatedSchedules` の重複除外ルールを変えたら、`scripts/check_dedup.py` と共通テストデータ `BusNowTests/Fixtures/dedup_cases.json` も合わせる。両側は同じデータで検証する(iOS: `DedupRuleTests`、Python: `python3 scripts/test_dedup_rule.py`)。Stop hook(`.claude/hooks/dedup-sync-on-stop.sh`)が Python 側を検証し、Swift 側だけが変わった場合は同期漏れとして止める。
- `StringNormalization` は Web アプリ(`20_Source/Web/src/utils/stringNormalization.ts`)にも同じ処理がある。Web が保留中の間は Swift 側の変更を反映しなくてよいが、あとで揃えられるよう変更点を残す。
- Release の表示名 `ばすみる` は変更しない。
- UI文言・エラーメッセージは日本語。

## 設定
Debug ビルドはローカルの Supabase、Release ビルドは本番に接続する。`Config-Debug.xcconfig.template` → `Config-Debug.xcconfig`、`Config-Release.xcconfig.template` → `Config-Release.xcconfig` とコピーして使う(どちらも gitignore 対象。ハーネスで読み取りを禁止している)。Release はローカル向けのドメインを受け付けない。本物のキーは絶対にコミットしない。

## テスト
- `BusNowTests/`: `BusNowTests`、`StringNormalizationTests`、`StopNameRepositoryTests`、`DedupRuleTests`
- `BusNowUITests/`: 起動と画面遷移
- **モックはまだない**(`Mocks/` ディレクトリなし)。`SupabaseService` を直接使っているため、それに依存する ViewModel のロジックは単独で単体テストできない。モックを追加するときは、`SupabaseService` からプロトコルを切り出し、`BusNowTests/Mocks/` に置く。
