import SwiftUI
import UIKit

enum AppFont {
    static func kanji(size: CGFloat) -> Font {
        .system(size: size, weight: .regular)
    }

    static func uiKanjiFont(size: CGFloat) -> UIFont {
        return .systemFont(ofSize: size, weight: .regular)
    }
}
