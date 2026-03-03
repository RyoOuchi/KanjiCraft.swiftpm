import Foundation

final class ProgressStore {
    private enum Keys {
        static let solvedKanjiIDs = "solvedKanjiIDs"
        static let solvedKanjiStatuses = "solvedKanjiStatuses"
    }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func loadSolvedKanjiIDs() -> Set<String> {
        Set(loadSolvedKanjiStatuses().keys)
    }

    func saveSolvedKanjiIDs(_ ids: Set<String>) {
        userDefaults.set(Array(ids).sorted(), forKey: Keys.solvedKanjiIDs)
    }

    func loadSolvedKanjiStatuses() -> [String: KanjiDiscoveryStatus] {
        let storedStatuses = userDefaults.dictionary(forKey: Keys.solvedKanjiStatuses) as? [String: String] ?? [:]
        var statuses = storedStatuses.reduce(into: [String: KanjiDiscoveryStatus]()) { result, pair in
            if let status = KanjiDiscoveryStatus(rawValue: pair.value) {
                result[pair.key] = status
            }
        }

        let legacySolvedIDs = userDefaults.stringArray(forKey: Keys.solvedKanjiIDs) ?? []
        for kanjiID in legacySolvedIDs where statuses[kanjiID] == nil {
            statuses[kanjiID] = .clean
        }

        return statuses
    }

    func saveSolvedKanjiStatuses(_ statuses: [String: KanjiDiscoveryStatus]) {
        let rawStatuses = statuses.mapValues(\.rawValue)
        userDefaults.set(rawStatuses, forKey: Keys.solvedKanjiStatuses)
        saveSolvedKanjiIDs(Set(statuses.keys))
    }

    func markSolved(kanjiID: String, usedHint: Bool) {
        var statuses = loadSolvedKanjiStatuses()
        guard statuses[kanjiID] == nil else {
            saveSolvedKanjiStatuses(statuses)
            return
        }

        statuses[kanjiID] = usedHint ? .hinted : .clean
        saveSolvedKanjiStatuses(statuses)
    }
}
