import SwiftUI

struct PuzzleAssistantSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var puzzleViewModel: PuzzleViewModel
    @StateObject private var viewModel: PuzzleAssistantViewModel

    private let suggestionPrompts = [
        "Give me a subtle hint.",
        "What meaning should I focus on next?",
        "How do my current pieces look?"
    ]

    init(
        puzzleViewModel: PuzzleViewModel,
        kanjiEntry: KanjiEntry,
        allRadicals: [RadicalEntry],
        allRadicalsByID: [String: RadicalEntry],
        allowedRadicalsByID: [String: RadicalEntry]
    ) {
        self.puzzleViewModel = puzzleViewModel
        _viewModel = StateObject(
            wrappedValue: PuzzleAssistantViewModel(
                kanjiEntry: kanjiEntry,
                allRadicals: allRadicals,
                allRadicalsByID: allRadicalsByID,
                allowedRadicalsByID: allowedRadicalsByID
            )
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                messageScrollView

                Divider()

                suggestionRow

                inputBar
            }
            .navigationTitle("Apple Intelligence")
            .toolbar {
                ToolbarItem {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .task {
            viewModel.loadAvailabilityStatusIfNeeded()
        }
    }

    private var messageScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        messageBubble(message)
                            .id(message.id)
                    }

                    if viewModel.isSending {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                            Text("Thinking…")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
                .padding(16)
            }
            .background(Color.secondary.opacity(0.08))
            .onAppear {
                scrollToBottom(using: proxy, animated: false)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                scrollToBottom(using: proxy, animated: true)
            }
        }
    }

    private var suggestionRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(suggestionPrompts, id: \.self) { prompt in
                    Button {
                        viewModel.sendSuggestedPrompt(
                            prompt,
                            placedTiles: puzzleViewModel.placedTiles,
                            generatedPrompt: puzzleViewModel.generatedPrompt
                        )
                    } label: {
                        Text(prompt)
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(Color.secondary.opacity(0.10))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isSending)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private var inputBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let availabilityText = viewModel.availabilityText {
                Text(availabilityText)
                    .font(.caption)
                    .foregroundStyle(viewModel.isAppleIntelligenceAvailable ? .green : .secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
            }

            if let statusText = viewModel.statusText {
                Text(statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
            }

            HStack(alignment: .bottom, spacing: 12) {
                TextField("Ask for a hint...", text: $viewModel.draftMessage, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.secondary.opacity(0.10))
                    )

                Button {
                    viewModel.sendCurrentDraft(
                        placedTiles: puzzleViewModel.placedTiles,
                        generatedPrompt: puzzleViewModel.generatedPrompt
                    )
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                }
                .disabled(!viewModel.canSend)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            .padding(.top, 4)
        }
        .background(.thinMaterial)
    }

    private func messageBubble(_ message: PuzzleAssistantViewModel.Message) -> some View {
        HStack {
            if message.role == .assistant {
                avatarView(systemName: "apple.intelligence", fillColor: Color.blue.opacity(0.14))
                bubbleContent(message, fillColor: Color.blue.opacity(0.14), alignment: .leading)
                Spacer(minLength: 16)
            } else {
                Spacer(minLength: 16)
                bubbleContent(message, fillColor: Color.mint.opacity(0.20), alignment: .trailing)
                avatarView(systemName: "person.fill", fillColor: Color.mint.opacity(0.20))
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .assistant ? .leading : .trailing)
    }

    private func bubbleContent(
        _ message: PuzzleAssistantViewModel.Message,
        fillColor: Color,
        alignment: Alignment
    ) -> some View {
        Text(message.text)
            .font(.body)
            .foregroundStyle(.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(fillColor)
            )
            .frame(maxWidth: .infinity, alignment: alignment)
    }

    private func avatarView(systemName: String, fillColor: Color) -> some View {
        Image(systemName: systemName)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
            .frame(width: 34, height: 34)
            .background(
                Circle()
                    .fill(fillColor)
            )
    }

    private func scrollToBottom(using proxy: ScrollViewProxy, animated: Bool) {
        guard let lastMessageID = viewModel.messages.last?.id else { return }
        if animated {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(lastMessageID, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(lastMessageID, anchor: .bottom)
        }
    }
}
