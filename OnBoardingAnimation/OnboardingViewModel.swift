import Foundation
import UIKit

@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Step: Int, CaseIterable, Identifiable {
        case orientation
        case accessibility
        case basics
        case tutorial

        var id: Int { rawValue }
    }

    enum AccessibilitySupportOption: String, CaseIterable, Identifiable {
        case visualImpairment
        case cognitiveImpairment

        var id: String { rawValue }

        var title: String {
            switch self {
            case .visualImpairment:
                return "Visually Impaired"
            case .cognitiveImpairment:
                return "Easy Mode"
            }
        }

        var symbolName: String {
            switch self {
            case .visualImpairment:
                return "eye"
            case .cognitiveImpairment:
                return "brain.head.profile"
            }
        }

        var subtitle: String {
            switch self {
            case .visualImpairment:
                return "Prioritizes stronger visual guidance, clearer labels, and works in tandem with VoiceOver to provide a better experience."
            case .cognitiveImpairment:
                return "Provides simpler interactions and more intuitive options, making the app easier to follow."
            }
        }
    }

    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let onboardingAccessibilitySupportOptions = "onboardingAccessibilitySupportOptions"
    }

    @Published var currentStep: Step = .orientation
    @Published var selectedAccessibilitySupportOptions: Set<AccessibilitySupportOption>
    @Published private(set) var hasCompletedOnboarding: Bool
    @Published private(set) var isReplayingOnboarding = false

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.hasCompletedOnboarding = userDefaults.bool(forKey: Keys.hasCompletedOnboarding)

        if let storedAccessibilityRawValues = userDefaults.stringArray(forKey: Keys.onboardingAccessibilitySupportOptions) {
            self.selectedAccessibilitySupportOptions = Set(
                storedAccessibilityRawValues.compactMap(AccessibilitySupportOption.init(rawValue:))
            )
        } else if UIAccessibility.isVoiceOverRunning {
            self.selectedAccessibilitySupportOptions = [.visualImpairment]
        } else {
            self.selectedAccessibilitySupportOptions = []
        }
    }

    var shouldShowOnboarding: Bool {
        !hasCompletedOnboarding || isReplayingOnboarding
    }

    var isOnFirstStep: Bool {
        currentStep == .orientation
    }

    var isOnLastStep: Bool {
        currentStep == .tutorial
    }

    var currentStepIndex: Int {
        currentStep.rawValue
    }

    var totalStepCount: Int {
        Step.allCases.count
    }

    var continueButtonTitle: String {
        isOnLastStep ? "Enter App" : "Continue"
    }

    var prefersReducedMotion: Bool {
        selectedAccessibilitySupportOptions.contains(.cognitiveImpairment)
    }

    var currentDifficultyProfile: KanjiDifficultyProfile {
        selectedAccessibilitySupportOptions.contains(.cognitiveImpairment) ? .easyMode : .standard
    }

    var usesVisionImpairedGrid: Bool {
        selectedAccessibilitySupportOptions.contains(.visualImpairment)
    }

    var shouldRecommendVoiceOverBeforeContinuing: Bool {
        currentStep == .accessibility
        && selectedAccessibilitySupportOptions.contains(.visualImpairment)
        && !UIAccessibility.isVoiceOverRunning
    }

    func isAccessibilitySupportOptionSelected(_ option: AccessibilitySupportOption) -> Bool {
        selectedAccessibilitySupportOptions.contains(option)
    }

    func toggleAccessibilitySupportOption(_ option: AccessibilitySupportOption) {
        if selectedAccessibilitySupportOptions.contains(option) {
            selectedAccessibilitySupportOptions.remove(option)
        } else {
            selectedAccessibilitySupportOptions.insert(option)
        }

        userDefaults.set(
            selectedAccessibilitySupportOptions.map(\.rawValue).sorted(),
            forKey: Keys.onboardingAccessibilitySupportOptions
        )
    }

    func goBack() {
        guard let previousStep = Step(rawValue: currentStep.rawValue - 1) else { return }
        currentStep = previousStep
    }

    func continueForward() {
        if isOnLastStep {
            finishOnboarding()
            return
        }

        guard let nextStep = Step(rawValue: currentStep.rawValue + 1) else { return }
        currentStep = nextStep
    }

    func finishOnboarding() {
        isReplayingOnboarding = false
        hasCompletedOnboarding = true
        userDefaults.set(true, forKey: Keys.hasCompletedOnboarding)
    }

    func reopenOnboarding() {
        currentStep = .orientation
        isReplayingOnboarding = true
    }
}
