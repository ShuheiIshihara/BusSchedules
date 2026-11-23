import XCTest
@testable import BusNow

/// Verifies SupabaseService.deduplicatedSchedules against the shared fixture
/// Fixtures/dedup_cases.json, which scripts/test_dedup_rule.py (check_dedup.py) also uses.
/// If either side changes the rule, one of the two tests fails until both are aligned.
final class DedupRuleTests: XCTestCase {

    private struct Fixture: Decodable {
        let cases: [Case]
    }

    private struct Case: Decodable {
        let name: String
        let input: [BusScheduleRPCResponse]
        let expected: [String]
    }

    private func loadCases() throws -> [Case] {
        let url = try XCTUnwrap(
            Bundle(for: Self.self).url(forResource: "dedup_cases", withExtension: "json"),
            "dedup_cases.json is not bundled with the test target"
        )
        return try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url)).cases
    }

    func testSharedFixtureCases() throws {
        let cases = try loadCases()
        XCTAssertFalse(cases.isEmpty)
        for testCase in cases {
            let schedules = testCase.input.map { BusScheduleData(from: $0) }
            let kept = SupabaseService.deduplicatedSchedules(schedules).map(\.platform)
            XCTAssertEqual(kept, testCase.expected, testCase.name)
        }
    }
}
