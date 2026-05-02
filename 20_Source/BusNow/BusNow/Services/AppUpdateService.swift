import Foundation

// 新バージョンが存在する場合にアラートへ渡すデータ
struct AppUpdateInfo: Identifiable {
    let id = UUID()
    let latestVersion: String  // App Store 上の最新バージョン文字列
    let storeURL: URL          // App Store の該当ページ URL
}

// iTunes Lookup API を使ってバージョンチェックを行うサービス
class AppUpdateService {
    static let shared = AppUpdateService()
    private init() {}

    // 新バージョンがあれば AppUpdateInfo を返す。最新版または取得失敗時は nil
    func checkForUpdate() async throws -> AppUpdateInfo? {
        // Bundle.main.bundleIdentifier を使うことで pbxproj との二重管理を避ける
        guard let bundleID = Bundle.main.bundleIdentifier,
              // country=jp で日本の App Store を参照
              let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleID)&country=jp") else {
            return nil
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(iTunesLookupResponse.self, from: data)

        // results が空の場合は App Store 未公開 or 非該当のため nil
        guard let result = response.results.first,
              let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
              isNewerVersion(result.version, than: currentVersion),
              let storeURL = URL(string: result.trackViewUrl) else {
            return nil
        }

        return AppUpdateInfo(latestVersion: result.version, storeURL: storeURL)
    }

    // セマンティックバージョンをコンポーネント単位で比較する（例: "1.10" > "1.9"）
    private func isNewerVersion(_ version: String, than current: String) -> Bool {
        let newParts = version.split(separator: ".").compactMap { Int($0) }
        let curParts = current.split(separator: ".").compactMap { Int($0) }
        let count = max(newParts.count, curParts.count)
        for i in 0..<count {
            let new = i < newParts.count ? newParts[i] : 0
            let cur = i < curParts.count ? curParts[i] : 0
            if new != cur { return new > cur }
        }
        return false
    }
}

// iTunes Lookup API のレスポンス構造
private struct iTunesLookupResponse: Decodable {
    let results: [iTunesResult]
}

private struct iTunesResult: Decodable {
    let version: String
    let trackViewUrl: String
}
