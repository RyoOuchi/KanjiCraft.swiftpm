import SwiftUI

struct CollectionView: View {
    @ObservedObject var viewModel: CollectionViewModel
    let onTapUndiscoveredTile: (KanjiDifficulty) -> Void
    let onOpenTutorial: () -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 140), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            collectionContent
            .navigationTitle("My Kanji Collection")
            .toolbar {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button {
                        SoundEffectService.shared.play(.clickLow)
                        onOpenTutorial()
                    } label: {
                        Label("Tutorial", systemImage: "gear")
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search collection")
            .sheet(item: $viewModel.selectedKanji) { entry in
                KanjiDetailView(entry: entry, radicals: viewModel.radicalsUsed(for: entry))
            }
        }
    }

    @ViewBuilder
    private var collectionContent: some View {
        if viewModel.filteredCollectionSections.isEmpty {
            ContentUnavailableView(
                "No Matches",
                systemImage: "magnifyingglass",
                description: Text("Try searching by kanji or English meaning.")
            )
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(viewModel.filteredCollectionSections) { section in
                        collectionSectionView(section)
                    }
                }
                .padding()
            }
        }
    }

    private func collectionSectionView(_ section: CollectionViewModel.DifficultySection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(section.difficulty.title)
                    .font(.title3.weight(.semibold))
                Text(viewModel.collectionProgressText(for: section.difficulty))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(section.tiles) { tile in
                    collectionTileView(tile, difficulty: section.difficulty)
                }
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private func collectionTileView(
        _ tile: CollectionViewModel.CollectionTile,
        difficulty: KanjiDifficulty
    ) -> some View {
        if tile.isSolved {
            Button {
                SoundEffectService.shared.play(.clickHigh)
                viewModel.openKanjiDetail(tile.entry)
            } label: {
                solvedCollectionTileContent(
                    kanji: tile.entry.kanji,
                    meaning: tile.entry.meaningEnglish,
                    discoveryStatus: tile.discoveryStatus ?? .clean
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Solved kanji \(tile.entry.meaningEnglish)")
        } else {
            Button {
                onTapUndiscoveredTile(difficulty)
            } label: {
                UndiscoveredCollectionTileView(
                    usesVisionImpairedGrid: viewModel.usesVisionImpairedGrid
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Uncollected kanji in \(difficulty.title)")
        }
    }

    private func solvedCollectionTileContent(
        kanji: String,
        meaning: String,
        discoveryStatus: KanjiDiscoveryStatus
    ) -> some View {
        VStack(spacing: 8) {
            Text(kanji)
                .font(AppFont.kanji(size: viewModel.usesVisionImpairedGrid ? 88 : 64))
                .minimumScaleFactor(0.5)

            Text(meaning)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .modifier(
            CollectionTileChrome(
                outlineColor: outlineColor(for: discoveryStatus),
                fillColor: fillColor(for: discoveryStatus),
                usesVisionImpairedGrid: viewModel.usesVisionImpairedGrid
            )
        )
    }

    private func outlineColor(for discoveryStatus: KanjiDiscoveryStatus) -> Color {
        switch discoveryStatus {
        case .clean:
            return .green
        case .hinted:
            return .yellow
        }
    }

    private func fillColor(for discoveryStatus: KanjiDiscoveryStatus) -> Color {
        let baseColor: Color
        switch discoveryStatus {
        case .clean:
            baseColor = .green
        case .hinted:
            baseColor = .yellow
        }

        return baseColor.opacity(viewModel.usesVisionImpairedGrid ? 0.18 : 0.08)
    }
}

private struct UndiscoveredCollectionTileView: View {
    let usesVisionImpairedGrid: Bool
    @State private var isBobbing = false

    var body: some View {
        VStack(spacing: 8) {
            Image("PuzzlePiece")
                .resizable()
                .scaledToFit()
                .frame(height: usesVisionImpairedGrid ? 72 : 62)
                .opacity(0.50)
                .offset(y: isBobbing ? -4 : 4)
                .onAppear {
                    guard !isBobbing else { return }
                    withAnimation(.easeInOut(duration: 1.45).repeatForever(autoreverses: true)) {
                        isBobbing = true
                    }
                }

            Text("To Be Discovered")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .modifier(
            CollectionTileChrome(
                outlineColor: Color.gray.opacity(0.75),
                fillColor: Color.gray.opacity(usesVisionImpairedGrid ? 0.14 : 0.10),
                usesVisionImpairedGrid: usesVisionImpairedGrid
            )
        )
    }
}

private struct CollectionTileChrome: ViewModifier {
    let outlineColor: Color
    let fillColor: Color
    let usesVisionImpairedGrid: Bool

    func body(content: Content) -> some View {
        content
        .frame(maxWidth: .infinity, minHeight: usesVisionImpairedGrid ? 156 : 132)
        .padding(12)
        .background(fillColor, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    outlineColor,
                    style: StrokeStyle(
                        lineWidth: usesVisionImpairedGrid ? 3.0 : 1.5,
                        dash: usesVisionImpairedGrid ? [7, 5] : [5, 4]
                    )
                )
        )
    }
}
