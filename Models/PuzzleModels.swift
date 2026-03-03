import Foundation
import CoreGraphics

enum KanjiDifficulty: String, CaseIterable, Hashable, Sendable {
    case easy
    case medium
    case hard

    var title: String {
        switch self {
        case .easy:
            return "Easy"
        case .medium:
            return "Medium"
        case .hard:
            return "Hard"
        }
    }

    var description: String {
        switch self {
        case .easy:
            return "Only easy kanji will appear."
        case .medium:
            return "Only medium level kanji will appear"
        case .hard:
            return "The most difficult kanji will appear."
        }
    }
}

enum KanjiDifficultyProfile: String, Hashable, Sendable {
    case standard
    case easyMode
}

enum PuzzleMode: String, CaseIterable, Hashable, Sendable {
    case discovery
    case revision

    var title: String {
        switch self {
        case .discovery:
            return "Discovery"
        case .revision:
            return "Revision"
        }
    }

    var description: String {
        switch self {
        case .discovery:
            return "Discover new kanji by creating them with radicals"
        case .revision:
            return "Revise your knowledge of the kanji you already built with radicals"
        }
    }
}

enum KanjiDiscoveryStatus: String, Hashable, Sendable {
    case clean
    case hinted
}

enum RadicalDisplayPosition: String, CaseIterable, Hashable, Identifiable, Sendable {
    case all
    case leftSide
    case topLeft
    case top
    case rightSide
    case leftBottom
    case bottom
    case enclosing
    case standalone

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .all:
            return "All"
        case .leftSide:
            return "Left Side"
        case .topLeft:
            return "Top-Left"
        case .top:
            return "Top"
        case .rightSide:
            return "Right Side"
        case .leftBottom:
            return "Left-Bottom"
        case .bottom:
            return "Bottom"
        case .enclosing:
            return "Enclosing"
        case .standalone:
            return "Standalone"
        }
    }
}

struct KanjiEntry: Identifiable, Hashable, Sendable {
    let id: String
    let kanji: String
    let meaningEnglish: String
    let promptEnglish: String
    let requiredComponents: [String]
    let layout: PuzzleLayout
    let explanationEnglish: String
    let slotGlyphScaleOverrides: [String: Double]
    let slotGlyphStretchXOverrides: [String: Double]
    let slotGlyphStretchYOverrides: [String: Double]
    let explicitDifficulty: KanjiDifficulty?
    let difficultyOverrides: [KanjiDifficultyProfile: KanjiDifficulty]
    let isAvailableInEasyMode: Bool

    var difficulty: KanjiDifficulty {
        difficulty(for: .standard)
    }

    func difficulty(for profile: KanjiDifficultyProfile) -> KanjiDifficulty {
        difficultyOverrides[profile] ?? explicitDifficulty ?? inferredDifficulty
    }

    private var inferredDifficulty: KanjiDifficulty {
        switch requiredComponents.count {
        case 0...2:
            return .easy
        case 3:
            return .medium
        default:
            return .hard
        }
    }

    init(
        id: String,
        kanji: String,
        meaningEnglish: String,
        promptEnglish: String,
        requiredComponents: [String],
        layout: PuzzleLayout,
        explanationEnglish: String,
        slotGlyphScaleOverrides: [String: Double],
        slotGlyphStretchXOverrides: [String: Double] = [:],
        slotGlyphStretchYOverrides: [String: Double] = [:],
        explicitDifficulty: KanjiDifficulty? = nil,
        difficultyOverrides: [KanjiDifficultyProfile: KanjiDifficulty] = [:],
        isAvailableInEasyMode: Bool = true
    ) {
        self.id = id
        self.kanji = kanji
        self.meaningEnglish = meaningEnglish
        self.promptEnglish = promptEnglish
        self.requiredComponents = requiredComponents
        self.layout = layout
        self.explanationEnglish = explanationEnglish
        self.slotGlyphScaleOverrides = slotGlyphScaleOverrides
        self.slotGlyphStretchXOverrides = slotGlyphStretchXOverrides
        self.slotGlyphStretchYOverrides = slotGlyphStretchYOverrides
        self.explicitDifficulty = explicitDifficulty
        self.difficultyOverrides = difficultyOverrides
        self.isAvailableInEasyMode = isAvailableInEasyMode
    }
}

struct RadicalEntry: Identifiable, Hashable, Sendable {
    let id: String
    let symbol: String
    let nameEnglish: String
    let meaningEnglish: [String]
    let searchTags: [String]
    let displayPosition: RadicalDisplayPosition

    var searchableText: String {
        ([symbol, nameEnglish, displayPosition.title] + meaningEnglish + searchTags)
            .joined(separator: " ")
            .lowercased()
    }

    var primaryMeaning: String {
        meaningEnglish.first ?? ""
    }

    init(
        id: String,
        symbol: String,
        nameEnglish: String,
        meaningEnglish: [String],
        searchTags: [String],
        displayPosition: RadicalDisplayPosition = .standalone
    ) {
        self.id = id
        self.symbol = symbol
        self.nameEnglish = nameEnglish
        self.meaningEnglish = meaningEnglish
        self.searchTags = searchTags
        self.displayPosition = displayPosition
    }
}

struct PuzzleLayout: Hashable, Sendable {
    let slots: [PuzzleSlot]
}

struct NormalizedRect: Hashable, Sendable {
    let x: Double
    let y: Double
    let w: Double
    let h: Double
}

struct PuzzleSlot: Identifiable, Hashable, Sendable {
    let slotID: String
    let expectedRadicalID: String
    let shapeType: SlotShapeType
    let normalizedFrame: NormalizedRect
    let frameUThicknessRatio: Double?
    let frameUSideThicknessRatio: Double?
    let frameUTopThicknessRatio: Double?

    var id: String {
        slotID
    }

    init(
        slotID: String,
        expectedRadicalID: String,
        shapeType: SlotShapeType,
        normalizedFrame: NormalizedRect,
        frameUThicknessRatio: Double? = nil,
        frameUSideThicknessRatio: Double? = nil,
        frameUTopThicknessRatio: Double? = nil
    ) {
        self.slotID = slotID
        self.expectedRadicalID = expectedRadicalID
        self.shapeType = shapeType
        self.normalizedFrame = normalizedFrame
        self.frameUThicknessRatio = frameUThicknessRatio
        self.frameUSideThicknessRatio = frameUSideThicknessRatio
        self.frameUTopThicknessRatio = frameUTopThicknessRatio
    }
}

enum SlotShapeType: String, Hashable, Sendable {
    case normalRect
    case leftTall
    case leftBottom
    case topWide
    case frameUShape
}

struct PlacedTile: Hashable, Sendable {
    let slotID: String
    let radicalID: String
}

enum DragSource: Equatable, Sendable {
    case sidebar
    case slot(slotID: String)
}

struct DragState: Equatable, Sendable {
    var isDragging: Bool
    let radicalID: String
    let source: DragSource
    let startPosition: CGPoint
    var currentPosition: CGPoint
    var hoveredSlotID: String?
}

struct RadicalPromptExplanation: Hashable, Codable, Identifiable, Sendable {
    let slotID: String
    let radicalID: String
    let radicalSymbol: String
    let radicalNameEnglish: String
    let radicalMeaningEnglish: String
    let explanationEnglish: String

    var id: String {
        slotID
    }
}

struct GeneratedKanjiPrompt: Hashable, Sendable {
    let promptEnglish: String
    let radicalExplanations: [RadicalPromptExplanation]
}
