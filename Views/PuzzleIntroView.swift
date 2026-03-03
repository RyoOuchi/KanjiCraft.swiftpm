import SwiftUI

struct PuzzleIntroView: View {
    @Binding var selectedMode: PuzzleMode
    @Binding var selectedDifficulty: KanjiDifficulty
    let prefersReducedMotion: Bool
    let showsModeSelection: Bool
    let availableDifficulties: [KanjiDifficulty]
    let availablePuzzleCount: Int
    let openTutorialAction: () -> Void
    let startAction: () -> Void
    @State private var playSectionFrame: CGRect = .zero

    private let playSectionID = "playPuzzleSection"

    var body: some View {
        GeometryReader { proxy in
            ScrollViewReader { scrollViewProxy in
                ZStack(alignment: .bottomTrailing) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            PuzzleHowToPlayView(prefersReducedMotion: prefersReducedMotion)
                                .frame(maxWidth: .infinity, alignment: .topLeading)

                            PuzzleUsefulTipsView()
                                .frame(maxWidth: .infinity, alignment: .topLeading)

                            VStack(alignment: .leading, spacing: 24) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Play Puzzle")
                                        .font(.system(size: 34, weight: .bold, design: .rounded))

                                    Text("Customize which kanji appear in the puzzle.")
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                }

                                if showsModeSelection {
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Mode")
                                            .font(.headline)

                                        Picker("Mode", selection: $selectedMode) {
                                            ForEach(PuzzleMode.allCases, id: \.self) { mode in
                                                Text(mode.title)
                                                    .tag(mode)
                                            }
                                        }
                                        .pickerStyle(.segmented)

                                        Text(selectedMode.description)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                } else {
                //                    Text("Easy Mode mixes discovered and undiscovered kanji together.")
                //                        .font(.subheadline)
                //                        .foregroundStyle(.secondary)
                                }

                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Difficulty")
                                        .font(.headline)

                                    Picker("Difficulty", selection: $selectedDifficulty) {
                                        ForEach(availableDifficulties, id: \.self) { difficulty in
                                            Text(difficulty.title)
                                                .tag(difficulty)
                                        }
                                    }
                                    .pickerStyle(.segmented)

                                    Text(selectedDifficulty.description)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Text(availablePuzzleCount == 1 ? "1 puzzle available" : "\(availablePuzzleCount) puzzles available")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                HStack {
                                    Spacer()

                                    Button {
                                        SoundEffectService.shared.play(.clickLow)
                                        startAction()
                                    } label: {
                                        Text("Start Puzzle")
                                            .font(.title.weight(.semibold))
                                            .padding(.horizontal, 28)
                                            .padding(.vertical, 8)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.large)
                                    .padding(.top, 8)
                                    .disabled(availablePuzzleCount == 0)

                                    Spacer()
                                }
                            }
                            .id(playSectionID)
                            .background(
                                GeometryReader { sectionProxy in
                                    Color.clear
                                        .preference(
                                            key: PuzzleIntroPlaySectionFramePreferenceKey.self,
                                            value: sectionProxy.frame(in: .named("PuzzleIntroScroll"))
                                        )
                                }
                            )

                            Spacer(minLength: 0)
                        }
                    }
                    .coordinateSpace(name: "PuzzleIntroScroll")
                    .padding(24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .onPreferenceChange(PuzzleIntroPlaySectionFramePreferenceKey.self) { newFrame in
                        playSectionFrame = newFrame
                    }

                    if shouldShowScrollToPlayButton(viewportHeight: proxy.size.height) {
                        Button {
                            SoundEffectService.shared.play(.clickLow)
                            withAnimation(.easeInOut(duration: 0.28)) {
                                scrollViewProxy.scrollTo(playSectionID, anchor: .top)
                            }
                        } label: {
                            Image(systemName: "arrow.down")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(.white)
                                .padding(18)
                                .background(.mint, in: Circle())
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                        .shadow(color: Color.black.opacity(0.14), radius: 12, y: 6)
                        .accessibilityLabel("Jump to Play Puzzle")
                        .accessibilityHint("Scroll to the Play Puzzle section.")
                    }
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarLeading) {
                Button {
                    SoundEffectService.shared.play(.clickLow)
                    openTutorialAction()
                } label: {
                    Label("Tutorial", systemImage: "gear")
                }
            }
        }
        .onChange(of: selectedMode) { _, _ in
            guard showsModeSelection else { return }
            SoundEffectService.shared.play(.clickHigh)
        }
        .onChange(of: selectedDifficulty) { _, _ in
            SoundEffectService.shared.play(.clickHigh)
        }
    }

    private func shouldShowScrollToPlayButton(viewportHeight: CGFloat) -> Bool {
        guard playSectionFrame != .zero else { return false }
        return playSectionFrame.minY > viewportHeight - 40
    }
}

private struct PuzzleIntroPlaySectionFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect {
        .zero
    }

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
