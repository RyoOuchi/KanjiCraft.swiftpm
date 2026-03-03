import SwiftUI

struct PuzzleHowToPlayView: View {
    let prefersReducedMotion: Bool

    @State private var isShowingClosingMessage = false

    private let onboardingCards: [PuzzleInfoCard] = [
        PuzzleInfoCard(
            icon: "square.grid.3x3",
            title: "Build inside the grid",
            detail: "Drag a radical into the grey puzzle area, or tap a radical and then tap a slot."
        ),
        PuzzleInfoCard(
            icon: "magnifyingglass",
            title: "Use the sidebar",
            detail: "Search radicals, filter by position, and keep the right pieces close while you build."
        ),
        PuzzleInfoCard(
            icon: "hand.tap",
            title: "Fix mistakes quickly",
            detail: "Double-tap a placed piece to remove it and try a different radical."
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            PuzzleInfoCardSectionView(
                title: "How To Play",
                subtitle: "Each puzzle gives you a meaning and a hint. Your job is to build the missing kanji by placing the right radicals into the grid.",
                cards: onboardingCards
            )

            Text("Learn kanji through intuition. Have fun learning kanji.")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.mint)
                .opacity(isShowingClosingMessage ? 1 : 0)
                .offset(y: isShowingClosingMessage ? 0 : (prefersReducedMotion ? 0 : 12))
                .animation(
                    prefersReducedMotion ? .easeIn(duration: 0.6) : .easeInOut(duration: 1.1),
                    value: isShowingClosingMessage
                )
        }
        .task {
            isShowingClosingMessage = false

            try? await Task.sleep(for: .milliseconds(650))
            isShowingClosingMessage = true
        }
    }
}

struct PuzzleUsefulTipsView: View {
    private let tipCards: [PuzzleInfoCard] = [
        PuzzleInfoCard(
            icon: "apple.intelligence",
            title: "Ask the AI assistant",
            detail: "Press the Apple Intelligence chat button in the top right corner of the puzzle screen to ask for subtle hints from the AI assistant."
        ),
        PuzzleInfoCard(
            icon: "lightbulb",
            title: "Use Hint carefully",
            detail: "Hint highlights helpful radicals first. Press it again to reveal the answer, but revealed answers do not count as discovered."
        ),
        PuzzleInfoCard(
            icon: "arrow.counterclockwise.circle",
            title: "Reset the board",
            detail: "Press Reset to clear the current placements and try the same kanji again from the beginning."
        ),
        PuzzleInfoCard(
            icon: "shuffle.circle",
            title: "Load a new puzzle",
            detail: "Press New Puzzle to move on to a different kanji when you want a fresh challenge."
        )
    ]

    var body: some View {
        PuzzleInfoCardSectionView(
            title: "Useful Tips",
            subtitle: "Keep these controls in mind while you play. They help you with solving the puzzles!",
            cards: tipCards
        )
    }
}

private struct PuzzleInfoCardSectionView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let title: String
    let subtitle: String
    let cards: [PuzzleInfoCard]

    private var usesCompactLayout: Bool {
        horizontalSizeClass == .compact
    }

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
                                PuzzleInfoCardView(card: card, usesCompactLayout: true)
                            }
                        }
                    } else {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(cards) { card in
                                PuzzleInfoCardView(card: card, usesCompactLayout: false)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: usesCompactLayout ? CGFloat(cards.count) * 240 : 340, maxHeight: .infinity)
        }
    }
}

private struct PuzzleInfoCardView: View {
    let card: PuzzleInfoCard
    let usesCompactLayout: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { proxy in
                let symbolSide = min(
                    proxy.size.width * (usesCompactLayout ? 0.28 : 0.34),
                    proxy.size.height * (usesCompactLayout ? 0.82 : 0.88)
                )

                Image(systemName: card.icon)
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.mint)
                    .frame(width: symbolSide, height: symbolSide, alignment: .center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .frame(
                maxWidth: .infinity,
                minHeight: usesCompactLayout ? 96 : 128,
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

private struct PuzzleInfoCard: Identifiable {
    let icon: String
    let title: String
    let detail: String

    var id: String {
        title
    }
}
