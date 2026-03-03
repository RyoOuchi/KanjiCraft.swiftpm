import SwiftUI
import UIKit

struct PuzzleSlotView: View {
    let slot: PuzzleSlot
    let frameSize: CGSize
    let glyphScaleOverride: Double?
    let glyphStretchXOverride: Double?
    let glyphStretchYOverride: Double?
    let placedRadical: RadicalEntry?
    let isTapSelected: Bool
    let isHovered: Bool
    let hoverIsWarning: Bool
    let showReplaceIndicator: Bool
    let previewRadical: RadicalEntry?
    let feedback: PuzzleViewModel.PlacementFeedback?

    @State private var showPositiveFeedback = false
    @State private var showNegativeFeedback = false
    @State private var shakeTrigger: CGFloat = 0

    private let glyphInsetRatio: CGFloat = 0.06
    private var frameUShape: FrameUShape {
        let baseRatio = slot.frameUThicknessRatio ?? 0.16
        return FrameUShape(
            sideThicknessRatio: CGFloat(slot.frameUSideThicknessRatio ?? baseRatio),
            topThicknessRatio: CGFloat(slot.frameUTopThicknessRatio ?? baseRatio)
        )
    }

    var body: some View {
        ZStack {
            subdivisionFill

            if let placedRadical {
                gridPiece(for: placedRadical, opacity: 1.0)
            } else if let previewRadical {
                gridPiece(for: previewRadical, opacity: 0.45)
            } else {
                Circle()
                    .fill(Color.secondary.opacity(0.10))
                    .frame(width: min(frameSize.width, frameSize.height) * 0.10)
            }

            if showReplaceIndicator {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .foregroundStyle(.orange)
                    .font(.title3)
                    .padding(6)
                    .background(.ultraThinMaterial, in: Circle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(6)
            }

            if showPositiveFeedback {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title2)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .overlay {
            subdivisionStroke
        }
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .modifier(ShakeEffect(animatableData: shakeTrigger))
        .onChange(of: feedback) { _, newFeedback in
            switch newFeedback {
            case .positive:
                withAnimation(.easeOut(duration: 0.18)) {
                    showPositiveFeedback = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
                    withAnimation(.easeIn(duration: 0.18)) {
                        showPositiveFeedback = false
                    }
                }
            case .negative:
                withAnimation(.easeOut(duration: 0.18)) {
                    showNegativeFeedback = true
                }
                withAnimation(.linear(duration: 0.28)) {
                    shakeTrigger += 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
                    withAnimation(.easeIn(duration: 0.18)) {
                        showNegativeFeedback = false
                    }
                }
            case .none:
                break
            }
        }
    }

    @ViewBuilder
    private var subdivisionFill: some View {
        let baseColor = isHovered ? Color.blue.opacity(0.10) : Color.secondary.opacity(0.06)
        let warningColor = Color.orange.opacity(0.14)

        switch slot.shapeType {
        case .normalRect, .leftTall, .topWide:
            Rectangle()
                .fill(hoverIsWarning ? warningColor : baseColor)
        case .leftBottom:
            LeftBottomShape()
                .fill(hoverIsWarning ? warningColor : baseColor)
        case .frameUShape:
            frameUShape
                .fill(hoverIsWarning ? warningColor : baseColor)
        }
    }

    @ViewBuilder
    private var subdivisionStroke: some View {
        let strokeColor: Color = showNegativeFeedback
            ? .red
            : (showPositiveFeedback
                ? .green
                : (hoverIsWarning ? .orange : (isHovered || isTapSelected ? .blue : .secondary.opacity(0.55))))
        let strokeWidth: CGFloat = showNegativeFeedback || showPositiveFeedback || isHovered ? 3 : (isTapSelected ? 3 : 2)

        switch slot.shapeType {
        case .normalRect, .leftTall, .topWide:
            Rectangle()
                .stroke(style: StrokeStyle(lineWidth: strokeWidth, dash: [6]))
                .foregroundStyle(strokeColor)
        case .leftBottom:
            LeftBottomShape()
                .stroke(style: StrokeStyle(lineWidth: strokeWidth, dash: [6]))
                .foregroundStyle(strokeColor)
        case .frameUShape:
            frameUShape
                .stroke(style: StrokeStyle(lineWidth: strokeWidth, dash: [6]))
                .foregroundStyle(strokeColor)
        }
    }

    @ViewBuilder
    private func gridPiece(for radical: RadicalEntry, opacity: Double) -> some View {
        switch slot.shapeType {
        case .normalRect, .leftTall, .topWide:
            Rectangle()
                .fill(Color.accentColor.opacity(0.16))
                .overlay {
                    gridGlyph(for: radical)
                }
                .opacity(opacity)
        case .leftBottom:
            LeftBottomShape()
                .fill(Color.accentColor.opacity(0.16))
                .overlay {
                    gridGlyph(for: radical)
                }
                .opacity(opacity)
        case .frameUShape:
            frameUShape
                .fill(Color.accentColor.opacity(0.16))
                .overlay {
                    gridGlyph(for: radical)
                }
                .opacity(opacity)
        }
    }

    private func gridGlyph(for radical: RadicalEntry) -> some View {
        let uniformScale = max(0.1, CGFloat(glyphScaleOverride ?? 1.0))
        let stretchX = max(0.1, CGFloat(glyphStretchXOverride ?? 1.0))
        let stretchY = max(0.1, CGFloat(glyphStretchYOverride ?? 1.0))

        return Text(radical.symbol)
            .font(AppFont.kanji(size: baseGridGlyphFontSize(for: radical.symbol)))
            .fontWeight(.semibold)
            .lineLimit(1)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: glyphAlignment)
            .padding(glyphPaddingInsets)
            .scaleEffect(x: uniformScale * stretchX, y: uniformScale * stretchY, anchor: .center)
            .foregroundStyle(.primary)
            .clipped()
    }

    private var gridGlyphInset: CGFloat {
        max(2, min(frameSize.width, frameSize.height) * glyphInsetRatio)
    }

    private var glyphAlignment: Alignment {
        switch slot.shapeType {
        case .leftBottom:
            return .bottomLeading
        default:
            return .center
        }
    }

    private var glyphPaddingInsets: EdgeInsets {
        switch slot.shapeType {
        case .leftBottom:
            return EdgeInsets(
                top: frameSize.height * 0.14,
                leading: gridGlyphInset * 0.7,
                bottom: gridGlyphInset * 0.45,
                trailing: frameSize.width * 0.18
            )
        default:
            return EdgeInsets(top: gridGlyphInset, leading: gridGlyphInset, bottom: gridGlyphInset, trailing: gridGlyphInset)
        }
    }

    private func baseGridGlyphFontSize(for symbol: String) -> CGFloat {
        let usableWidth = max(8, frameSize.width - (glyphPaddingInsets.leading + glyphPaddingInsets.trailing))
        let usableHeight = max(8, frameSize.height - (glyphPaddingInsets.top + glyphPaddingInsets.bottom))
        let referenceSize: CGFloat = 100
        let measuredSize = (symbol as NSString).size(
            withAttributes: [.font: AppFont.uiKanjiFont(size: referenceSize)]
        )

        guard measuredSize.width > 0.1, measuredSize.height > 0.1 else {
            return max(24, min(usableWidth, usableHeight) * 0.94)
        }

        let widthScale = usableWidth / measuredSize.width
        let heightScale = usableHeight / measuredSize.height
        let baseSize = referenceSize * min(widthScale, heightScale)

        let shapeAdjustment: CGFloat

        switch slot.shapeType {
        case .leftTall:
            // Slight boost for narrow left radicals like 亻.
            shapeAdjustment = 1.06
        case .leftBottom:
            shapeAdjustment = 0.98
        case .topWide:
            shapeAdjustment = 0.98
        case .frameUShape:
            shapeAdjustment = 0.90
        case .normalRect:
            shapeAdjustment = 0.99
        }

        return max(24, baseSize * shapeAdjustment)
    }
}

struct FrameUShape: Shape {
    var sideThicknessRatio: CGFloat = 0.16
    var topThicknessRatio: CGFloat = 0.16

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let sideThickness = max(14, rect.width * sideThicknessRatio)
        let topThickness = max(14, rect.width * topThicknessRatio)
        let leftBar = CGRect(x: rect.minX, y: rect.minY, width: sideThickness, height: rect.height)
        let rightBar = CGRect(x: rect.maxX - sideThickness, y: rect.minY, width: sideThickness, height: rect.height)
        let topBar = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: topThickness)

        path.addRoundedRect(in: leftBar, cornerSize: CGSize(width: 10, height: 10))
        path.addRoundedRect(in: rightBar, cornerSize: CGSize(width: 10, height: 10))
        path.addRoundedRect(in: topBar, cornerSize: CGSize(width: 10, height: 10))

        return path
    }
}

struct LeftBottomShape: Shape {
    var sideThicknessRatio: CGFloat = 0.28
    var bottomThicknessRatio: CGFloat = 0.24

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let sideThickness = max(12, rect.width * sideThicknessRatio)
        let bottomThickness = max(12, rect.height * bottomThicknessRatio)
        let sideBar = CGRect(
            x: rect.minX,
            y: rect.minY,
            width: sideThickness,
            height: rect.height
        )
        let bottomBar = CGRect(
            x: rect.minX,
            y: rect.maxY - bottomThickness,
            width: rect.width,
            height: bottomThickness
        )

        path.addRoundedRect(in: sideBar, cornerSize: CGSize(width: 10, height: 10))
        path.addRoundedRect(in: bottomBar, cornerSize: CGSize(width: 10, height: 10))

        return path
    }
}

struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(
            CGAffineTransform(translationX: amount * sin(animatableData * .pi * shakesPerUnit), y: 0)
        )
    }
}
