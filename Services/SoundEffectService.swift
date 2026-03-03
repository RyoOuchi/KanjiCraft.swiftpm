import Foundation

@MainActor
final class SoundEffectService {
    static let shared = SoundEffectService()

    enum SoundEffect: Hashable {
        case clickLow
        case clickHigh
        case success
        case mistake
        case completed

    }

    init() {}

    func play(_ effect: SoundEffect) {
        _ = effect
    }
}
