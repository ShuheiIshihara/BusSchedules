import XCTest
@testable import BusNow

final class StopNameRepositoryTests: XCTestCase {

    // テスト用のダミーバス停マスタ
    private func makeRepository() -> StopNameRepository {
        let stops = [
            Stop(name: "野並", reading: "のなみ"),
            Stop(name: "野並町", reading: "のなみちょう"),
            Stop(name: "東野並", reading: "ひがしのなみ"),  // 「野並」を部分一致で含む
            Stop(name: "緑車庫", reading: "みどりしゃこ"),
            Stop(name: "高辻", reading: "たかつじ")
        ]
        return StopNameRepository(stops: stops)
    }

    func testPrefixMatchComesBeforePartialMatch() {
        // 前方一致が部分一致より先に並ぶこと
        let repo = makeRepository()
        let results = repo.suggestions(for: "野並")

        XCTAssertTrue(results.count >= 3, "野並/野並町/東野並 が候補に含まれるべき")
        // 前方一致（野並・野並町）が部分一致（東野並）より前に来る
        let names = results.map { $0.name }
        let indexNonami = names.firstIndex(of: "野並")!
        let indexNonamicho = names.firstIndex(of: "野並町")!
        let indexHigashi = names.firstIndex(of: "東野並")!
        XCTAssertLessThan(indexNonami, indexHigashi, "前方一致は部分一致より前であるべき")
        XCTAssertLessThan(indexNonamicho, indexHigashi, "前方一致は部分一致より前であるべき")
    }

    func testLimitTruncatesResults() {
        // limit で件数が打ち切られること
        let stops = (0..<20).map { Stop(name: "野並\($0)", reading: nil) }
        let repo = StopNameRepository(stops: stops)

        let results = repo.suggestions(for: "野並", limit: 5)
        XCTAssertEqual(results.count, 5, "limit で件数が打ち切られるべき")
    }

    func testEmptyQueryReturnsEmpty() {
        // 空クエリで空配列が返ること
        let repo = makeRepository()
        XCTAssertTrue(repo.suggestions(for: "").isEmpty, "空クエリは空配列を返すべき")
        XCTAssertTrue(repo.suggestions(for: "   ").isEmpty, "空白のみのクエリは空配列を返すべき")
    }

    func testWhitespaceInQueryIsNormalized() {
        // 全角空白を含むクエリでも正規化されて一致すること
        let repo = makeRepository()
        let results = repo.suggestions(for: "　野並　")
        XCTAssertTrue(results.contains { $0.name == "野並" }, "全角空白付きクエリでも一致するべき")
    }

    func testNoMatchReturnsEmpty() {
        // 一致しないクエリは空配列
        let repo = makeRepository()
        XCTAssertTrue(repo.suggestions(for: "存在しないバス停").isEmpty, "一致しなければ空配列を返すべき")
    }

    func testHiraganaReadingMatch() {
        // ひらがな入力で読みがな一致する（漢字名に「のな」は含まれない）
        let repo = makeRepository()
        let results = repo.suggestions(for: "のな")
        let names = results.map { $0.name }
        XCTAssertTrue(names.contains("野並"), "読み『のなみ』前方一致で野並が出るべき")
        XCTAssertTrue(names.contains("野並町"), "読み前方一致で野並町が出るべき")
        XCTAssertTrue(names.contains("東野並"), "読み部分一致で東野並が出るべき")
    }

    func testKatakanaInputMatchesReading() {
        // カタカナ入力でも読みがな（ひらがな）に一致する
        let repo = makeRepository()
        let results = repo.suggestions(for: "ノナミ")
        XCTAssertTrue(results.contains { $0.name == "野並" }, "カタカナ『ノナミ』でも野並が出るべき")
    }

    func testHalfWidthKatakanaMatchesReading() {
        // 半角カナ入力でも一致する
        let repo = makeRepository()
        let results = repo.suggestions(for: "ﾉﾅﾐ")
        XCTAssertTrue(results.contains { $0.name == "野並" }, "半角カナ『ﾉﾅﾐ』でも野並が出るべき")
    }

    func testKanjiPrefixComesBeforeReadingMatch() {
        // 漢字名の前方一致は、読み一致より先に並ぶ
        let stops = [
            Stop(name: "東野並", reading: "ひがしのなみ"), // 読み部分一致
            Stop(name: "野並", reading: "のなみ")          // 漢字前方一致
        ]
        let repo = StopNameRepository(stops: stops)
        let results = repo.suggestions(for: "野並").map { $0.name }
        XCTAssertEqual(results.first, "野並", "漢字前方一致が先頭に来るべき")
    }
}
