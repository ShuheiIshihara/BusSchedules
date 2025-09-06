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
    @Published var nextBusIndex: Int? = nil
    @Published var targetDate: Date = Date()
    
    private let originalStationPair: StationPair
    private var currentStationPair: StationPair
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
        self.originalStationPair = stationPair
        self.currentStationPair = stationPair
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
                self.updateNextBusIndex() // 時間経過に伴う次のバス更新
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
                routeId: "\(currentStationPair.departureStation)_\(currentStationPair.arrivalStation)",
                direction: selectedDirection.rawValue,
                date: targetDate
            )
            busSchedules = schedules
            updateNextBusIndex() // 次のバスのインデックスを更新
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
        
        // 現在の日付の種類を判定
        let today = Date()
        let isTodayWeekday = isWeekday(today)
        
        // 選択されたサービスタイプに基づいて対象日付を計算
        switch serviceType {
        case .weekday:
            if isTodayWeekday {
                // 平日に平日ボタン -> 今日のまま
                targetDate = today
            } else {
                // 土日祝に平日ボタン -> 次の月曜日
                targetDate = getNextMonday(from: today)
            }
        case .holiday:
            if isTodayWeekday {
                // 平日に土日祝ボタン -> 次の土曜日
                targetDate = getNextSaturday(from: today)
            } else {
                // 土日祝に土日祝ボタン -> 今日のまま
                targetDate = today
            }
        }
        
        loadBusSchedules()
    }
    
    func selectDirection(_ direction: Direction) {
        selectedDirection = direction
        
        // 方向に基づいて駅ペアを設定
        switch direction {
        case .outbound:
            // 行き: 元の駅ペアを使用
            currentStationPair = originalStationPair
            stationPair = originalStationPair
        case .inbound:
            // 帰り: 駅を入れ替え
            let reversedStationPair = StationPair(
                departure: originalStationPair.arrivalStation,
                arrival: originalStationPair.departureStation
            )
            currentStationPair = reversedStationPair
            stationPair = reversedStationPair
        }
        
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
        
        return formatter.string(from: targetDate) + weekdayFormatter.string(from: targetDate)
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
            
            return currentTotalMinutes >= scheduledTotalMinutes // 発車時刻ちょうどでも発車済とする
        }
        
        return false
    }
    
    // 現在時刻以降の最初のバスのインデックスを検索
    private func findNextBusIndex() -> Int? {
        for (index, schedule) in busSchedules.enumerated() {
            if !isPastTime(schedule.departureTime) {
                return index
            }
        }
        return nil // 全てのバスが発車済み
    }
    
    // 次のバスインデックスを更新
    private func updateNextBusIndex() {
        let newIndex = findNextBusIndex()
        if nextBusIndex != newIndex {
            nextBusIndex = newIndex
        }
    }
    
    // 次のバスまでの時間を計算（分単位）
    func minutesUntilNextBus() -> Int? {
        guard let index = nextBusIndex,
              index < busSchedules.count else { return nil }
        
        let schedule = busSchedules[index]
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        guard let scheduledTime = formatter.date(from: schedule.departureTime) else {
            return nil
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
            
            return max(0, scheduledTotalMinutes - currentTotalMinutes)
        }
        
        return nil
    }
    
    // 日付が平日かどうかを判定
    private func isWeekday(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        // weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
        return weekday >= 2 && weekday <= 6 // Monday to Friday
    }
    
    // 次の土曜日の日付を取得
    private func getNextSaturday(from date: Date) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        // 現在が土曜日（weekday = 7）の場合は今日を返す
        if weekday == 7 {
            return date
        }
        
        // 次の土曜日までの日数を計算
        let daysUntilSaturday = (7 - weekday + 7) % 7
        let adjustedDays = daysUntilSaturday == 0 ? 7 : daysUntilSaturday
        
        return calendar.date(byAdding: .day, value: adjustedDays, to: date) ?? date
    }
    
    // 次の月曜日の日付を取得
    private func getNextMonday(from date: Date) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        
        // 現在が月曜日（weekday = 2）の場合は今日を返す
        if weekday == 2 {
            return date
        }
        
        // 次の月曜日までの日数を計算
        let daysUntilMonday = weekday == 1 ? 1 : (9 - weekday) // Sunday: 1 day, other: 9-weekday
        
        return calendar.date(byAdding: .day, value: daysUntilMonday, to: date) ?? date
    }
}
