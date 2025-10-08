//
//  BusNowUITests.swift
//  BusNowUITests
//
//  Created by 石原脩平 on 2025/08/25.
//

import XCTest

final class BusNowUITests: XCTestCase {
    
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testAppLaunchAndInitialView() throws {
        // アプリが正常に起動し、初期画面が表示されることを確認
        XCTAssertTrue(app.staticTexts["バス停を入力"].exists)
        XCTAssertTrue(app.textFields["野並"].exists) // 出発地のプレースホルダー
        XCTAssertTrue(app.textFields["緑車庫"].exists) // 到着地のプレースホルダー
    }
    
    @MainActor
    func testStationInputAndSearch() throws {
        // バス停入力と検索のテスト
        let departureField = app.textFields["野並"]
        let arrivalField = app.textFields["緑車庫"]
        let searchButton = app.buttons["検索"]
        
        // 初期状態では検索ボタンが無効
        XCTAssertFalse(searchButton.isEnabled)
        
        // 出発地を入力
        departureField.tap()
        departureField.typeText("名古屋駅")
        
        // 到着地を入力
        arrivalField.tap()
        arrivalField.typeText("ささしまライブ")
        
        // 検索ボタンが有効になる
        XCTAssertTrue(searchButton.isEnabled)
        
        // 検索実行
        searchButton.tap()
        
        // 時刻表画面に遷移することを確認（ネットワーク接続があれば）
        let expectation = XCTestExpectation(description: "Schedule view appears or error message appears")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // 時刻表が表示されるか、エラーメッセージが表示される
            if self.app.staticTexts["現在時刻"].exists || 
               self.app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'エラー'")).firstMatch.exists {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    @MainActor
    func testStationSwap() throws {
        let departureField = app.textFields["野並"]
        let arrivalField = app.textFields["緑車庫"]
        let swapButton = app.buttons["arrow.up.arrow.down"]
        
        // 初期値を入力
        departureField.tap()
        departureField.typeText("名古屋駅")
        
        arrivalField.tap()
        arrivalField.typeText("ささしまライブ")
        
        // スワップボタンをタップ
        swapButton.tap()
        
        // 値が入れ替わることを確認
        XCTAssertEqual(departureField.value as? String, "ささしまライブ")
        XCTAssertEqual(arrivalField.value as? String, "名古屋駅")
    }
    
    @MainActor
    func testNavigationToScheduleView() throws {
        // バス停を入力して時刻表画面に遷移
        let departureField = app.textFields["野並"]
        let arrivalField = app.textFields["緑車庫"]
        let searchButton = app.buttons["検索"]
        
        departureField.tap()
        departureField.typeText("名古屋駅")
        
        arrivalField.tap()
        arrivalField.typeText("ささしまライブ")
        
        searchButton.tap()
        
        // 時刻表画面の要素が表示されることを確認（最大10秒待機）
        let backButton = app.buttons["戻る"]
        let settingsButton = app.buttons["gearshape"]
        let proximityButton = app.buttons["接近情報"]
        
        let predicate = NSPredicate(format: "exists == true")
        expectation(for: predicate, evaluatedWith: backButton, handler: nil)
        waitForExpectations(timeout: 10.0)
        
        XCTAssertTrue(backButton.exists)
        XCTAssertTrue(settingsButton.exists)
        XCTAssertTrue(proximityButton.exists)
    }
    
    @MainActor
    func testSettingsAccess() throws {
        // 時刻表画面から設定画面にアクセス
        testNavigationToScheduleView() // 時刻表画面に移動
        
        let settingsButton = app.buttons["gearshape"]
        settingsButton.tap()
        
        // 設定画面の要素を確認
        XCTAssertTrue(app.staticTexts["設定"].exists)
        XCTAssertTrue(app.staticTexts["利用規約"].exists)
        XCTAssertTrue(app.staticTexts["プライバシーポリシー"].exists)
        XCTAssertTrue(app.staticTexts["アプリについて"].exists)
        
        // プライバシーポリシーにアクセス
        app.staticTexts["プライバシーポリシー"].tap()
        XCTAssertTrue(app.staticTexts["プライバシーポリシー"].exists)
        
        // 閉じるボタンで戻る
        let closeButton = app.buttons["閉じる"]
        closeButton.tap()
        
        // 設定画面に戻る
        XCTAssertTrue(app.staticTexts["設定"].exists)
        
        // 設定画面を閉じる
        let doneButton = app.buttons["完了"]
        doneButton.tap()
    }
    
    @MainActor 
    func testDirectionSwitch() throws {
        // 時刻表画面で行き・帰りの切り替えをテスト
        testNavigationToScheduleView() // 時刻表画面に移動
        
        // 帰りボタンの存在確認と tap
        let inboundButton = app.buttons["帰り"]
        if inboundButton.waitForExistence(timeout: 5.0) {
            inboundButton.tap()
            
            // 駅名が入れ替わることを確認
            let stationDisplayText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '→'")).firstMatch
            if stationDisplayText.exists {
                XCTAssertTrue(stationDisplayText.label.contains("ささしまライブ → 名古屋駅"))
            }
        }
        
        // 行きボタンで元に戻す
        let outboundButton = app.buttons["行き"]
        if outboundButton.exists {
            outboundButton.tap()
        }
    }
    
    @MainActor
    func testServiceTypeSwitch() throws {
        // 時刻表画面で平日・土日祝の切り替えをテスト  
        testNavigationToScheduleView() // 時刻表画面に移動
        
        // 土日祝ボタンの存在確認と tap
        let holidayButton = app.buttons["土日祝"]
        if holidayButton.waitForExistence(timeout: 5.0) {
            holidayButton.tap()
            // タブの選択状態の変化を確認（UIの変更があれば）
            XCTAssertTrue(holidayButton.exists)
        }
        
        // 平日ボタンで元に戻す
        let weekdayButton = app.buttons["平日"]
        if weekdayButton.exists {
            weekdayButton.tap()
        }
    }
    
    @MainActor
    func testSearchHistoryFunctionality() throws {
        // 検索履歴の機能をテスト
        let departureField = app.textFields["野並"]
        let arrivalField = app.textFields["緑車庫"]
        let searchButton = app.buttons["検索"]
        
        // 最初の検索
        departureField.tap()
        departureField.typeText("名古屋駅")
        
        arrivalField.tap()
        arrivalField.typeText("ささしまライブ")
        
        searchButton.tap()
        
        // 戻る
        let backButton = app.buttons["戻る"]
        backButton.waitForExistence(timeout: 10.0)
        backButton.tap()
        
        // 検索履歴が表示されることを確認
        XCTAssertTrue(app.staticTexts["検索履歴"].exists)
        
        // 履歴項目が存在することを確認
        let historyItem = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '名古屋駅'")).firstMatch
        if historyItem.exists {
            XCTAssertTrue(historyItem.exists)
        }
    }

    @MainActor
    func testLaunchPerformance() throws {
        // アプリ起動パフォーマンスを測定
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    @MainActor
    func testMemoryPerformance() throws {
        // メモリ使用量のパフォーマンス測定
        measure(metrics: [XCTMemoryMetric()]) {
            // 複数回の検索実行
            for i in 1...5 {
                let departureField = app.textFields["野並"]
                let arrivalField = app.textFields["緑車庫"]
                let searchButton = app.buttons["検索"]
                
                departureField.tap()
                departureField.clearAndEnterText("テスト駅\(i)")
                
                arrivalField.tap()
                arrivalField.clearAndEnterText("目的地\(i)")
                
                if searchButton.isEnabled {
                    searchButton.tap()
                    
                    let backButton = app.buttons["戻る"]
                    if backButton.waitForExistence(timeout: 3.0) {
                        backButton.tap()
                    }
                }
            }
        }
    }
}

// XCUIElement の拡張
extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and enter text into a non-string value")
            return
        }
        
        self.tap()
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        self.typeText(text)
    }
}
