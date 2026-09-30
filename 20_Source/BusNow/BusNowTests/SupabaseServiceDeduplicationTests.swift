import XCTest
@testable import BusNow

final class SupabaseServiceDeduplicationTests: XCTestCase {

    private func make(_ departure: String, arrival: String?, route: String = "名駅１１", destination: String = "名古屋駅（左回り）") -> BusScheduleData {
        BusScheduleData(departureTime: departure, arrivalTime: arrival, routeName: route, destination: destination, platform: "5")
    }

    func testKeepsEarliestArrivalForSameTrip() {
        // 環状線: 同じ出発時刻で「1周して戻る」エントリと直行エントリが返る
        let input = [make("06:20", arrival: "06:47"), make("06:20", arrival: "06:22")]
        let result = SupabaseService.deduplicatedSchedules(input)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.arrivalTime, "06:22")
    }

    func testPreservesOrderAndDistinctTrips() {
        let input = [make("06:20", arrival: "06:22"), make("06:35", arrival: "06:37"), make("06:20", arrival: "06:47")]
        let result = SupabaseService.deduplicatedSchedules(input)
        XCTAssertEqual(result.map(\.departureTime), ["06:20", "06:35"])
    }

    func testDifferentRouteOrDestinationAreNotMerged() {
        let input = [make("07:00", arrival: "07:10", route: "A"), make("07:00", arrival: "07:10", route: "B")]
        XCTAssertEqual(SupabaseService.deduplicatedSchedules(input).count, 2)
    }

    func testNilArrivalLosesToKnownArrival() {
        let input = [make("07:00", arrival: nil), make("07:00", arrival: "07:10")]
        XCTAssertEqual(SupabaseService.deduplicatedSchedules(input).first?.arrivalTime, "07:10")
    }
}
