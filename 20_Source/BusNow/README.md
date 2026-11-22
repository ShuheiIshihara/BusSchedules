# BusNow - iOS バス時刻表アプリ

## 🚀 初期設定

### 1. Supabase 設定（必須）

このプロジェクトはSupabaseデータベースを使用します。以下の手順で設定してください：

接続先はビルド構成ごとに切り替わります。

| ビルド構成 | 設定ファイル | 接続先 |
|---|---|---|
| Debug | `Config-Debug.xcconfig` | ローカルSupabase（DB更新の検証用） |
| Release | `Config-Release.xcconfig` | 本番Supabase |

#### xcconfig ファイルの作成
```bash
# 20_Source/BusNow/ で実行
cp Config-Debug.xcconfig.template Config-Debug.xcconfig
cp Config-Release.xcconfig.template Config-Release.xcconfig
```

`SUPABASE_DOMAIN` と `SUPABASE_ANON_KEY` を各ファイルに設定します（ローカルのキーは `supabase status` で確認）。

**注意**:
- SUPABASE_DOMAINにはドメイン名（`host[:port]`）のみを記録します。スキームはアプリ内で付与されます（`127.0.0.1` / `localhost` / プライベートIP / `.local` は `http://`、それ以外は `https://`）。
- 実機からローカルDBに接続する場合は、MacのLAN IP（例: `192.168.0.11:54321`）を指定します。
- Releaseビルドでローカル向けのドメインが設定されていると、`SupabaseConfig.isConfigured` が false になり接続しません。

**⚠️ 重要**: `Config-Debug.xcconfig` / `Config-Release.xcconfig` はGitにコミットされません。チームメンバーは各自で設定する必要があります。

### 2. Xcode設定

1. BusNow.xcodeproj をXcodeで開く
2. 設定済みの値（Debug / Release それぞれのxcconfig）は `Info-Supabase.plist` 経由でInfo.plistに埋め込まれます
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
- `Config-Debug.xcconfig` / `Config-Release.xcconfig` は .gitignore で除外済み
- 実行時にBundle.main.infoDictionaryから値を取得

## 📋 開発要件

- iOS 18.6+
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