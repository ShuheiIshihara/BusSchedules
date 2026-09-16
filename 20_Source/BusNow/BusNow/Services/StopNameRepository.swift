import Foundation

// バンドルした stops.json を読み込み、バス停名の候補検索を提供するリポジトリ
final class StopNameRepository {
    static let shared = StopNameRepository()

    // 全バス停（読み込み済みをメモリ保持）
    private let stops: [Stop]
    // 検索用に正規化済みの「漢字名」と「読みがな」をあらかじめ持つ（毎入力での再正規化を避ける）
    private let normalizedIndex: [(stop: Stop, name: String, reading: String)]

    // 本番用：バンドルから読み込む
    private convenience init() {
        self.init(stops: Self.loadFromBundle())
    }

    // テスト・将来の差し替え用：任意のバス停配列を注入できる
    init(stops: [Stop]) {
        self.stops = stops
        self.normalizedIndex = stops.map {
            ($0, $0.name.normalizedForSearch(), ($0.reading ?? "").normalizedKana())
        }
    }

    private static func loadFromBundle() -> [Stop] {
        guard let url = Bundle.main.url(forResource: "stops", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let stops = try? JSONDecoder().decode([Stop].self, from: data) else {
            // 読み込み失敗時は空配列（サジェストが出ないだけで検索自体は従来通り動く）
            #if DEBUG
            print("StopNameRepository: stops.json の読み込みに失敗しました")
            #endif
            return []
        }
        return stops
    }

    // 入力文字列に対する候補を返す。
    // 漢字名・読みがな（ひらがな/カタカナ入力）の両方を対象に、
    // 「漢字名 前方一致 → 読み 前方一致 → 漢字名 部分一致 → 読み 部分一致」の優先順で並べ、上限で打ち切る。
    func suggestions(for query: String, limit: Int = 8) -> [Stop] {
        let nameQuery = query.normalizedForSearch()   // 漢字・そのままの一致用
        let kanaQuery = query.normalizedKana()        // 読みがな（カナ→ひらがな）一致用
        guard !nameQuery.isEmpty else { return [] }

        var namePrefix: [Stop] = []
        var readingPrefix: [Stop] = []
        var namePartial: [Stop] = []
        var readingPartial: [Stop] = []

        for entry in normalizedIndex {
            if entry.name.hasPrefix(nameQuery) {
                namePrefix.append(entry.stop)
            } else if !kanaQuery.isEmpty, entry.reading.hasPrefix(kanaQuery) {
                readingPrefix.append(entry.stop)
            } else if entry.name.contains(nameQuery) {
                namePartial.append(entry.stop)
            } else if !kanaQuery.isEmpty, entry.reading.contains(kanaQuery) {
                readingPartial.append(entry.stop)
            }
        }
        return Array((namePrefix + readingPrefix + namePartial + readingPartial).prefix(limit))
    }
}
