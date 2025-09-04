# Supabase Swift SDK 統合ガイド（ドメイン分離版）

## 1. 設定ファイルの準備（重要：セキュリティ対応）

### 手順1: ローカル設定ファイルの作成
1. `Config-Local.xcconfig.template` を `Config-Local.xcconfig` にコピー
2. `Config-Local.xcconfig` を開き、実際のSupabase値を設定：
```
SUPABASE_DOMAIN = your-actual-project-ref.supabase.co
SUPABASE_ANON_KEY = your-actual-anon-public-key-here
```

**重要**: 
- `Config-Local.xcconfig` は自動的に .gitignore に追加されており、Gitにコミットされません
- **SUPABASE_DOMAINにはドメイン名のみを記録**します（`https://`は不要）
- URLの`https://`部分はアプリ内で自動付与されます

### URL構成の仕組み
```
設定ファイル: SUPABASE_DOMAIN = "your-project.supabase.co"
↓
アプリ内で結合: "https://" + ドメイン名
↓
最終URL: "https://your-project.supabase.co"
```

### 手順2: Xcode Build Configuration の設定
1. Xcodeでプロジェクト (BusNow.xcodeproj) を開く
2. Project Navigator でプロジェクトルートを選択
3. "Info" タブを選択
4. "Configurations" セクションで、Debug と Release の両方に対して：
   - "Based on Configuration File" で `Config-Local.xcconfig` を選択

### 手順3: Build Settings でのUser-Defined変数確認
1. Build Settings タブを開く
2. "All" と "Combined" を選択
3. "User-Defined" セクションに以下が表示されることを確認：
   - `SUPABASE_DOMAIN` (例: your-project.supabase.co)
   - `SUPABASE_ANON_KEY`

**注意**: 
- 現代のSwiftUIプロジェクトではInfo.plistは自動生成されます
- User-DefinedでURLが途切れる問題は、ドメイン名のみの記録により解決されます

## 2. Xcode Package Manager での SDK 追加手順

### Package Dependencies の追加
1. Project Navigator でプロジェクトルートを選択
2. "Package Dependencies" タブを選択
3. "+" ボタンをクリック
4. URL入力欄に `https://github.com/supabase/supabase-swift.git` を入力
5. "Add Package" をクリック
6. バージョンは "2.0.0" 以上を選択
7. "Supabase" product を選択して "Add Package" をクリック

## 3. SupabaseService の更新

### Import文の追加
SupabaseService.swiftの先頭に以下を追加：
```swift
import Supabase
```

### クライアント初期化コードの更新
```swift
import Foundation
import Supabase

class SupabaseService: ObservableObject {
    static let shared = SupabaseService()
    
    private var client: SupabaseClient?
    
    private init() {
        initializeClient()
    }
    
    private func initializeClient() {
        guard SupabaseConfig.isConfigured else {
            print("SupabaseConfig: \(SupabaseConfig.configurationStatus)")
            return
        }
        
        guard let url = URL(string: SupabaseConfig.supabaseUrl) else {
            print("SupabaseConfig: 無効なURLです - \(SupabaseConfig.supabaseUrl)")
            return
        }
        
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
        
        print("SupabaseService: クライアントが正常に初期化されました")
    }
    
    func testConnection() async -> Bool {
        guard let client = client else {
            print("SupabaseService: クライアントが初期化されていません")
            print(SupabaseConfig.configurationStatus)
            return false
        }
        
        do {
            // 簡単なテーブル存在確認
            let _: [String: Any] = try await client
                .from("stops")
                .select("stop_id")
                .limit(1)
                .execute()
                .value
            print("SupabaseService: 接続テスト成功")
            return true
        } catch {
            print("SupabaseService: 接続テスト失敗 - \(error.localizedDescription)")
            return false
        }
    }
}
```

## 4. 設定確認とテスト方法

### アプリ起動時の設定確認
```swift
// BusNowApp.swift で
SupabaseConfig.printDebugInfo()

Task {
    let isConnected = await SupabaseService.shared.testConnection()
    print("Supabase接続状態: \(isConnected)")
}
```

### デバッグ情報の出力例
```
=== Supabase Configuration Debug ===
Domain: 'your-project.supabase.co'
Constructed URL: 'https://your-project.supabase.co'
Key length: 110
Configuration status: ✅ Supabase設定が正常です (URL: https://your-project.supabase.co...)
=====================================
Supabase接続状態: true
```

## 5. 重要なセキュリティ注意事項

- ✅ `Config-Local.xcconfig` は .gitignore に追加済み
- ✅ 実際のAPIキーはGitにコミットされません
- ✅ ドメイン名のみ設定ファイルに記録、URLスキームはコード内で管理
- ✅ Bundle.main.infoDictionaryから実行時に値を取得
- ⚠️ `Config-Local.xcconfig` をチーム間で共有する際は安全な方法を使用
- ⚠️ 本番環境では追加のセキュリティ対策を検討してください

## 6. トラブルシューティング

### URL構成に関する問題
**問題**: User-DefinedでURLが"https:"までしか表示されない
**解決**: ドメイン分離方式により解決済み。SUPABASE_DOMAINにはドメイン名のみが表示されます

### 設定が反映されない場合
1. Xcode でプロジェクト設定の Configurations を確認
2. Build Settings の User-Defined セクションで変数が表示されるか確認
3. Clean Build Folder (Cmd+Shift+K) を実行
4. `Config-Local.xcconfig` の内容を確認
5. アプリ内で `SupabaseConfig.printDebugInfo()` を実行

### よくある問題と解決方法
- **空の値が返される**: xconfigファイルがBuild Configurationに正しく設定されていない
- **プレースホルダー値**: `Config-Local.xcconfig` に実際の値が設定されていない
- **ドメイン形式エラー**: SUPABASE_DOMAINが`.supabase.co`で終わっていない
- **URL構築失敗**: ドメイン名に`https://`が含まれている（不要）

## 7. この方式のメリット

1. **xcconfig互換性**: `//`コメント問題を完全回避
2. **Xcode表示**: User-Definedでドメイン名が正常表示
3. **コード明確性**: URLスキーム部分がコードで明示的
4. **設定管理**: ドメイン名のみで設定が簡潔
5. **セキュリティ**: 機密情報の分離は維持