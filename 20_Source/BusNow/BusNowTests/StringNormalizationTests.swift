import XCTest
@testable import BusNow

final class StringNormalizationTests: XCTestCase {
    
    func testBasicUnicodeNormalization() {
        // 基本的なUnicode正規化テスト
        let input = "高辻"  // 標準的な文字列
        let normalized = StringNormalization.normalizeForSearch(input)
        XCTAssertEqual(normalized, input, "標準的な文字列は変更されないべき")
    }
    
    func testComposedCharacterNormalization() {
        // Unicode合成文字の正規化テスト
        let decomposed = "が" // NFD形式（濁点分離）
        let composed = "が"   // NFC形式（濁点合成）
        
        let normalized = StringNormalization.normalizeForSearch(decomposed)
        XCTAssertEqual(normalized, composed, "Unicode文字が正規化されるべき")
    }
    
    func testStationNameConsistency() {
        // 駅名の一貫性テスト（フォント表示問題対応）
        let stationNames = ["高辻", "新宿", "池袋", "上野"]
        
        for stationName in stationNames {
            let normalized = StringNormalization.normalizeForSearch(stationName)
            XCTAssertEqual(normalized, stationName, "標準的な駅名「\(stationName)」は変更されないべき")
        }
    }
    
    
    func testWhitespaceNormalization() {
        // 空白文字の正規化テスト
        let inputWithVariousWhitespace = " 　高辻　駅 \t\n"  // 全角・半角空白、タブ、改行
        let expectedOutput = "高辻 駅"  // 前後削除、全角→半角、連続空白削除
        
        let normalized = StringNormalization.normalizeForSearch(inputWithVariousWhitespace)
        XCTAssertEqual(normalized, expectedOutput, "空白文字が正しく正規化されるべき")
    }
    
    func testEmptyStringHandling() {
        // 空文字列の処理テスト
        let emptyString = ""
        let normalized = StringNormalization.normalizeForSearch(emptyString)
        XCTAssertEqual(normalized, "", "空文字列は変更されずに返されるべき")
    }
    
    func testNormalCharactersUnchanged() {
        // 通常の文字が変更されないことを確認
        let normalText = "名古屋駅"
        let normalized = StringNormalization.normalizeForSearch(normalText)
        XCTAssertEqual(normalized, normalText, "通常の文字は変更されないべき")
    }
    
    func testStringExtension() {
        // String拡張機能のテスト
        let testString = "高辻駅"
        let normalized = testString.normalizedForSearch()
        XCTAssertEqual(normalized, testString, "String拡張による正規化が機能すべき")
        
        // フォント表示問題解決のため、異体字検出機能は簡素化
        XCTAssertFalse(testString.containsVariantCharacters(), "標準的な文字列は異体字を含まないべき")
    }
}