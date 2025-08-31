import Foundation
import SwiftUI

@MainActor
class BusScheduleViewModel: ObservableObject {
    @Published var stationPair: StationPair
    @Published var currentTime: Date = Date()
    @Published var selectedServiceType: ServiceType = .weekday
    @Published var selectedDirection: Direction = .outbound
    @Published var busSchedules: [BusScheduleData] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private var timer: Timer?
    private let supabaseService = SupabaseService.shared
    
    enum ServiceType: String, CaseIterable {
        case weekday = "平日"
        case holiday = "土日祝"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    enum Direction: String, CaseIterable {
        case outbound = "行き"
        case inbound = "帰り"
        
        var displayName: String {
            return self.rawValue
        }
    }
    
    init(stationPair: StationPair) {
        self.stationPair = stationPair
        startTimeTimer()
        loadBusSchedules()
    }
    
    deinit {
        timer?.invalidate()
        timer = nil
    }
    
    private func startTimeTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in
                self.currentTime = Date()
            }
        }
    }
    
    func loadBusSchedules() {
        Task {
            await fetchBusSchedules()
        }
    }
    
    private func fetchBusSchedules() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let schedules = try await supabaseService.getBusSchedules(
                routeId: "\(stationPair.departureStation)_\(stationPair.arrivalStation)",
                direction: selectedDirection.rawValue,
                date: currentTime
            )
            busSchedules = schedules
        } catch {
            errorMessage = "時刻表の取得に失敗しました: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refreshSchedules() {
        loadBusSchedules()
    }
    
    func selectServiceType(_ serviceType: ServiceType) {
        selectedServiceType = serviceType
        loadBusSchedules()
    }
    
    func selectDirection(_ direction: Direction) {
        selectedDirection = direction
        loadBusSchedules()
    }
    
    var currentTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: currentTime)
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        let weekdayFormatter = DateFormatter()
        weekdayFormatter.dateFormat = "(E)"
        weekdayFormatter.locale = Locale(identifier: "ja_JP")
        
        return formatter.string(from: currentTime) + weekdayFormatter.string(from: currentTime)
    }
    
    func isPastTime(_ departureTime: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let scheduledTime = formatter.date(from: departureTime) else {
            return false
        }
        
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.hour, .minute], from: currentTime)
        let scheduledComponents = calendar.dateComponents([.hour, .minute], from: scheduledTime)
        
        if let currentHour = currentComponents.hour,
           let currentMinute = currentComponents.minute,
           let scheduledHour = scheduledComponents.hour,
           let scheduledMinute = scheduledComponents.minute {
            
            let currentTotalMinutes = currentHour * 60 + currentMinute
            let scheduledTotalMinutes = scheduledHour * 60 + scheduledMinute
            
            return currentTotalMinutes > scheduledTotalMinutes
        }
        
        return false
    }
}
