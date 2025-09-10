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
        guard let client = client else {
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
    
    func getBusSchedules(routeId: String, direction: String, date: Date = Date()) async throws -> [BusScheduleData] {
        guard let client = client else {
            throw SupabaseError.connectionFailed
        }
        
        do {
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
                print("SupabaseService: Successfully decoded \(rpcResponses.count) schedules")
                
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
            
        } catch let supabaseError as SupabaseError {
            // SupabaseErrorをそのまま再スロー
            print("SupabaseService: getBusSchedules failed - \(supabaseError.debugDescription)")
            throw supabaseError
        } catch {
            print("SupabaseService: getBusSchedules failed - \(error.localizedDescription)")
            print("SupabaseService: Detailed error: \(error)")
            
            // エラーの種類に応じて適切なSupabaseErrorに変換
            if error.localizedDescription.contains("network") || error.localizedDescription.contains("internet") {
                throw SupabaseError.networkError(error.localizedDescription)
            } else {
                throw SupabaseError.connectionFailed
            }
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
    
    // テスト用の簡単なRPC呼び出し
    func testRPCCall() async -> Bool {
        guard let client = client else {
            print("SupabaseService: Client not initialized")
            return false
        }
        
        do {
            // テスト用: 名古屋駅からささしまライブのサンプル検索（文字正規化適用）
            let testParams = [
                "departure_station": "名古屋駅".normalizedForSearch(),
                "arrival_station": "ささしまライブ".normalizedForSearch()
            ]
            
            print("SupabaseService: Test RPC parameters:")
            for (key, value) in testParams {
                print("  - \(key): '\(value)'")
            }
            
            let result = try await client.rpc("get_phase1_bus_schedule", params: testParams).execute()
            print("SupabaseService: Test RPC call successful")
            print("SupabaseService: Test result type: \(type(of: result))")
            print("SupabaseService: Test result data length: \(result.data.count) bytes")
            print("SupabaseService: Test result status: \(result.status)")
            
            if let dataString = String(data: result.data, encoding: .utf8) {
                print("SupabaseService: Test result data as string: \(dataString)")
                
                // データの詳細分析
                let trimmed = dataString.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    print("SupabaseService: Test result is empty string")
                } else if trimmed == "null" {
                    print("SupabaseService: Test result is null")
                } else if trimmed == "[]" {
                    print("SupabaseService: Test result is empty array")
                } else if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                    print("SupabaseService: Test result appears to be a JSON array")
                } else {
                    print("SupabaseService: Test result format: unknown (\(trimmed.count) characters)")
                }
                
                // JSONパース試行
                do {
                    let testDecoding = try JSONDecoder().decode([BusScheduleRPCResponse].self, from: result.data)
                    print("SupabaseService: Test JSON parsing successful, \(testDecoding.count) items")
                } catch {
                    print("SupabaseService: Test JSON parsing failed: \(error.localizedDescription)")
                    if let decodingError = error as? DecodingError {
                        print("SupabaseService: Test decoding error details: \(decodingError)")
                    }
                }
            } else {
                print("SupabaseService: Test result data is not valid UTF-8")
            }
            
            return true
        } catch {
            print("SupabaseService: Test RPC call failed - \(error.localizedDescription)")
            print("SupabaseService: Test RPC detailed error: \(error)")
            return false
        }
    }
    
    // 「高辻」検索専用テスト関数
    func testTakatsujiSearch() async -> Bool {
        guard let client = client else {
            print("SupabaseService: Client not initialized for Takatsuji search test")
            return false
        }
        
        print("SupabaseService: 「高辻」検索テスト開始")
        
        // テストケース: 「高辻」を含む検索パターン（1点しんにょうバージョンも含む）
        let testCases = [
            ("名古屋駅", "高辻"),      // 標準入力
            ("高辻", "ささしまライブ"),  // 標準入力
            ("名古屋駅", "高辻󠄀"),     // 1点しんにょう強制版
            ("高辻󠄀", "ささしまライブ"), // 1点しんにょう強制版
            ("栄", "高辻")
        ]
        
        for (departure, arrival) in testCases {
            do {
                print("SupabaseService: テストケース: \(departure) → \(arrival)")
                
                let normalizedDeparture = departure.normalizedForSearch()
                let normalizedArrival = arrival.normalizedForSearch()
                
                print("SupabaseService: 入力文字: '\(departure)' → '\(arrival)'")
                print("SupabaseService: 正規化後: '\(normalizedDeparture)' → '\(normalizedArrival)'")
                
                // Unicode詳細情報を表示
                func getUnicodeInfo(_ str: String) -> String {
                    return str.unicodeScalars.map { "U+\(String($0.value, radix: 16, uppercase: true))" }.joined(separator: " ")
                }
                
                print("SupabaseService: 入力Unicode: \(getUnicodeInfo(departure)) → \(getUnicodeInfo(arrival))")
                print("SupabaseService: 正規化Unicode: \(getUnicodeInfo(normalizedDeparture)) → \(getUnicodeInfo(normalizedArrival))")
                
                let testParams = [
                    "departure_station": normalizedDeparture,
                    "arrival_station": normalizedArrival,
                    "target_date": "2024-12-02"
                ]
                
                let result = try await client.rpc("get_phase1_bus_schedule", params: testParams).execute()
                
                if let dataString = String(data: result.data, encoding: .utf8) {
                    let trimmed = dataString.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed == "[]" || trimmed == "null" || trimmed.isEmpty {
                        print("SupabaseService: 結果なし - \(departure) → \(arrival)")
                    } else {
                        print("SupabaseService: 結果あり - \(departure) → \(arrival): \(dataString.prefix(100))...")
                        
                        // JSON デコードテスト
                        do {
                            let schedules = try JSONDecoder().decode([BusScheduleRPCResponse].self, from: result.data)
                            print("SupabaseService: \(schedules.count) 件のスケジュール取得成功")
                            
                            // 「高辻」を含む結果の表示確認
                            for schedule in schedules.prefix(3) {
                                let displayRoute = schedule.routeName.normalizedForDisplay()
                                let displayDestination = schedule.destination.normalizedForDisplay()
                                print("SupabaseService: 表示テスト - \(schedule.departureTime) \(displayRoute) → \(displayDestination)")
                            }
                        } catch {
                            print("SupabaseService: JSON パースエラー - \(error)")
                        }
                    }
                } else {
                    print("SupabaseService: UTF-8 変換失敗 - \(departure) → \(arrival)")
                }
                
            } catch {
                print("SupabaseService: 検索エラー - \(departure) → \(arrival): \(error)")
            }
        }
        
        print("SupabaseService: 「高辻」検索テスト完了")
        return true
    }
}

// RPC関数レスポンス用のCodable構造体
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
            self.busStops = Self.processedBusStops(from: stops)
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
    
    // バス停リストの加工処理（重複を削除し、見やすく整理）
    private static func processedBusStops(from rawStops: [String]) -> [String] {
        var processedStops: [String] = []
        var lastStop = ""
        
        for stop in rawStops {
            let normalizedStop = stop.normalizedForDisplay()
            // 連続する同じバス停名を除去（例: ["栄", "栄"] → ["栄"]）
            if normalizedStop != lastStop && !normalizedStop.isEmpty {
                processedStops.append(normalizedStop)
                lastStop = normalizedStop
            }
        }
        
        return processedStops
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
            return "機能が実装されていません"
        case .connectionFailed:
            return "データベースへの接続に失敗しました"
        case .invalidResponse:
            return "サーバーから無効なレスポンスを受信しました"
        case .authenticationFailed:
            return "認証に失敗しました"
        case .jsonParsingFailed(let details):
            return "データの解析に失敗しました: \(details)"
        case .emptyResponse:
            return "指定された条件に合致するデータが見つかりませんでした"
        case .invalidData:
            return "受信したデータの形式が不正です"
        case .networkError(let details):
            return "ネットワークエラーが発生しました: \(details)"
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
