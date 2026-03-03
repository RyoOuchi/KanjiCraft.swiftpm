import Foundation

final class CollectionViewModel: ObservableObject {
    struct CollectionTile: Identifiable {
        let entry: KanjiEntry
        let discoveryStatus: KanjiDiscoveryStatus?

        var isSolved: Bool {
            discoveryStatus != nil
        }

        var id: String {
            entry.id
        }
    }

    struct DifficultySection: Identifiable {
        let difficulty: KanjiDifficulty
        let tiles: [CollectionTile]

        var id: String {
            difficulty.rawValue
        }
    }

    @Published private(set) var solvedKanji: [KanjiEntry] = []
    @Published private(set) var solvedStatusesByKanjiID: [String: KanjiDiscoveryStatus] = [:]
    @Published var selectedKanji: KanjiEntry?
    @Published var searchText: String = ""
    @Published private(set) var difficultyProfile: KanjiDifficultyProfile = .standard
    @Published private(set) var usesVisionImpairedGrid = false

    private let dataStore: DataStore
    private let progressStore: ProgressStore

    init(dataStore: DataStore, progressStore: ProgressStore) {
        self.dataStore = dataStore
        self.progressStore = progressStore
        loadSolvedKanji()
    }

    func loadSolvedKanji() {
        solvedStatusesByKanjiID = progressStore.loadSolvedKanjiStatuses()
        let solvedIDs = Set(solvedStatusesByKanjiID.keys)
        solvedKanji = dataStore.kanjiEntries.filter { solvedIDs.contains($0.id) }
            .sorted { $0.meaningEnglish < $1.meaningEnglish }
    }

    func openKanjiDetail(_ entry: KanjiEntry) {
        selectedKanji = entry
    }

    func setUsesVisionImpairedGrid(_ usesVisionImpairedGrid: Bool) {
        self.usesVisionImpairedGrid = usesVisionImpairedGrid

        if usesVisionImpairedGrid,
           let selectedKanji,
           !dataStore.supportsVisionImpairedMode(selectedKanji) {
            self.selectedKanji = nil
        }
    }

    func setDifficultyProfile(_ difficultyProfile: KanjiDifficultyProfile) {
        self.difficultyProfile = difficultyProfile

        if let selectedKanji,
           !dataStore.supportsDifficultyProfile(difficultyProfile, for: selectedKanji) {
            self.selectedKanji = nil
        }
    }

    private var normalizedSearchText: String {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return query
    }

    private var filteredKanjiEntries: [KanjiEntry] {
        let query = normalizedSearchText
        guard !query.isEmpty else { return visibleKanjiEntries }

        return visibleKanjiEntries.filter { entry in
            entry.kanji.localizedCaseInsensitiveContains(query)
                || entry.meaningEnglish.localizedCaseInsensitiveContains(query)
                || entry.explanationEnglish.localizedCaseInsensitiveContains(query)
        }
    }

    private var visibleKanjiEntries: [KanjiEntry] {
        dataStore.kanjiEntries.filter { entry in
            guard dataStore.supportsDifficultyProfile(difficultyProfile, for: entry) else { return false }
            if usesVisionImpairedGrid {
                return dataStore.supportsVisionImpairedMode(entry)
            }
            return true
        }
    }

    var filteredCollectionSections: [DifficultySection] {
        return KanjiDifficulty.allCases.compactMap { difficulty in
            let entries = filteredKanjiEntries
                .filter { $0.difficulty(for: difficultyProfile) == difficulty }
                .sorted { $0.meaningEnglish < $1.meaningEnglish }
            guard !entries.isEmpty else { return nil }

            let tiles = entries.map { entry in
                CollectionTile(entry: entry, discoveryStatus: solvedStatusesByKanjiID[entry.id])
            }
            return DifficultySection(difficulty: difficulty, tiles: tiles)
        }
    }

    func collectionProgressText(for difficulty: KanjiDifficulty) -> String {
        let totalCount = visibleKanjiEntries.filter { $0.difficulty(for: difficultyProfile) == difficulty }.count
        guard totalCount > 0 else { return "0% collected" }

        let visibleIDs = Set(visibleKanjiEntries.map(\.id))
        let solvedCount = solvedKanji.filter {
            $0.difficulty(for: difficultyProfile) == difficulty && visibleIDs.contains($0.id)
        }.count
        let percentCollected = Int((Double(solvedCount) / Double(totalCount) * 100).rounded())
        let remainingCount = max(totalCount - solvedCount, 0)
        return "\(percentCollected)% collected, \(remainingCount) remaining"
    }

    func radicalsUsed(for entry: KanjiEntry) -> [RadicalEntry] {
        entry.layout.slots.compactMap { slot in
            dataStore.radical(for: slot.expectedRadicalID)
        }
    }
}
