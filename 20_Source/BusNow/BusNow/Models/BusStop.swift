import Foundation

struct BusStop: Codable, Identifiable, Equatable {
    let id: String
    let stopName: String

    private enum CodingKeys: String, CodingKey {
        case id = "stop_id"
        case stopName = "stop_name"
    }

    init(id: String, stopName: String) {
        self.id = id
        self.stopName = stopName
    }
}
