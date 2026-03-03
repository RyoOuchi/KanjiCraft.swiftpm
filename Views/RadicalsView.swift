import SwiftUI

struct RadicalsView: View {
    @ObservedObject var viewModel: RadicalsViewModel
    let onOpenTutorial: () -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 140), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.filteredRadicals.isEmpty {
                    ContentUnavailableView(
                        "No Matches",
                        systemImage: "magnifyingglass",
                        description: Text("Try searching by radical symbol or English meaning.")
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            ForEach(viewModel.filteredRadicalSections) { section in
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                                        Text(section.position.title)
                                            .font(.title3.weight(.semibold))
                                        Text("\(section.radicals.count) shown")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    LazyVGrid(columns: columns, spacing: 16) {
                                        ForEach(section.radicals) { radical in
                                            radicalTileContent(radical)
                                                .accessibilityLabel("Radical \(radical.primaryMeaning)")
                                        }
                                    }
                                }
                                .padding(16)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Radicals")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        SoundEffectService.shared.play(.clickLow)
                        onOpenTutorial()
                    } label: {
                        Label("Tutorial", systemImage: "gear")
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search radicals (meaning or symbol)")
        }
    }

    private func radicalTileContent(_ radical: RadicalEntry) -> some View {
        VStack(spacing: 8) {
            Text(radical.symbol)
                .font(AppFont.kanji(size: viewModel.usesVisionImpairedGrid ? 88 : 64))
                .minimumScaleFactor(0.5)

            Text(radical.nameEnglish)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(radical.meaningEnglish.joined(separator: ", "))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .modifier(
            RadicalCollectionTileChrome(
                usesVisionImpairedGrid: viewModel.usesVisionImpairedGrid
            )
        )
    }
}

private struct RadicalCollectionTileChrome: ViewModifier {
    let usesVisionImpairedGrid: Bool

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, minHeight: usesVisionImpairedGrid ? 156 : 132)
            .padding(12)
            .background(
                Color.gray.opacity(usesVisionImpairedGrid ? 0.14 : 0.10),
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        Color.gray.opacity(0.75),
                        style: StrokeStyle(
                            lineWidth: usesVisionImpairedGrid ? 3.0 : 1.5,
                            dash: usesVisionImpairedGrid ? [7, 5] : [5, 4]
                        )
                    )
            )
    }
}
