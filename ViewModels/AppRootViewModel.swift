import Foundation

final class AppRootViewModel: ObservableObject {
    enum AppTab: Hashable {
        case main
        case puzzle
        case radicals
    }

    @Published var selectedTab: AppTab = .main
}
