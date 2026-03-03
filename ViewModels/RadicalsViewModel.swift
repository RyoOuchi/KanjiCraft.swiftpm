import Foundation

final class RadicalsViewModel: ObservableObject {
    struct RadicalSection: Identifiable {
        let position: RadicalDisplayPosition
        let radicals: [RadicalEntry]

        var id: RadicalDisplayPosition { position }
    }

    @Published var searchText: String = ""
    @Published private(set) var usesVisionImpairedGrid = false

    private let dataStore: DataStore

    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }

    var filteredRadicals: [RadicalEntry] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let visibleRadicals = baseVisibleRadicals

        if query.isEmpty {
            return visibleRadicals
        }
        return visibleRadicals.filter { radical in
            radical.searchableText.contains(query)
        }
    }

    var filteredRadicalSections: [RadicalSection] {
        let grouped = Dictionary(grouping: filteredRadicals, by: \.displayPosition)

        return RadicalDisplayPosition.allCases
            .filter { $0 != .all }
            .compactMap { position in
                guard let radicals = grouped[position], !radicals.isEmpty else { return nil }
                return RadicalSection(
                    position: position,
                    radicals: radicals.sorted { $0.symbol < $1.symbol }
                )
            }
    }

    func setUsesVisionImpairedGrid(_ usesVisionImpairedGrid: Bool) {
        self.usesVisionImpairedGrid = usesVisionImpairedGrid
    }

    private var baseVisibleRadicals: [RadicalEntry] {
        if usesVisionImpairedGrid {
            return dataStore.radicals.filter { radical in
                dataStore.supportsVisionImpairedMode(radical)
            }
        }
        return dataStore.radicals
    }
}
