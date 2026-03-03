import SwiftUI

struct KanjiDetailView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let entry: KanjiEntry
    let radicals: [RadicalEntry]

    private var usesCompactLayout: Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
//                VStack(alignment: .leading, spacing: 8) {
//                    Text(entry.kanji)
//                        .font(AppFont.kanji(size: 108))
//                        .frame(maxWidth: .infinity)
//
//                    Text("Kanji Detail")
//                        .font(.system(size: 34, weight: .bold, design: .rounded))
//
//                    Text("Review the meaning and building pieces for this kanji.")
//                        .font(.body)
//                        .foregroundStyle(.secondary)
//                }

                KanjiDetailSectionView(
                    title: "Meaning",
                    subtitle: "What does this kanji mean?",
                    cards: [
                        KanjiDetailCard(
                            symbol: entry.kanji,
                            title: entry.meaningEnglish,
                            detail: "Meaning"
                        )
                    ],
                    usesCompactLayout: usesCompactLayout
                )

                KanjiDetailSectionView(
                    title: "Components",
                    subtitle: "These are the radicals used to build this kanji.",
                    cards: radicals.map { radical in
                        KanjiDetailCard(
                            symbol: radical.symbol,
                            title: radical.primaryMeaning.capitalized,
                            detail: radical.nameEnglish
                        )
                    },
                    usesCompactLayout: usesCompactLayout
                )
            }
            .padding(24)
        }
        .presentationDetents([.large])
    }
}

private struct KanjiDetailSectionView: View {
    let title: String
    let subtitle: String
    let cards: [KanjiDetailCard]
    let usesCompactLayout: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))

                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { _ in
                Group {
                    if usesCompactLayout {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(cards) { card in
                                KanjiDetailCardView(card: card, usesCompactLayout: true)
                            }
                        }
                    } else {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(cards) { card in
                                KanjiDetailCardView(card: card, usesCompactLayout: false)
                            }
                        }
                    }
                }
            }
            .frame(
                maxWidth: .infinity,
                minHeight: usesCompactLayout ? CGFloat(cards.count) * 220 : 320,
                maxHeight: .infinity
            )
        }
    }
}

private struct KanjiDetailCardView: View {
    let card: KanjiDetailCard
    let usesCompactLayout: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { proxy in
                let symbolSide = min(
                    proxy.size.width * (usesCompactLayout ? 0.32 : 0.38),
                    proxy.size.height * (usesCompactLayout ? 0.86 : 0.9)
                )

                Text(card.symbol)
                    .font(AppFont.kanji(size: symbolSide))
                    .frame(width: symbolSide, height: symbolSide, alignment: .center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .frame(
                maxWidth: .infinity,
                minHeight: usesCompactLayout ? 112 : 148,
                maxHeight: .infinity
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(card.title)
                    .font(.headline)
                Text(card.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct KanjiDetailCard: Identifiable {
    let symbol: String
    let title: String
    let detail: String

    var id: String {
        "\(symbol)-\(title)"
    }
}
