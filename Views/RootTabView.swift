import SwiftUI

struct RootTabView: View {
    @ObservedObject var appRootViewModel: AppRootViewModel
    @ObservedObject var collectionViewModel: CollectionViewModel
    @ObservedObject var radicalsViewModel: RadicalsViewModel
    @ObservedObject var puzzleViewModel: PuzzleViewModel
    let usesVisionImpairedGrid: Bool
    let onOpenTutorial: () -> Void

    var body: some View {
        TabView(selection: $appRootViewModel.selectedTab) {
            CollectionView(
                viewModel: collectionViewModel,
                onTapUndiscoveredTile: openPuzzle(for:),
                onOpenTutorial: onOpenTutorial
            )
                .tabItem {
                    Label("Collection", systemImage: "square.grid.2x2")
                }
                .tag(AppRootViewModel.AppTab.main)

            PuzzleView(
                viewModel: puzzleViewModel,
                usesVisionImpairedGrid: usesVisionImpairedGrid,
                onOpenTutorial: onOpenTutorial
            )
                .tabItem {
                    Label("Puzzle", systemImage: "puzzlepiece")
                }
                .tag(AppRootViewModel.AppTab.puzzle)

            RadicalsView(
                viewModel: radicalsViewModel,
                onOpenTutorial: onOpenTutorial
            )
                .tabItem {
                    Label("Radicals", systemImage: "book")
                }
                .tag(AppRootViewModel.AppTab.radicals)
        }
        .onChange(of: appRootViewModel.selectedTab) { _, _ in
#if !targetEnvironment(simulator)
            SoundEffectService.shared.play(.clickLow)
#endif
        }
        .onChange(of: puzzleViewModel.didSolveCurrentPuzzle) { _, isSolved in
            if isSolved {
                collectionViewModel.loadSolvedKanji()
            }
        }
    }

    private func openPuzzle(for difficulty: KanjiDifficulty) {
        puzzleViewModel.selectedMode = .discovery
        puzzleViewModel.selectedDifficulty = difficulty
        puzzleViewModel.returnToIntro()
        appRootViewModel.selectedTab = .puzzle
    }
}
