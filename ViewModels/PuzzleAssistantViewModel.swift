import Foundation

@MainActor
final class PuzzleAssistantViewModel: ObservableObject {
    struct Message: Identifiable, Equatable {
        enum Role {
            case user
            case assistant
        }

        let id = UUID()
        let role: Role
        let text: String
    }

    @Published var messages: [Message]
    @Published var draftMessage = ""
    @Published private(set) var isSending = false
    @Published private(set) var statusText: String?
    @Published private(set) var availabilityText: String?
    @Published private(set) var isAppleIntelligenceAvailable = false

    private let kanjiEntry: KanjiEntry
    private let allRadicals: [RadicalEntry]
    private let allRadicalsByID: [String: RadicalEntry]
    private let allowedRadicalsByID: [String: RadicalEntry]
    private let puzzleAssistantService: PuzzleAssistantService

    init(
        kanjiEntry: KanjiEntry,
        allRadicals: [RadicalEntry],
        allRadicalsByID: [String: RadicalEntry],
        allowedRadicalsByID: [String: RadicalEntry],
        puzzleAssistantService: PuzzleAssistantService = PuzzleAssistantService()
    ) {
        self.kanjiEntry = kanjiEntry
        self.allRadicals = allRadicals
        self.allRadicalsByID = allRadicalsByID
        self.allowedRadicalsByID = allowedRadicalsByID
        self.puzzleAssistantService = puzzleAssistantService
        self.messages = [
            Message(
                role: .assistant,
                text: "Ask for a hint about this puzzle and I’ll guide you without giving away too much."
            )
        ]
    }

    var canSend: Bool {
        !draftMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    func loadAvailabilityStatusIfNeeded() {
        guard availabilityText == nil else { return }

        Task { @MainActor [weak self] in
            guard let self else { return }
            let availabilityStatus = await self.puzzleAssistantService.availabilityStatus()
            self.isAppleIntelligenceAvailable = availabilityStatus.isAvailable
            self.availabilityText = availabilityStatus.message
        }
    }

    func sendCurrentDraft(
        placedTiles: [String: String],
        generatedPrompt: GeneratedKanjiPrompt?
    ) {
        let message = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        draftMessage = ""
        send(
            message,
            placedTiles: placedTiles,
            generatedPrompt: generatedPrompt
        )
    }

    func sendSuggestedPrompt(
        _ prompt: String,
        placedTiles: [String: String],
        generatedPrompt: GeneratedKanjiPrompt?
    ) {
        send(
            prompt,
            placedTiles: placedTiles,
            generatedPrompt: generatedPrompt
        )
    }

    private func send(
        _ userText: String,
        placedTiles: [String: String],
        generatedPrompt: GeneratedKanjiPrompt?
    ) {
        let userMessage = Message(role: .user, text: userText)
        messages.append(userMessage)
        isSending = true
        statusText = "Thinking…"

        let conversation = messages.map {
            PuzzleAssistantConversationTurn(
                roleLabel: $0.role == .user ? "User" : "Assistant",
                text: $0.text
            )
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            let response = await self.puzzleAssistantService.respond(
                to: userText,
                kanjiEntry: self.kanjiEntry,
                allRadicals: self.allRadicals,
                allRadicalsByID: self.allRadicalsByID,
                allowedRadicalsByID: self.allowedRadicalsByID,
                placedTiles: placedTiles,
                generatedPrompt: generatedPrompt,
                conversation: conversation
            )

            self.messages.append(Message(role: .assistant, text: response.message))
            self.statusText = response.statusText
            self.isSending = false
        }
    }
}
