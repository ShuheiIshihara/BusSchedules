import SwiftUI
import UIKit

extension Font {
    // iOS標準フォントで1点しんにょう表示を試行（優先順位順）
    static let stationName = Font.custom("YuGothic-Medium", size: 16, relativeTo: .body)
    static let stationNameLarge = Font.custom("YuGothic-Medium", size: 18, relativeTo: .title2)
    static let stationNameSmall = Font.custom("YuGothic-Medium", size: 14, relativeTo: .caption)
    
    static let busScheduleRoute = Font.custom("YuGothic-Medium", size: 14, relativeTo: .body)
    static let busScheduleDestination = Font.custom("YuGothic-Medium", size: 12, relativeTo: .caption)
    
    // フォールバック用システムフォント
    static let stationNameSystem = Font.system(size: 16, weight: .medium, design: .default)
    static let stationNameLargeSystem = Font.system(size: 18, weight: .semibold, design: .default)
}

struct ConsistentFontModifier: ViewModifier {
    let fontStyle: Font
    
    func body(content: Content) -> some View {
        content
            .font(fontStyle)
    }
}

extension View {
    func stationNameFont() -> some View {
        self.modifier(ConsistentFontModifier(fontStyle: .stationName))
    }
    
    func stationNameLargeFont() -> some View {
        self.modifier(ConsistentFontModifier(fontStyle: .stationNameLarge))
    }
    
    func stationNameSmallFont() -> some View {
        self.modifier(ConsistentFontModifier(fontStyle: .stationNameSmall))
    }
    
    func busRouteFont() -> some View {
        self.modifier(ConsistentFontModifier(fontStyle: .busScheduleRoute))
    }
    
    func busDestinationFont() -> some View {
        self.modifier(ConsistentFontModifier(fontStyle: .busScheduleDestination))
    }
}

// フォント情報デバッグ用
class FontDebugHelper {
    static func printAvailableFonts() {
        print("=== 利用可能なフォント一覧 ===")
        UIFont.familyNames.sorted().forEach { familyName in
            print("Family: \(familyName)")
            UIFont.fontNames(forFamilyName: familyName).forEach { fontName in
                print("  - \(fontName)")
            }
        }
    }
    
    static func testTsujiCharacter() {
        let testChar = "辻"
        print("=== 辻文字フォント表示テスト ===")
        
        let testFonts = [
            "YuGothic-Medium",
            "YuGothic-Regular", 
            "HiraKakuProN-W3",
            "HiraKakuProN-W6",
            "HiraginoSans-W3",
            "HiraginoSans-W6",
            "NotoSansCJKjp-Regular"
        ]
        
        testFonts.forEach { fontName in
            if let font = UIFont(name: fontName, size: 16) {
                print("✅ \(fontName): 利用可能")
            } else {
                print("❌ \(fontName): 利用不可")
            }
        }
    }
}