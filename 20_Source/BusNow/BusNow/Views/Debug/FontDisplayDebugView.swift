import SwiftUI

struct FontDisplayDebugView: View {
    @State private var testText = "高辻駅"
    @State private var showFontList = false
    @State private var availableFonts: [String] = []
    @State private var selectedFontName = "YuGothic-Medium"
    
    private let testCharacters = [
        "辻", // U+8FBB - standard tsuji
        "辻\u{E0100}", // U+8FBB + variant selector for 1-dot shinnyou
        "高辻", // Takatsuji with standard characters
        "高辻\u{E0100}", // Takatsuji with variant selector
        "名古屋→高辻", // Route example
        "高辻→ささしまライブ" // Route example
    ]
    
    private let fontTestCandidates = [
        "YuGothic-Medium",
        "YuGothic-Regular",
        "HiraginoSans-W3",
        "HiraginoSans-W6", 
        "HiraKakuProN-W3",
        "HiraKakuProN-W6",
        "System"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    
                    characterTestSection
                    
                    fontComparisonSection
                    
                    normalizedTextSection
                    
                    systemInfoSection
                }
                .padding()
            }
            .navigationTitle("フォント表示テスト")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadAvailableFonts()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("辻文字（1点しんにょう）表示テスト")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text("各フォントでの「辻」文字の表示確認")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var characterTestSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("文字別表示テスト")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(testCharacters, id: \.self) { character in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("文字:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(character)
                            .stationNameLargeFont()
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(getUnicodeInfo(character))
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private var fontComparisonSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("フォント別比較")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(fontTestCandidates, id: \.self) { fontName in
                HStack {
                    Text(fontName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 140, alignment: .leading)
                    
                    Text("高辻\u{E0100}")
                        .font(fontName == "System" ? .system(size: 18, weight: .medium) : .custom(fontName, size: 18))
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(isFontAvailable(fontName) ? "✅" : "❌")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(8)
            }
        }
    }
    
    private var normalizedTextSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("正規化テスト")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("入力:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("テスト文字を入力", text: $testText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("検索用正規化: \(testText.normalizedForSearch())")
                        .font(.body)
                    
                    Text("表示用正規化: \(testText.normalizedForDisplay())")
                        .stationNameLargeFont()
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(8)
                
                Button("「高辻」検索テストを実行") {
                    Task {
                        _ = await SupabaseService.shared.testTakatsujiSearch()
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.top, 8)
            }
        }
    }
    
    private var systemInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("システム情報")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("iOS Version: \(UIDevice.current.systemVersion)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Device: \(UIDevice.current.model)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button("利用可能フォント一覧を表示") {
                    showFontList.toggle()
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                if showFontList {
                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(availableFonts, id: \.self) { font in
                                Text(font)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private func loadAvailableFonts() {
        availableFonts = UIFont.familyNames.flatMap { familyName in
            UIFont.fontNames(forFamilyName: familyName)
        }.sorted()
    }
    
    private func isFontAvailable(_ fontName: String) -> Bool {
        return fontName == "System" || UIFont(name: fontName, size: 16) != nil
    }
    
    private func getUnicodeInfo(_ string: String) -> String {
        return string.unicodeScalars.map { 
            "U+\(String($0.value, radix: 16, uppercase: true))" 
        }.joined(separator: " ")
    }
}

#Preview {
    FontDisplayDebugView()
}