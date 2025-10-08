import SwiftUI

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // アプリアイコンとタイトル
                    headerSection
                    
                    // アプリ情報
                    aboutContent
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                    .foregroundStyle(.blue)
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // 実際のアプリアイコンを表示
            if let appIcon = getAppIcon() {
                Image(uiImage: appIcon)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                // フォールバック：アイコンが取得できない場合
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.gradient)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "bus.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                    )
            }
            
            VStack(spacing: 4) {
                Text("ばすみる")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("名古屋市バス時刻表アプリ")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text("Version \(getAppVersion())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var aboutContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            aboutSection(
                title: "アプリについて",
                content: """
                ばすみるは、名古屋市バスの時刻表情報を簡単に確認できる非公式アプリです。
                
                バス停間の時刻表検索、リアルタイムでの現在時刻表示、検索履歴の保存など、日常のバス利用を快適にサポートします。
                """
            )
            
            aboutSection(
                title: "主な機能",
                content: """
                • バス停間の時刻表検索
                • リアルタイム時刻表示（秒単位）
                • 平日・土日祝の自動判定
                • 行き・帰りの方向切り替え
                • 検索履歴の保存・管理
                • バス接近情報との連携
                • 過ぎた時刻の自動グレーアウト
                • 次のバスへの自動スクロール
                """
            )
            
            aboutSection(
                title: "データについて",
                content: """
                本アプリは GTFS-JP 形式のバス時刻表データを使用しています。

                • データは定期的に更新されます
                • 運行遅延や運休情報は反映されません
                • 実際の運行状況は公式情報をご確認ください
                """
            )

            attributionSection

            aboutSection(
                title: "免責事項",
                content: """
                • 本アプリは名古屋市バスの非公式アプリです
                • 時刻表情報の正確性を保証するものではありません
                • 実際のバス運行は公式情報を必ずご確認ください
                • アプリ利用により生じた損害について責任を負いません
                """
            )
            
            aboutSection(
                title: "技術情報",
                content: """
                • iOS 17.0 以降対応
                • SwiftUI + MVVM アーキテクチャ
                • Supabase データベース連携
                • オフライン検索履歴機能
                """
            )
            
            // フッター
            VStack(spacing: 8) {
                Text("© 2024 ばすみる開発チーム")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text("名古屋市バスの快適な利用をサポートします")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
        }
    }

    private var attributionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("オープンデータの出典")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 4) {
                Text("[市バスGTFS-JPデータ]")
                    .font(.body)
                    .foregroundStyle(.primary)

                Text("名古屋市")
                    .font(.body)
                    .foregroundStyle(.primary)

                Text("クリエイティブ・コモンズ・ライセンス 表示4.0 国際")
                    .font(.body)
                    .foregroundStyle(.primary)

                Link("https://creativecommons.org/licenses/by/4.0/deed.ja",
                     destination: URL(string: "https://creativecommons.org/licenses/by/4.0/deed.ja")!)
                    .font(.body)
                    .tint(.blue)
            }
            .lineSpacing(4)
        }
        .padding(.vertical, 8)
    }

    private func aboutSection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            Text(content)
                .font(.body)
                .foregroundStyle(.primary)
                .lineSpacing(4)
        }
        .padding(.vertical, 8)
    }
    
    private func getAppVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return "1.0.0"
    }

    private func getAppIcon() -> UIImage? {
        guard let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIconsDictionary = iconsDictionary["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIconsDictionary["CFBundleIconFiles"] as? [String],
              let lastIcon = iconFiles.last else {
            return nil
        }

        return UIImage(named: lastIcon)
    }
}

#Preview {
    AboutView()
}
