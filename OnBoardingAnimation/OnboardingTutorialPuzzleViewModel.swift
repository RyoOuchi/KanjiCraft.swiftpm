import Foundation
import CoreGraphics

@MainActor
final class OnboardingTutorialPuzzleViewModel: ObservableObject {
    @Published private(set) var currentKanji: KanjiEntry?
    @Published var placedTiles: [String: String] = [:]
    @Published var sidebarSearchText: String = ""
    @Published var selectedRadicalDisplayPosition: RadicalDisplayPosition = .all
    @Published var selectedRadicalID: String?
    @Published private(set) var feedbackMessage = "Build rest by placing person on the left and tree on the right."
    @Published private(set) var didCompleteTutorial = false
    @Published var feedbackSlotID: String?
    @Published var slotFeedback: PuzzleViewModel.PlacementFeedback?
    @Published var dragState: DragState?
    @Published var hoveredSlotID: String?

    let hintHighlightedRadicalIDs: Set<String> = []

    private let dataStore: DataStore
    private let soundEffectService: SoundEffectService
    private var slotFrames: [String: CGRect] = [:]
    private var gridFrame: CGRect?

    init(
        dataStore: DataStore = DataStore(),
        soundEffectService: SoundEffectService? = nil
    ) {
        self.dataStore = dataStore
        self.soundEffectService = soundEffectService ?? .shared
        self.currentKanji = dataStore.kanjiEntries.first(where: { $0.id == "rest" })
    }

    var activePromptEnglish: String {
        currentKanji?.promptEnglish ?? ""
    }

    var filteredSidebarRadicals: [RadicalEntry] {
        let query = sidebarSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let requiredIDs = Set(currentKanji?.requiredComponents ?? [])
        let availableRadicals = dataStore.radicals.filter { requiredIDs.contains($0.id) }

        let placementFilteredRadicals: [RadicalEntry]
        if selectedRadicalDisplayPosition == .all {
            placementFilteredRadicals = availableRadicals
        } else {
            placementFilteredRadicals = availableRadicals.filter {
                $0.displayPosition == selectedRadicalDisplayPosition
            }
        }

        if query.isEmpty {
            return placementFilteredRadicals
        }

        return placementFilteredRadicals.filter { $0.searchableText.contains(query) }
    }

    var availableRadicalDisplayPositions: [RadicalDisplayPosition] {
        let requiredIDs = Set(currentKanji?.requiredComponents ?? [])
        let positions = Set(
            dataStore.radicals
                .filter { requiredIDs.contains($0.id) }
                .map(\.displayPosition)
        )

        return RadicalDisplayPosition.allCases.filter { displayPosition in
            displayPosition == .all || positions.contains(displayPosition)
        }
    }

    func radical(for radicalID: String) -> RadicalEntry? {
        dataStore.radical(for: radicalID)
    }

    func resetTutorial() {
        placedTiles = [:]
        sidebarSearchText = ""
        selectedRadicalDisplayPosition = .all
        selectedRadicalID = nil
        feedbackMessage = "Build rest by placing person on the left and tree on the right."
        didCompleteTutorial = false
        feedbackSlotID = nil
        slotFeedback = nil
        dragState = nil
        hoveredSlotID = nil
    }

    func selectRadicalForTapPlacement(radicalID: String) {
        selectedRadicalID = radicalID
    }

    func handleSlotTap(slotID: String) {
        guard let selectedRadicalID else { return }
        hoveredSlotID = slotID
        placeRadical(radicalID: selectedRadicalID, into: slotID)
        self.selectedRadicalID = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self, self.dragState == nil else { return }
            self.hoveredSlotID = nil
        }
    }

    func handleSlotDoubleTap(slotID: String) {
        guard placedTiles[slotID] != nil else { return }
        placedTiles[slotID] = nil
        didCompleteTutorial = false
        feedbackMessage = "Piece removed. Place person on the left and tree on the right."
    }

    func updateSlotFrames(_ frames: [String: CGRect]) {
        slotFrames = frames
        guard var dragState else { return }
        let hoveredID = resolveSnapTarget(at: dragState.currentPosition)
        dragState.hoveredSlotID = hoveredID
        self.dragState = dragState
        hoveredSlotID = hoveredID
    }

    func updateGridFrame(_ frame: CGRect) {
        guard frame.width > 0, frame.height > 0 else { return }
        gridFrame = frame
        guard var dragState else { return }
        let hoveredID = resolveSnapTarget(at: dragState.currentPosition)
        dragState.hoveredSlotID = hoveredID
        self.dragState = dragState
        hoveredSlotID = hoveredID
    }

    func beginDragFromSidebar(radicalID: String, startPoint: CGPoint) {
        guard dragState == nil else { return }
        selectedRadicalID = nil
        let hoveredID = resolveSnapTarget(at: startPoint)
        dragState = DragState(
            isDragging: true,
            radicalID: radicalID,
            source: .sidebar,
            startPosition: startPoint,
            currentPosition: startPoint,
            hoveredSlotID: hoveredID
        )
        hoveredSlotID = hoveredID
    }

    func updateDrag(to point: CGPoint) {
        guard var dragState else { return }
        dragState.currentPosition = point
        let hoveredID = resolveSnapTarget(at: point)
        dragState.hoveredSlotID = hoveredID
        self.dragState = dragState
        hoveredSlotID = hoveredID
    }

    func endDrag(at endPoint: CGPoint) {
        guard let dragState else { return }
        guard let targetSlotID = resolveSnapTarget(at: endPoint) else {
            self.dragState = nil
            hoveredSlotID = nil
            return
        }

        placeRadical(radicalID: dragState.radicalID, into: targetSlotID)
        self.dragState = nil
        hoveredSlotID = nil
    }

    private func placeRadical(radicalID: String, into slotID: String) {
        guard let currentKanji else { return }
        guard currentKanji.layout.slots.contains(where: { $0.id == slotID }) else { return }

        placedTiles[slotID] = radicalID
        didCompleteTutorial = false

        let expectedRadicalID = currentKanji.layout.slots.first(where: { $0.id == slotID })?.expectedRadicalID
        let isCorrectPlacement = expectedRadicalID == radicalID
        feedbackMessage = isCorrectPlacement
            ? successMessage(for: slotID)
            : "That radical belongs in the other slot. Try matching the meaning to the right side."

        emitSlotFeedback(
            slotID: slotID,
            feedback: isCorrectPlacement ? .positive : .negative
        )

        if !currentKanji.layout.slots.allSatisfy({ placedTiles[$0.id] == $0.expectedRadicalID }) {
            soundEffectService.play(isCorrectPlacement ? .success : .mistake)
        }

        updateCompletionState()
    }

    private func updateCompletionState() {
        guard let currentKanji else {
            didCompleteTutorial = false
            return
        }

        let didSolve = currentKanji.layout.slots.allSatisfy { slot in
            placedTiles[slot.id] == slot.expectedRadicalID
        }

        didCompleteTutorial = didSolve
        if didSolve {
            soundEffectService.play(.completed)
            feedbackMessage = "Good. You built rest by placing person on the left and tree on the right."
        }
    }

    private func successMessage(for slotID: String) -> String {
        switch slotID {
        case "rest-left":
            return "Good. Person belongs on the left."
        case "rest-right":
            return "Good. Tree belongs on the right."
        default:
            return "Good placement."
        }
    }

    private func emitSlotFeedback(slotID: String, feedback: PuzzleViewModel.PlacementFeedback) {
        feedbackSlotID = slotID
        slotFeedback = feedback

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self else { return }
            if self.feedbackSlotID == slotID, self.slotFeedback == feedback {
                self.feedbackSlotID = nil
                self.slotFeedback = nil
            }
        }
    }

    private func resolveSnapTarget(at point: CGPoint) -> String? {
        guard isPointInsideGrid(point) else { return nil }

        if let containingSlot = slotContaining(point) {
            return containingSlot
        }

        return nearestSlot(to: point)
    }

    private func isPointInsideGrid(_ point: CGPoint) -> Bool {
        if let gridFrame, !gridFrame.isEmpty {
            return gridFrame.insetBy(dx: -1, dy: -1).contains(point)
        }
        let fallbackFrames = effectiveSlotFrames()
        guard !fallbackFrames.isEmpty else { return false }
        let unionFrame = fallbackFrames.values.reduce(CGRect.null) { $0.union($1) }
        return !unionFrame.isNull && unionFrame.insetBy(dx: -1, dy: -1).contains(point)
    }

    private func slotContaining(_ point: CGPoint) -> String? {
        let matchingSlots = effectiveSlotFrames()
            .filter { $0.value.insetBy(dx: -0.5, dy: -0.5).contains(point) }
            .sorted { lhs, rhs in
                lhs.value.width * lhs.value.height < rhs.value.width * rhs.value.height
            }
        return matchingSlots.first?.key
    }

    private func nearestSlot(to point: CGPoint) -> String? {
        effectiveSlotFrames().min { lhs, rhs in
            distanceSquared(from: point, to: lhs.value.center) < distanceSquared(from: point, to: rhs.value.center)
        }?.key
    }

    private func effectiveSlotFrames() -> [String: CGRect] {
        if let computedFrames = computedSlotFramesFromLayout(), !computedFrames.isEmpty {
            return computedFrames
        }
        return slotFrames
    }

    private func computedSlotFramesFromLayout() -> [String: CGRect]? {
        guard let currentKanji, let gridFrame, !gridFrame.isEmpty else {
            return nil
        }

        var computedFrames: [String: CGRect] = [:]
        for slot in currentKanji.layout.slots {
            let normalizedFrame = slot.normalizedFrame
            computedFrames[slot.id] = CGRect(
                x: gridFrame.minX + normalizedFrame.x * gridFrame.width,
                y: gridFrame.minY + normalizedFrame.y * gridFrame.height,
                width: normalizedFrame.w * gridFrame.width,
                height: normalizedFrame.h * gridFrame.height
            )
        }
        return computedFrames
    }

    private func distanceSquared(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return dx * dx + dy * dy
    }
}

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
