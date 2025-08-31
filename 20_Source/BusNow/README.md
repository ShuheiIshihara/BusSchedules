# BusNow - iOS バス時刻表アプリ

## 🚀 初期設定

### 1. Supabase 設定（必須）

このプロジェクトはSupabaseデータベースを使用します。以下の手順で設定してください：

#### Config-Local.xcconfig ファイルの作成
```bash
# プロジェクトルートで実行
cp Config-Local.xcconfig.template Config-Local.xcconfig
```

#### 実際の値を設定
`Config-Local.xcconfig` を開き、以下の値を実際のSupabaseプロジェクトの値に変更：

```
SUPABASE_DOMAIN = your-project-ref.supabase.co
SUPABASE_ANON_KEY = your-actual-anon-public-key
```

**注意**: SUPABASE_DOMAINにはドメイン名のみを記録します。`https://`はアプリ内で自動付与されます。

**⚠️ 重要**: `Config-Local.xcconfig` はGitにコミットされません。チームメンバーは各自で設定する必要があります。

### 2. Xcode設定

1. BusNow.xcodeproj をXcodeで開く
2. Project設定 → Info タブ → Configurations で：
   - Debug: Config-Local.xcconfig を選択
   - Release: Config-Local.xcconfig を選択
3. Package Dependencies で Supabase Swift SDK を追加

詳細な手順は `BusNow/Services/SupabaseIntegrationGuide.md` を参照してください。

## 📁 プロジェクト構造

```
BusNow/
├── Application/
│   └── BusNowApp.swift
├── Models/
│   └── StationPair.swift
├── Views/
│   ├── StationSelectionView.swift
│   └── ContentView.swift
├── ViewModels/
│   └── StationSelectionViewModel.swift
├── Services/
│   ├── SupabaseService.swift
│   ├── SupabaseConfig.swift
│   └── SupabaseIntegrationGuide.md
└── Assets.xcassets/
```

## 🛠️ 開発状況

### ✅ 完了済み
- [x] Xcodeプロジェクト作成
- [x] 駅選択画面の実装
- [x] Supabase設定基盤（セキュア版）
- [x] 安全な設定管理システム

### 🔄 進行中
- [ ] Supabase Swift SDK統合
- [ ] データモデル実装
- [ ] バス時刻表メイン画面

詳細なタスク管理は `10_Document/03_タスク/11_開発タスク.md` を参照してください。

## 🔒 セキュリティ

- API キーやURLなどの機密情報は .xcconfig ファイルで管理
- `Config-Local.xcconfig` は .gitignore で除外済み
- 実行時にBundle.main.infoDictionaryから値を取得

## 📋 開発要件

- iOS 18.0+
- Xcode 16.4+
- Swift 5.10+
- Supabase Swift SDK 2.0.0+

## 🧪 テスト

設定が正しく行われているかは、アプリ起動時のコンソールログで確認できます：

```
=== Supabase Configuration Debug ===
Domain: 'your-project.supabase.co'
Constructed URL: 'https://your-project.supabase.co'
Key length: 110
Configuration status: ✅ Supabase設定が正常です (URL: https://your-project.supabase.co...)
=====================================
SupabaseService: クライアントが正常に初期化されました
Supabase接続状態: true
```