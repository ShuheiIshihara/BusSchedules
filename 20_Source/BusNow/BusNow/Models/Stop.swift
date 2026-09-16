import Foundation

// バンドルした stops.json の1要素に対応するバス停マスタ
struct Stop: Codable, Identifiable, Equatable {
    var id: String { name }   // 漢字名をそのまま一意キーに使う
    let name: String          // 漢字バス停名（表示・一致対象）
    let reading: String?      // ひらがな読み（将来のかな変換用。現状は未使用）
}
