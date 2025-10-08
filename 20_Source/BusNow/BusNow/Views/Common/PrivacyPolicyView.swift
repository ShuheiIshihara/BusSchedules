import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("プライバシーポリシー")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                    
                    privacyPolicyContent
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }
    
    private var privacyPolicyContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("最終更新日: 2024年12月13日")
                .font(.caption)
                .foregroundColor(.secondary)
            
            policySection(
                title: "1. 基本方針",
                content: """
                ばすみるアプリ（以下「本アプリ」）は、名古屋市バスの時刻表情報を提供するサービスです。ユーザーのプライバシーを尊重し、個人情報の保護に努めます。
                """
            )
            
            policySection(
                title: "2. 収集する情報",
                content: """
                本アプリでは以下の情報を収集します：

                • バス停検索履歴
                　- 出発地・到着地の組み合わせ
                　- 検索日時
                　
                • アプリ使用状況
                　- エラーログ（クラッシュレポート）
                　- 機能使用頻度
                
                注意: 個人を特定できる情報（氏名、電話番号、住所等）は一切収集しません。
                """
            )
            
            policySection(
                title: "3. 情報の利用目的",
                content: """
                収集した情報は以下の目的でのみ使用します：

                • バス時刻表情報の提供
                • アプリの機能改善
                • 技術的問題の解決
                • ユーザー体験の向上
                """
            )
            
            policySection(
                title: "4. データの保存と管理",
                content: """
                • 検索履歴はデバイス内にローカル保存されます
                • バス時刻表データはSupabase（クラウドデータベース）から取得します
                • データ通信は暗号化されています
                • サーバー上にユーザーの個人情報は保存されません
                """
            )
            
            policySection(
                title: "5. 第三者への提供",
                content: """
                本アプリは、以下の場合を除き、ユーザーの情報を第三者に提供しません：

                • 法令に基づく開示要求がある場合
                • ユーザーの同意がある場合
                • アプリの技術的運用に必要な範囲で信頼できるサービスプロバイダー（Supabase等）を利用する場合
                """
            )
            
            policySection(
                title: "6. データの削除",
                content: """
                ユーザーはいつでも以下の操作が可能です：

                • 検索履歴のクリア（アプリ内機能）
                • アプリのアンインストール（全データ削除）
                
                アプリをアンインストールすると、すべてのローカルデータが削除されます。
                """
            )
            
            policySection(
                title: "7. セキュリティ",
                content: """
                本アプリは、情報の安全性確保のため以下の対策を実施しています：

                • HTTPS通信による暗号化
                • 最小限の権限でのデータアクセス
                • 定期的なセキュリティアップデート
                """
            )
            
            policySection(
                title: "8. 免責事項",
                content: """
                • 本アプリは名古屋市バスの非公式アプリです
                • バス時刻表情報の正確性を保証するものではありません
                • 実際のバス運行状況は公式情報をご確認ください
                • 本アプリの利用により生じた損害について責任を負いません
                """
            )
            
            policySection(
                title: "9. プライバシーポリシーの変更",
                content: """
                本プライバシーポリシーは必要に応じて更新される場合があります。重要な変更がある場合は、アプリ内で通知いたします。
                """
            )
            
            policySection(
                title: "10. お問い合わせ",
                content: """
                プライバシーポリシーに関するご質問は、App Store のアプリページからお問い合わせください。
                """
            )
        }
    }
    
    private func policySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(content)
                .font(.body)
                .foregroundColor(.primary)
                .lineSpacing(4)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    PrivacyPolicyView()
}