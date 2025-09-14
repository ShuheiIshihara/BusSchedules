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
            print("SupabaseService: Configuration incomplete - \(SupabaseConfig.configurationStatus)")
            return
        }
        
        guard let url = URL(string: SupabaseConfig.supabaseUrl) else {
            print("SupabaseService: Invalid Supabase URL")
            return
        }
        
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
        
        print("SupabaseService: Client initialized successfully")
    }
    
    func testConnection() async -> Bool {
        guard let client = self.client else {
            print("SupabaseService: Client not initialized")
            return false
        }
        
        do {
            // 匿名アクセス用の接続テスト: RPC関数を使用してデータベース接続を確認
            let result = try client.rpc("phase1_health_check")
            print("SupabaseService: Database connection test successful")
            print("SupabaseService: Health check result: \(result)")
            return true
        } catch {
            print("SupabaseService: Database connection test failed - \(error.localizedDescription)")
            
            // フォールバック: 基本的なRESTエンドポイント確認
            do {
                _ = try await client
                    .from("security_phase_info")
                    .select("phase_name")
                    .limit(1)
                    .execute()
                print("SupabaseService: Basic REST connection successful")
                return true
            } catch {
                print("SupabaseService: Basic REST connection also failed - \(error.localizedDescription)")
                return false
            }
        }
    }
    
    func getBusSchedules(routeId: String, direction: String, date: Date = Date(), retryCount: Int = 3) async throws -> [BusScheduleData] {
        guard let client = self.client else {
            throw SupabaseError.connectionFailed
        }
        
        var lastError: Error?
        
        for attempt in 0..<retryCount {
            do {
                print("SupabaseService: Attempt \(attempt + 1) of \(retryCount)")
                
                // DateFormatter for SQL date format
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let dateString = dateFormatter.string(from: date)
                
                // routeIdから駅名を抽出し、文字正規化を適用
                let departure_station = String(routeId.split(separator: "_").first ?? "").normalizedForSearch()
                let arrival_station = String(routeId.split(separator: "_").last ?? "").normalizedForSearch()
                
                let rpcParams = [
                    "departure_station": departure_station,
                    "arrival_station": arrival_station,
                    "target_date": dateString
                ]
                
                let response = try await client.rpc("get_phase1_bus_schedule_2", params: rpcParams).execute()
                let data = response.data
                
                // レスポンスデータの詳細ログ
                print("SupabaseService: RPC response details:")
                print("  - Status code: \(response.status)")
                print("  - Data size: \(data.count) bytes")
                
                // データが空の場合の早期チェック
                if data.isEmpty {
                    print("SupabaseService: Empty response data received")
                    throw SupabaseError.emptyResponse
                }
                
                // レスポンス内容をログ出力（デバッグ用）
                if let dataString = String(data: data, encoding: .utf8) {
                    // レスポンスの最初の部分のみ表示（長すぎる場合は切り詰める）
                    let preview = dataString.count > 500 ? String(dataString.prefix(500)) + "..." : dataString
                    print("SupabaseService: Response data preview: \(preview)")
                    
                    // 実際のJSONキー構造を分析
                    if dataString.contains("departureTime") {
                        print("SupabaseService: Response uses camelCase keys (departureTime)")
                    } else if dataString.contains("departure_time") {
                        print("SupabaseService: Response uses snake_case keys (departure_time)")
                    } else {
                        print("SupabaseService: Unknown key format in response")
                    }
                    
                    // 空配列や空文字列チェック
                    let trimmed = dataString.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed == "null" || trimmed == "[]" || trimmed == "{}" || trimmed.isEmpty {
                        print("SupabaseService: Response contains no actual data (null/empty)")
                        return [] // 空配列を返す
                    }
                } else {
                    print("SupabaseService: Response data is not valid UTF-8")
                    throw SupabaseError.invalidResponse
                }
                
                do {
                    // JSON を BusScheduleRPCResponse 配列にデコード
                    let rpcResponses = try JSONDecoder().decode([BusScheduleRPCResponse].self, from: data)
                    print("SupabaseService: Successfully decoded \(rpcResponses.count) schedules on attempt \(attempt + 1)")
                    
                    // BusScheduleData 配列に変換
                    let schedules = rpcResponses.map { BusScheduleData(from: $0) }
                    return schedules
                    
                } catch {
                    print("SupabaseService: JSON parsing failed - \(error.localizedDescription)")
                    print("SupabaseService: JSON parsing detailed error: \(error)")
                    
                    // より具体的なエラー情報を提供
                    if let decodingError = error as? DecodingError {
                        print("SupabaseService: Decoding error details: \(decodingError)")
                    }
                    
                    throw SupabaseError.jsonParsingFailed(error.localizedDescription)
                }
                
            } catch let error {
                lastError = error
                print("SupabaseService: Attempt \(attempt + 1) failed: \(error.localizedDescription)")
                
                // 最後の試行でない場合は少し待機してリトライ
                if attempt < retryCount - 1 {
                    let delay = Double(attempt + 1) * 1.0
                    print("SupabaseService: Retrying in \(delay) seconds...")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        // すべての試行が失敗した場合
        if let lastError = lastError {
            print("SupabaseService: All \(retryCount) attempts failed")
            
            if let supabaseError = lastError as? SupabaseError {
                throw supabaseError
            }
            
            // エラーの種類に応じて適切なSupabaseErrorに変換
            let errorMessage = lastError.localizedDescription
            if errorMessage.contains("network") || 
               errorMessage.contains("internet") || 
               errorMessage.contains("connection") ||
               errorMessage.contains("timeout") {
                throw SupabaseError.networkError("インターネット接続を確認してください")
            } else {
                throw SupabaseError.connectionFailed
            }
        } else {
            throw SupabaseError.connectionFailed
        }
    }
    
    func getRouteSettings() async throws -> [RouteSettingData] {
        print("SupabaseService: getRouteSettings placeholder - SDK integration required")
        throw SupabaseError.notImplemented
    }
    
    func getHolidays() async throws -> [HolidayData] {
        print("SupabaseService: getHolidays placeholder - SDK integration required")
        throw SupabaseError.notImplemented
    }
}

// MARK: - Data Models

struct BusScheduleRPCResponse: Codable {
    let departureTime: String
    let routeName: String
    let destination: String
    let platform: String
    let serviceType: String
    let departureMinutes: Double
    let serviceId: String
    let busStops: [String]?  // バス停リスト（オプショナル）
    
    private enum CodingKeys: String, CodingKey {
        case departureTime = "departureTime"
        case routeName = "routeName"
        case destination = "destination"
        case platform = "platform"
        case serviceType = "serviceType"
        case departureMinutes = "departureMinutes"
        case serviceId = "serviceId"
        case busStops = "busStops"
    }
}

struct BusScheduleData {
    let departureTime: String
    let routeName: String
    let destination: String
    let platform: String
    let serviceId: String
    let busStops: [String]  // バス停リスト
    
    // RPC レスポンスから BusScheduleData への変換（表示用正規化適用）
    init(from rpcResponse: BusScheduleRPCResponse) {
        // 時刻から秒を削除（HH:MM:SS → HH:MM）
        self.departureTime = Self.formatTimeWithoutSeconds(rpcResponse.departureTime)
        self.routeName = rpcResponse.routeName.normalizedForDisplay()
        self.destination = rpcResponse.destination.normalizedForDisplay()
        self.platform = rpcResponse.platform
        self.serviceId = rpcResponse.serviceId
        
        // バス停リストの正規化処理（重複を削除して表示用に整理）
        if let stops = rpcResponse.busStops {
            self.busStops = stops
        } else {
            self.busStops = []
        }
    }
    
    // 時刻文字列から秒を削除するヘルパー関数
    private static func formatTimeWithoutSeconds(_ timeString: String) -> String {
        // HH:MM:SS形式の場合、HH:MMに変換
        let components = timeString.split(separator: ":")
        if components.count >= 2 {
            return "\(components[0]):\(components[1])"
        }
        // すでにHH:MM形式の場合はそのまま返す
        return timeString
    }
    
    // 既存のイニシャライザーも保持（テスト用）
    init(departureTime: String, routeName: String, destination: String, platform: String, serviceId: String = "平日", busStops: [String] = []) {
        self.departureTime = departureTime
        self.routeName = routeName
        self.destination = destination
        self.platform = platform
        self.serviceId = serviceId
        self.busStops = busStops
    }
}

struct RouteSettingData {
    let id: String
    let name: String
    let outboundRouteId: String
    let inboundRouteId: String
    let proximityUrl: String
}

struct HolidayData {
    let date: Date
    let name: String
}

enum SupabaseError: Error {
    case notImplemented
    case connectionFailed
    case invalidResponse
    case authenticationFailed
    case jsonParsingFailed(String)
    case emptyResponse
    case invalidData
    case networkError(String)
    
    var localizedDescription: String {
        switch self {
        case .notImplemented:
            return "この機能は現在利用できません"
        case .connectionFailed:
            return "サーバーに接続できませんでした。\nしばらく待ってから再試行してください。"
        case .invalidResponse:
            return "サーバーから正しい応答を受信できませんでした。\n再試行してください。"
        case .authenticationFailed:
            return "認証に失敗しました"
        case .jsonParsingFailed(_):
            return "データの読み込みに失敗しました。\n再試行してください。"
        case .emptyResponse:
            return "指定された区間の時刻表が見つかりませんでした。\nバス停名を確認してください。"
        case .invalidData:
            return "データの形式に問題があります。\n再試行してください。"
        case .networkError(_):
            return "インターネット接続を確認してください。\nWi-Fiまたはモバイルデータをオンにして再試行してください。"
        }
    }
    
    var debugDescription: String {
        switch self {
        case .jsonParsingFailed(let details):
            return "JSON解析エラー - 詳細: \(details)"
        case .emptyResponse:
            return "空のレスポンス - データベースから結果が返されませんでした"
        case .invalidResponse:
            return "無効なレスポンス - サーバーレスポンスの形式に問題があります"
        case .invalidData:
            return "無効なデータ - データが破損しているか形式が間違っています"
        case .networkError(let details):
            return "ネットワークエラー - \(details)"
        default:
            return localizedDescription
        }
    }
}