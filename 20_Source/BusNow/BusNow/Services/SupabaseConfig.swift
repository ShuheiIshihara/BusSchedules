import Foundation

/// Supabase接続設定。
/// 値はビルド構成ごとのxcconfig(Config-Debug / Config-Release)からInfo.plist経由で注入される。
/// Debug: ローカルSupabase / Release: 本番Supabase
struct SupabaseConfig {
    private static func infoValue(for key: String) -> String {
        (Bundle.main.object(forInfoDictionaryKey: key) as? String) ?? ""
    }

    private static var supabaseDomain: String { infoValue(for: "SUPABASE_DOMAIN") }

    static var supabaseUrl: String {
        let domain = supabaseDomain
        if domain.isEmpty { return "" }
        // ローカルSupabase(DB更新の検証用)はhttpで接続する
        return isLocalDomain(domain) ? "http://\(domain)" : "https://\(domain)"
    }

    /// ローカルSupabaseとみなす宛先
    /// 127.0.0.1 / localhost / プライベートIP(実機からMac上のローカルDBへ接続する場合) / .local
    private static func isLocalDomain(_ domain: String) -> Bool {
        let host = domain.split(separator: ":").first.map(String.init) ?? domain
        if host == "localhost" || host.hasSuffix(".local") { return true }

        let octets = host.split(separator: ".").compactMap { Int($0) }
        guard octets.count == 4, host.split(separator: ".").count == 4 else { return false }
        switch (octets[0], octets[1]) {
        case (127, _), (10, _), (192, 168): return true
        case (172, 16...31): return true
        default: return false
        }
    }
    
    static var supabaseAnonKey: String { infoValue(for: "SUPABASE_ANON_KEY") }

    static var isConfigured: Bool {
        let domain = supabaseDomain
        let key = supabaseAnonKey
        #if DEBUG
        let isAllowedDomain = domain.contains(".supabase.co") || isLocalDomain(domain)
        #else
        // Releaseではローカル向け設定を許可しない(ローカルDBのままの提出を防ぐ)
        let isAllowedDomain = domain.contains(".supabase.co") && !isLocalDomain(domain)
        #endif
        return !domain.isEmpty &&
               !domain.contains("YOUR-PROJECT-REF") &&
               isAllowedDomain &&
               !key.isEmpty &&
               !key.contains("YOUR_")
    }

    static var configurationStatus: String {
        let domain = supabaseDomain
        let url = supabaseUrl
        let key = supabaseAnonKey

        if isConfigured {
            return "✅ Supabase設定が正常です (URL: \(String(url.prefix(35)))...)"
        } else if domain.isEmpty && key.isEmpty {
            return "⚠️ Config-Debug.xcconfig / Config-Release.xcconfig を作成してください"
        } else if domain.uppercased().contains("YOUR-PROJECT-REF") || key.contains("YOUR_") {
            return "⚠️ xcconfigに実際のSupabase値を設定してください"
        } else if isLocalDomain(domain) {
            return "⚠️ Releaseビルドではローカルの接続先は使用できません。Config-Release.xcconfigを確認してください"
        } else if !domain.contains(".supabase.co") && !domain.isEmpty {
            return "⚠️ SUPABASE_DOMAINが正しいSupabaseドメイン形式ではありません (例: your-project.supabase.co)"
        } else {
            return "⚠️ Supabase設定に問題があります。ドメインとAPIキーを確認してください"
        }
    }

    static func printDebugInfo() {
        #if DEBUG
        print("=== Supabase Configuration Debug ===")
        print("  Domain: '\(supabaseDomain)'")
        print("  Constructed URL: '\(supabaseUrl)'")
        print("  Key length: \(supabaseAnonKey.count)")
        print("  Is Configured: \(isConfigured)")
        print("  Status: \(configurationStatus)")
        print("=====================================")
        #endif
    }
}
