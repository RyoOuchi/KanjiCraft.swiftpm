import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

actor KanjiPromptGenerator {
    func supportsAppleIntelligenceGeneration() -> Bool {
#if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
#endif
        return false
    }

    func generatePromptUsingAppleIntelligence(
        for kanjiEntry: KanjiEntry,
        radicalsByID: [String: RadicalEntry]
    ) async -> GeneratedKanjiPrompt? {
        await generateWithAppleIntelligence(
            for: kanjiEntry,
            radicalsByID: radicalsByID
        )
    }

    func generateLocalFallbackPrompt(
        for kanjiEntry: KanjiEntry,
        radicalsByID: [String: RadicalEntry]
    ) -> GeneratedKanjiPrompt {
        generateFallbackPrompt(for: kanjiEntry, radicalsByID: radicalsByID)
    }

    func generatePrompt(
        for kanjiEntry: KanjiEntry,
        radicalsByID: [String: RadicalEntry]
    ) async -> GeneratedKanjiPrompt {
        if let generatedByModel = await generatePromptUsingAppleIntelligence(
            for: kanjiEntry,
            radicalsByID: radicalsByID
        ) {
            return generatedByModel
        }

        return generateLocalFallbackPrompt(for: kanjiEntry, radicalsByID: radicalsByID)
    }

    private func generateFallbackPrompt(
        for kanjiEntry: KanjiEntry,
        radicalsByID: [String: RadicalEntry]
    ) -> GeneratedKanjiPrompt {
        let radicalExplanations = makeFallbackRadicalExplanations(
            for: kanjiEntry,
            radicalsByID: radicalsByID
        )
        let promptEnglish = composePromptEnglish(
            kanjiEntry: kanjiEntry,
            radicalExplanations: radicalExplanations
        )
        return GeneratedKanjiPrompt(
            promptEnglish: promptEnglish,
            radicalExplanations: radicalExplanations
        )
    }

    private func makeFallbackRadicalExplanations(
        for kanjiEntry: KanjiEntry,
        radicalsByID: [String: RadicalEntry]
    ) -> [RadicalPromptExplanation] {
        let slots = kanjiEntry.layout.slots
        let componentUsageCounts = slots.reduce(into: [String: Int]()) { partialResult, slot in
            partialResult[slot.expectedRadicalID, default: 0] += 1
        }

        var seenComponentCounts: [String: Int] = [:]
        var explanations: [RadicalPromptExplanation] = []
        explanations.reserveCapacity(slots.count)

        for slot in slots {
            let radicalID = slot.expectedRadicalID
            let radical = radicalsByID[radicalID]
            seenComponentCounts[radicalID, default: 0] += 1
            let instanceIndex = seenComponentCounts[radicalID] ?? 1
            let componentTotal = componentUsageCounts[radicalID] ?? 1

            let radicalName = radical?.nameEnglish ?? radicalID
            let radicalSymbol = radical?.symbol ?? "?"
            let fallbackMeaning = radical?.primaryMeaning ?? "component"
            let explanationEnglish = fallbackClueFragment(
                radicalID: radicalID,
                fallbackMeaning: fallbackMeaning,
                instanceIndex: instanceIndex,
                componentTotal: componentTotal
            )

            explanations.append(
                RadicalPromptExplanation(
                    slotID: slot.id,
                    radicalID: radicalID,
                    radicalSymbol: radicalSymbol,
                    radicalNameEnglish: radicalName,
                    radicalMeaningEnglish: fallbackMeaning,
                    explanationEnglish: explanationEnglish
                )
            )
        }

        return explanations
    }

    private func composePromptEnglish(
        kanjiEntry: KanjiEntry,
        radicalExplanations: [RadicalPromptExplanation]
    ) -> String {
        composePromptEnglish(
            summaryEnglish: "",
            kanjiEntry: kanjiEntry,
            radicalExplanations: radicalExplanations
        )
    }

    private func fallbackClueFragment(
        radicalID: String,
        fallbackMeaning: String,
        instanceIndex: Int,
        componentTotal: Int
    ) -> String {
        switch radicalID {
        case "person-left":
            return "a person leans"
        case "tree":
            if componentTotal > 1 {
                return instanceIndex == 1 ? "one tree stands" : "another tree stands nearby"
            }
            return "against a tree to rest"
        case "speech":
            return "speech flows"
        case "grass-crown":
            return "grass spreads above"
        case "cover-u", "roof-cover":
            return "a cover hangs overhead"
        case "roof":
            return "a roof hangs overhead"
        case "sun":
            return "the sun shines at the center"
        case "moon":
            return "the moon glows nearby"
        case "fire":
            return componentTotal > 1 && instanceIndex > 1 ? "another fire flares" : "a fire burns"
        case "gate":
            return "a gate surrounds the scene"
        case "ear":
            return "an ear listens closely"
        case "mouth":
            return componentTotal > 1 && instanceIndex > 1 ? "another mouth opens nearby" : "a mouth opens"
        case "little-bits":
            return "small bits gather above"
        case "child":
            return "a child learns below"
        case "step-left":
            return "step moves forward"
        case "walk-left-bottom":
            return "a path curves forward"
        case "mountain":
            return "a mountain stands firm"
        case "stone":
            return "a stone rests below"
        case "white":
            return "white light stays clear"
        case "water":
            return "water flows below"
        case "water-left":
            return "water flows along the side"
        case "person":
            return "a person stands within the scene"
        case "stand":
            return "someone comes to stand upright"
        case "master":
            return "a master holds the center"
        case "past":
            return "the past lingers in the scene"
        case "say-cloud":
            return "someone begins to say more"
        case "move":
            return "something starts to move"
        case "heavy":
            return "something heavy weighs down the scene"
        case "power":
            return "power pushes from the side"
        case "field":
            return "a field opens below"
        case "comfort":
            return "comfort brings relief"
        case "world":
            return "the world spreads outward"
        case "grain-left":
            return "grain leans along the side"
        case "wine-jar":
            return "a wine jar holds liquid"
        case "woman":
            return "a woman rests below"
        case "each":
            return "each arrival comes beneath shelter"
        case "lose":
            return "something can lose its way"
        case "tongue":
            return "a tongue shapes speech"
        case "stop":
            return "a stop marks the upper step"
        case "little":
            return "little traces remain below"
        case "wind":
            return "wind moves through the scene"
        case "bird":
            return "a bird moves ahead"
        case "army":
            return "an army moves as one load"
        case "bird-full":
            return "a bird cries out"
        case "gold":
            return componentTotal > 1 && instanceIndex > 1 ? "more gold gathers nearby" : "gold gleams brightly"
        case "car":
            return componentTotal > 1 && instanceIndex > 1 ? "another car rumbles nearby" : "a car rumbles forward"
        case "big":
            return "something big anchors the middle"
        case "king":
            return "king holds the center"
        case "strike":
            return "strike adds force"
        case "heart":
            return "the heart carries feeling"
        case "one":
            return "a single line anchors the image"
        default:
            if componentTotal > 1, instanceIndex > 1 {
                return "another sign of \(fallbackMeaning) appears"
            }
            return "the idea of \(fallbackMeaning) appears"
        }
    }

}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable(description: "Structured prompt output for a kanji puzzle.")
private struct GuidedKanjiPromptPayload {
    @Guide(description: "One coherent English hint sentence. No kanji characters, no radical symbols, and no step-by-step instructions.")
    var summaryEnglish: String

    @Guide(
        description: "One explanation entry per slot. Include every slot ID provided by the prompt.",
        .minimumCount(1)
    )
    var radicalExplanations: [GuidedRadicalExplanation]
}

@available(iOS 26.0, *)
@Generable(description: "Explanation of one radical placement in one slot.")
private struct GuidedRadicalExplanation {
    @Guide(description: "slotID must match one of the slot IDs from the prompt.")
    var slotID: String

    @Guide(description: "Short English clue fragment for this radical. Use English meaning only; no symbols or Japanese text.")
    var explanationEnglish: String
}
#endif

private extension KanjiPromptGenerator {
    func generateWithAppleIntelligence(
        for kanjiEntry: KanjiEntry,
        radicalsByID: [String: RadicalEntry]
    ) async -> GeneratedKanjiPrompt? {
#if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return await generateWithFoundationModels(
                for: kanjiEntry,
                radicalsByID: radicalsByID
            )
        }
#endif
        return nil
    }

#if canImport(FoundationModels)
    @available(iOS 26.0, *)
    func generateWithFoundationModels(
        for kanjiEntry: KanjiEntry,
        radicalsByID: [String: RadicalEntry]
    ) async -> GeneratedKanjiPrompt? {
        let model = SystemLanguageModel.default
        guard model.isAvailable else {
            promptGenerationDebug("Apple Intelligence unavailable: \(availabilityDescription(model.availability))")
            return nil
        }
        guard model.supportsLocale(Locale(identifier: "en_US")) else {
            promptGenerationDebug("Apple Intelligence does not support en_US locale on this device.")
            return nil
        }

        let instructions = """
        You are generating clue-style hints for a kanji-learning app.
        Requirements:
        1) Keep all text in English.
        2) Do not output the target kanji character.
        3) Do not output any radical symbols or Japanese text.
        4) Do not use step-by-step language like "first", "then", "place", or "put".
        5) Generate in full, grammatically accurate English sentences.
        6) summaryEnglish must be a single clue sentence.
        7) Try to tie the meaning of each radical to the meaning of the target kanji.
        8) Generate mnemonic-style hints using the radicals of the target kanji.
        9) Use natural clue patterns like "a person resting on a tree" or "a mountainous rock" when they fit.
        10) The hint should feel intuitive and memorable, not mechanical.
        11) Prefer one coherent mnemonic sentence that actually makes sense in English.
        12) If a fully natural mnemonic sentence is not possible, fall back to a clear clue sentence instead of forcing awkward wording.
        13) summaryEnglish must include each slot's exact meaning token from the prompt at least once.
        14) radicalExplanations must include every slotID provided by the prompt.
        15) Each explanationEnglish must be a short clue fragment describing that radical's meaning.
        16) Each explanationEnglish must contain that slot's exact meaning token from the prompt (for example: step, mountain, king, strike, heart).
        """

        let session = LanguageModelSession(model: model, instructions: instructions)
        let prompt = buildModelPrompt(
            for: kanjiEntry,
            radicalsByID: radicalsByID
        )

        do {
            let response = try await session.respond(
                to: prompt,
                generating: GuidedKanjiPromptPayload.self
            )
            let payload = response.content

            let mappedExplanations = mapPayloadExplanations(
                payload: payload,
                kanjiEntry: kanjiEntry,
                radicalsByID: radicalsByID
            )
            guard mappedExplanations.count == kanjiEntry.layout.slots.count else {
                return nil
            }

            let promptEnglish = composePromptEnglish(
                summaryEnglish: payload.summaryEnglish,
                kanjiEntry: kanjiEntry,
                radicalExplanations: mappedExplanations
            )
            return GeneratedKanjiPrompt(
                promptEnglish: promptEnglish,
                radicalExplanations: mappedExplanations
            )
        } catch {
            promptGenerationDebug("Apple Intelligence generation failed: \(String(describing: error))")
            return nil
        }
    }
#endif

    func composePromptEnglish(
        summaryEnglish: String,
        kanjiEntry: KanjiEntry,
        radicalExplanations: [RadicalPromptExplanation]
    ) -> String {
        let cleanedSummary = sanitizeClueFragment(
            summaryEnglish,
            kanjiEntry: kanjiEntry,
            radicalSymbol: "",
            radicalNameEnglish: ""
        )

        let sanitizedFragments = radicalExplanations.map { explanation in
            let sanitizedMeaning = sanitizeMeaningToken(explanation.radicalMeaningEnglish)
            let sanitizedFragment = sanitizeClueFragment(
                explanation.explanationEnglish,
                kanjiEntry: kanjiEntry,
                radicalSymbol: explanation.radicalSymbol,
                radicalNameEnglish: explanation.radicalNameEnglish
            )
            return enforceMeaningToken(
                in: sanitizedFragment,
                meaningToken: sanitizedMeaning
            )
        }
        .filter { !$0.isEmpty }

        let clueCore: String
        if isUsableSummarySentence(cleanedSummary, radicalExplanations: radicalExplanations) {
            clueCore = cleanedSummary
        } else if !sanitizedFragments.isEmpty {
            clueCore = joinClueFragments(sanitizedFragments)
        } else {
            clueCore = cleanedSummary.isEmpty ? "meanings weave together into a hidden idea" : cleanedSummary
        }

        return finalizeClueSentence(clueCore)
    }

    func buildModelPrompt(
        for kanjiEntry: KanjiEntry,
        radicalsByID: [String: RadicalEntry]
    ) -> String {
        let slotLines = kanjiEntry.layout.slots.map { slot in
            let radical = radicalsByID[slot.expectedRadicalID]
            let meaning = radical?.primaryMeaning ?? "component"
            return "- slotID: \(slot.id), radicalID: \(slot.expectedRadicalID), meaning: \(meaning)"
        }
        .joined(separator: "\n")

        return """
        Generate one clue hint for this puzzle.
        Target meaning: \(kanjiEntry.meaningEnglish)
        Write the clue as a natural mnemonic sentence in full grammatical English.
        Try to connect the radical meanings to the target meaning in a memorable way.
        Example style: "a person resting on a tree" or "a mountainous rock."
        If a natural mnemonic sentence does not work well, return a clear clue sentence instead of awkward English.
        The final clue sentence must include every slot meaning token at least once.
        Return one explanation for each slotID below. Do not output kanji characters, symbols, or Japanese text.
        Slots:
        \(slotLines)
        """
    }

    func isUsableSummarySentence(
        _ text: String,
        radicalExplanations: [RadicalPromptExplanation]
    ) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        let wordCount = trimmed.split(whereSeparator: \.isWhitespace).count
        guard wordCount >= 4 else { return false }

        let requiredMeaningTokens = Set(
            radicalExplanations
                .map { sanitizeMeaningToken($0.radicalMeaningEnglish) }
                .filter { !$0.isEmpty }
        )

        return requiredMeaningTokens.allSatisfy { token in
            containsWholeMeaningToken(trimmed, token: token)
        }
    }

#if canImport(FoundationModels)
    func mapPayloadExplanations(
        payload: GuidedKanjiPromptPayload,
        kanjiEntry: KanjiEntry,
        radicalsByID: [String: RadicalEntry]
    ) -> [RadicalPromptExplanation] {
        let slots = kanjiEntry.layout.slots
        let componentUsageCounts = slots.reduce(into: [String: Int]()) { partialResult, slot in
            partialResult[slot.expectedRadicalID, default: 0] += 1
        }
        var payloadBySlotID: [String: String] = [:]
        for item in payload.radicalExplanations {
            payloadBySlotID[item.slotID] = item.explanationEnglish.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        var seenComponentCounts: [String: Int] = [:]
        var explanations: [RadicalPromptExplanation] = []
        explanations.reserveCapacity(slots.count)

        for slot in slots {
            let radicalID = slot.expectedRadicalID
            let radical = radicalsByID[radicalID]
            seenComponentCounts[radicalID, default: 0] += 1
            let instanceIndex = seenComponentCounts[radicalID] ?? 1
            let componentTotal = componentUsageCounts[radicalID] ?? 1
            let radicalName = radical?.nameEnglish ?? radicalID
            let radicalSymbol = radical?.symbol ?? "?"
            let fallbackMeaning = radical?.primaryMeaning ?? "component"
            let explanationEnglish = payloadBySlotID[slot.id]
                ?? fallbackClueFragment(
                    radicalID: radicalID,
                    fallbackMeaning: fallbackMeaning,
                    instanceIndex: instanceIndex,
                    componentTotal: componentTotal
                )

            explanations.append(
                RadicalPromptExplanation(
                    slotID: slot.id,
                    radicalID: radicalID,
                    radicalSymbol: radicalSymbol,
                    radicalNameEnglish: radicalName,
                    radicalMeaningEnglish: fallbackMeaning,
                    explanationEnglish: explanationEnglish
                )
            )
        }

        return explanations
    }
#endif

    func sanitizeClueFragment(
        _ text: String,
        kanjiEntry: KanjiEntry,
        radicalSymbol: String,
        radicalNameEnglish: String
    ) -> String {
        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !result.isEmpty else { return "" }

        let forbiddenTokens = [kanjiEntry.kanji, radicalSymbol, radicalNameEnglish]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { $0 == kanjiEntry.kanji || $0 == radicalSymbol }
        for token in forbiddenTokens {
            result = result.replacingOccurrences(
                of: token,
                with: "",
                options: [.caseInsensitive, .diacriticInsensitive]
            )
        }
        result = removeCJKAndKanaCharacters(from: result)

        let bannedPhrases = ["first", "second", "third", "then", "next", "finally", "place", "put", "slot"]
        for phrase in bannedPhrases {
            result = result.replacingOccurrences(
                of: phrase,
                with: "",
                options: [.caseInsensitive, .diacriticInsensitive]
            )
        }

        result = result.replacingOccurrences(of: "  ", with: " ")
        result = result.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        return result
    }

    func sanitizeMeaningToken(_ text: String) -> String {
        removeCJKAndKanaCharacters(from: text)
            .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
            .lowercased()
    }

    func enforceMeaningToken(in fragment: String, meaningToken: String) -> String {
        let cleanedMeaningToken = sanitizeMeaningToken(meaningToken)
        guard !cleanedMeaningToken.isEmpty else {
            return fragment
        }

        if containsWholeMeaningToken(fragment, token: cleanedMeaningToken) {
            return fragment
        }

        if fragment.isEmpty {
            return cleanedMeaningToken
        }

        return "\(cleanedMeaningToken) \(fragment)"
    }

    func containsWholeMeaningToken(_ text: String, token: String) -> Bool {
        let escapedToken = NSRegularExpression.escapedPattern(for: token)
        let pattern = "\\b\(escapedToken)\\b"
        guard let regex = try? NSRegularExpression(
            pattern: pattern,
            options: [.caseInsensitive]
        ) else {
            return text.lowercased().contains(token.lowercased())
        }

        let fullRange = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.firstMatch(in: text, options: [], range: fullRange) != nil
    }

    func removeCJKAndKanaCharacters(from text: String) -> String {
        let filteredScalars = text.unicodeScalars.filter { scalar in
            let value = scalar.value
            switch value {
            case 0x3040...0x30FF, // Hiragana + Katakana
                 0x3400...0x4DBF, // CJK Extension A
                 0x4E00...0x9FFF, // CJK Unified Ideographs
                 0x2E80...0x2EFF, // CJK Radicals Supplement
                 0x2F00...0x2FDF, // Kangxi Radicals
                 0x31C0...0x31EF, // CJK Strokes
                 0xF900...0xFAFF: // CJK Compatibility Ideographs
                return false
            default:
                return true
            }
        }
        return String(String.UnicodeScalarView(filteredScalars))
    }

    func joinClueFragments(_ fragments: [String]) -> String {
        switch fragments.count {
        case 0:
            return ""
        case 1:
            return fragments[0]
        case 2:
            let second = fragments[1].lowercased()
            let prepositionStarts = ["against ", "under ", "within ", "inside ", "beneath ", "above ", "around "]
            if prepositionStarts.contains(where: { second.hasPrefix($0) }) {
                return "\(fragments[0]) \(fragments[1])"
            }
            return "\(fragments[0]) and \(fragments[1])"
        default:
            let head = fragments.dropLast().joined(separator: ", ")
            return "\(head), and \(fragments.last ?? "")"
        }
    }

    func finalizeClueSentence(_ clueCore: String) -> String {
        let cleaned = clueCore.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            return "Meanings weave together into a hidden idea."
        }
        if cleaned.hasSuffix(".") || cleaned.hasSuffix("!") || cleaned.hasSuffix("?") {
            return cleaned.prefix(1).uppercased() + cleaned.dropFirst()
        }
        return cleaned.prefix(1).uppercased() + cleaned.dropFirst() + "."
    }

#if canImport(FoundationModels)
    @available(iOS 26.0, *)
    func availabilityDescription(_ availability: SystemLanguageModel.Availability) -> String {
        switch availability {
        case .available:
            return "available"
        case .unavailable(let reason):
            return "unavailable(\(reason))"
        }
    }
#endif

    func promptGenerationDebug(_ message: String) {
#if DEBUG
        print("[PromptGen] \(message)")
#endif
    }
}
