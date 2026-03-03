import SwiftUI

@main
struct MyApp: App {
    @StateObject private var appRootViewModel: AppRootViewModel
    @StateObject private var collectionViewModel: CollectionViewModel
    @StateObject private var radicalsViewModel: RadicalsViewModel
    @StateObject private var puzzleViewModel: PuzzleViewModel
    @StateObject private var onboardingViewModel: OnboardingViewModel
    @State private var appEntryWhiteOpacity = 0.0

    init() {
        let dataStore = DataStore()
        let progressStore = ProgressStore()

        let appRoot = AppRootViewModel()
        let collection = CollectionViewModel(dataStore: dataStore, progressStore: progressStore)
        let radicals = RadicalsViewModel(dataStore: dataStore)
        let puzzle = PuzzleViewModel(dataStore: dataStore, progressStore: progressStore)
        let onboarding = OnboardingViewModel()

        _appRootViewModel = StateObject(wrappedValue: appRoot)
        _collectionViewModel = StateObject(wrappedValue: collection)
        _radicalsViewModel = StateObject(wrappedValue: radicals)
        _puzzleViewModel = StateObject(wrappedValue: puzzle)
        _onboardingViewModel = StateObject(wrappedValue: onboarding)
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if onboardingViewModel.shouldShowOnboarding {
                        OnboardingFlowView(
                            viewModel: onboardingViewModel,
                            usesVisionImpairedGrid: onboardingViewModel.usesVisionImpairedGrid,
                            onEnterApp: transitionIntoMainApp
                        )
                    } else {
                        RootTabView(
                            appRootViewModel: appRootViewModel,
                            collectionViewModel: collectionViewModel,
                            radicalsViewModel: radicalsViewModel,
                            puzzleViewModel: puzzleViewModel,
                            usesVisionImpairedGrid: onboardingViewModel.usesVisionImpairedGrid,
                            onOpenTutorial: onboardingViewModel.reopenOnboarding
                        )
                    }
                }

                Color.white
                    .ignoresSafeArea()
                    .opacity(appEntryWhiteOpacity)
                    .allowsHitTesting(appEntryWhiteOpacity > 0.01)
            }
            .onAppear {
                puzzleViewModel.setUsesVisionImpairedGrid(onboardingViewModel.usesVisionImpairedGrid)
                puzzleViewModel.setDifficultyProfile(onboardingViewModel.currentDifficultyProfile)
                collectionViewModel.setUsesVisionImpairedGrid(onboardingViewModel.usesVisionImpairedGrid)
                collectionViewModel.setDifficultyProfile(onboardingViewModel.currentDifficultyProfile)
                radicalsViewModel.setUsesVisionImpairedGrid(onboardingViewModel.usesVisionImpairedGrid)
            }
            .onChange(of: onboardingViewModel.usesVisionImpairedGrid) { _, usesVisionImpairedGrid in
                puzzleViewModel.setUsesVisionImpairedGrid(usesVisionImpairedGrid)
                collectionViewModel.setUsesVisionImpairedGrid(usesVisionImpairedGrid)
                radicalsViewModel.setUsesVisionImpairedGrid(usesVisionImpairedGrid)
            }
            .onChange(of: onboardingViewModel.currentDifficultyProfile) { _, difficultyProfile in
                puzzleViewModel.setDifficultyProfile(difficultyProfile)
                collectionViewModel.setDifficultyProfile(difficultyProfile)
            }
        }
    }

    @MainActor
    private func transitionIntoMainApp() {
        appEntryWhiteOpacity = 1
        onboardingViewModel.finishOnboarding()

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            withAnimation(.easeOut(duration: 1.0)) {
                appEntryWhiteOpacity = 0
            }
        }
    }
}
