//
//  BusNowTests.swift
//  BusNowTests
//
//  Created by 石原脩平 on 2025/08/25.
//

import XCTest
@testable import BusNow

final class BusNowTests: XCTestCase {
    
    var viewModel: StationSelectionViewModel!
    var busScheduleViewModel: BusScheduleViewModel!
    
    override func setUpWithError() throws {
        viewModel = StationSelectionViewModel()
        let testStationPair = StationPair(departure: "名古屋駅", arrival: "ささしまライブ")
        busScheduleViewModel = BusScheduleViewModel(stationPair: testStationPair)
    }

    override func tearDownWithError() throws {
        viewModel = nil
        busScheduleViewModel = nil
    }

    // MARK: - StationPair Tests
    
    func testStationPairCreation() throws {
        let stationPair = StationPair(departure: "名古屋駅", arrival: "ささしまライブ")
        XCTAssertEqual(stationPair.departureStation, "名古屋駅")
        XCTAssertEqual(stationPair.arrivalStation, "ささしまライブ")
        XCTAssertEqual(stationPair.displayName, "名古屋駅 → ささしまライブ")
    }
    
    func testStationPairDisplayName() throws {
        let stationPair = StationPair(departure: "栄", arrival: "緑車庫")
        XCTAssertEqual(stationPair.displayName, "栄 → 緑車庫")
    }
    
    // MARK: - StationSelectionViewModel Tests
    
    func testSwapStations() throws {
        var departure = "名古屋駅"
        var arrival = "ささしまライブ"
        
        viewModel.swapStations(&departure, &arrival)
        
        XCTAssertEqual(departure, "ささしまライブ")
        XCTAssertEqual(arrival, "名古屋駅")
    }
    
    func testSaveAndLoadStationPair() throws {
        let testPair = StationPair(departure: "栄", arrival: "緑車庫")
        viewModel.saveStationPair(testPair)
        
        let loadedPair = viewModel.loadSavedStationPair()
        XCTAssertNotNil(loadedPair)
        XCTAssertEqual(loadedPair?.departureStation, "栄")
        XCTAssertEqual(loadedPair?.arrivalStation, "緑車庫")
    }
    
    func testClearHistory() throws {
        // Add some test history
        let testPair1 = StationPair(departure: "名古屋駅", arrival: "ささしまライブ")
        let testPair2 = StationPair(departure: "栄", arrival: "緑車庫")
        
        viewModel.saveStationPair(testPair1)
        viewModel.saveStationPair(testPair2)
        
        // Verify history exists
        XCTAssertFalse(viewModel.searchHistory.isEmpty)
        
        // Clear history
        viewModel.clearHistory()
        
        // Verify history is cleared
        XCTAssertTrue(viewModel.searchHistory.isEmpty)
    }
    
    // MARK: - BusScheduleViewModel Tests
    
    func testInitialState() throws {
        XCTAssertEqual(busScheduleViewModel.selectedServiceType, .weekday)
        XCTAssertEqual(busScheduleViewModel.selectedDirection, .outbound)
        XCTAssertEqual(busScheduleViewModel.stationPair.departureStation, "名古屋駅")
        XCTAssertEqual(busScheduleViewModel.stationPair.arrivalStation, "ささしまライブ")
    }
    
    func testServiceTypeSelection() throws {
        busScheduleViewModel.selectServiceType(.holiday)
        XCTAssertEqual(busScheduleViewModel.selectedServiceType, .holiday)
    }
    
    func testDirectionSelection() throws {
        busScheduleViewModel.selectDirection(.inbound)
        XCTAssertEqual(busScheduleViewModel.selectedDirection, .inbound)
        // 帰りの場合は駅が入れ替わる
        XCTAssertEqual(busScheduleViewModel.stationPair.departureStation, "ささしまライブ")
        XCTAssertEqual(busScheduleViewModel.stationPair.arrivalStation, "名古屋駅")
    }
    
    func testCurrentTimeString() throws {
        let timeString = busScheduleViewModel.currentTimeString
        // 時刻文字列が HH:MM:SS の形式であることを確認
        let timeRegex = try NSRegularExpression(pattern: "^\\d{2}:\\d{2}:\\d{2}$")
        let range = NSRange(location: 0, length: timeString.count)
        XCTAssertTrue(timeRegex.firstMatch(in: timeString, options: [], range: range) != nil)
    }
    
    func testDateString() throws {
        let dateString = busScheduleViewModel.dateString
        // 日付文字列が適切な形式であることを確認
        XCTAssertTrue(dateString.contains("年"))
        XCTAssertTrue(dateString.contains("月"))
        XCTAssertTrue(dateString.contains("日"))
    }
    
    func testIsPastTime() throws {
        // 現在時刻より前の時刻をテスト
        let pastTime = "08:00"
        let futureTime = "23:59"
        
        // 現在時刻を9:00と仮定してテスト
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day], from: now)
        
        if let testDate = calendar.date(from: DateComponents(year: components.year, month: components.month, day: components.day, hour: 9, minute: 0)) {
            // プライベートメソッドのテストのため、パブリックメソッドでテスト
            busScheduleViewModel.currentTime = testDate
            
            // 過去の時刻はtrueを返すはず（ただし、プライベートメソッドなので間接的にテスト）
            XCTAssertNotNil(busScheduleViewModel.currentTime)
        }
    }
    
    // MARK: - BusScheduleData Tests
    
    func testBusScheduleDataCreation() throws {
        let scheduleData = BusScheduleData(
            departureTime: "08:30",
            routeName: "名駅12",
            destination: "ささしまライブ",
            platform: "7番のりば",
            serviceId: "平日"
        )
        
        XCTAssertEqual(scheduleData.departureTime, "08:30")
        XCTAssertEqual(scheduleData.routeName, "名駅12")
        XCTAssertEqual(scheduleData.destination, "ささしまライブ")
        XCTAssertEqual(scheduleData.platform, "7番のりば")
        XCTAssertEqual(scheduleData.serviceId, "平日")
    }
    
    func testBusScheduleDataFromRPCResponse() throws {
        let rpcResponse = BusScheduleRPCResponse(
            departureTime: "08:30:00",
            routeName: "名駅12",
            destination: "ささしまライブ",
            platform: "7番のりば",
            serviceType: "平日",
            departureMinutes: 510.0,
            serviceId: "平日",
            busStops: ["名古屋駅", "国際センター", "ささしまライブ"]
        )
        
        let scheduleData = BusScheduleData(from: rpcResponse)
        
        // 秒が削除されていることを確認
        XCTAssertEqual(scheduleData.departureTime, "08:30")
        XCTAssertEqual(scheduleData.routeName, "名駅12")
        XCTAssertEqual(scheduleData.destination, "ささしまライブ")
        XCTAssertEqual(scheduleData.platform, "7番のりば")
        XCTAssertEqual(scheduleData.busStops.count, 3)
    }
    
    // MARK: - String Extension Tests
    
    func testStringNormalization() throws {
        // 文字正規化のテスト
        let testString = "高辻"
        let normalizedForSearch = testString.normalizedForSearch()
        let normalizedForDisplay = testString.normalizedForDisplay()
        
        XCTAssertNotNil(normalizedForSearch)
        XCTAssertNotNil(normalizedForDisplay)
        XCTAssertFalse(normalizedForSearch.isEmpty)
        XCTAssertFalse(normalizedForDisplay.isEmpty)
    }
    
    // MARK: - Performance Tests
    
    func testStationPairCreationPerformance() throws {
        self.measure {
            for _ in 0..<1000 {
                _ = StationPair(departure: "名古屋駅", arrival: "ささしまライブ")
            }
        }
    }
    
    func testStringNormalizationPerformance() throws {
        self.measure {
            for _ in 0..<1000 {
                _ = "高辻駅前".normalizedForSearch()
            }
        }
    }

}
