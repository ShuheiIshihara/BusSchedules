import SwiftUI

// デザイントークン（D案 / ライト・ダーク対応）
extension Color {
    // プライマリ青 #0a84ff（ライト/ダーク共通）
    static let busAccent = Color(red: 10 / 255, green: 132 / 255, blue: 255 / 255)

    // ライト/ダークで値を切り替える Color を生成
    init(light: UIColor, dark: UIColor) {
        self = Color(UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }

    // ドロップダウン面: 白 / #2c2c2e（ダークは黒背景から浮かせる）
    static let busDropSurface = Color(
        light: .white,
        dark: UIColor(red: 44 / 255, green: 44 / 255, blue: 46 / 255, alpha: 1)
    )
    // フォーカス中のフィールド背景: 白 / #3a3a3c
    static let busFieldFocus = Color(
        light: .white,
        dark: UIColor(red: 58 / 255, green: 58 / 255, blue: 60 / 255, alpha: 1)
    )
    // 区切り線: rgba(60,60,67,0.13) / rgba(84,84,88,0.65)
    static let busSeparator = Color(
        light: UIColor(red: 60 / 255, green: 60 / 255, blue: 67 / 255, alpha: 0.13),
        dark: UIColor(red: 84 / 255, green: 84 / 255, blue: 88 / 255, alpha: 0.65)
    )
    // ピン円の背景: rgba(10,132,255,0.12) / rgba(10,132,255,0.24)
    static let busPinBackground = Color(
        light: UIColor(red: 10 / 255, green: 132 / 255, blue: 255 / 255, alpha: 0.12),
        dark: UIColor(red: 10 / 255, green: 132 / 255, blue: 255 / 255, alpha: 0.24)
    )
}

// TextField 直下に重ねて表示するサジェスト候補ドロップダウン（D案）
struct StopSuggestionList: View {
    let heading: String          // 「出発バス停の候補」/「到着バス停の候補」
    let query: String            // 入力文字列（候補なし表示で使用）
    let suggestions: [Stop]
    let onSelect: (String) -> Void

    @Environment(\.colorScheme) private var colorScheme

    // 行高56px・4件分でスクロール
    private let rowHeight: CGFloat = 56
    private let visibleRows: CGFloat = 4
    // 下側のみ角丸14
    private let dropShape = UnevenRoundedRectangle(
        cornerRadii: .init(bottomLeading: 14, bottomTrailing: 14)
    )

    var body: some View {
        VStack(spacing: 0) {
            headingBar
            if suggestions.isEmpty {
                emptyState
            } else {
                candidateList
            }
        }
        .background(Color.busDropSurface)
        .clipShape(dropShape)
        // 上辺ボーダー 0.5px
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.busSeparator)
                .frame(height: 0.5)
        }
        // ダーク時は枠線を足して黒背景から輪郭を立たせる
        .overlay {
            if colorScheme == .dark {
                dropShape.stroke(Color.white.opacity(0.16), lineWidth: 1)
            }
        }
        // 影（ダークは濃く）
        .shadow(
            color: .black.opacity(colorScheme == .dark ? 0.75 : 0.15),
            radius: colorScheme == .dark ? 17 : 15,
            x: 0, y: 12
        )
    }

    // 編集中の欄に応じた固定見出し（青背景＋白字で強調）
    private var headingBar: some View {
        HStack(spacing: 7) {
            Image(systemName: "location.fill")
                .font(.system(size: 13))
                .foregroundColor(.white)
            Text(heading)
                .font(.system(size: 13, weight: .bold))
                .kerning(0.3)
                .foregroundColor(.white)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.busAccent)
    }

    // 候補リスト（スクロール領域）
    // overlay 内ではフィールド高(52pt)が提案されるため、ScrollView を maxHeight で置くと
    // 潰れて視認できなくなる。表示件数ぶんの「確定した高さ」を与える（最大4件=224px）。
    private var candidateList: some View {
        let visibleCount = min(suggestions.count, Int(visibleRows))
        return ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, stop in
                    Button(action: { onSelect(stop.name) }) {
                        row(for: stop, isLast: index == suggestions.count - 1)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(height: CGFloat(visibleCount) * rowHeight)
    }

    // 候補の各行
    private func row(for stop: Stop, isLast: Bool) -> some View {
        HStack(spacing: 13) {
            ZStack {
                Circle()
                    .fill(Color.busPinBackground)
                    .frame(width: 32, height: 32)
                Image(systemName: "mappin")
                    .font(.system(size: 15))
                    .foregroundColor(.busAccent)
            }
            Text(stop.name.normalizedForDisplay())   // 表示は一点しんにょう
                .font(.system(size: 17, weight: .medium))
                .kerning(-0.3)
                .foregroundColor(.primary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .frame(height: rowHeight)
        .contentShape(Rectangle())
        // 区切り線（最終行以外、左61pxインセット）
        .overlay(alignment: .bottomLeading) {
            if !isLast {
                Rectangle()
                    .fill(Color.busSeparator)
                    .frame(height: 0.5)
                    .padding(.leading, 61)
            }
        }
    }

    // 候補が0件のときの表示
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 24))
                .foregroundColor(Color(
                    light: UIColor(red: 184 / 255, green: 184 / 255, blue: 192 / 255, alpha: 1),
                    dark: UIColor(red: 138 / 255, green: 138 / 255, blue: 144 / 255, alpha: 1)
                ))
            Text("候補がありません")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.primary.opacity(0.85))
            Text("「\(query)」に一致するバス停が見つかりません")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.init(top: 26, leading: 20, bottom: 28, trailing: 20))
    }
}

#Preview {
    VStack(spacing: 24) {
        StopSuggestionList(
            heading: "出発バス停の候補",
            query: "なるみ",
            suggestions: [
                Stop(name: "名鉄鳴海駅", reading: "めいてつなるみえき"),
                Stop(name: "鳴海", reading: "なるみ"),
                Stop(name: "鳴海駅前", reading: "なるみえきまえ")
            ],
            onSelect: { _ in }
        )
        StopSuggestionList(
            heading: "到着バス停の候補",
            query: "ぐぐ",
            suggestions: [],
            onSelect: { _ in }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
