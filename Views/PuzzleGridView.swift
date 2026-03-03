import SwiftUI

struct PuzzleGridView: View {
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
                RoundedRectangle(cornerRadius: 20)
                    .fill(.thinMaterial)
                
                ForEach(slots) { slot in
                    let frame = frameForSlot(slot, in: proxy.size)
                    let placedRadicalID = placedTiles[slot.id]
                    let placedRadical = placedRadicalID.flatMap(radicalLookup)
                    let isHovered = hoveredSlotID == slot.id
                    let draggingRadical = draggingRadicalID.flatMap(radicalLookup)
                    let hoverIsWarning = isHovered && draggingRadicalID != nil && draggingRadicalID != slot.expectedRadicalID
                    let showReplaceIndicator = isHovered && placedRadicalID != nil
                    let previewRadical = isHovered && placedRadicalID == nil ? draggingRadical : nil
                    
                    PuzzleSlotView(
                        slot: slot,
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
                        feedback: feedbackSlotID == slot.id ? slotFeedback : nil
                    )
                    .frame(width: frame.width, height: frame.height)
                    .offset(x: frame.minX, y: frame.minY)
                    .contentShape(
                        SlotHitShape(
                            shapeType: slot.shapeType,
                            frameUThicknessRatio: slot.frameUThicknessRatio,
                            frameUSideThicknessRatio: slot.frameUSideThicknessRatio,
                            frameUTopThicknessRatio: slot.frameUTopThicknessRatio
                        )
                    )
                    .accessibilityLabel(accessibilityLabel(for: slot))
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 20))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.secondary.opacity(0.35), lineWidth: 1.5)
            )
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
    
    private func frameForSlot(_ slot: PuzzleSlot, in size: CGSize) -> CGRect {
        let normalizedFrame = slot.normalizedFrame
        return CGRect(
            x: normalizedFrame.x * size.width,
            y: normalizedFrame.y * size.height,
            width: normalizedFrame.w * size.width,
            height: normalizedFrame.h * size.height
        )
    }
    
    private func accessibilityLabel(for slot: PuzzleSlot) -> String {
        if let radicalID = placedTiles[slot.id], let radical = radicalLookup(radicalID) {
            return "Slot \(slot.id), filled with \(radical.primaryMeaning)"
        }
        return "Slot \(slot.id), empty"
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
        let slotID = resolvedSlotID(forLocalPoint: point, containerSize: containerSize)
        tapDebug("containerSingleTap local=\(pointDebug(point)) slot=\(slotID ?? "nil")")
        guard let slotID else { return }
        onTapSlot(slotID)
    }
    
    private func handleContainerDoubleTap(at point: CGPoint, containerSize: CGSize) {
        let slotID = resolvedSlotID(forLocalPoint: point, containerSize: containerSize)
        tapDebug("containerDoubleTap local=\(pointDebug(point)) slot=\(slotID ?? "nil")")
        guard let slotID else { return }
        onDoubleTapSlot(slotID)
    }
    
    private func resolvedSlotID(forLocalPoint point: CGPoint, containerSize: CGSize) -> String? {
        let framesBySlotID = slots.reduce(into: [String: CGRect]()) { result, slot in
            result[slot.id] = frameForSlot(slot, in: containerSize)
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
            let normalizedFrame = slot.normalizedFrame
            result[slot.id] = CGRect(
                x: containerFrame.minX + normalizedFrame.x * containerFrame.width,
                y: containerFrame.minY + normalizedFrame.y * containerFrame.height,
                width: normalizedFrame.w * containerFrame.width,
                height: normalizedFrame.h * containerFrame.height
            )
        }
        
        // Defer to next runloop to avoid state updates during view update.
        DispatchQueue.main.async {
            onUpdateGridFrame(containerFrame)
            onUpdateSlotFrames(globalSlotFrames)
        }
    }
    
    private func tapDebug(_ message: String) {
#if DEBUG
        print("[TapDebug] \(message)")
#endif
    }
    
    private func pointDebug(_ point: CGPoint) -> String {
        "(\(Int(point.x.rounded())),\(Int(point.y.rounded())))"
    }
    
    private func distanceSquared(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return dx * dx + dy * dy
    }
}

struct SlotHitShape: Shape {
    let shapeType: SlotShapeType
    let frameUThicknessRatio: Double?
    let frameUSideThicknessRatio: Double?
    let frameUTopThicknessRatio: Double?
    
    func path(in rect: CGRect) -> Path {
        switch shapeType {
        case .normalRect, .leftTall, .topWide:
            return Rectangle().path(in: rect)
        case .leftBottom:
            return LeftBottomShape().path(in: rect)
        case .frameUShape:
            let baseRatio = frameUThicknessRatio ?? 0.16
            return FrameUShape(
                sideThicknessRatio: CGFloat(frameUSideThicknessRatio ?? baseRatio),
                topThicknessRatio: CGFloat(frameUTopThicknessRatio ?? baseRatio)
            ).path(in: rect)
        }
    }
}

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
