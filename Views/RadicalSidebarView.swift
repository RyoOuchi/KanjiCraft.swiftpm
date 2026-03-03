import SwiftUI

struct RadicalSidebarView: View {
    let radicals: [RadicalEntry]
    let availableDisplayPositions: [RadicalDisplayPosition]
    let usesVisionImpairedGrid: Bool
    @Binding var searchText: String
    @Binding var selectedDisplayPosition: RadicalDisplayPosition
    let selectedRadicalID: String?
    let hintHighlightedRadicalIDs: Set<String>
    let coordinateSpaceName: String
    let onTapRadical: (String) -> Void
    let onBeginDrag: (String, CGPoint) -> Void
    let onDragMove: (CGPoint) -> Void
    let onEndDrag: (CGPoint) -> Void

    private let tileSpacing: CGFloat = 18
    private let tileHitboxInset: CGFloat = 8

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: usesVisionImpairedGrid ? 150 : 90), spacing: tileSpacing)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search \(selectedDisplayPosition.title) Radicals", text: $searchText)
                    .textFieldStyle(.plain)
                    .autocorrectionDisabled()

                Divider()
                    .frame(height: 20)

                Menu {
                    Picker("Radical position", selection: $selectedDisplayPosition) {
                        ForEach(availableDisplayPositions) { displayPosition in
                            Text(displayPosition.title)
                                .tag(displayPosition)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedDisplayPosition.title)
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.06), lineWidth: 0.8)
            )

            ScrollView {
                LazyVGrid(columns: columns, spacing: tileSpacing) {
                    ForEach(radicals) { radical in
                        RadicalTileView(
                            radical: radical,
                            isSelected: selectedRadicalID == radical.id,
                            isHintHighlighted: hintHighlightedRadicalIDs.contains(radical.id),
                            tileScaleMultiplier: usesVisionImpairedGrid ? 1.7 : 1.0
                        )
                        .padding(4)
                        .contentShape(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .inset(by: tileHitboxInset)
                        )
                        .gesture(dragGesture(for: radical.id))
                        .accessibilityLabel("Radical: \(radical.primaryMeaning)")
                    }
                }
                .padding(.vertical, 4)
                .padding(.bottom, 8)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.26),
                            Color.white.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.58),
                            Color.white.opacity(0.14)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .overlay(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.22),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .allowsHitTesting(false)
        }
        .shadow(color: Color.black.opacity(0.12), radius: 18, x: 0, y: 10)
        .onChange(of: selectedDisplayPosition) { _, _ in
            SoundEffectService.shared.play(.clickHigh)
        }
    }

    private func dragGesture(for radicalID: String) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(coordinateSpaceName))
            .onChanged { value in
                onBeginDrag(radicalID, value.startLocation)
                onDragMove(value.location)
            }
            .onEnded { value in
                let dragDistance = hypot(value.translation.width, value.translation.height)
                onEndDrag(value.location)
                if dragDistance < 4 {
                    SoundEffectService.shared.play(.clickHigh)
                    onTapRadical(radicalID)
                }
            }
    }
}
