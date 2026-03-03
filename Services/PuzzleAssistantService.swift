import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

struct PuzzleAssistantResponse: Sendable {
    let message: String
    let usedAppleIntelligence: Bool
    let statusText: String
}

struct PuzzleAssistantAvailabilityStatus: Sendable {
    let isAvailable: Bool
    let message: String
}

private enum PuzzleAssistantGenerationPath {
    case guided
    case plainText
}

private struct PuzzleAssistantGenerationSuccess {
    let reply: String
    let path: PuzzleAssistantGenerationPath
}

private struct PuzzleAssistantBoardSlot {
    enum Status: String {
        case empty = "EMPTY"
        case correct = "CORRECT"
        case wrong = "WRONG"
    }

    let slotID: String
    let slotRoleDescription: String
    let expectedMeaning: String
    let expectedTokens: Set<String>
    let placedMeaning: String?
    let placedTokens: Set<String>
    let status: Status

    var isFilled: Bool {
        status != .empty
    }

    var isCorrect: Bool {
        status == .correct
    }

    var isWrong: Bool {
        status == .wrong
    }
}

private struct PuzzleAssistantBoardSnapshot {
    let slots: [PuzzleAssistantBoardSlot]

    var filledCount: Int {
        slots.filter(\.isFilled).count
    }

    var correctCount: Int {
        slots.filter(\.isCorrect).count
    }

    var wrongCount: Int {
        slots.filter(\.isWrong).count
    }

    var remainingCount: Int {
        slots.count - correctCount
    }

    var unresolvedSlots: [PuzzleAssistantBoardSlot] {
        slots.filter { !$0.isCorrect }
    }

    var correctlyPlacedSlots: [PuzzleAssistantBoardSlot] {
        slots.filter(\.isCorrect)
    }

    func correctCount(for token: String) -> Int {
        slots.filter { $0.isCorrect && $0.expectedTokens.contains(token) }.count
    }

    func remainingExpectedCount(for token: String) -> Int {
        slots.filter { !$0.isCorrect && $0.expectedTokens.contains(token) }.count
    }

    func placedCount(for token: String) -> Int {
        slots.filter { $0.placedTokens.contains(token) }.count
    }

    func wrongPlacedCount(for token: String) -> Int {
        slots.filter { $0.isWrong && $0.placedTokens.contains(token) }.count
    }
}

actor PuzzleAssistantService {
    func availabilityStatus() -> PuzzleAssistantAvailabilityStatus {
#if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            guard model.isAvailable else {
                return PuzzleAssistantAvailabilityStatus(
                    isAvailable: false,
                    message: "Unavailable: the on-device Apple Intelligence model is not available on this device right now."
                )
            }

            guard model.supportsLocale(Locale(identifier: "en_US")) else {
                return PuzzleAssistantAvailabilityStatus(
                    isAvailable: false,
                    message: "Unavailable: the on-device model does not support English (United States)."
                )
            }

            return PuzzleAssistantAvailabilityStatus(
                isAvailable: true,
                message: "Apple Intelligence is available on this device."
            )
        }

        return PuzzleAssistantAvailabilityStatus(
            isAvailable: false,
            message: "Unavailable: this feature requires iOS 26 or later in the current build."
        )
#else
        return PuzzleAssistantAvailabilityStatus(
            isAvailable: false,
            message: "Unavailable: the FoundationModels framework is not present in this build."
        )
#endif
    }

    func supportsAppleIntelligence() -> Bool {
#if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
#endif
        return false
    }

    func respond(
        to userMessage: String,
        kanjiEntry: KanjiEntry,
        allRadicals: [RadicalEntry],
        allRadicalsByID: [String: RadicalEntry],
        allowedRadicalsByID: [String: RadicalEntry],
        placedTiles: [String: String],
        generatedPrompt: GeneratedKanjiPrompt?,
        conversation: [PuzzleAssistantConversationTurn]
    ) async -> PuzzleAssistantResponse {
        let boardSnapshot = buildBoardSnapshot(
            kanjiEntry: kanjiEntry,
            allRadicalsByID: allRadicalsByID,
            allowedRadicalsByID: allowedRadicalsByID,
            placedTiles: placedTiles
        )
        let explicitlyAskedForRadicals = userExplicitlyAskedForRadicals(in: userMessage)
        let availability = availabilityStatus()

        guard availability.isAvailable else {
            return PuzzleAssistantResponse(
                message: fallbackReply(
                    for: userMessage,
                    kanjiEntry: kanjiEntry,
                    boardSnapshot: boardSnapshot,
                    generatedPrompt: generatedPrompt,
                    explicitlyAskedForRadicals: explicitlyAskedForRadicals
                ),
                usedAppleIntelligence: false,
                statusText: availability.message
            )
        }

        if let generationSuccess = await generateWithAppleIntelligence(
            userMessage: userMessage,
            kanjiEntry: kanjiEntry,
            allRadicalsByID: allRadicalsByID,
            allowedRadicalsByID: allowedRadicalsByID,
            boardSnapshot: boardSnapshot,
            generatedPrompt: generatedPrompt,
            conversation: conversation
        ) {
            let validatedReply = validatedReply(
                generationSuccess.reply,
                userMessage: userMessage,
                kanjiEntry: kanjiEntry,
                allRadicals: allRadicals,
                allowedRadicalsByID: allowedRadicalsByID,
                boardSnapshot: boardSnapshot,
                generatedPrompt: generatedPrompt,
                explicitlyAskedForRadicals: explicitlyAskedForRadicals
            )
            return PuzzleAssistantResponse(
                message: validatedReply,
                usedAppleIntelligence: true,
                statusText: generationSuccess.path == .guided
                    ? "Apple Intelligence"
                    : "Apple Intelligence (plain text fallback)"
            )
        }

        return PuzzleAssistantResponse(
            message: fallbackReply(
                for: userMessage,
                kanjiEntry: kanjiEntry,
                boardSnapshot: boardSnapshot,
                generatedPrompt: generatedPrompt,
                explicitlyAskedForRadicals: explicitlyAskedForRadicals
            ),
            usedAppleIntelligence: false
            ,
            statusText: "Apple Intelligence was detected, but the generation request failed."
        )
    }

    private func fallbackReply(
        for userMessage: String,
        kanjiEntry: KanjiEntry,
        boardSnapshot: PuzzleAssistantBoardSnapshot,
        generatedPrompt: GeneratedKanjiPrompt?,
        explicitlyAskedForRadicals: Bool
    ) -> String {
        let lowercasedMessage = userMessage.lowercased()

        if asksForRemainingHelp(in: lowercasedMessage) {
            return remainingBoardReply(
                kanjiEntry: kanjiEntry,
                boardSnapshot: boardSnapshot,
                explicitlyAskedForRadicals: explicitlyAskedForRadicals
            )
        }

        if asksAboutCurrentBoard(in: lowercasedMessage) {
            return currentBoardReply(
                kanjiEntry: kanjiEntry,
                boardSnapshot: boardSnapshot,
                explicitlyAskedForRadicals: explicitlyAskedForRadicals
            )
        }

        if explicitlyAskedForRadicals {
            let remainingMeanings = boardSnapshot.unresolvedSlots.map(\.expectedMeaning)
            if remainingMeanings.isEmpty {
                return "Apple Intelligence is not available right now. Every required part is already in the correct place."
            }
            return "Apple Intelligence is not available right now. The unresolved parts you still need are tied to these meanings: \(joinedList(remainingMeanings)). Think about how they connect to \(kanjiEntry.meaningEnglish.lowercased())."
        }

        if let generatedPrompt, !generatedPrompt.promptEnglish.isEmpty {
            if boardSnapshot.correctCount > 0 {
                return "Apple Intelligence is not available right now. Start from this hint: \(generatedPrompt.promptEnglish) Some parts are already correct, so focus only on the remaining unsolved areas of the grid."
            }
            return "Apple Intelligence is not available right now. Start from this hint: \(generatedPrompt.promptEnglish)"
        }

        if boardSnapshot.correctCount > 0 {
            return "Apple Intelligence is not available right now. Some parts of the grid are already correct, so focus on the remaining unsolved slots and how they support the meaning \(kanjiEntry.meaningEnglish.lowercased())."
        }

        return "Apple Intelligence is not available right now. Focus on the target meaning \(kanjiEntry.meaningEnglish.lowercased()) and the unresolved parts of the grid. Ask explicitly about radicals if you want component-level help."
    }

    private func currentBoardReply(
        kanjiEntry: KanjiEntry,
        boardSnapshot: PuzzleAssistantBoardSnapshot,
        explicitlyAskedForRadicals: Bool
    ) -> String {
        if boardSnapshot.correctCount == boardSnapshot.slots.count {
            return "Everything currently on the grid is correct. You have matched all of the required parts for \(kanjiEntry.meaningEnglish.lowercased())."
        }

        let incorrectDescriptions = boardSnapshot.slots.compactMap { slot -> String? in
            guard slot.isWrong else { return nil }
            if explicitlyAskedForRadicals, let placedMeaning = slot.placedMeaning {
                return "The \(slot.slotRoleDescription) is currently \(placedMeaning), but it should match \(slot.expectedMeaning)."
            }
            return "The \(slot.slotRoleDescription) is filled, but it is not the right piece yet."
        }

        let emptyDescriptions = boardSnapshot.slots.compactMap { slot -> String? in
            guard slot.status == .empty else { return nil }
            if explicitlyAskedForRadicals {
                return "The \(slot.slotRoleDescription) is still empty and needs \(slot.expectedMeaning)."
            }
            return "The \(slot.slotRoleDescription) is still empty."
        }

        let details = incorrectDescriptions + emptyDescriptions
        let summary = "Right now you have \(boardSnapshot.correctCount) correct, \(boardSnapshot.wrongCount) wrong, and \(boardSnapshot.slots.count - boardSnapshot.filledCount) empty slot\(boardSnapshot.slots.count - boardSnapshot.filledCount == 1 ? "" : "s")."

        if details.isEmpty {
            return summary
        }

        return "\(summary) \(joinedSentences(details))"
    }

    private func remainingBoardReply(
        kanjiEntry: KanjiEntry,
        boardSnapshot: PuzzleAssistantBoardSnapshot,
        explicitlyAskedForRadicals: Bool
    ) -> String {
        let unresolvedSlots = boardSnapshot.unresolvedSlots
        guard !unresolvedSlots.isEmpty else {
            return "There is nothing left to place. Every required part for \(kanjiEntry.meaningEnglish.lowercased()) is already correct."
        }

        let remainingRoles = unresolvedSlots.map(\.slotRoleDescription)
        if explicitlyAskedForRadicals {
            let remainingMeanings = unresolvedSlots.map(\.expectedMeaning)
            return "Ignore the parts that are already correct. The remaining unsolved slots are the \(joinedList(remainingRoles)), and they still need these meanings: \(joinedList(remainingMeanings))."
        }

        return "Ignore the parts that are already correct. Focus on the \(joinedList(remainingRoles)) and the meanings still missing from the grid."
    }

    private func generateWithAppleIntelligence(
        userMessage: String,
        kanjiEntry: KanjiEntry,
        allRadicalsByID: [String: RadicalEntry],
        allowedRadicalsByID: [String: RadicalEntry],
        boardSnapshot: PuzzleAssistantBoardSnapshot,
        generatedPrompt: GeneratedKanjiPrompt?,
        conversation: [PuzzleAssistantConversationTurn]
    ) async -> PuzzleAssistantGenerationSuccess? {
#if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            let model = SystemLanguageModel.default
            guard model.isAvailable else { return nil }
            guard model.supportsLocale(Locale(identifier: "en_US")) else { return nil }

            let session = LanguageModelSession(model: model, instructions: assistantInstructions)
            let prompt = buildPrompt(
                userMessage: userMessage,
                kanjiEntry: kanjiEntry,
                allRadicalsByID: allRadicalsByID,
                allowedRadicalsByID: allowedRadicalsByID,
                boardSnapshot: boardSnapshot,
                generatedPrompt: generatedPrompt,
                conversation: conversation
            )

            for attempt in 1...2 {
                logGenerationAttempt(prompt: prompt, generationKind: "guided", attempt: attempt)
                do {
                    let response = try await session.respond(
                        to: prompt,
                        generating: GuidedPuzzleAssistantReply.self
                    )
                    return PuzzleAssistantGenerationSuccess(
                        reply: response.content.replyEnglish.trimmingCharacters(in: .whitespacesAndNewlines),
                        path: .guided
                    )
                } catch {
                    logGenerationFailure(error, generationKind: "guided", attempt: attempt)
                }
            }

            logGenerationAttempt(prompt: prompt, generationKind: "plain-text", attempt: 1)
            do {
                let response = try await session.respond(to: prompt)
                return PuzzleAssistantGenerationSuccess(
                    reply: response.content.trimmingCharacters(in: .whitespacesAndNewlines),
                    path: .plainText
                )
            } catch {
                logGenerationFailure(error, generationKind: "plain-text", attempt: 1)
                return nil
            }
        }
#endif
        return nil
    }

    private var assistantInstructions: String {
        """
        You are an Apple Intelligence puzzle guide inside an offline kanji learning app.
        Requirements:
        1) Keep all text in English.
        2) Help the player with hints, reasoning, and observations about the puzzle.
        3) Do not reveal the target kanji character unless the user explicitly asks for the full answer.
        4) Prefer subtle guidance over direct solutions.
        5) Keep replies concise and helpful, usually 2 to 5 sentences.
        6) If the player asks about the current board, refer only to the board state provided in the prompt.
        7) Never claim a slot is filled unless the board state explicitly says FILLED.
        8) If the board state says EMPTY, treat that slot as having no placed radical.
        9) Unless the user explicitly asks for a radical, component, or piece, do not reveal the radical directly.
        10) If every slot is EMPTY, do not say the player has already placed anything.
        11) If you mention radicals, only mention radicals that are explicitly listed as allowed for this kanji.
        12) Each board line includes a slot role and a status of EMPTY, CORRECT, or WRONG. Use that exact status when reasoning.
        13) If the user asks what remains or what to place next, focus only on slots marked EMPTY or WRONG.
        14) Do not spend time on a CORRECT slot unless the user explicitly asks for a full board review.
        15) If one radical is already correct, do not suggest placing it again when the user asks about the remaining work.
        """
    }

    private func buildPrompt(
        userMessage: String,
        kanjiEntry: KanjiEntry,
        allRadicalsByID: [String: RadicalEntry],
        allowedRadicalsByID: [String: RadicalEntry],
        boardSnapshot: PuzzleAssistantBoardSnapshot,
        generatedPrompt: GeneratedKanjiPrompt?,
        conversation: [PuzzleAssistantConversationTurn]
    ) -> String {
        let slotLines = boardSnapshot.slots.map { slot in
            let currentPieceDescription: String
            switch slot.status {
            case .empty:
                currentPieceDescription = "no piece"
            case .correct:
                currentPieceDescription = slot.placedMeaning ?? "the correct piece"
            case .wrong:
                currentPieceDescription = slot.placedMeaning ?? "the wrong piece"
            }
            return "- \(slot.slotID) (\(slot.slotRoleDescription)): expects \(slot.expectedMeaning). Status: \(slot.status.rawValue). Current piece: \(currentPieceDescription)."
        }
        .joined(separator: "\n")

        let recentConversation = conversation.suffix(6).map { turn in
            "\(turn.roleLabel): \(turn.text)"
        }
        .joined(separator: "\n")

        let generatedHintText = generatedPrompt?.promptEnglish ?? "No generated hint available."
        let allowedRadicalMeanings = allowedRadicalTokens(from: allowedRadicalsByID)
            .sorted()
            .joined(separator: ", ")
        let correctlyPlacedMeanings = joinedList(boardSnapshot.correctlyPlacedSlots.map(\.expectedMeaning))
        let unresolvedMeanings = joinedList(boardSnapshot.unresolvedSlots.map(\.expectedMeaning))
        let wrongPlacedMeanings = joinedList(boardSnapshot.slots.compactMap { $0.isWrong ? $0.placedMeaning : nil })

        return """
        Current puzzle target meaning: \(kanjiEntry.meaningEnglish)
        Current hint text: \(generatedHintText)
        Filled slot count: \(boardSnapshot.filledCount) of \(boardSnapshot.slots.count)
        Correct slot count: \(boardSnapshot.correctCount)
        Wrong slot count: \(boardSnapshot.wrongCount)
        Allowed radical meanings for this kanji: \(allowedRadicalMeanings)
        Correctly placed meanings right now: \(correctlyPlacedMeanings.isEmpty ? "none" : correctlyPlacedMeanings)
        Meanings still unresolved: \(unresolvedMeanings.isEmpty ? "none" : unresolvedMeanings)
        Meanings currently placed in the wrong slot: \(wrongPlacedMeanings.isEmpty ? "none" : wrongPlacedMeanings)
        Board:
        \(slotLines)

        Recent conversation:
        \(recentConversation.isEmpty ? "No prior conversation." : recentConversation)

        User message:
        \(userMessage)
        """
    }

    private func userExplicitlyAskedForRadicals(in text: String) -> Bool {
        let lowercasedText = text.lowercased()
        return lowercasedText.contains("radical")
            || lowercasedText.contains("component")
            || lowercasedText.contains("piece")
    }

    private func asksAboutCurrentBoard(in text: String) -> Bool {
        let lowercasedText = text.lowercased()
        return lowercasedText.contains("current")
            || lowercasedText.contains("board")
            || lowercasedText.contains("grid")
            || lowercasedText.contains("pieces look")
            || lowercasedText.contains("what did i place")
            || lowercasedText.contains("what have i placed")
            || lowercasedText.contains("what is wrong")
            || lowercasedText.contains("what's wrong")
            || lowercasedText.contains("correct right now")
    }

    private func asksForRemainingHelp(in text: String) -> Bool {
        let lowercasedText = text.lowercased()
        return lowercasedText.contains("remaining")
            || lowercasedText.contains("what next")
            || lowercasedText.contains("what should i place next")
            || lowercasedText.contains("what do i need")
            || lowercasedText.contains("what is left")
            || lowercasedText.contains("what's left")
            || lowercasedText.contains("still need")
            || lowercasedText.contains("left to place")
            || lowercasedText.contains("next")
    }

    private func validatedReply(
        _ reply: String,
        userMessage: String,
        kanjiEntry: KanjiEntry,
        allRadicals: [RadicalEntry],
        allowedRadicalsByID: [String: RadicalEntry],
        boardSnapshot: PuzzleAssistantBoardSnapshot,
        generatedPrompt: GeneratedKanjiPrompt?,
        explicitlyAskedForRadicals: Bool
    ) -> String {
        if replyMentionsForbiddenRadical(reply, allRadicals: allRadicals, allowedRadicalsByID: allowedRadicalsByID) {
            return fallbackReply(
                for: explicitlyAskedForRadicals ? "radical" : userMessage,
                kanjiEntry: kanjiEntry,
                boardSnapshot: boardSnapshot,
                generatedPrompt: explicitlyAskedForRadicals ? nil : generatedPrompt,
                explicitlyAskedForRadicals: explicitlyAskedForRadicals
            )
        }

        if replyContradictsBoardState(reply, boardSnapshot: boardSnapshot, allowedRadicalsByID: allowedRadicalsByID) {
            return fallbackReply(
                for: userMessage,
                kanjiEntry: kanjiEntry,
                boardSnapshot: boardSnapshot,
                generatedPrompt: generatedPrompt,
                explicitlyAskedForRadicals: explicitlyAskedForRadicals
            )
        }

        return reply
    }

    private func replyMentionsForbiddenRadical(
        _ reply: String,
        allRadicals: [RadicalEntry],
        allowedRadicalsByID: [String: RadicalEntry]
    ) -> Bool {
        let allowedTokens = allowedRadicalTokens(from: allowedRadicalsByID)
        let allKnownTokens = Set(
            allRadicals.flatMap { radical in
                [radical.nameEnglish] + radical.meaningEnglish
            }
            .map(normalizedRadicalToken)
            .filter { !$0.isEmpty }
        )

        let forbiddenTokens = allKnownTokens.subtracting(allowedTokens)
        return forbiddenTokens.contains { token in
            containsWholeToken(reply, token: token)
        }
    }

    private func replyContradictsBoardState(
        _ reply: String,
        boardSnapshot: PuzzleAssistantBoardSnapshot,
        allowedRadicalsByID: [String: RadicalEntry]
    ) -> Bool {
        let lowercasedReply = reply.lowercased()

        let globalPlacedClaimPhrases = [
            "already placed",
            "currently placed",
            "on the grid",
            "on the board",
            "you have placed",
            "you've placed"
        ]
        let globalCorrectClaimPhrases = [
            "already correct",
            "correctly placed",
            "in the right place",
            "already in place"
        ]
        let globalRemainingClaimPhrases = [
            "still need",
            "remaining",
            "left to place",
            "what remains"
        ]

        if boardSnapshot.filledCount == 0 && containsAnyPhrase(lowercasedReply, phrases: globalPlacedClaimPhrases) {
            return true
        }

        if boardSnapshot.correctCount == 0 && containsAnyPhrase(lowercasedReply, phrases: globalCorrectClaimPhrases) {
            return true
        }

        if boardSnapshot.remainingCount == 0 && containsAnyPhrase(lowercasedReply, phrases: globalRemainingClaimPhrases) {
            return true
        }

        let allowedTokens = allowedRadicalTokens(from: allowedRadicalsByID)
        let sentences = boardAwareSentences(from: lowercasedReply)

        for sentence in sentences {
            let mentionedTokens = allowedTokens.filter { containsWholeToken(sentence, token: $0) }
            guard !mentionedTokens.isEmpty else { continue }

            for token in mentionedTokens {
                if containsAnyPhrase(sentence, phrases: globalCorrectClaimPhrases)
                    && boardSnapshot.correctCount(for: token) == 0 {
                    return true
                }

                if containsAnyPhrase(sentence, phrases: ["wrong", "incorrect", "not the right"])
                    && boardSnapshot.wrongPlacedCount(for: token) == 0 {
                    return true
                }

                if containsAnyPhrase(sentence, phrases: globalPlacedClaimPhrases)
                    && boardSnapshot.placedCount(for: token) == 0 {
                    return true
                }

                if containsAnyPhrase(sentence, phrases: ["still need", "remaining", "left", "next", "missing"])
                    && boardSnapshot.remainingExpectedCount(for: token) == 0 {
                    return true
                }
            }
        }

        return false
    }

    private func buildBoardSnapshot(
        kanjiEntry: KanjiEntry,
        allRadicalsByID: [String: RadicalEntry],
        allowedRadicalsByID: [String: RadicalEntry],
        placedTiles: [String: String]
    ) -> PuzzleAssistantBoardSnapshot {
        let slots = kanjiEntry.layout.slots.map { slot in
            let expectedRadical = allowedRadicalsByID[slot.expectedRadicalID] ?? allRadicalsByID[slot.expectedRadicalID]
            let placedRadical = placedTiles[slot.id].flatMap { allRadicalsByID[$0] }
            let status: PuzzleAssistantBoardSlot.Status

            if let placedRadical {
                status = placedRadical.id == slot.expectedRadicalID ? .correct : .wrong
            } else {
                status = .empty
            }

            return PuzzleAssistantBoardSlot(
                slotID: slot.id,
                slotRoleDescription: slotRoleDescription(for: slot, expectedRadical: expectedRadical),
                expectedMeaning: expectedRadical?.primaryMeaning ?? "component",
                expectedTokens: tokens(for: expectedRadical),
                placedMeaning: placedRadical?.primaryMeaning,
                placedTokens: tokens(for: placedRadical),
                status: status
            )
        }

        return PuzzleAssistantBoardSnapshot(slots: slots)
    }

    private func slotRoleDescription(for slot: PuzzleSlot, expectedRadical: RadicalEntry?) -> String {
        switch expectedRadical?.displayPosition {
        case .leftSide:
            return "left radical"
        case .topLeft:
            return "top-left radical"
        case .top:
            return "top radical"
        case .rightSide:
            return "right-side radical"
        case .leftBottom:
            return "left-bottom radical"
        case .bottom:
            return "bottom radical"
        case .enclosing:
            return "enclosing radical"
        case .standalone, .all, .none:
            switch slot.shapeType {
            case .leftTall:
                return "left radical"
            case .leftBottom:
                return "left-bottom radical"
            case .topWide:
                return "top radical"
            case .frameUShape:
                return "enclosing radical"
            case .normalRect:
                return slot.normalizedFrame.y <= 0.2 ? "top slot" : "main slot"
            }
        }
    }

    private func tokens(for radical: RadicalEntry?) -> Set<String> {
        guard let radical else { return [] }
        return Set(
            ([radical.nameEnglish] + radical.meaningEnglish)
                .map(normalizedRadicalToken)
                .filter { !$0.isEmpty }
        )
    }

    private func allowedRadicalTokens(from radicalsByID: [String: RadicalEntry]) -> Set<String> {
        Set(
            radicalsByID.values.flatMap { radical in
                [radical.nameEnglish] + radical.meaningEnglish
            }
            .map(normalizedRadicalToken)
            .filter { !$0.isEmpty }
        )
    }

    private func normalizedRadicalToken(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
            .lowercased()
    }

    private func boardAwareSentences(from text: String) -> [String] {
        text
            .components(separatedBy: CharacterSet(charactersIn: ".!?\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func containsAnyPhrase(_ text: String, phrases: [String]) -> Bool {
        phrases.contains { text.contains($0) }
    }

    private func joinedList(_ values: [String]) -> String {
        let cleanedValues = values.filter { !$0.isEmpty }
        guard !cleanedValues.isEmpty else { return "" }
        if cleanedValues.count == 1 {
            return cleanedValues[0]
        }
        if cleanedValues.count == 2 {
            return "\(cleanedValues[0]) and \(cleanedValues[1])"
        }
        return "\(cleanedValues.dropLast().joined(separator: ", ")), and \(cleanedValues.last ?? "")"
    }

    private func joinedSentences(_ sentences: [String]) -> String {
        sentences.joined(separator: " ")
    }

    private func containsWholeToken(_ text: String, token: String) -> Bool {
        let escapedToken = NSRegularExpression.escapedPattern(for: token)
        let pattern = "\\b\(escapedToken)\\b"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return text.lowercased().contains(token.lowercased())
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }

    private func logGenerationAttempt(prompt: String, generationKind: String, attempt: Int) {
#if DEBUG
        print(
            "[PuzzleAssistant] generation=\(generationKind) attempt=\(attempt) promptCharacters=\(prompt.count) promptUTF8Bytes=\(prompt.utf8.count)"
        )
#endif
    }

    private func logGenerationFailure(_ error: Error, generationKind: String, attempt: Int) {
#if DEBUG
        print("[PuzzleAssistant] \(generationKind) generation failed on attempt \(attempt): \(error)")
#endif
    }
}

struct PuzzleAssistantConversationTurn: Sendable {
    let roleLabel: String
    let text: String
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable(description: "A concise chat reply for the puzzle assistant.")
private struct GuidedPuzzleAssistantReply {
    @Guide(description: "A short English reply that helps the player with hints about the current kanji puzzle.")
    var replyEnglish: String
}
#endif
