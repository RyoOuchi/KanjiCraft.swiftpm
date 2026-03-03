import SwiftUI

struct AccessibilityOptionView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var isShowingAccessibilityMessage = false

    private var usesCompactLayout: Bool {
        horizontalSizeClass == .compact
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Set Up Your Experience")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text("Choose the support profile that best matches how you want the tutorial and puzzle flow to feel before you begin.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Group {
                if usesCompactLayout {
                    VStack(alignment: .leading, spacing: 12) {
                        accessibilityOptionCards
                    }
                } else {
                    GeometryReader { _ in
                        HStack(alignment: .top, spacing: 12) {
                            accessibilityOptionCards
                        }
                    }
                }
            }
            .frame(
                maxWidth: .infinity,
                minHeight: usesCompactLayout ? nil : 320,
                maxHeight: usesCompactLayout ? nil : .infinity
            )

            VStack(alignment: .leading, spacing: 10) {
                Label("Selecting none means you have chosen to experience the app in default mode.", systemImage: "checkmark.seal")
                Label("Visually impaired support emphasizes clearer visual structure and orientation cues.", systemImage: "eye")
                Label("Easy Mode is designed to make interactions smoother and easier for users.", systemImage: "brain.head.profile")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if !usesCompactLayout {
                Spacer(minLength: 0)
            }
        }
        .task {
            isShowingAccessibilityMessage = false

            try? await Task.sleep(for: .milliseconds(650))
            isShowingAccessibilityMessage = true
        }
    }

    @ViewBuilder
    private var accessibilityOptionCards: some View {
        ForEach(OnboardingViewModel.AccessibilitySupportOption.allCases) { option in
            Button {
                let willSelect = !viewModel.isAccessibilitySupportOptionSelected(option)
                SoundEffectService.shared.play(willSelect ? .clickHigh : .clickLow)
                viewModel.toggleAccessibilitySupportOption(option)
            } label: {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .center, spacing: 12) {
                        Text(option.title)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Spacer(minLength: 0)

                        Image(systemName: viewModel.isAccessibilitySupportOptionSelected(option) ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(viewModel.isAccessibilitySupportOptionSelected(option) ? .mint : .secondary)
                    }
                    GeometryReader { proxy in
                        let symbolSide = min(
                            proxy.size.width * (usesCompactLayout ? 0.28 : 0.34),
                            proxy.size.height * (usesCompactLayout ? 0.82 : 0.88)
                        )

                        Image(systemName: option.symbolName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: symbolSide, height: symbolSide, alignment: .center)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            .foregroundStyle(viewModel.isAccessibilitySupportOptionSelected(option) ? .mint : .primary)
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: usesCompactLayout ? 84 : 132,
                        maxHeight: .infinity
                    )
                    .padding(.vertical, usesCompactLayout ? 4 : 12)

                    Text(option.subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(18)
                .frame(
                    maxWidth: .infinity,
                    minHeight: usesCompactLayout ? 190 : nil,
                    maxHeight: usesCompactLayout ? nil : .infinity,
                    alignment: .topLeading
                )
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(viewModel.isAccessibilitySupportOptionSelected(option) ? Color.mint.opacity(0.14) : Color(uiColor: .secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(viewModel.isAccessibilitySupportOptionSelected(option) ? Color.mint : Color.black.opacity(0.06), lineWidth: viewModel.isAccessibilitySupportOptionSelected(option) ? 2 : 1)
                )
            }
            .buttonStyle(.plain)
            .frame(
                maxWidth: .infinity,
                minHeight: usesCompactLayout ? nil : 0,
                maxHeight: usesCompactLayout ? nil : .infinity,
                alignment: .top
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(option.title)
            .accessibilityValue(viewModel.isAccessibilitySupportOptionSelected(option) ? "Selected" : "Not selected")
            .accessibilityHint("\(option.subtitle) Double tap to toggle this option.")
        }
    }
}

#Preview {
    AccessibilityOptionView(viewModel: OnboardingViewModel())
}
