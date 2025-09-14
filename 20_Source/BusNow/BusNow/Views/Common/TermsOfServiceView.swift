import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("利用規約")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 20)
                    
                    termsContent
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
    
    private var termsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("最終更新日: 2024年12月13日")
                .font(.caption)
                .foregroundColor(.secondary)
            
            termSection(
                title: "1. はじめに",
                content: """
                本利用規約（以下「本規約」）は、ばすみるアプリ（以下「本アプリ」）の利用に関する条件を定めるものです。本アプリをご利用いただく前に、必ず本規約をお読みください。
                """
            )
            
            termSection(
                title: "2. アプリの概要",
                content: """
                本アプリは、名古屋市バスの時刻表情報を提供する非公式アプリケーションです。

                主な機能：
                • バス停間の時刻表検索
                • リアルタイム時刻表示
                • 検索履歴の保存
                • バス接近情報への連携
                """
            )
            
            termSection(
                title: "3. 利用条件",
                content: """
                本アプリをご利用いただくには、以下の条件に同意していただく必要があります：

                • 18歳以上であること、または保護者の同意を得ていること
                • 本規約及びプライバシーポリシーに同意すること
                • 法令を遵守すること
                • 他者の権利を侵害しないこと
                """
            )
            
            termSection(
                title: "4. 禁止事項",
                content: """
                本アプリの利用にあたり、以下の行為を禁止します：

                • アプリの機能を悪用する行為
                • 不正アクセスやハッキング行為
                • 他者の迷惑となる行為
                • 商用利用や営利目的での使用
                • リバースエンジニアリングや解析行為
                """
            )
            
            termSection(
                title: "5. 情報の正確性について",
                content: """
                • 本アプリは名古屋市バスの非公式アプリです
                • 提供するバス時刻表情報は参考情報です
                • 情報の正確性や最新性を保証するものではありません
                • 実際のバス運行状況は公式情報を必ずご確認ください
                • 運行遅延や運休等の情報は反映されない場合があります
                """
            )
            
            termSection(
                title: "6. 免責事項",
                content: """
                以下の事項について、開発者は一切の責任を負いません：

                • 本アプリの利用により生じた損害
                • 情報の誤りによる損失や機会損失
                • アプリの動作不良やサービス中断
                • 第三者サービスとの連携エラー
                • データの消失や破損
                """
            )
            
            termSection(
                title: "7. 知的財産権",
                content: """
                • 本アプリのソフトウェア、デザイン、コンテンツの著作権は開発者に帰属します
                • ユーザーには本アプリの個人利用に関する限定的な使用権のみが付与されます
                • バス時刻表データは各交通事業者に帰属します
                """
            )
            
            termSection(
                title: "8. サービスの変更・終了",
                content: """
                開発者は以下の権利を有します：

                • 予告なくアプリの機能を変更すること
                • メンテナンスやアップデートの実施
                • サービスの一時停止や終了
                • 利用規約の変更
                
                重要な変更については、可能な限り事前に通知いたします。
                """
            )
            
            termSection(
                title: "9. プライバシー",
                content: """
                個人情報の取り扱いについては、別途定めるプライバシーポリシーをご確認ください。本規約とプライバシーポリシーが矛盾する場合は、プライバシーポリシーが優先されます。
                """
            )
            
            termSection(
                title: "10. 規約の変更",
                content: """
                本規約は必要に応じて変更される場合があります。重要な変更がある場合は、アプリ内で通知いたします。変更後も本アプリを継続してご利用いただく場合、変更後の規約に同意したものとみなします。
                """
            )
            
            termSection(
                title: "11. 準拠法・管轄裁判所",
                content: """
                本規約は日本法に準拠します。本アプリに関する紛争が生じた場合は、開発者の所在地を管轄する裁判所を専属的合意管轄とします。
                """
            )
            
            termSection(
                title: "12. お問い合わせ",
                content: """
                本規約に関するご質問は、App Store のアプリページからお問い合わせください。
                """
            )
        }
    }
    
    private func termSection(title: String, content: String) -> some View {
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
    TermsOfServiceView()
}