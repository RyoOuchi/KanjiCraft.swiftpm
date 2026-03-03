import SwiftUI

struct RadicalTileView: View {
    let radical: RadicalEntry
    let isSelected: Bool
    let isHintHighlighted: Bool
    let tileScaleMultiplier: CGFloat

    init(
        radical: RadicalEntry,
        isSelected: Bool,
        isHintHighlighted: Bool,
        tileScaleMultiplier: CGFloat = 1.0
    ) {
        self.radical = radical
        self.isSelected = isSelected
        self.isHintHighlighted = isHintHighlighted
        self.tileScaleMultiplier = tileScaleMultiplier
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(radical.symbol)
                .font(AppFont.kanji(size: 34 * tileScaleMultiplier))
                .frame(maxWidth: .infinity)
            Text(radical.primaryMeaning)
                .font(.system(size: 12 * min(tileScaleMultiplier, 1.3)))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.vertical, 8 * min(tileScaleMultiplier, 1.5))
        .padding(.horizontal, 6 * min(tileScaleMultiplier, 1.35))
        .frame(minHeight: 72 * tileScaleMultiplier)
        .background(backgroundColor, in: RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(borderColor, lineWidth: borderLineWidth)
        )
        .shadow(color: shadowColor, radius: 3, x: 0, y: 1)
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.blue.opacity(0.22)
        }
        if isHintHighlighted {
            return Color.accentColor.opacity(0.18)
        }
        return Color.secondary.opacity(0.12)
    }

    private var borderColor: Color {
        if isSelected {
            return .blue
        }
        if isHintHighlighted {
            return .accentColor
        }
        return Color.secondary.opacity(0.3)
    }

    private var borderLineWidth: Double {
        if isSelected || isHintHighlighted {
            return 2
        }
        return 1
    }

    private var shadowColor: Color {
        if isHintHighlighted {
            return Color.accentColor.opacity(0.12)
        }
        return Color.black.opacity(0.08)
    }
}
