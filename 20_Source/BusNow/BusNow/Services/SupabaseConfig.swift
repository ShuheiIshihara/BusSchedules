import Foundation

struct SupabaseConfig {
    private static var supabaseDomain: String {
        // 方法1: Info.plistから読み取り（理想的だが現在動作しない）
        if let domain = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_DOMAIN") as? String,
           !domain.isEmpty {
            return domain
        }
        
        // 方法2: Config-Local.xcconfigファイルから直接読み取り
        return readConfigValue(for: "SUPABASE_DOMAIN")
    }
    
    static var supabaseUrl: String {
        let domain = supabaseDomain
        return domain.isEmpty ? "" : "https://\(domain)"
    }
    
    static var supabaseAnonKey: String {
        // 方法1: Info.plistから読み取り（理想的だが現在動作しない）
        if let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
           !key.isEmpty {
            return key
        }
        
        // 方法2: Config-Local.xcconfigファイルから直接読み取り
        return readConfigValue(for: "SUPABASE_ANON_KEY")
    }
    
    private static func readConfigValue(for key: String) -> String {
        guard let configPath = Bundle.main.path(forResource: "Config-Local", ofType: "xcconfig") else {
            #if DEBUG
            print("SupabaseConfig: Config-Local.xcconfig not found in bundle")
            #endif
            return ""
        }
        
        do {
            let content = try String(contentsOfFile: configPath, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespaces)
                if trimmedLine.hasPrefix(key + " = ") {
                    let value = String(trimmedLine.dropFirst((key + " = ").count))
                    return value.trimmingCharacters(in: .whitespaces)
                }
            }
        } catch {
            #if DEBUG
            print("SupabaseConfig: Error reading config file - \(error)")
            #endif
        }
        
        return ""
    }
    
    static var isConfigured: Bool {
        let domain = supabaseDomain
        let key = supabaseAnonKey
        return !domain.isEmpty && 
               !domain.contains("YOUR-PROJECT-REF") && 
               domain.contains(".supabase.co") &&
               !key.isEmpty && 
               !key.contains("YOUR_SUPABASE")
    }
    
    static var configurationStatus: String {
        let domain = supabaseDomain
        let url = supabaseUrl
        let key = supabaseAnonKey
        
        if isConfigured {
            return "✅ Supabase設定が正常です (URL: \(String(url.prefix(35)))...)"
        } else if domain.isEmpty && key.isEmpty {
            return "⚠️ Config-Local.xcconfigファイルを作成し、Xcode Build Configurationに設定してください"
        } else if domain.contains("YOUR-PROJECT-REF") || key.contains("YOUR_SUPABASE") {
            return "⚠️ Config-Local.xcconfigファイルに実際のSupabase値を設定してください"
        } else if !domain.contains(".supabase.co") && !domain.isEmpty {
            return "⚠️ SUPABASE_DOMAINが正しいSupabaseドメイン形式ではありません (例: your-project.supabase.co)"
        } else {
            return "⚠️ Supabase設定に問題があります。ドメインとAPIキーを確認してください"
        }
    }
    
    static func printDebugInfo() {
        #if DEBUG
        print("=== Supabase Configuration Debug ===")
        print("Bundle Path: \(Bundle.main.bundlePath)")
        
        print("\nBundle Resource Check:")
        if let configPath = Bundle.main.path(forResource: "Config-Local", ofType: "xcconfig") {
            print("  Config-Local.xcconfig found at: \(configPath)")
        } else {
            print("  Config-Local.xcconfig NOT FOUND in bundle")
            print("  Available resources:")
            if let resourcePath = Bundle.main.resourcePath {
                do {
                    let resources = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                    for resource in resources.sorted() {
                        if resource.contains("config") || resource.contains("Config") {
                            print("    \(resource)")
                        }
                    }
                } catch {
                    print("    Error listing resources: \(error)")
                }
            }
        }
        
        print("\nInfo.plist Key Check:")
        if let infoPlist = Bundle.main.infoDictionary {
            print("  Total Info.plist keys: \(infoPlist.keys.count)")
            for key in infoPlist.keys.sorted() {
                if key.contains("SUPABASE") {
                    print("  \(key) = \(infoPlist[key] ?? "nil")")
                }
            }
        }
        
        print("\nDirect Key Lookup:")
        print("  SUPABASE_DOMAIN = '\(Bundle.main.object(forInfoDictionaryKey: "SUPABASE_DOMAIN") as? String ?? "nil")'")
        print("  SUPABASE_ANON_KEY = '\(Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? "nil")'")
        
        print("\nConfig File Reading:")
        print("  Domain from config: '\(readConfigValue(for: "SUPABASE_DOMAIN"))'")
        print("  Key from config: '\(readConfigValue(for: "SUPABASE_ANON_KEY"))'")
        
        print("\nFinal Results:")
        print("  Domain: '\(supabaseDomain)'")
        print("  Constructed URL: '\(supabaseUrl)'")
        print("  Key length: \(supabaseAnonKey.count)")
        print("  Is Configured: \(isConfigured)")
        print("  Status: \(configurationStatus)")
        print("=====================================")
        #endif
    }
}
