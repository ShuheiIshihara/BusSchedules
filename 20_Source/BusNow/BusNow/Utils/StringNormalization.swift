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
    
    // 検索用：異体字セレクタを除去してデータベース文字と一致させる
    private static func convertToTwoPointShinnyou(_ string: String) -> String {
        var result = string
        
        // 各しんにょう文字に異体字セレクタを追加して1点表示を強制
        for (twoPoint, _) in shinnnyouMapping {
            // 既に異体字セレクタが付いていない場合のみ追加
            let pattern = "\(twoPoint)(?!\u{E0100})"
            result = result.replacingOccurrences(
                of: pattern,
                with: "\(twoPoint)\u{E0100}",
                options: .regularExpression
            )
        }
        
        return result
    }
    
    // 表示用：2点しんにょう文字を1点しんにょう表示に変換
    private static func convertToOnePointShinnyou(_ string: String) -> String {
        var result = string
        
        // 各しんにょう文字に異体字セレクタを追加して1点表示を強制
        for (twoPoint, _) in shinnnyouMapping {
            // 既に異体字セレクタが付いていない場合のみ追加
            let pattern = "\(twoPoint)(?!\u{E0100})"
            result = result.replacingOccurrences(
                of: pattern,
                with: "\(twoPoint)\u{E0100}",
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
