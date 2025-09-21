import SwiftUI

// 通知名の拡張
extension Notification.Name {
    static let searchHistoryCleared = Notification.Name("searchHistoryCleared")
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    @State private var showingAbout = false
    @State private var showingClearHistoryAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                // アプリ情報セクション
                Section(header: Text("アプリ情報")) {
                    SettingsRowView(
                        icon: "info.circle",
                        title: "アプリについて",
                        showChevron: true
                    ) {
                        showingAbout = true
                    }
                    
                    SettingsRowView(
                        icon: "gearshape",
                        title: "バージョン",
                        value: getAppVersion(),
                        showChevron: false
                    )
                }
                
                // 法的文書セクション
                Section(header: Text("法的文書")) {
                    SettingsRowView(
                        icon: "doc.text",
                        title: "利用規約",
                        showChevron: true
                    ) {
                        showingTermsOfService = true
                    }
                    
                    SettingsRowView(
                        icon: "hand.raised",
                        title: "プライバシーポリシー",
                        showChevron: true
                    ) {
                        showingPrivacyPolicy = true
                    }
                }
                
                // サポートセクション
                Section(header: Text("サポート")) {
                    SettingsRowView(
                        icon: "questionmark.circle",
                        title: "ヘルプ",
                        value: "App Store ページ",
                        showChevron: true
                    ) {
                        openAppStoreURL()
                    }
                    
                    SettingsRowView(
                        icon: "envelope",
                        title: "お問い合わせ",
                        value: "App Store レビュー",
                        showChevron: true
                    ) {
                        openAppStoreReviewURL()
                    }
                }
                
                // データ管理セクション
                Section(
                    header: Text("データ管理"),
                    footer: Text("検索履歴を削除してもアプリの機能に影響はありません。")
                ) {
                    SettingsRowView(
                        icon: "trash",
                        title: "検索履歴をクリア",
                        showChevron: true
                    ) {
                        showingClearHistoryAlert = true
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingTermsOfService) {
            TermsOfServiceView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .alert("検索履歴をクリア", isPresented: $showingClearHistoryAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("クリア", role: .destructive) {
                clearSearchHistory()
            }
        } message: {
            Text("検索履歴を削除しますか？この操作は取り消すことができません。")
        }
    }
    
    private func getAppVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "\(version) (\(build))"
        }
        return "不明"
    }
    
    private func openAppStoreURL() {
        // App Store URL
        if let url = URL(string: "https://apps.apple.com/jp/app/id6751941954") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openAppStoreReviewURL() {
        // App Store レビューURL
        if let url = URL(string: "https://apps.apple.com/jp/app/id6751941954?action=write-review") {
            UIApplication.shared.open(url)
        }
    }
    
    private func clearSearchHistory() {
        // 検索履歴をクリアする処理（検索画面と同じキーを使用）
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "StationPairHistory")
        
        // 通知を送信して他の画面に変更を知らせる
        NotificationCenter.default.post(name: .searchHistoryCleared, object: nil)
    }
}

struct SettingsRowView: View {
    let icon: String
    let title: String
    let value: String?
    let showChevron: Bool
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        value: String? = nil,
        showChevron: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.showChevron = showChevron
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            action?()
        }) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let value = value {
                    Text(value)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
        .disabled(action == nil)
    }
}

#Preview {
    SettingsView()
}
