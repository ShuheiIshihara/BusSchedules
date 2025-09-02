import Foundation

class StationSelectionViewModel: ObservableObject {
    private let userDefaults = UserDefaults.standard
    private let stationPairKey = "SavedStationPair"
    private let historyKey = "StationPairHistory"
    private let maxHistoryCount = 10
    
    @Published var searchHistory: [StationPair] = []
    
    init() {
        loadHistory()
    }
    
    func saveStationPair(_ stationPair: StationPair) {
        let normalizedPair = StationPair(
            departure: stationPair.departureStation.normalizedForSearch(),
            arrival: stationPair.arrivalStation.normalizedForSearch()
        )
        
        if let encoded = try? JSONEncoder().encode(normalizedPair) {
            userDefaults.set(encoded, forKey: stationPairKey)
        }
        addToHistory(normalizedPair)
    }
    
    func loadSavedStationPair() -> StationPair? {
        guard let data = userDefaults.data(forKey: stationPairKey),
              let stationPair = try? JSONDecoder().decode(StationPair.self, from: data) else {
            return nil
        }
        return stationPair
    }
    
    func clearSavedStationPair() {
        userDefaults.removeObject(forKey: stationPairKey)
    }
    
    private func addToHistory(_ stationPair: StationPair) {
        let normalizedPair = StationPair(
            departure: stationPair.departureStation.normalizedForSearch(),
            arrival: stationPair.arrivalStation.normalizedForSearch()
        )
        
        var history = searchHistory
        
        history.removeAll { $0.departureStation == normalizedPair.departureStation && $0.arrivalStation == normalizedPair.arrivalStation }
        
        history.insert(normalizedPair, at: 0)
        
        if history.count > maxHistoryCount {
            history = Array(history.prefix(maxHistoryCount))
        }
        
        searchHistory = history
        saveHistory()
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(searchHistory) {
            userDefaults.set(encoded, forKey: historyKey)
        }
    }
    
    private func loadHistory() {
        guard let data = userDefaults.data(forKey: historyKey),
              let history = try? JSONDecoder().decode([StationPair].self, from: data) else {
            return
        }
        searchHistory = history
    }
    
    func clearHistory() {
        searchHistory = []
        userDefaults.removeObject(forKey: historyKey)
    }
    
    func swapStations(_ departureStation: inout String, _ arrivalStation: inout String) {
        let temp = departureStation
        departureStation = arrivalStation
        arrivalStation = temp
    }
}