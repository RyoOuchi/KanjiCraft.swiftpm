import SwiftUI

struct PuzzleView: View {
    @ObservedObject var viewModel: PuzzleViewModel
    let usesVisionImpairedGrid: Bool
    let onOpenTutorial: () -> Void

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.screenState {
                case .intro:
                    PuzzleIntroView(
                        selectedMode: $viewModel.selectedMode,
                        selectedDifficulty: $viewModel.selectedDifficulty,
                        prefersReducedMotion: viewModel.difficultyProfile == .easyMode,
                        showsModeSelection: viewModel.difficultyProfile != .easyMode,
                        availableDifficulties: viewModel.availableDifficulties,
                        availablePuzzleCount: viewModel.availablePuzzleCount,
                        openTutorialAction: onOpenTutorial,
                        startAction: viewModel.startPuzzle
                    )
                case .active:
                    PuzzleGameView(
                        viewModel: viewModel,
                        usesVisionImpairedGrid: usesVisionImpairedGrid
                    )
                }
            }
        }
    }
}
