import Foundation

class StringNormalization {
    
    // 2点しんにょう → 1点しんにょう変換マッピング
    private static let shinnnyouMapping: [String: String] = [
        "辻": "辻󠄀",  // U+8FBB (2点) → U+8FBB + 異体字セレクタ (1点表示)
        "込": "込",  // U+8FBC (2点) → U+8FBC + 異体字セレクタ (1点表示)  
        "迫": "迫",  // U+8FEB (2点) → U+8FEB + 異体字セレクタ (1点表示)
        "追": "追",  // U+8FFD (2点) → U+8FFD + 異体字セレクタ (1点表示)
    ]
    
    private static let variantCharacterMapping: [String: String] = [:]
    
    static func normalizeForSearch(_ input: String) -> String {
        guard !input.isEmpty else { return input }
        
        var normalizedString = input
        
        // Unicode正規化（合成文字の統一）
        normalizedString = normalizeUnicode(normalizedString)
        
        // 検索時は1点しんにょう入力を2点しんにょうに変換（データベースマッチング用）
        normalizedString = convertToTwoPointShinnyou(normalizedString)
        
        // ホワイトスペース正規化
        normalizedString = normalizeWhitespace(normalizedString)
        
        return normalizedString
    }
    
    // 表示用に1点しんにょうを強制する関数
    static func normalizeForDisplay(_ input: String) -> String {
        guard !input.isEmpty else { return input }
        
        var normalizedString = input
        
        // Unicode正規化（合成文字の統一）
        normalizedString = normalizeUnicode(normalizedString)
        
        // 2点しんにょう文字を1点しんにょう表示に変換
        normalizedString = convertToOnePointShinnyou(normalizedString)
        
        // ホワイトスペース正規化
        normalizedString = normalizeWhitespace(normalizedString)
        
        return normalizedString
    }
    
    private static func normalizeUnicode(_ string: String) -> String {
        return string.precomposedStringWithCanonicalMapping
    }
    
    
    private static func normalizeWhitespace(_ string: String) -> String {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = trimmed.replacingOccurrences(of: "　", with: " ")
        return normalized.replacingOccurrences(
            of: "\\s+", 
            with: " ", 
            options: .regularExpression
        )
    }
    
    // DB上で異体字セレクタ(U+E0100)付きで保存されていることを確認済みの文字。
    // 確認元: RPC結果CSV(辻のみ。例: 高辻󠄀、辻󠄀本通)。込・迫・追はDBでの表記が未確認のため、検索では変更しない。
    private static let databaseSelectorCharacters: [String] = ["辻"]
    
    // 検索用：DBの表記に合わせる(DBでセレクタ付きの文字に、無ければ付与する)
    private static func convertToTwoPointShinnyou(_ string: String) -> String {
        return appendingVariationSelector(to: string, characters: databaseSelectorCharacters)
    }
    
    // 表示用：しんにょう文字すべてにセレクタを付与して1点表示を強制する
    private static func convertToOnePointShinnyou(_ string: String) -> String {
        return appendingVariationSelector(to: string, characters: Array(shinnnyouMapping.keys))
    }
    
    // 指定文字の直後に異体字セレクタが無ければ付与する
    private static func appendingVariationSelector(to string: String, characters: [String]) -> String {
        var result = string
        for character in characters {
            let pattern = "\(character)(?!\u{E0100})"
            result = result.replacingOccurrences(
                of: pattern,
                with: "\(character)\u{E0100}",
                options: .regularExpression
            )
        }
        return result
    }
    
    static func isVariantCharacter(_ character: String) -> Bool {
        return variantCharacterMapping.keys.contains(character)
    }
    
    static func getStandardCharacter(for variant: String) -> String? {
        return variantCharacterMapping[variant]
    }
    
    static func debugCharacterInfo(_ string: String) -> [(character: String, unicode: String, isVariant: Bool)] {
        return string.map { char in
            let charString = String(char)
            let unicode = char.unicodeScalars.map { "U+\(String($0.value, radix: 16).uppercased())" }.joined(separator: " ")
            let isVariant = isVariantCharacter(charString)
            return (character: charString, unicode: unicode, isVariant: isVariant)
        }
    }
}

extension String {
    func normalizedForSearch() -> String {
        return StringNormalization.normalizeForSearch(self)
    }
    
    func normalizedForDisplay() -> String {
        return StringNormalization.normalizeForDisplay(self)
    }
    
    func containsVariantCharacters() -> Bool {
        return self.contains { char in
            StringNormalization.isVariantCharacter(String(char))
        }
    }
}
