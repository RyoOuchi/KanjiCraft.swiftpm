import SwiftUI

struct PuzzleGameView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var viewModel: PuzzleViewModel
    let usesVisionImpairedGrid: Bool
    private let puzzleCoordinateSpaceName = "PuzzleSession"
    private let HINT_TEXT_OPACITY: Double = 0.30
    private let HINT_LOADING_MIN_OPACITY: Double = 0.30
    @State private var hintLoadingOpacity: Double = 1.0
    @State private var successFlashOpacity: Double = 0.0
    @State private var isShowingPuzzleAssistant = false

    private var usesCompactLayout: Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        if let currentKanji = viewModel.currentKanji {
            GeometryReader { proxy in
                let isLandscape = proxy.size.width > proxy.size.height

                Group {
                    if usesCompactLayout {
                        ScrollView {
                            ZStack {
                                compactLayout(currentKanji: currentKanji, containerSize: proxy.size)

                                if let dragState = viewModel.dragState, let radical = viewModel.radical(for: dragState.radicalID) {
                                    RadicalTileView(radical: radical, isSelected: false, isHintHighlighted: false)
                                        .scaleEffect(1.08)
                                        .opacity(dragState.isDragging ? 1.0 : 0.0)
                                        .shadow(radius: 6, y: 3)
                                        .frame(width: 96)
                                        .position(x: dragState.currentPosition.x, y: dragState.currentPosition.y)
                                        .allowsHitTesting(false)
                                        .animation(.easeOut(duration: 0.12), value: dragState.isDragging)
                                    }
                            }
                            .frame(maxWidth: .infinity, alignment: .top)
                            .padding(16)
                            .coordinateSpace(name: puzzleCoordinateSpaceName)
                        }
                    } else {
                        ZStack {
                            if isLandscape {
                                landscapeLayout(currentKanji: currentKanji, containerSize: proxy.size)
                            } else {
                                portraitLayout(currentKanji: currentKanji, containerSize: proxy.size)
                            }

                            if let dragState = viewModel.dragState, let radical = viewModel.radical(for: dragState.radicalID) {
                                RadicalTileView(radical: radical, isSelected: false, isHintHighlighted: false)
                                    .scaleEffect(1.08)
                                    .opacity(dragState.isDragging ? 1.0 : 0.0)
                                    .shadow(radius: 6, y: 3)
                                    .frame(width: 96)
                                    .position(x: dragState.currentPosition.x, y: dragState.currentPosition.y)
                                    .allowsHitTesting(false)
                                    .animation(.easeOut(duration: 0.12), value: dragState.isDragging)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(16)
                        .coordinateSpace(name: puzzleCoordinateSpaceName)
                    }
                }
            }
            .overlay {
                if successFlashOpacity > 0 {
                    Color.green
                        .opacity(successFlashOpacity)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }
            }
            .onChange(of: viewModel.didSolveCurrentPuzzle) { _, didSolve in
                guard didSolve else { return }
                triggerSuccessFlash()
            }
            .navigationTitle("Puzzle")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isShowingPuzzleAssistant) {
                PuzzleAssistantSheetView(
                    puzzleViewModel: viewModel,
                    kanjiEntry: currentKanji,
                    allRadicals: viewModel.allKnownRadicals,
                    allRadicalsByID: allRadicalsByID,
                    allowedRadicalsByID: allowedRadicalsByID(for: currentKanji)
                )
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        SoundEffectService.shared.play(.clickLow)
                        viewModel.returnToIntro()
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                    }
                }
                
                ToolbarItem {
                    Button {
                        isShowingPuzzleAssistant = true
                    } label: {
                        Image(systemName: "apple.intelligence")
                    }
                    .accessibilityLabel("Use apple intelligence to solve this puzzle")
                }
                
                ToolbarSpacer()
                
                ToolbarItem {
                    Button {
                        SoundEffectService.shared.play(.clickLow)
                        viewModel.handleHintButtonTap()
                    } label: {
                        if viewModel.hintButtonTitle == "Hint" {
                            Image(systemName: "lightbulb")
                        } else {
                            Text("Answer")
                        }
                    }
                    .accessibilityLabel(viewModel.hintButtonTitle == "Hint" ? "Display Hint" : "Reveal Answer")
                }
                
                ToolbarSpacer()
                
                ToolbarItemGroup {
                    Button {
                        SoundEffectService.shared.play(.clickLow)
                        viewModel.resetPuzzle()
                    } label: {
                        Image(systemName: "arrow.counterclockwise.circle")
                    }
                    .accessibilityLabel("Reset Puzzle")
                    Button {
                        SoundEffectService.shared.play(.clickLow)
                        viewModel.newPuzzle()
                    } label: {
                        Image(systemName: viewModel.isShowingKanjiReveal ? "play.circle" : "shuffle.circle")
                    }
                    .accessibilityLabel(viewModel.isShowingKanjiReveal ? "Play Again" : "New Puzzle")
                }
            }
        } else {
            Text("No puzzle data available.")
                .foregroundStyle(.secondary)
        }
    }

    private func compactLayout(currentKanji: KanjiEntry, containerSize: CGSize) -> some View {
        let gridHeight = min(containerSize.width - 32, 360)
        let sidebarHeight = min(max(containerSize.height * 0.30, 240), 320)

        return VStack(alignment: .leading, spacing: 12) {
            headerView(currentKanji: currentKanji)

            puzzleGrid(currentKanji: currentKanji)
                .frame(maxWidth: .infinity, minHeight: gridHeight, maxHeight: gridHeight)
                .layoutPriority(2)

            RadicalSidebarView(
                radicals: viewModel.filteredSidebarRadicals,
                availableDisplayPositions: viewModel.availableRadicalDisplayPositions,
                usesVisionImpairedGrid: usesVisionImpairedGrid,
                searchText: $viewModel.sidebarSearchText,
                selectedDisplayPosition: $viewModel.selectedRadicalDisplayPosition,
                selectedRadicalID: viewModel.selectedRadicalID,
                hintHighlightedRadicalIDs: viewModel.hintHighlightedRadicalIDs,
                coordinateSpaceName: puzzleCoordinateSpaceName,
                onTapRadical: viewModel.selectRadicalForTapPlacement,
                onBeginDrag: viewModel.beginDragFromSidebar,
                onDragMove: viewModel.updateDrag,
                onEndDrag: { point in
                    viewModel.endDrag(at: point)
                }
            )
            .allowsHitTesting(!viewModel.isShowingKanjiReveal)
            .frame(maxWidth: .infinity, minHeight: sidebarHeight, maxHeight: sidebarHeight)
            .layoutPriority(1)

            feedbackArea
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private var allRadicalsByID: [String: RadicalEntry] {
        viewModel.allKnownRadicals.reduce(into: [String: RadicalEntry]()) { result, radical in
            result[radical.id] = radical
        }
    }

    private func allowedRadicalsByID(for kanjiEntry: KanjiEntry) -> [String: RadicalEntry] {
        let expectedRadicalIDs = Set(kanjiEntry.layout.slots.map(\.expectedRadicalID))
        return expectedRadicalIDs.reduce(into: [String: RadicalEntry]()) { result, radicalID in
            if let radical = allRadicalsByID[radicalID] {
                result[radicalID] = radical
            }
        }
    }

    private func landscapeLayout(currentKanji: KanjiEntry, containerSize: CGSize) -> some View {
        let sidebarMinWidth = containerSize.width * 0.40

        return VStack(alignment: .leading, spacing: 12) {
            headerView(currentKanji: currentKanji)

            HStack(alignment: .top, spacing: 12) {
                puzzleGrid(currentKanji: currentKanji)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(2)

                RadicalSidebarView(
                    radicals: viewModel.filteredSidebarRadicals,
                    availableDisplayPositions: viewModel.availableRadicalDisplayPositions,
                    usesVisionImpairedGrid: usesVisionImpairedGrid,
                    searchText: $viewModel.sidebarSearchText,
                    selectedDisplayPosition: $viewModel.selectedRadicalDisplayPosition,
                    selectedRadicalID: viewModel.selectedRadicalID,
                    hintHighlightedRadicalIDs: viewModel.hintHighlightedRadicalIDs,
                    coordinateSpaceName: puzzleCoordinateSpaceName,
                    onTapRadical: viewModel.selectRadicalForTapPlacement,
                    onBeginDrag: viewModel.beginDragFromSidebar,
                    onDragMove: viewModel.updateDrag,
                    onEndDrag: { point in
                        viewModel.endDrag(at: point)
                    }
                )
                .allowsHitTesting(!viewModel.isShowingKanjiReveal)
                .frame(minWidth: sidebarMinWidth, maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            feedbackArea
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func portraitLayout(currentKanji: KanjiEntry, containerSize: CGSize) -> some View {
        let sidebarMinHeight = containerSize.height * 0.30

        return VStack(alignment: .leading, spacing: 12) {
            headerView(currentKanji: currentKanji)

            puzzleGrid(currentKanji: currentKanji)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(2)

            RadicalSidebarView(
                radicals: viewModel.filteredSidebarRadicals,
                availableDisplayPositions: viewModel.availableRadicalDisplayPositions,
                usesVisionImpairedGrid: usesVisionImpairedGrid,
                searchText: $viewModel.sidebarSearchText,
                selectedDisplayPosition: $viewModel.selectedRadicalDisplayPosition,
                selectedRadicalID: viewModel.selectedRadicalID,
                hintHighlightedRadicalIDs: viewModel.hintHighlightedRadicalIDs,
                coordinateSpaceName: puzzleCoordinateSpaceName,
                onTapRadical: viewModel.selectRadicalForTapPlacement,
                onBeginDrag: viewModel.beginDragFromSidebar,
                onDragMove: viewModel.updateDrag,
                onEndDrag: { point in
                    viewModel.endDrag(at: point)
                }
            )
            .allowsHitTesting(!viewModel.isShowingKanjiReveal)
            .frame(maxWidth: .infinity, minHeight: sidebarMinHeight, maxHeight: .infinity)
            .layoutPriority(1)

            feedbackArea
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func headerView(currentKanji: KanjiEntry) -> some View {
        let meaningFont: Font = usesVisionImpairedGrid ? .title.weight(.semibold) : .title3.weight(.semibold)
        let hintFont: Font = usesVisionImpairedGrid ? .title3.weight(.semibold) : .headline

        return ZStack(alignment: .leading) {

            VStack(spacing: 4) {
                Text("Meaning: \(currentKanji.meaningEnglish)")
                    .font(meaningFont)

                if viewModel.shouldShowHintLoadingState {
                    HStack(spacing: 8) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Hint: generating...")
                            .font(hintFont)
                    }
                    .opacity(hintLoadingOpacity)
                    .onAppear {
                        hintLoadingOpacity = HINT_LOADING_MIN_OPACITY
                        withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                            hintLoadingOpacity = 1.0
                        }
                    }
                    .onDisappear {
                        hintLoadingOpacity = 1.0
                    }
                } else {
                    Text("Hint: \(viewModel.activePromptEnglish)")
                        .font(hintFont)
                        .opacity(HINT_TEXT_OPACITY)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func puzzleGrid(currentKanji: KanjiEntry) -> some View {
        puzzleGridView(currentKanji: currentKanji)
        .allowsHitTesting(!viewModel.isShowingKanjiReveal)
        .overlay {
            if viewModel.isShowingKanjiReveal {
                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white)
                    solvedKanjiOverlay(currentKanji: currentKanji)
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .animation(.easeInOut(duration: 0.18), value: viewModel.isShowingKanjiReveal)
    }

    @ViewBuilder
    private func puzzleGridView(currentKanji: KanjiEntry) -> some View {
        if usesVisionImpairedGrid {
            VisionImpairedPuzzleGridView(
                slots: currentKanji.layout.slots,
                slotGlyphScaleOverrides: currentKanji.slotGlyphScaleOverrides,
                slotGlyphStretchXOverrides: currentKanji.slotGlyphStretchXOverrides,
                slotGlyphStretchYOverrides: currentKanji.slotGlyphStretchYOverrides,
                placedTiles: viewModel.placedTiles,
                radicalLookup: viewModel.radical(for:),
                selectedRadicalID: viewModel.selectedRadicalID,
                hoveredSlotID: viewModel.hoveredSlotID,
                draggingRadicalID: viewModel.dragState?.radicalID,
                feedbackSlotID: viewModel.feedbackSlotID,
                slotFeedback: viewModel.slotFeedback,
                coordinateSpaceName: puzzleCoordinateSpaceName,
                onUpdateGridFrame: viewModel.updateGridFrame,
                onUpdateSlotFrames: viewModel.updateSlotFrames,
                onTapSlot: viewModel.handleSlotTap,
                onDoubleTapSlot: viewModel.handleSlotDoubleTap
            )
        } else {
            PuzzleGridView(
                slots: currentKanji.layout.slots,
                slotGlyphScaleOverrides: currentKanji.slotGlyphScaleOverrides,
                slotGlyphStretchXOverrides: currentKanji.slotGlyphStretchXOverrides,
                slotGlyphStretchYOverrides: currentKanji.slotGlyphStretchYOverrides,
                placedTiles: viewModel.placedTiles,
                radicalLookup: viewModel.radical(for:),
                selectedRadicalID: viewModel.selectedRadicalID,
                hoveredSlotID: viewModel.hoveredSlotID,
                draggingRadicalID: viewModel.dragState?.radicalID,
                feedbackSlotID: viewModel.feedbackSlotID,
                slotFeedback: viewModel.slotFeedback,
                coordinateSpaceName: puzzleCoordinateSpaceName,
                onUpdateGridFrame: viewModel.updateGridFrame,
                onUpdateSlotFrames: viewModel.updateSlotFrames,
                onTapSlot: viewModel.handleSlotTap,
                onDoubleTapSlot: viewModel.handleSlotDoubleTap
            )
        }
    }

    private func solvedKanjiOverlay(currentKanji: KanjiEntry) -> some View {
        GeometryReader { proxy in
            let glyphSize = min(proxy.size.width, proxy.size.height) * 0.72

            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.primary.opacity(0.08))

                Text(currentKanji.kanji)
                    .font(AppFont.kanji(size: glyphSize))
                    .lineLimit(1)
                    .minimumScaleFactor(0.2)
                    .foregroundStyle(.primary)
                    .accessibilityLabel("Completed kanji \(currentKanji.meaningEnglish)")
            }
        }
        .allowsHitTesting(false)
    }

    private var feedbackArea: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let feedbackMessage = viewModel.feedbackMessage {
                Text(feedbackMessage)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(viewModel.didSolveCurrentPuzzle ? .green : .orange)
            }
        }
    }

    private func triggerSuccessFlash() {
        successFlashOpacity = 0
        withAnimation(.easeOut(duration: 0.20)) {
            successFlashOpacity = 0.24
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.easeOut(duration: 1.00)) {
                successFlashOpacity = 0
            }
        }
    }
}
