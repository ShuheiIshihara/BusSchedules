# TestFlight ベータ版アプリ説明文

## アプリ名
ばすみる (バス時刻表)

## ベータ版説明文（日本語）

家族でよく使用するバス路線の時刻表をまとめて管理できるアプリです。複数のバス路線を登録し、リアルタイムで現在時刻と照らし合わせて表示します。

**主な機能：**
- 複数バス路線の時刻表統合表示
- 行き・帰り方向の切り替えタブ
- リアルタイム時計表示（秒単位）
- 平日・土日祝日の自動判定と適切な時刻表選択
- 過去の出発時刻の自動グレーアウト
- バス接近情報の確認（アプリ内ブラウザ）
- 路線設定の追加・編集・削除

**ベータテストでの確認事項：**
1. 路線設定機能の動作確認
2. 時刻表データの正確な表示
3. タブ切り替えとリアルタイム更新
4. UIの直感性と使いやすさ
5. データベース連携の安定性
6. アプリの全体的な動作安定性

**技術的特徴：**
- Supabaseデータベースによるリアルタイムデータ管理
- MVVM + Service Layer アーキテクチャ
- SwiftUI による iOS ネイティブ実装

**注意事項：**
- 本アプリは各交通機関の非公式アプリです
- 時刻表データは参考程度にご利用ください
- 正確な運行情報は各交通機関の公式サイトをご確認ください
- プライベート配布専用（App Store非掲載）

## Beta Description (English)

A family-oriented app for managing and viewing multiple bus route timetables in a unified interface. Register commonly used bus routes and view them in real-time against the current time.

**Key Features:**
- Unified display of multiple bus route timetables
- Direction switching tabs (Outbound/Inbound)
- Real-time clock display with second precision
- Automatic weekday/weekend/holiday detection and appropriate timetable selection
- Automatic graying out of past departure times
- Bus approach information access (in-app browser)
- Route settings management (add/edit/delete)

**Beta Testing Focus:**
1. Route settings functionality
2. Accuracy of timetable data display
3. Tab switching and real-time updates
4. UI intuitiveness and usability
5. Database integration stability
6. Overall app stability

**Technical Features:**
- Supabase database for real-time data management
- MVVM + Service Layer architecture
- SwiftUI native iOS implementation

**Important Notes:**
- This is an unofficial app for various transportation agencies
- Timetable data should be used for reference only
- Please check official sources for accurate service information
- Private distribution only (not available on App Store)

## テスター向けフィードバック要請

以下の点について特にフィードバックをお願いします：

1. **路線設定機能**
   - 路線の追加・編集・削除は直感的に操作できますか？
   - GTFS路線IDの入力は分かりやすいですか？
   - 接近情報URLの設定は適切に動作しますか？

2. **時刻表表示**
   - 複数路線の統合表示は見やすいですか？
   - 行き・帰りのタブ切り替えはスムーズですか？
   - リアルタイム時計表示は適切ですか？
   - 過去の時刻のグレーアウトは分かりやすいですか？

3. **データ連携**
   - Supabaseからの時刻表データ読み込みは正常に動作しますか？
   - 祝日判定による時刻表切り替えは適切ですか？
   - データの読み込み速度は満足できますか？

4. **全体的な使用感**
   - アプリの起動や画面遷移は快適ですか？
   - エラーやクラッシュは発生しますか？
   - バッテリー消費は許容範囲ですか？

5. **改善要望**
   - 追加してほしい機能はありますか？
   - UI/UXで改善したい点はありますか？
   - より便利にするためのアイデアはありますか？

## 連絡先・フィードバック方法

フィードバックやバグレポートは以下の方法でお知らせください：

### 推奨方法
- **TestFlightアプリ内フィードバック機能**（最も迅速に対応）
- **GitHub Issues**: https://github.com/ShuheiIshihara/BusSchedules/issues

### フィードバック時の詳細情報
以下の情報も併せてお知らせいただけると、より迅速な改善が可能です：
- 使用デバイス（iPhone機種）
- iOS バージョン
- 問題が発生した具体的な操作手順
- エラーメッセージ（表示された場合）
- 期待していた動作と実際の動作の相違点

---

## AppStoreConnect外部テスト審査用情報

**アプリ名**: BusSchedules  
**開発者**: 家族チーム  
**バージョン**: 1.0 (ベータ)  
**対象OS**: iOS 18.0以降  
**配布方法**: プライベート配布（TestFlight）  
**審査カテゴリ**: 交通・ユーティリティ

**テスト目的**: 複数バス路線管理機能の実用性検証とUI/UX改善  
**テスト期間**: 初回リリース後30日間  
**テスター数**: 家族・友人を中心とした10名程度