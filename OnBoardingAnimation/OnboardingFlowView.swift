import SwiftUI
import UIKit

struct OnboardingFlowView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var viewModel: OnboardingViewModel
    let usesVisionImpairedGrid: Bool
    let onEnterApp: () -> Void
    @State private var isTutorialComplete = false
    @State private var isShowingVoiceOverRecommendationAlert = false
    @State private var onboardingExitVideoPresentation: OnboardingExitVideoPresentation?
    @State private var isTransitioningToExitVideo = false
    @State private var isShowingInlineExitVideo = false
    @State private var exitTransitionWhiteOpacity = 0.0

    private var usesCompactLayout: Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.99, blue: 1.0),
                        Color(red: 0.93, green: 0.98, blue: 0.96)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                contentContainer(minHeight: proxy.size.height)
                    .allowsHitTesting(!isTransitioningToExitVideo)

                if isTransitioningToExitVideo {
                    Color.white
                        .ignoresSafeArea()
                        .opacity(exitTransitionWhiteOpacity)
                }

                if let presentation = onboardingExitVideoPresentation, isShowingInlineExitVideo {
                    OnboardingExitVideoView(url: presentation.url) {
                        onboardingExitVideoPresentation = nil
                        isShowingInlineExitVideo = false
                        isTransitioningToExitVideo = false
                        exitTransitionWhiteOpacity = 0
                        onEnterApp()
                    }
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(2)
                }
            }
        }
        .alert("VoiceOver Recommended", isPresented: $isShowingVoiceOverRecommendationAlert) {
            Button("Stay Here", role: .cancel) {
                SoundEffectService.shared.play(.clickLow)
            }
            Button("Continue Anyway") {
                SoundEffectService.shared.play(.clickLow)
                viewModel.continueForward()
            }
        } message: {
            Text("Turn on VoiceOver for a better experience.")
        }
    }

    @ViewBuilder
    private func contentContainer(minHeight: CGFloat) -> some View {
        if usesCompactLayout {
            ScrollView {
                onboardingStack
                    .frame(maxWidth: .infinity, minHeight: minHeight - 32, alignment: .top)
                    .padding(16)
            }
        } else {
            onboardingStack
                .padding(28)
        }
    }

    private var onboardingStack: some View {
        VStack(spacing: 28) {
            header

            slideCard

            footer
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Kanji Puzzle", systemImage: "puzzlepiece.extension")
                    .font(.title2.weight(.bold))
                Spacer()
                Text("Step \(viewModel.currentStepIndex + 1) of \(viewModel.totalStepCount)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                ForEach(OnboardingViewModel.Step.allCases) { step in
                    Capsule()
                        .fill(step.rawValue <= viewModel.currentStepIndex ? Color.mint : Color.black.opacity(0.08))
                        .frame(height: 8)
                }
            }
        }
    }

    private var slideCard: some View {
        Group {
            switch viewModel.currentStep {
            case .orientation:
                OrientationRecommendationView()
            case .accessibility:
                AccessibilityOptionView(viewModel: viewModel)
            case .basics:
                PuzzleHowToPlayView(prefersReducedMotion: viewModel.prefersReducedMotion)
            case .tutorial:
                OnboardingTutorialView(
                    prefersReducedMotion: viewModel.prefersReducedMotion,
                    usesVisionImpairedGrid: usesVisionImpairedGrid,
                    isComplete: $isTutorialComplete
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(usesCompactLayout ? 16 : 28)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.5), lineWidth: 1)
        )
        .transition(viewModel.prefersReducedMotion ? .opacity : .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        ))
        .animation(viewModel.prefersReducedMotion ? .easeOut(duration: 0.12) : .spring(response: 0.44, dampingFraction: 0.88), value: viewModel.currentStep)
        .onChange(of: viewModel.currentStep) { _, newStep in
            if newStep != .tutorial {
                isTutorialComplete = false
            }
        }
    }

    private var footer: some View {
        HStack {
            Button("Back") {
                SoundEffectService.shared.play(.clickLow)
                viewModel.goBack()
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.isOnFirstStep)
            .accessibilityLabel("Back")
            .accessibilityHint("Return to the previous tutorial screen.")

            Spacer()

            Button(viewModel.continueButtonTitle) {
                SoundEffectService.shared.play(.clickLow)
                handleContinueTap()
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.currentStep == .tutorial && !isTutorialComplete)
            .accessibilityLabel(viewModel.continueButtonTitle)
            .accessibilityHint(
                viewModel.currentStep == .tutorial && !isTutorialComplete
                    ? "Complete the practice puzzle before continuing."
                    : (viewModel.isOnLastStep ? "Finish the tutorial and enter the app." : "Go to the next tutorial screen.")
            )
        }
    }

    private func handleContinueTap() {
        if viewModel.shouldRecommendVoiceOverBeforeContinuing {
            isShowingVoiceOverRecommendationAlert = true
            return
        }

        if viewModel.isOnLastStep, let videoURL = OnboardingVideoResolver.resolvedOnboardingExitVideoURL() {
            startExitVideoTransition(to: videoURL)
            return
        }

        if viewModel.isOnLastStep {
            onEnterApp()
        } else {
            viewModel.continueForward()
        }
    }

    private func startExitVideoTransition(to videoURL: URL) {
        onboardingExitVideoPresentation = OnboardingExitVideoPresentation(url: videoURL)
        isTransitioningToExitVideo = true
        isShowingInlineExitVideo = false
        exitTransitionWhiteOpacity = 0

        withAnimation(.easeInOut(duration: 0.55)) {
            exitTransitionWhiteOpacity = 1
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(580))
            guard onboardingExitVideoPresentation?.url == videoURL else { return }
            isShowingInlineExitVideo = true
        }
    }
}

private struct OrientationRecommendationView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var usesCompactLayout: Bool {
        horizontalSizeClass == .compact
    }

    private var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    private var recommendationTitle: String {
        isPhone ? "Use Portrait Mode" : "Use Landscape Mode"
    }

    private var recommendationDetail: String {
        if isPhone {
            return "This tutorial and puzzle flow fit best on iPhone when the device stays upright in portrait."
        }
        return "This tutorial and puzzle flow fit best on iPad when the device stays sideways in landscape."
    }

    private var recommendationSymbol: String {
        isPhone ? "iphone" : "ipad.landscape"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Recommended Orientation")
                    .font(.system(size: 34, weight: .bold, design: .rounded))

                Text("Before you begin, rotate the device to the orientation that gives this app the cleanest layout.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 16) {
                GeometryReader { proxy in
                    let symbolSide = min(
                        proxy.size.width * (usesCompactLayout ? 0.34 : 0.26),
                        proxy.size.height * 0.72
                    )

                    Image(systemName: recommendationSymbol)
                        .resizable()
                        .scaledToFit()
                        .frame(width: symbolSide, height: symbolSide)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .foregroundStyle(.mint)
                }
                .frame(height: usesCompactLayout ? 140 : 200)

                VStack(alignment: .leading, spacing: 6) {
                    Text(recommendationTitle)
                        .font(.title3.weight(.semibold))

                    Text(recommendationDetail)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )

            HStack(spacing: 10) {
                Label("iPhone: portrait", systemImage: "iphone")
                Label("iPad: landscape", systemImage: "ipad.landscape")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
    }
}

private struct OnboardingExitVideoPresentation: Identifiable {
    let id = UUID()
    let url: URL
}

private struct OnboardingTutorialView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let prefersReducedMotion: Bool
    let usesVisionImpairedGrid: Bool
    @Binding var isComplete: Bool
    @StateObject private var puzzleViewModel = OnboardingTutorialPuzzleViewModel()
    @State private var coachStep: TutorialCoachStep = .focusHint
    @State private var measuredFrames: [TutorialCoachRegion: CGRect] = [:]
    @State private var handAnimationProgress: CGFloat = 0
    @State private var initialHintOverlayOpacity: Double = 0

    private let puzzleCoordinateSpaceName = "OnboardingPracticeSession"

    private var usesCompactLayout: Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        GeometryReader { outerProxy in
            ZStack(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Practice Puzzle")
                        .font(.system(size: usesCompactLayout ? 30 : 34, weight: .bold, design: .rounded))

                    if let currentKanji = puzzleViewModel.currentKanji {
                        GeometryReader { proxy in
                            let isLandscape = proxy.size.width > proxy.size.height

                            ZStack {
                                if usesCompactLayout {
                                    compactTutorialLayout(currentKanji: currentKanji, containerSize: proxy.size)
                                } else if isLandscape {
                                    landscapeTutorialLayout(currentKanji: currentKanji, containerSize: proxy.size)
                                } else {
                                    portraitTutorialLayout(currentKanji: currentKanji, containerSize: proxy.size)
                                }

                                if let dragState = puzzleViewModel.dragState,
                                   let radical = puzzleViewModel.radical(for: dragState.radicalID) {
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
                            .padding(8)
                        }
                        .frame(
                            maxWidth: .infinity,
                            minHeight: usesCompactLayout ? 560 : 420,
                            maxHeight: usesCompactLayout ? 560 : .infinity
                        )
                    } else {
                        Text("Tutorial puzzle unavailable.")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

                tutorialCoachOverlay(in: outerProxy.size)
            }
            .coordinateSpace(name: puzzleCoordinateSpaceName)
            .onPreferenceChange(TutorialCoachFramePreferenceKey.self) { preferenceFrames in
                measuredFrames = preferenceFrames
                if coachStep == .dragDemo {
                    startHandAnimation()
                }
            }
        }
        .onAppear {
            isComplete = puzzleViewModel.didCompleteTutorial
            if !puzzleViewModel.didCompleteTutorial {
                coachStep = .focusHint
                startInitialHintOverlayFadeIn()
            }
        }
        .onChange(of: puzzleViewModel.didCompleteTutorial) { _, didCompleteTutorial in
            isComplete = didCompleteTutorial
            if didCompleteTutorial {
                coachStep = .none
                handAnimationProgress = 0
                initialHintOverlayOpacity = 0
            }
        }
        .onChange(of: coachStep) { _, newStep in
            switch newStep {
            case .dragDemo:
                startHandAnimation()
            case .focusHint:
                startInitialHintOverlayFadeIn()
                handAnimationProgress = 0
            case .focusSidebar, .none:
                initialHintOverlayOpacity = 1
                handAnimationProgress = 0
            }
        }
    }

    private func compactTutorialLayout(currentKanji: KanjiEntry, containerSize: CGSize) -> some View {
        let gridHeight = min(containerSize.width - 16, 320)
        let sidebarHeight = min(max(containerSize.height * 0.30, 220), 280)

        return VStack(alignment: .leading, spacing: 12) {
            tutorialHeader(currentKanji: currentKanji)

            tutorialGrid(currentKanji: currentKanji)
                .frame(maxWidth: .infinity, minHeight: gridHeight, maxHeight: gridHeight)
                .layoutPriority(2)

            tutorialSidebar
                .frame(maxWidth: .infinity, minHeight: sidebarHeight, maxHeight: sidebarHeight)
                .layoutPriority(1)
        }
    }

    private func landscapeTutorialLayout(currentKanji: KanjiEntry, containerSize: CGSize) -> some View {
        let sidebarMinWidth = containerSize.width * 0.40

        return VStack(alignment: .leading, spacing: 12) {
            tutorialHeader(currentKanji: currentKanji)

            HStack(alignment: .top, spacing: 12) {
                tutorialGrid(currentKanji: currentKanji)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(2)

                tutorialSidebar
                    .frame(minWidth: sidebarMinWidth, maxWidth: .infinity, maxHeight: .infinity)
                    .layoutPriority(2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

        }
    }

    private func portraitTutorialLayout(currentKanji: KanjiEntry, containerSize: CGSize) -> some View {
        let sidebarMinHeight = containerSize.height * 0.30

        return VStack(alignment: .leading, spacing: 12) {
            tutorialHeader(currentKanji: currentKanji)

            tutorialGrid(currentKanji: currentKanji)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .layoutPriority(2)

            tutorialSidebar
                .frame(maxWidth: .infinity, minHeight: sidebarMinHeight, maxHeight: .infinity)
                .layoutPriority(1)
        }
    }

    private func tutorialHeader(currentKanji: KanjiEntry) -> some View {
        VStack(spacing: 4) {
            Text("Meaning: \(currentKanji.meaningEnglish)")
                .font(.title3.weight(.semibold))

            Text("Hint: \(puzzleViewModel.activePromptEnglish)")
                .font(.headline)
                .opacity(0.30)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .background(frameReporter(for: .header))
    }

    private func tutorialGrid(currentKanji: KanjiEntry) -> some View {
        tutorialGridView(currentKanji: currentKanji)
        .background(frameReporter(for: .grid))
    }

    @ViewBuilder
    private func tutorialGridView(currentKanji: KanjiEntry) -> some View {
        if usesVisionImpairedGrid {
            VisionImpairedPuzzleGridView(
                slots: currentKanji.layout.slots,
                slotGlyphScaleOverrides: currentKanji.slotGlyphScaleOverrides,
                slotGlyphStretchXOverrides: currentKanji.slotGlyphStretchXOverrides,
                slotGlyphStretchYOverrides: currentKanji.slotGlyphStretchYOverrides,
                placedTiles: puzzleViewModel.placedTiles,
                radicalLookup: puzzleViewModel.radical(for:),
                selectedRadicalID: puzzleViewModel.selectedRadicalID,
                hoveredSlotID: puzzleViewModel.hoveredSlotID,
                draggingRadicalID: puzzleViewModel.dragState?.radicalID,
                feedbackSlotID: puzzleViewModel.feedbackSlotID,
                slotFeedback: puzzleViewModel.slotFeedback,
                coordinateSpaceName: puzzleCoordinateSpaceName,
                onUpdateGridFrame: puzzleViewModel.updateGridFrame,
                onUpdateSlotFrames: puzzleViewModel.updateSlotFrames,
                onTapSlot: puzzleViewModel.handleSlotTap,
                onDoubleTapSlot: puzzleViewModel.handleSlotDoubleTap
            )
        } else {
            PuzzleGridView(
                slots: currentKanji.layout.slots,
                slotGlyphScaleOverrides: currentKanji.slotGlyphScaleOverrides,
                slotGlyphStretchXOverrides: currentKanji.slotGlyphStretchXOverrides,
                slotGlyphStretchYOverrides: currentKanji.slotGlyphStretchYOverrides,
                placedTiles: puzzleViewModel.placedTiles,
                radicalLookup: puzzleViewModel.radical(for:),
                selectedRadicalID: puzzleViewModel.selectedRadicalID,
                hoveredSlotID: puzzleViewModel.hoveredSlotID,
                draggingRadicalID: puzzleViewModel.dragState?.radicalID,
                feedbackSlotID: puzzleViewModel.feedbackSlotID,
                slotFeedback: puzzleViewModel.slotFeedback,
                coordinateSpaceName: puzzleCoordinateSpaceName,
                onUpdateGridFrame: puzzleViewModel.updateGridFrame,
                onUpdateSlotFrames: puzzleViewModel.updateSlotFrames,
                onTapSlot: puzzleViewModel.handleSlotTap,
                onDoubleTapSlot: puzzleViewModel.handleSlotDoubleTap
            )
        }
    }

    private var tutorialSidebar: some View {
        RadicalSidebarView(
            radicals: puzzleViewModel.filteredSidebarRadicals,
            availableDisplayPositions: puzzleViewModel.availableRadicalDisplayPositions,
            usesVisionImpairedGrid: usesVisionImpairedGrid,
            searchText: $puzzleViewModel.sidebarSearchText,
            selectedDisplayPosition: $puzzleViewModel.selectedRadicalDisplayPosition,
            selectedRadicalID: puzzleViewModel.selectedRadicalID,
            hintHighlightedRadicalIDs: puzzleViewModel.hintHighlightedRadicalIDs,
            coordinateSpaceName: puzzleCoordinateSpaceName,
            onTapRadical: puzzleViewModel.selectRadicalForTapPlacement,
            onBeginDrag: puzzleViewModel.beginDragFromSidebar,
            onDragMove: puzzleViewModel.updateDrag,
            onEndDrag: { point in
                puzzleViewModel.endDrag(at: point)
            }
        )
        .background(frameReporter(for: .sidebar))
        .overlay {
            if coachStep == .focusSidebar {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.red, lineWidth: 4)
                    .shadow(color: Color.red.opacity(0.28), radius: 12, x: 0, y: 0)
            }
        }
    }

    @ViewBuilder
    private func tutorialCoachOverlay(in containerSize: CGSize) -> some View {
        switch coachStep {
        case .focusHint:
            ZStack {
                if let headerFrame = measuredFrames[.header] {
                    spotlightOverlay(highlightFrame: headerFrame.insetBy(dx: -14, dy: -12))
                } else {
                    Color.white.opacity(0.96)
                }

                coachCard(
                    text: "Read the meaning and hint. The meaning is the meaning of the kanji we want to construct.",
                    buttonTitle: "Proceed to Next Step",
                    action: { coachStep = .focusSidebar }
                )
                .frame(maxWidth: usesCompactLayout ? min(containerSize.width - 32, 360) : min(containerSize.width * 0.52, 460))
                .position(
                    x: containerSize.width * 0.5,
                    y: usesCompactLayout ? containerSize.height * 0.72 : containerSize.height * 0.58
                )
            }
            .opacity(initialHintOverlayOpacity)
            .allowsHitTesting(initialHintOverlayOpacity > 0.01)
        case .focusSidebar:
            ZStack(alignment: .topLeading) {
                Color.clear
                    .contentShape(Rectangle())

                coachCard(
                    text: "Choose the radical that best suits the provided hint. The hint for rest reads “A person leans on a tree to rest,” so choose the radicals that mean person and tree to complete the kanji.",
                    buttonTitle: "Proceed to Next Step",
                    action: { coachStep = .dragDemo }
                )
                .frame(maxWidth: usesCompactLayout ? min(containerSize.width - 32, 360) : min(containerSize.width * 0.38, 420))
                .position(
                    x: usesCompactLayout
                        ? containerSize.width * 0.5
                        : min(max(240, containerSize.width * 0.28), containerSize.width - 240),
                    y: usesCompactLayout ? containerSize.height * 0.78 : containerSize.height * 0.52
                )
            }
        case .dragDemo:
            ZStack {
                if let handPosition {
                    Image(systemName: "hand.draw.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.mint)
                        .shadow(color: Color.black.opacity(0.12), radius: 6, y: 3)
                        .position(handPosition)
                }

                if usesCompactLayout {
                    VStack {
                        dragDemoInstructionCard
                            .padding(.top, 16)
                            .padding(.horizontal, 16)
                        Spacer()
                    }
                } else {
                    VStack {
                        Spacer()
                        HStack {
                            dragDemoInstructionCard
                            Spacer()
                        }
                        .padding(24)
                    }
                }
            }
            .allowsHitTesting(false)
        case .none:
            EmptyView()
        }
    }

    private func spotlightOverlay(highlightFrame: CGRect) -> some View {
        ZStack {
            Color.white.opacity(0.96)

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .frame(width: highlightFrame.width, height: highlightFrame.height)
                .position(x: highlightFrame.midX, y: highlightFrame.midY)
                .blendMode(.destinationOut)

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.mint.opacity(0.5), lineWidth: 3)
                .frame(width: highlightFrame.width, height: highlightFrame.height)
                .position(x: highlightFrame.midX, y: highlightFrame.midY)
        }
        .compositingGroup()
    }

    private func frameReporter(for region: TutorialCoachRegion) -> some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: TutorialCoachFramePreferenceKey.self,
                    value: [region: proxy.frame(in: .named(puzzleCoordinateSpaceName))]
                )
        }
    }

    private var handPosition: CGPoint? {
        guard let gridFrame = measuredFrames[.grid], let sidebarFrame = measuredFrames[.sidebar] else {
            return nil
        }

        let startPoint: CGPoint
        let endPoint: CGPoint

        if sidebarFrame.minX > gridFrame.maxX {
            startPoint = CGPoint(x: sidebarFrame.minX + 76, y: sidebarFrame.midY - sidebarFrame.height * 0.18)
            endPoint = CGPoint(x: gridFrame.midX, y: gridFrame.midY)
        } else if sidebarFrame.minY > gridFrame.maxY {
            startPoint = CGPoint(x: sidebarFrame.midX, y: sidebarFrame.minY + 56)
            endPoint = CGPoint(x: gridFrame.midX, y: gridFrame.midY)
        } else {
            startPoint = sidebarFrame.center
            endPoint = gridFrame.center
        }

        return CGPoint(
            x: startPoint.x + (endPoint.x - startPoint.x) * handAnimationProgress,
            y: startPoint.y + (endPoint.y - startPoint.y) * handAnimationProgress
        )
    }

    private func startHandAnimation() {
        guard measuredFrames[.grid] != nil, measuredFrames[.sidebar] != nil else { return }
        handAnimationProgress = 0
        withAnimation(
            (prefersReducedMotion ? Animation.easeInOut(duration: 1.6) : Animation.easeInOut(duration: 1.9))
                .repeatForever(autoreverses: false)
        ) {
            handAnimationProgress = 1
        }
    }

    private func startInitialHintOverlayFadeIn() {
        initialHintOverlayOpacity = 0
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(prefersReducedMotion ? .easeIn(duration: 0.35) : .easeInOut(duration: 0.6)) {
                initialHintOverlayOpacity = 1
            }
        }
    }

    private func coachCard(text: String, buttonTitle: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(text)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)

            Button(buttonTitle, action: action)
                .simultaneousGesture(
                    TapGesture().onEnded {
                        SoundEffectService.shared.play(.clickLow)
                    }
                )
                .buttonStyle(.borderedProminent)
                .accessibilityLabel(buttonTitle)
                .accessibilityHint("Advance the tutorial guidance to the next step.")
        }
        .padding(22)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.65), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 10)
    }

    private var dragDemoInstructionCard: some View {
        Text("Drag and drop the radical into the Puzzle grid to complete the kanji.\n If you make a mistake, double tap the radical within the grid to erase it!")
            .font(usesCompactLayout ? .subheadline.weight(.semibold) : .headline)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
    }
}

private enum TutorialCoachStep {
    case focusHint
    case focusSidebar
    case dragDemo
    case none
}

private enum TutorialCoachRegion: Hashable {
    case header
    case grid
    case sidebar
}

private struct TutorialCoachFramePreferenceKey: PreferenceKey {
    static var defaultValue: [TutorialCoachRegion: CGRect] {
        [:]
    }

    static func reduce(value: inout [TutorialCoachRegion: CGRect], nextValue: () -> [TutorialCoachRegion: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}

#Preview {
    OnboardingFlowView(
        viewModel: OnboardingViewModel(),
        usesVisionImpairedGrid: false,
        onEnterApp: {}
    )
}
