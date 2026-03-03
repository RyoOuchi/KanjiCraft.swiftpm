import SwiftUI
import UIKit

struct VisionImpairedPuzzleGridView: View {
    let slots: [PuzzleSlot]
    let slotGlyphScaleOverrides: [String: Double]
    let slotGlyphStretchXOverrides: [String: Double]
    let slotGlyphStretchYOverrides: [String: Double]
    let placedTiles: [String: String]
    let radicalLookup: (String) -> RadicalEntry?
    let selectedRadicalID: String?
    let hoveredSlotID: String?
    let draggingRadicalID: String?
    let feedbackSlotID: String?
    let slotFeedback: PuzzleViewModel.PlacementFeedback?
    let coordinateSpaceName: String
    let onUpdateGridFrame: (CGRect) -> Void
    let onUpdateSlotFrames: ([String: CGRect]) -> Void
    let onTapSlot: (String) -> Void
    let onDoubleTapSlot: (String) -> Void

    var body: some View {
        GeometryReader { proxy in
            let containerFrame = proxy.frame(in: .named(coordinateSpaceName))

            ZStack(alignment: .topLeading) {
                Color.clear

                ForEach(slots) { slot in
                    let frame = accessibleFrameForSlot(slot, in: proxy.size)
                    let placedRadicalID = placedTiles[slot.id]
                    let placedRadical = placedRadicalID.flatMap(radicalLookup)
                    let isHovered = hoveredSlotID == slot.id
                    let draggingRadical = draggingRadicalID.flatMap(radicalLookup)
                    let hoverIsWarning = isHovered && draggingRadicalID != nil && draggingRadicalID != slot.expectedRadicalID
                    let showReplaceIndicator = isHovered && placedRadicalID != nil
                    let previewRadical = isHovered && placedRadicalID == nil ? draggingRadical : nil

                    VisionImpairedPuzzleSlotView(
                        frameSize: frame.size,
                        glyphScaleOverride: slotGlyphScaleOverrides[slot.id],
                        glyphStretchXOverride: slotGlyphStretchXOverrides[slot.id],
                        glyphStretchYOverride: slotGlyphStretchYOverrides[slot.id],
                        placedRadical: placedRadical,
                        isTapSelected: selectedRadicalID != nil,
                        isHovered: isHovered,
                        hoverIsWarning: hoverIsWarning,
                        showReplaceIndicator: showReplaceIndicator,
                        previewRadical: previewRadical,
                        feedback: feedbackSlotID == slot.id ? slotFeedback : nil,
                        negativeFeedbackAnnouncement: negativeFeedbackAnnouncement(for: slot)
                    )
                    .frame(width: frame.width, height: frame.height)
                    .offset(x: frame.minX, y: frame.minY)
                    .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(accessibilityLabel(for: slot))
                    .accessibilityValue(accessibilityValue(for: slot))
                    .accessibilityHint(accessibilityHint(for: slot))
                    .accessibilityAddTraits(.isButton)
                }
            }
            .contentShape(Rectangle())
            .highPriorityGesture(containerTapGesture(in: proxy.size))
            .onAppear {
                publishGeometry(containerFrame: containerFrame)
            }
            .onChange(of: containerFrame) { _, newFrame in
                publishGeometry(containerFrame: newFrame)
            }
            .onChange(of: slots) { _, _ in
                publishGeometry(containerFrame: containerFrame)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .animation(.easeInOut(duration: 0.16), value: hoveredSlotID)
        .animation(.easeOut(duration: 0.14), value: placedTiles)
    }

    private func accessibleFrameForSlot(_ slot: PuzzleSlot, in size: CGSize) -> CGRect {
        let baseFrame = CGRect(
            x: slot.normalizedFrame.x * size.width,
            y: slot.normalizedFrame.y * size.height,
            width: slot.normalizedFrame.w * size.width,
            height: slot.normalizedFrame.h * size.height
        )

        let insetX = min(max(4, baseFrame.width * 0.04), max(4, baseFrame.width * 0.10))
        let insetY = min(max(4, baseFrame.height * 0.04), max(4, baseFrame.height * 0.10))
        let insetFrame = baseFrame.insetBy(dx: insetX, dy: insetY)

        if insetFrame.width >= 44, insetFrame.height >= 44 {
            return insetFrame
        }

        return baseFrame.insetBy(
            dx: min(3, baseFrame.width * 0.03),
            dy: min(3, baseFrame.height * 0.03)
        )
    }

    private func accessibilityLabel(for slot: PuzzleSlot) -> String {
        return "Slot \(slot.id)"
    }

    private func accessibilityValue(for slot: PuzzleSlot) -> String {
        if let radicalID = placedTiles[slot.id], let radical = radicalLookup(radicalID) {
            return "Filled with \(radical.primaryMeaning)"
        }
        return "Empty"
    }

    private func accessibilityHint(for slot: PuzzleSlot) -> String {
        let radicalType = requiredRadicalTypeText(for: slot)
        if let expectedRadical = radicalLookup(slot.expectedRadicalID) {
            return "Needs a \(radicalType) for \(expectedRadical.primaryMeaning). Double tap to place the selected radical."
        }
        return "Needs a \(radicalType). Double tap to place the selected radical."
    }

    private func negativeFeedbackAnnouncement(for slot: PuzzleSlot) -> String? {
        guard feedbackSlotID == slot.id, slotFeedback == .negative else { return nil }

        let radicalType = requiredRadicalTypeText(for: slot)
        if let expectedRadical = radicalLookup(slot.expectedRadicalID) {
            return "Wrong. This slot needs a \(radicalType) for \(expectedRadical.primaryMeaning)."
        }

        return "Wrong. This slot needs a \(radicalType)."
    }

    private func requiredRadicalTypeText(for slot: PuzzleSlot) -> String {
        guard let expectedRadical = radicalLookup(slot.expectedRadicalID) else {
            return slot.shapeType.accessibilityRadicalType
        }

        switch expectedRadical.displayPosition {
        case .leftSide:
            return "left radical"
        case .top:
            return "top radical"
        case .rightSide:
            return "right radical"
        case .bottom:
            return "bottom radical"
        case .topLeft:
            return "top-left radical"
        case .leftBottom:
            return "left-bottom radical"
        case .enclosing:
            return "enclosing radical"
        case .standalone, .all:
            return slot.shapeType.accessibilityRadicalType
        }
    }

    private func containerTapGesture(in containerSize: CGSize) -> some Gesture {
        SpatialTapGesture(count: 2)
            .exclusively(before: SpatialTapGesture(count: 1))
            .onEnded { result in
                switch result {
                case .first(let doubleTap):
                    handleContainerDoubleTap(at: doubleTap.location, containerSize: containerSize)
                case .second(let singleTap):
                    handleContainerSingleTap(at: singleTap.location, containerSize: containerSize)
                }
            }
    }

    private func handleContainerSingleTap(at point: CGPoint, containerSize: CGSize) {
        guard let slotID = resolvedSlotID(forLocalPoint: point, containerSize: containerSize) else { return }
        onTapSlot(slotID)
    }

    private func handleContainerDoubleTap(at point: CGPoint, containerSize: CGSize) {
        guard let slotID = resolvedSlotID(forLocalPoint: point, containerSize: containerSize) else { return }
        onDoubleTapSlot(slotID)
    }

    private func resolvedSlotID(forLocalPoint point: CGPoint, containerSize: CGSize) -> String? {
        let framesBySlotID = slots.reduce(into: [String: CGRect]()) { result, slot in
            result[slot.id] = accessibleFrameForSlot(slot, in: containerSize)
        }

        let containing = framesBySlotID
            .filter { $0.value.contains(point) }
            .sorted { lhs, rhs in
                lhs.value.width * lhs.value.height < rhs.value.width * rhs.value.height
            }

        if let slotID = containing.first?.key {
            return slotID
        }

        return framesBySlotID.min { lhs, rhs in
            distanceSquared(from: point, to: lhs.value.center) < distanceSquared(from: point, to: rhs.value.center)
        }?.key
    }

    private func publishGeometry(containerFrame: CGRect) {
        guard containerFrame.width > 0, containerFrame.height > 0 else { return }

        let globalSlotFrames = slots.reduce(into: [String: CGRect]()) { result, slot in
            let localFrame = accessibleFrameForSlot(
                slot,
                in: CGSize(width: containerFrame.width, height: containerFrame.height)
            )
            result[slot.id] = CGRect(
                x: containerFrame.minX + localFrame.minX,
                y: containerFrame.minY + localFrame.minY,
                width: localFrame.width,
                height: localFrame.height
            )
        }

        DispatchQueue.main.async {
            onUpdateGridFrame(containerFrame)
            onUpdateSlotFrames(globalSlotFrames)
        }
    }

    private func distanceSquared(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return dx * dx + dy * dy
    }
}

private struct VisionImpairedPuzzleSlotView: View {
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
    let negativeFeedbackAnnouncement: String?

    @State private var showPositiveFeedback = false
    @State private var showNegativeFeedback = false
    @State private var shakeTrigger: CGFloat = 0
    @State private var lastAnnouncedMessage: String?

    private let glyphInsetRatio: CGFloat = 0.08

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(backgroundColor)

            if let placedRadical {
                roundedPiece(for: placedRadical, opacity: 1.0)
            } else if let previewRadical {
                roundedPiece(for: previewRadical, opacity: 0.45)
            } else {
                Circle()
                    .fill(Color.secondary.opacity(0.14))
                    .frame(width: min(frameSize.width, frameSize.height) * 0.12)
            }

            if showReplaceIndicator {
                Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                    .foregroundStyle(.orange)
                    .font(.title3)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Circle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(8)
            }

            if showPositiveFeedback {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title2)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(borderColor, style: StrokeStyle(lineWidth: borderWidth, dash: [8, 6]))
        }
        .shadow(color: Color.black.opacity(isHovered ? 0.12 : 0.06), radius: isHovered ? 10 : 6, y: 3)
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
                announceIfNeeded(negativeFeedbackAnnouncement)
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

    private func announceIfNeeded(_ message: String?) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        guard let message else { return }
        guard message != lastAnnouncedMessage else { return }
        lastAnnouncedMessage = message
        UIAccessibility.post(notification: .announcement, argument: message)
    }

    private var backgroundColor: Color {
        if hoverIsWarning {
            return Color.orange.opacity(0.18)
        }
        if isHovered {
            return Color.blue.opacity(0.18)
        }
        return Color.black.opacity(0.08)
    }

    private var borderColor: Color {
        if showNegativeFeedback {
            return .red
        }
        if showPositiveFeedback {
            return .green
        }
        if hoverIsWarning {
            return .orange
        }
        if isHovered || isTapSelected {
            return .blue
        }
        return .black.opacity(0.78)
    }

    private var borderWidth: CGFloat {
        showNegativeFeedback || showPositiveFeedback || isHovered || isTapSelected ? 4 : 3
    }

    private func roundedPiece(for radical: RadicalEntry, opacity: Double) -> some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color.accentColor.opacity(0.18))
            .overlay {
                gridGlyph(for: radical)
            }
            .opacity(opacity)
    }

    private func gridGlyph(for radical: RadicalEntry) -> some View {
        let uniformScale = max(0.1, CGFloat(glyphScaleOverride ?? 1.0))
        let stretchX = max(0.1, CGFloat(glyphStretchXOverride ?? 1.0))
        let stretchY = max(0.1, CGFloat(glyphStretchYOverride ?? 1.0))

        return Text(radical.symbol)
            .font(AppFont.kanji(size: baseGridGlyphFontSize(for: radical.symbol)))
            .fontWeight(.semibold)
            .lineLimit(1)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(gridGlyphInset)
            .scaleEffect(x: uniformScale * stretchX, y: uniformScale * stretchY, anchor: .center)
            .foregroundStyle(.primary)
            .clipped()
    }

    private var gridGlyphInset: CGFloat {
        max(6, min(frameSize.width, frameSize.height) * glyphInsetRatio)
    }

    private func baseGridGlyphFontSize(for symbol: String) -> CGFloat {
        let usableWidth = max(8, frameSize.width - gridGlyphInset * 2)
        let usableHeight = max(8, frameSize.height - gridGlyphInset * 2)
        let referenceSize: CGFloat = 100
        let measuredSize = (symbol as NSString).size(
            withAttributes: [.font: AppFont.uiKanjiFont(size: referenceSize)]
        )

        guard measuredSize.width > 0.1, measuredSize.height > 0.1 else {
            return max(24, min(usableWidth, usableHeight) * 0.94)
        }

        let widthScale = usableWidth / measuredSize.width
        let heightScale = usableHeight / measuredSize.height
        return max(24, referenceSize * min(widthScale, heightScale))
    }
}

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

private extension SlotShapeType {
    var accessibilityRadicalType: String {
        switch self {
        case .leftTall:
            return "left radical"
        case .leftBottom:
            return "left-bottom radical"
        case .topWide:
            return "top radical"
        case .frameUShape:
            return "enclosing radical"
        case .normalRect:
            return "main radical"
        }
    }
}
