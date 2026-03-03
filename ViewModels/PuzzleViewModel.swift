import Foundation
import CoreGraphics
import SwiftUI

@MainActor
final class PuzzleViewModel: ObservableObject {
    enum PuzzleScreenState {
        case intro
        case active
    }

    enum PlacementFeedback: Equatable {
        case positive
        case negative
    }

    @Published var screenState: PuzzleScreenState = .intro
    @Published var selectedMode: PuzzleMode = .discovery
    @Published var selectedDifficulty: KanjiDifficulty = .easy
    @Published private(set) var difficultyProfile: KanjiDifficultyProfile = .standard
    @Published var usesVisionImpairedGrid = false
    @Published private(set) var currentKanji: KanjiEntry?
    @Published var placedTiles: [String: String] = [:]
    @Published var sidebarSearchText: String = ""
    @Published var selectedRadicalDisplayPosition: RadicalDisplayPosition = .all
    @Published var selectedRadicalID: String?
    @Published private(set) var hintHighlightedRadicalIDs: Set<String> = []
    @Published var feedbackMessage: String?
    @Published var didSolveCurrentPuzzle = false
    @Published private(set) var isShowingAnswerReveal = false
    @Published var doneScore: Double = 0.0
    @Published var correctCount: Int = 0
    @Published var wrongCount: Int = 0
    @Published var feedbackSlotID: String?
    @Published var slotFeedback: PlacementFeedback?
    @Published var dragState: DragState?
    @Published var hoveredSlotID: String?
    @Published private(set) var generatedPrompt: GeneratedKanjiPrompt?
    @Published private(set) var isGeneratingHint = false
    @Published private(set) var isUsingAppleIntelligenceHint = false
    @Published private(set) var hintGenerationErrorMessage: String?

    private let dataStore: DataStore
    private let progressStore: ProgressStore
    private let kanjiPromptGenerator: KanjiPromptGenerator
    private let soundEffectService: SoundEffectService
    private let wrongPenaltyFactor: Double = 1.0
    private let forceDisableAppleIntelligence = false
    private var slotFrames: [String: CGRect] = [:]
    private var gridFrame: CGRect?
    private var lastLoggedHoverSlotID: String?
    private var lastLoggedInsideGrid: Bool?
    private var promptGenerationTask: Task<Void, Never>?
    private var autoAdvanceTask: Task<Void, Never>?
    private var hasActivatedHintAssistForCurrentPuzzle = false

    init(
        dataStore: DataStore,
        progressStore: ProgressStore,
        kanjiPromptGenerator: KanjiPromptGenerator = KanjiPromptGenerator(),
        soundEffectService: SoundEffectService? = nil
    ) {
        self.dataStore = dataStore
        self.progressStore = progressStore
        self.kanjiPromptGenerator = kanjiPromptGenerator
        self.soundEffectService = soundEffectService ?? .shared
    }

    var allRadicals: [RadicalEntry] {
        if usesVisionImpairedGrid {
            return dataStore.radicals.filter { radical in
                dataStore.supportsVisionImpairedMode(radical)
            }
        }
        return dataStore.radicals
    }

    var allKnownRadicals: [RadicalEntry] {
        dataStore.radicals
    }

    var availableRadicalDisplayPositions: [RadicalDisplayPosition] {
        let positions = Set(allRadicals.map(\.displayPosition))
        return RadicalDisplayPosition.allCases.filter { displayPosition in
            displayPosition == .all || positions.contains(displayPosition)
        }
    }

    var filteredSidebarRadicals: [RadicalEntry] {
        let query = sidebarSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let placementFilteredRadicals: [RadicalEntry]
        if selectedRadicalDisplayPosition == .all {
            placementFilteredRadicals = allRadicals
        } else {
            placementFilteredRadicals = allRadicals.filter {
                $0.displayPosition == selectedRadicalDisplayPosition
            }
        }

        if query.isEmpty {
            return placementFilteredRadicals
        }
        return placementFilteredRadicals.filter { $0.searchableText.contains(query) }
    }

    var availablePuzzleCount: Int {
        eligibleEntries.count
    }

    var availableDifficulties: [KanjiDifficulty] {
        if difficultyProfile == .easyMode {
            return [.easy, .medium]
        }
        return KanjiDifficulty.allCases
    }

    var canStartSelectedMode: Bool {
        !eligibleEntries.isEmpty
    }

    var hintButtonTitle: String {
        hasActivatedHintAssistForCurrentPuzzle ? "Answer" : "Hint"
    }

    var isShowingKanjiReveal: Bool {
        didSolveCurrentPuzzle || isShowingAnswerReveal
    }

    func startPuzzle() {
        if selectNewPuzzle() {
            screenState = .active
        } else {
            screenState = .intro
        }
    }

    func newPuzzle() {
        autoAdvanceTask?.cancel()
        autoAdvanceTask = nil
        guard selectNewPuzzle() else {
            screenState = .intro
            return
        }
    }

    func returnToIntro() {
        autoAdvanceTask?.cancel()
        autoAdvanceTask = nil
        screenState = .intro
    }

    func setUsesVisionImpairedGrid(_ usesVisionImpairedGrid: Bool) {
        self.usesVisionImpairedGrid = usesVisionImpairedGrid

        if usesVisionImpairedGrid, !availableRadicalDisplayPositions.contains(selectedRadicalDisplayPosition) {
            selectedRadicalDisplayPosition = .all
        }

        guard let activeKanji = currentKanji else { return }
        guard usesVisionImpairedGrid else { return }

        if !isSupportedInVisionImpairedMode(activeKanji) {
            if screenState == .active {
                if !selectNewPuzzle() {
                    screenState = .intro
                }
            } else {
                currentKanji = nil
            }
        }
    }

    func setDifficultyProfile(_ difficultyProfile: KanjiDifficultyProfile) {
        self.difficultyProfile = difficultyProfile

        if !availableDifficulties.contains(selectedDifficulty) {
            selectedDifficulty = availableDifficulties.first ?? .easy
        }

        guard let activeKanji = currentKanji else { return }
        guard activeKanji.difficulty(for: difficultyProfile) != selectedDifficulty
            || !dataStore.supportsDifficultyProfile(difficultyProfile, for: activeKanji) else { return }

        if screenState == .active {
            if !selectNewPuzzle() {
                screenState = .intro
            }
        } else {
            currentKanji = nil
        }
    }

    func resetPuzzle(keepHint: Bool = true) {
        autoAdvanceTask?.cancel()
        autoAdvanceTask = nil
        if !keepHint {
            promptGenerationTask?.cancel()
            promptGenerationTask = nil
            generatedPrompt = nil
            isGeneratingHint = false
            isUsingAppleIntelligenceHint = false
            hintGenerationErrorMessage = nil
        }

        placedTiles.removeAll()
        sidebarSearchText = ""
        selectedRadicalDisplayPosition = .all
        selectedRadicalID = nil
        hintHighlightedRadicalIDs = []
        hasActivatedHintAssistForCurrentPuzzle = false
        feedbackMessage = nil
        didSolveCurrentPuzzle = false
        isShowingAnswerReveal = false
        feedbackSlotID = nil
        slotFeedback = nil
        dragState = nil
        hoveredSlotID = nil
        doneScore = 0.0
        correctCount = 0
        wrongCount = 0
    }

    func placeRadical(radicalID: String, into slotID: String) {
        guard let currentKanji else { return }
        guard currentKanji.layout.slots.contains(where: { $0.id == slotID }) else { return }
        let previousDoneScore = doneScore
        placedTiles[slotID] = radicalID
        feedbackMessage = nil
        didSolveCurrentPuzzle = false
        isShowingAnswerReveal = false
        recomputeDoneMeter()

        if doneScore > previousDoneScore {
            emitSlotFeedback(slotID: slotID, feedback: .positive)
        } else if doneScore < previousDoneScore {
            emitSlotFeedback(slotID: slotID, feedback: .negative)
        }

        playPlacementSoundIfNeeded(for: currentKanji, slotID: slotID, radicalID: radicalID)

        autoCheckIfCompleted()
    }

    func removePlacedRadical(from slotID: String) {
        tapInteractionDebug("removePlacedRadical slot=\(slotID) hadValue=\(placedTiles[slotID] ?? "nil")")
        placedTiles[slotID] = nil
        feedbackMessage = nil
        didSolveCurrentPuzzle = false
        isShowingAnswerReveal = false
        recomputeDoneMeter()
    }

    func handleSlotTap(slotID: String) {
        tapInteractionDebug(
            "handleSlotTap slot=\(slotID) selectedRadical=\(selectedRadicalID ?? "nil") occupied=\(placedTiles[slotID] != nil)"
        )
        if let selectedRadicalID {
            hoveredSlotID = slotID
            placeRadical(radicalID: selectedRadicalID, into: slotID)
            self.selectedRadicalID = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
                guard let self, self.dragState == nil else { return }
                self.hoveredSlotID = nil
            }
        }
    }

    func handleSlotDoubleTap(slotID: String) {
        tapInteractionDebug(
            "handleSlotDoubleTap slot=\(slotID) selectedRadical=\(selectedRadicalID ?? "nil") occupied=\(placedTiles[slotID] != nil)"
        )
        if placedTiles[slotID] != nil {
            removePlacedRadical(from: slotID)
            tapInteractionDebug("handleSlotDoubleTap removed slot=\(slotID)")
        } else {
            tapInteractionDebug("handleSlotDoubleTap no-op slot=\(slotID) because empty")
        }
    }

    func selectRadicalForTapPlacement(radicalID: String) {
        selectedRadicalID = radicalID
    }

    func handleHintButtonTap() {
        guard let currentKanji else { return }
        if hasActivatedHintAssistForCurrentPuzzle {
            revealAnswerWithoutDiscovery(for: currentKanji)
            return
        }

        selectedRadicalDisplayPosition = .all
        sidebarSearchText = ""
        hintHighlightedRadicalIDs = Set(currentKanji.layout.slots.map(\.expectedRadicalID))
        hasActivatedHintAssistForCurrentPuzzle = true
    }

    func updateSlotFrames(_ frames: [String: CGRect]) {
        // Keep measured frames only as fallback. Authoritative frames are derived from
        // current layout + grid frame to avoid transform/offset mismatches.
        slotFrames = frames
        snapDebug("updateSlotFrames count=\(frames.count) sample=\(frameDebugSummary(from: frames))")
        guard var dragState else { return }
        let hoveredID = resolveSnapTarget(at: dragState.currentPosition, requireInsideGrid: true, useNearestFallback: true)
        dragState.hoveredSlotID = hoveredID
        self.dragState = dragState
        hoveredSlotID = hoveredID
    }

    func updateGridFrame(_ frame: CGRect) {
        guard frame.width > 0, frame.height > 0 else { return }
        gridFrame = frame
        snapDebug("updateGridFrame \(rectDebug(frame))")
        guard var dragState else { return }
        let hoveredID = resolveSnapTarget(at: dragState.currentPosition, requireInsideGrid: true, useNearestFallback: true)
        dragState.hoveredSlotID = hoveredID
        self.dragState = dragState
        hoveredSlotID = hoveredID
    }

    func beginDragFromSidebar(radicalID: String, startPoint: CGPoint) {
        guard dragState == nil else { return }
        selectedRadicalID = nil
        let insideGrid = isPointInsideGrid(startPoint)
        let hoveredID = resolveSnapTarget(at: startPoint, requireInsideGrid: true, useNearestFallback: true)
        snapDebug("beginDragFromSidebar radical=\(radicalID) start=\(pointDebug(startPoint)) insideGrid=\(insideGrid) hovered=\(hoveredID ?? "nil")")
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

    func beginDragFromSlot(slotID _: String, radicalID _: String, startPoint _: CGPoint) {
        // Disabled intentionally: once a piece is placed on the board,
        // it cannot be moved by dragging.
        snapDebug("beginDragFromSlot ignored (board dragging disabled)")
    }

    func updateDrag(to point: CGPoint) {
        guard var dragState else { return }
        dragState.currentPosition = point
        let insideGrid = isPointInsideGrid(point)
        let hoveredID = resolveSnapTarget(at: point, requireInsideGrid: true, useNearestFallback: true)
        dragState.hoveredSlotID = hoveredID
        self.dragState = dragState
        hoveredSlotID = hoveredID

        if hoveredID != lastLoggedHoverSlotID || insideGrid != lastLoggedInsideGrid {
            snapDebug("updateDrag point=\(pointDebug(point)) insideGrid=\(insideGrid) hovered=\(hoveredID ?? "nil")")
            lastLoggedHoverSlotID = hoveredID
            lastLoggedInsideGrid = insideGrid
        }
    }

    func endDrag(at endPoint: CGPoint) {
        guard let dragState else { return }
        var updatedDragState = dragState
        updatedDragState.currentPosition = endPoint
        self.dragState = updatedDragState
        let insideGrid = isPointInsideGrid(endPoint)

        let targetSlotID = resolveSnapTarget(
            at: endPoint,
            requireInsideGrid: true,
            useNearestFallback: true
        )
        snapDebug("endDrag point=\(pointDebug(endPoint)) insideGrid=\(insideGrid) target=\(targetSlotID ?? "nil") source=\(dragSourceDebug(updatedDragState.source))")

        if let targetSlotID,
           currentKanji?.layout.slots.contains(where: { $0.id == targetSlotID }) == true {
            withAnimation(.easeOut(duration: 0.12)) {
                applyDrop(dragState: updatedDragState, targetSlotID: targetSlotID)
            }
            self.dragState = nil
            hoveredSlotID = nil
            lastLoggedHoverSlotID = nil
            lastLoggedInsideGrid = nil
            return
        }

        snapDebug("endDrag cancel outside-grid-or-no-target")
        self.dragState = nil
        hoveredSlotID = nil
        lastLoggedHoverSlotID = nil
        lastLoggedInsideGrid = nil
    }

    func endDrag() {
        guard let currentPoint = dragState?.currentPosition else { return }
        endDrag(at: currentPoint)
    }

    func checkAnswer() {
        guard let currentKanji else { return }
        let slots = currentKanji.layout.slots

        for slot in slots {
            guard let placedRadicalID = placedTiles[slot.id], placedRadicalID == slot.expectedRadicalID else {
                feedbackMessage = "Not quite. Check that every slot is filled with the correct component."
                didSolveCurrentPuzzle = false
                isShowingAnswerReveal = false
                return
            }
        }

        progressStore.markSolved(
            kanjiID: currentKanji.id,
            usedHint: hasActivatedHintAssistForCurrentPuzzle
        )
        soundEffectService.play(.completed)
        feedbackMessage = nil
        didSolveCurrentPuzzle = true
        isShowingAnswerReveal = false
        scheduleAutoAdvanceAfterSuccess(for: currentKanji.id)
    }

    func radical(for radicalID: String) -> RadicalEntry? {
        dataStore.radical(for: radicalID)
    }

    var activePromptEnglish: String {
        currentKanji?.promptEnglish ?? ""
    }

    var shouldShowHintLoadingState: Bool {
        false
    }

    var activeRadicalPromptExplanations: [RadicalPromptExplanation] {
        generatedPrompt?.radicalExplanations ?? []
    }

    func recomputeDoneMeter() {
        guard let currentKanji else {
            doneScore = 0.0
            correctCount = 0
            wrongCount = 0
            return
        }

        let slots = currentKanji.layout.slots
        var localCorrectCount = 0
        var localWrongCount = 0

        for slot in slots {
            guard let placedRadicalID = placedTiles[slot.id] else { continue }
            if placedRadicalID == slot.expectedRadicalID {
                localCorrectCount += 1
            } else {
                localWrongCount += 1
            }
        }

        let slotCount = max(slots.count, 1)
        let rawScore = (Double(localCorrectCount) - Double(localWrongCount) * wrongPenaltyFactor) / Double(slotCount)

        correctCount = localCorrectCount
        wrongCount = localWrongCount
        doneScore = min(max(rawScore, 0.0), 1.0)
    }

    private func emitSlotFeedback(slotID: String, feedback: PlacementFeedback) {
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

    private func resolveSnapTarget(at point: CGPoint, requireInsideGrid: Bool, useNearestFallback: Bool) -> String? {
        if requireInsideGrid, !isPointInsideGrid(point) {
            return nil
        }

        if let containingSlot = slotContaining(point) {
            return containingSlot
        }

        if useNearestFallback {
            return nearestSlot(to: point)
        }

        return nil
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
            let frame = CGRect(
                x: gridFrame.minX + normalizedFrame.x * gridFrame.width,
                y: gridFrame.minY + normalizedFrame.y * gridFrame.height,
                width: normalizedFrame.w * gridFrame.width,
                height: normalizedFrame.h * gridFrame.height
            )
            computedFrames[slot.id] = frame
        }
        return computedFrames
    }

    private func distanceSquared(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return dx * dx + dy * dy
    }

    private func applyDrop(dragState: DragState, targetSlotID: String) {
        let previousDoneScore = doneScore
        didSolveCurrentPuzzle = false
        isShowingAnswerReveal = false
        feedbackMessage = nil
        let previousTarget = placedTiles[targetSlotID]

        switch dragState.source {
        case .sidebar:
            placedTiles[targetSlotID] = dragState.radicalID
        case .slot:
            // Keep existing board pieces fixed in place. Even if this path is triggered,
            // do not clear the original source slot.
            placedTiles[targetSlotID] = dragState.radicalID
        }

        recomputeDoneMeter()
        snapDebug(
            "applyDrop source=\(dragSourceDebug(dragState.source)) target=\(targetSlotID) previousTarget=\(previousTarget ?? "nil") new=\(dragState.radicalID) correct=\(correctCount) wrong=\(wrongCount) done=\(String(format: "%.2f", doneScore))"
        )
        if doneScore > previousDoneScore {
            emitSlotFeedback(slotID: targetSlotID, feedback: .positive)
        } else if doneScore < previousDoneScore {
            emitSlotFeedback(slotID: targetSlotID, feedback: .negative)
        }

        if let currentKanji {
            playPlacementSoundIfNeeded(for: currentKanji, slotID: targetSlotID, radicalID: dragState.radicalID)
        }

        autoCheckIfCompleted()
    }

    @discardableResult
    private func selectNewPuzzle() -> Bool {
        let allEntries = eligibleEntries
        guard !allEntries.isEmpty else {
            currentKanji = nil
            resetPuzzle(keepHint: false)
            return false
        }

        let previousKanjiID = currentKanji?.id
        let preferredPool = allEntries
        let preferredNonRepeatingPool = preferredPool.filter { $0.id != previousKanjiID }
        if let selected = preferredNonRepeatingPool.randomElement() {
            currentKanji = selected
        } else {
            // If preferred pool only contains the current puzzle, fall back to any different puzzle.
            let anyNonRepeatingPool = allEntries.filter { $0.id != previousKanjiID }
            currentKanji = anyNonRepeatingPool.randomElement() ?? allEntries.randomElement()
        }

        resetPuzzle(keepHint: false)
        generatePromptForCurrentKanji()
        return true
    }

    private var eligibleEntries: [KanjiEntry] {
        let solvedIDs = progressStore.loadSolvedKanjiIDs()

        return dataStore.kanjiEntries.filter { entry in
            guard dataStore.supportsDifficultyProfile(difficultyProfile, for: entry) else { return false }
            guard entry.difficulty(for: difficultyProfile) == selectedDifficulty else { return false }
            guard !usesVisionImpairedGrid || isSupportedInVisionImpairedMode(entry) else { return false }

            if difficultyProfile == .easyMode {
                return true
            }

            switch selectedMode {
            case .discovery:
                return !solvedIDs.contains(entry.id)
            case .revision:
                return solvedIDs.contains(entry.id)
            }
        }
    }

    private func isSupportedInVisionImpairedMode(_ entry: KanjiEntry) -> Bool {
        dataStore.supportsVisionImpairedMode(entry)
    }

    private func generatePromptForCurrentKanji() {
        guard let currentKanji else { return }

        promptGenerationTask?.cancel()
        generatedPrompt = GeneratedKanjiPrompt(
            promptEnglish: currentKanji.promptEnglish,
            radicalExplanations: []
        )
        hintGenerationErrorMessage = nil
        isGeneratingHint = false
        isUsingAppleIntelligenceHint = false
    }

    private func autoCheckIfCompleted() {
        guard doneScore >= 1.0, !didSolveCurrentPuzzle else { return }
        checkAnswer()
    }

    private func playPlacementSoundIfNeeded(for kanji: KanjiEntry, slotID: String, radicalID: String) {
        let isCorrectPlacement = kanji.layout.slots.first(where: { $0.id == slotID })?.expectedRadicalID == radicalID
        let isPuzzleComplete = kanji.layout.slots.allSatisfy { slot in
            placedTiles[slot.id] == slot.expectedRadicalID
        }

        if isPuzzleComplete {
            return
        }

        soundEffectService.play(isCorrectPlacement ? .success : .mistake)
    }

    private func scheduleAutoAdvanceAfterSuccess(for kanjiID: String) {
        autoAdvanceTask?.cancel()
        autoAdvanceTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(nanoseconds: 2_000_000_000)
            } catch {
                return
            }

            guard !Task.isCancelled else { return }
            guard self.didSolveCurrentPuzzle else { return }
            guard self.currentKanji?.id == kanjiID else { return }
            self.newPuzzle()
        }
    }

    private func revealAnswerWithoutDiscovery(for currentKanji: KanjiEntry) {
        autoAdvanceTask?.cancel()
        autoAdvanceTask = nil
        feedbackMessage = nil
        selectedRadicalID = nil
        dragState = nil
        hoveredSlotID = nil
        didSolveCurrentPuzzle = false
        isShowingAnswerReveal = true
        scheduleAutoAdvanceAfterAnswerReveal(for: currentKanji.id)
    }

    private func scheduleAutoAdvanceAfterAnswerReveal(for kanjiID: String) {
        autoAdvanceTask?.cancel()
        autoAdvanceTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await Task.sleep(nanoseconds: 2_000_000_000)
            } catch {
                return
            }

            guard !Task.isCancelled else { return }
            guard self.isShowingAnswerReveal else { return }
            guard self.currentKanji?.id == kanjiID else { return }
            self.newPuzzle()
        }
    }

    private func snapDebug(_ message: String) {
#if DEBUG
        print("[SnapDebug] \(message)")
#endif
    }

    private func pointDebug(_ point: CGPoint) -> String {
        "(\(Int(point.x.rounded())),\(Int(point.y.rounded())))"
    }

    private func rectDebug(_ rect: CGRect) -> String {
        "x:\(Int(rect.minX.rounded())) y:\(Int(rect.minY.rounded())) w:\(Int(rect.width.rounded())) h:\(Int(rect.height.rounded()))"
    }

    private func frameDebugSummary(from frames: [String: CGRect]) -> String {
        guard let sample = frames.sorted(by: { $0.key < $1.key }).first else {
            return "none"
        }
        return "\(sample.key)=\(rectDebug(sample.value))"
    }

    private func dragSourceDebug(_ source: DragSource) -> String {
        switch source {
        case .sidebar:
            return "sidebar"
        case .slot(let slotID):
            return "slot(\(slotID))"
        }
    }

    private func tapInteractionDebug(_ message: String) {
#if DEBUG
        print("[TapVM] \(message)")
#endif
    }
}

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
