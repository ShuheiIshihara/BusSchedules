import Foundation

struct StationPair: Codable, Equatable, Identifiable {
    let id = UUID()
    let departureStation: String
    let arrivalStation: String
    let createdAt: Date
    
    init(departure: String, arrival: String, createdAt: Date = Date()) {
        self.departureStation = departure
        self.arrivalStation = arrival
        self.createdAt = createdAt
    }
    
    var isEmpty: Bool {
        return departureStation.isEmpty || arrivalStation.isEmpty
    }
    
    var displayName: String {
        return "\(departureStation) → \(arrivalStation)"
    }
}

extension StationPair {
    static let empty = StationPair(departure: "", arrival: "")
}