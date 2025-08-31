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
            
            // Call RPC function with parameters
            let result = try await client.rpc("get_phase1_bus_schedule", params: [
                "departure_station": String(routeId.split(separator: "_").first ?? ""),
                "arrival_station": String(routeId.split(separator: "_").last ?? ""),
                "target_date": dateString
            ]).execute()
            
            print("SupabaseService: RPC call successful, result: \(result)")
            
            // Parse JSON result to BusScheduleData array
            // Note: This is a placeholder implementation
            // You'll need to properly parse the JSON response based on your actual data structure
            return []
            
        } catch {
            print("SupabaseService: getBusSchedules failed - \(error.localizedDescription)")
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
    
    // テスト用の簡単なRPC呼び出し
    func testRPCCall() async -> Bool {
        guard let client = client else {
            print("SupabaseService: Client not initialized")
            return false
        }
        
        do {
            // テスト用: 東京駅から新宿駅のサンプル検索
            let result = try await client.rpc("get_phase1_bus_schedule", params: [
                "departure_station": "名古屋駅",
                "arrival_station": "ささしまライブ"
            ]).execute()
            print("SupabaseService: Test RPC call successful")
            print("SupabaseService: Test result: \(result)")
            return true
        } catch {
            print("SupabaseService: Test RPC call failed - \(error.localizedDescription)")
            return false
        }
    }
}

struct BusScheduleData {
    let departureTime: String
    let routeName: String
    let destination: String
    let platform: String
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
    
    var localizedDescription: String {
        switch self {
        case .notImplemented:
            return "機能が実装されていません"
        case .connectionFailed:
            return "データベース接続に失敗しました"
        case .invalidResponse:
            return "無効なレスポンスです"
        case .authenticationFailed:
            return "認証に失敗しました"
        }
    }
}
