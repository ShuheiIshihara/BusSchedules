# BusNow - iOS バス時刻表アプリ

![iOS](https://img.shields.io/badge/iOS-18.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.10%2B-orange)
![Xcode](https://img.shields.io/badge/Xcode-16.4%2B-blue)
![License](https://img.shields.io/badge/License-MIT-green)

**⚠️ 非公式アプリ**: このアプリは名古屋市営バスの公式アプリではありません。個人開発による非公式アプリです。

名古屋市営バス専用の時刻表管理アプリ。GTFS-JP形式のデータを使用して、複数のバス路線の時刻表と接近情報を一つのアプリで管理できます。

## ✨ 主な機能

- 🚌 **名古屋市営バス専用**: 名古屋市営バス路線の時刻表を管理
- 📊 **GTFS-JP準拠**: 標準的なGTFS-JP形式データを使用
- 📅 **平日・土日祝対応**: 日付に応じて適切な時刻表を自動選択
- ⏰ **リアルタイム**: 現在時刻表示と次のバスへの自動フォーカス
- 🔄 **行き・帰り対応**: 停留所の入れ替えで往復両方向の時刻表を表示
- 📍 **接近情報**: バス接近状況をアプリ内で確認
- 🎯 **スマートフォーカス**: 現在時刻に最も近い未到着バスを自動表示

## 🏗️ アーキテクチャ

- **Pattern**: MVVM + Service Layer
- **UI Framework**: SwiftUI
- **Database**: Supabase (PostgreSQL) 
- **Data Format**: GTFS-JP (General Transit Feed Specification - Japan)
- **Target**: 名古屋市営バス専用（非公式）
- **Authentication**: Anonymous access
- **Distribution**: Private (非App Store配布)

### 主要コンポーネント

```
20_Source/BusNow/BusNow/
├── Models/               # データモデル
│   └── StationPair.swift
├── ViewModels/           # MVVM ViewModels
│   ├── BusScheduleViewModel.swift
│   └── StationSelectionViewModel.swift
├── Views/                # SwiftUI Views
│   ├── StationSelectionView.swift
│   └── Schedule/
│       └── BusScheduleView.swift
├── Services/             # ビジネスロジック層
│   ├── SupabaseService.swift
│   └── SupabaseConfig.swift
├── Utils/                # ユーティリティ
│   └── StringNormalization.swift
├── Assets.xcassets       # アプリアセット
└── BusNowApp.swift      # アプリエントリーポイント
```

## 🚀 セットアップ

### 前提条件

- iOS 18.0+
- Xcode 16.4+
- Swift 5.10+
- Supabase プロジェクト

### 1. リポジトリのクローン

```bash
git clone [repository-url]
cd BusSchedules
```

### 2. Supabase設定

```bash
cd 20_Source/BusNow
cp Config-Local.xcconfig.template Config-Local.xcconfig
```

`Config-Local.xcconfig` を編集してSupabaseの設定を追加：

```
SUPABASE_DOMAIN = your-project-ref.supabase.co
SUPABASE_ANON_KEY = your-actual-anon-public-key
```

### 3. Xcodeプロジェクトを開く

```bash
open BusNow.xcodeproj
```

## 📱 使い方

### 基本的な操作

1. **停留所選択**: 出発停留所と到着停留所を選択（名古屋市営バス停留所のみ）
2. **時刻表表示**: 現在日時に応じた時刻表を表示
3. **方向切り替え**: 行き・帰りボタンで往復の時刻表を表示
4. **日付切り替え**: 平日・土日祝ボタンで適切な時刻表を選択

### スマート機能

- **自動日付判定**: 本日が平日か土日祝かを自動判定
- **日付計算**: 
  - 平日に土日祝ボタン → 次の土曜日の時刻表
  - 土日祝に平日ボタン → 次の月曜日の時刻表
- **次のバス表示**: 現在時刻以降の最初のバスを自動ハイライト
- **経過時間表示**: 次のバスまでの残り時間を表示

## 🗄️ データベース構造

### GTFS-JP準拠データ

このアプリは **GTFS-JP (General Transit Feed Specification - Japan)** 形式のデータを使用しています。

### 主要テーブル

- `stops`: 停留所情報（名古屋市営バス停留所）
- `routes`: 路線情報
- `trips`: 便情報
- `stop_times`: 時刻表データ
- `calendar`: サービス日情報（平日・土日祝）
- `calendar_dates`: 祝日・特別運行日

### データソース

- **対象事業者**: 名古屋市営バスのみ
- **データ形式**: GTFS-JP標準仕様
- **更新頻度**: 定期的なデータ更新

### データアクセス

- **認証**: 匿名アクセス（ユーザー登録不要）
- **セキュリティ**: Row Level Security (RLS) で公開データアクセス制御
- **API**: Supabase REST API + RPC関数

## 🧪 テスト

### ユニットテスト

```bash
cd 20_Source/BusNow
xcodebuild test -scheme BusNow -destination 'platform=iOS Simulator,name=iPhone 16'
```

### 特定のテスト実行

```bash
# 文字正規化テスト
cd 20_Source/BusNow
xcodebuild test -scheme BusNow -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:BusNowTests/StringNormalizationTests
```

## 🔒 セキュリティとプライバシー

- **設定ファイル分離**: 機密情報は `.xcconfig` で管理
- **Git除外**: `Config-Local.xcconfig` は `.gitignore` で除外
- **匿名アクセス**: ユーザー登録不要、個人情報収集なし
- **プライバシー保護**: 位置情報やデバイス識別情報は一切収集しません
- **詳細**: [プライバシーポリシー](PRIVACY_POLICY.md)をご確認ください

## 📋 開発状況

### ✅ 実装済み

- [x] Xcodeプロジェクト作成とSupabase SDK統合
- [x] 停留所選択機能（名古屋市営バス停留所）
- [x] Supabase設定基盤（セキュア版）
- [x] 文字正規化対応
- [x] StationPairモデル実装

### 🔄 今後の予定

- [ ] バス時刻表表示（GTFS-JPデータ使用）
- [ ] 平日・土日祝切り替え
- [ ] 行き・帰り切り替え
- [ ] リアルタイム時計
- [ ] 次のバス自動フォーカス
- [ ] 接近情報連携
- [ ] プッシュ通知
- [ ] お気に入り機能

## 🛠️ 開発コマンド

### ビルド

```bash
cd 20_Source/BusNow
xcodebuild -scheme BusNow -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### 型チェック

```bash
cd 20_Source/BusNow
xcodebuild -scheme BusNow -destination 'platform=iOS Simulator,name=iPhone 16' -configuration Debug -showBuildSettings | grep SWIFT_ENFORCE_EXCLUSIVE_ACCESS
```

## 📖 ドキュメント

- [CLAUDE.md](CLAUDE.md) - Claude Code用プロジェクトガイド
- [開発ガイド](20_Source/BusNow/README.md) - 詳細な開発情報
- [プライバシーポリシー](PRIVACY_POLICY.md) - 個人情報の取り扱いについて
- API仕様書: Supabaseダッシュボードを参照

## 🤝 コントリビュート

このプロジェクトはオープンソースです。コントリビュートを歓迎します！

### 貢献方法

1. このリポジトリをフォーク
2. フィーチャーブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m '追加: すばらしい機能'`)
4. ブランチをプッシュ (`git push origin feature/amazing-feature`)
5. プルリクエストを開く

### コミットメッセージ規約

```
動詞: 変更内容の簡潔な説明

例:
- 追加: ユーザー認証機能
- 修正: ログインバリデーションエラー  
- 改善: バス時刻表の表示領域を拡大
```

## 📄 ライセンス

このプロジェクトは [MIT License](LICENSE) の下で公開されています。

MIT Licenseにより、以下が許可されています：
- **使用**: 個人・商用問わず自由に使用
- **改変**: ソースコードの修正・カスタマイズ
- **配布**: アプリケーションの再配布
- **販売**: 商用利用・販売

詳細は [LICENSE](LICENSE) ファイルをご確認ください。

---

## ⚠️ 免責事項

- このアプリは名古屋市営バスの公式アプリではありません
- 個人開発による非公式アプリです
- 時刻表データの正確性については公式情報をご確認ください
- 運行遅延や運行停止情報は公式サイトでご確認ください

**開発者**: 家族チーム  
**最終更新**: 2025年9月