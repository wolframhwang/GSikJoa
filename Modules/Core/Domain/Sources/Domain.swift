// Domain — pure models for G식좋아.
// No UIKit, no SwiftUI, no Foundation-Networking. Foundation only.

import Foundation

// MARK: - Domain (knowledge area)

public enum LearningDomain: String, Codable, CaseIterable, Sendable, Hashable {
    case economy
    case physics
    case statistics

    public var displayKoreanName: String {
        switch self {
        case .economy: return "경제"
        case .physics: return "물리"
        case .statistics: return "통계"
        }
    }

    public var glyph: String {
        switch self {
        case .economy: return "₩"
        case .physics: return "◐"
        case .statistics: return "∿"
        }
    }
}

// MARK: - Difficulty

public enum Difficulty: String, Codable, CaseIterable, Sendable, Hashable {
    case l1 = "L1"
    case l2 = "L2"
    case l3 = "L3"
    case l4 = "L4"

    public var koreanName: String {
        switch self {
        case .l1: return "가벼운맛"
        case .l2: return "기본맛"
        case .l3: return "매운맛"
        case .l4: return "지옥맛"
        }
    }

    public var spiceLevel: Int {
        switch self {
        case .l1: return 1
        case .l2: return 2
        case .l3: return 3
        case .l4: return 4
        }
    }
}

// MARK: - Question types

public enum QuestionType: String, Codable, Sendable, Hashable {
    case multipleChoice
    case ox
    case fillBlank
    case pickWrongExplanation
    case causeFinding
}

// MARK: - QuizCard

public struct QuizCard: Identifiable, Codable, Equatable, Sendable, Hashable {
    public let id: String
    public let type: QuestionType
    public let question: String
    public let choices: [String]
    public let answerIndex: Int
    public let explanation: String
    public let conceptTags: [String]
    public let notInvestmentAdvice: Bool

    public init(
        id: String,
        type: QuestionType,
        question: String,
        choices: [String],
        answerIndex: Int,
        explanation: String,
        conceptTags: [String],
        notInvestmentAdvice: Bool = false
    ) {
        self.id = id
        self.type = type
        self.question = question
        self.choices = choices
        self.answerIndex = answerIndex
        self.explanation = explanation
        self.conceptTags = conceptTags
        self.notInvestmentAdvice = notInvestmentAdvice
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.type = try container.decode(QuestionType.self, forKey: .type)
        self.question = try container.decode(String.self, forKey: .question)
        self.choices = try container.decode([String].self, forKey: .choices)
        self.answerIndex = try container.decode(Int.self, forKey: .answerIndex)
        self.explanation = try container.decode(String.self, forKey: .explanation)
        self.conceptTags = try container.decodeIfPresent([String].self, forKey: .conceptTags) ?? []
        self.notInvestmentAdvice = try container.decodeIfPresent(Bool.self, forKey: .notInvestmentAdvice) ?? false
    }
}

// MARK: - CardPack

public struct CardPack: Identifiable, Codable, Equatable, Sendable, Hashable {
    public let packId: String
    public let title: String
    public let blurb: String
    public let domain: LearningDomain
    public let topicId: String
    public let difficulty: Difficulty
    public let estimatedSeconds: Int
    public let publishState: String
    public let cards: [QuizCard]

    public var id: String { packId }

    public init(
        packId: String,
        title: String,
        blurb: String,
        domain: LearningDomain,
        topicId: String,
        difficulty: Difficulty,
        estimatedSeconds: Int,
        publishState: String = "published",
        cards: [QuizCard]
    ) {
        self.packId = packId
        self.title = title
        self.blurb = blurb
        self.domain = domain
        self.topicId = topicId
        self.difficulty = difficulty
        self.estimatedSeconds = estimatedSeconds
        self.publishState = publishState
        self.cards = cards
    }
}

// MARK: - Pack file (top-level container for card_packs.json)

public struct CardPackBundle: Codable, Sendable {
    public let packs: [CardPack]
    public init(packs: [CardPack]) { self.packs = packs }
}

// MARK: - Difficulty preference per domain

public struct UserDifficultyPreference: Codable, Equatable, Sendable, Hashable {
    public var economy: Difficulty
    public var physics: Difficulty
    public var statistics: Difficulty

    public init(economy: Difficulty = .l2, physics: Difficulty = .l1, statistics: Difficulty = .l1) {
        self.economy = economy
        self.physics = physics
        self.statistics = statistics
    }

    public func difficulty(for domain: LearningDomain) -> Difficulty {
        switch domain {
        case .economy: return economy
        case .physics: return physics
        case .statistics: return statistics
        }
    }

    public mutating func setDifficulty(_ difficulty: Difficulty, for domain: LearningDomain) {
        switch domain {
        case .economy: economy = difficulty
        case .physics: physics = difficulty
        case .statistics: statistics = difficulty
        }
    }
}

// MARK: - Session difficulty (today's mood)

public enum SessionMood: String, Codable, CaseIterable, Sendable, Hashable {
    case easy   // 가벼운
    case normal // 평소대로
    case hard   // 빡세게

    public var koreanLabel: String {
        switch self {
        case .easy: return "오늘은 쉽게"
        case .normal: return "평소대로"
        case .hard: return "빡세게"
        }
    }

    public var spiceLevel: Int {
        switch self {
        case .easy: return 1
        case .normal: return 2
        case .hard: return 3
        }
    }

    public func adjusted(base: Difficulty) -> Difficulty {
        switch self {
        case .easy:   return [.l1, .l1, .l2, .l3][base.spiceLevel - 1]
        case .normal: return base
        case .hard:   return [.l2, .l3, .l4, .l4][base.spiceLevel - 1]
        }
    }
}

// MARK: - Answer / session record

public struct AnswerRecord: Codable, Equatable, Sendable, Hashable {
    public let cardId: String
    public let pickedIndex: Int
    public let isCorrect: Bool
    public let timestamp: Date

    public init(cardId: String, pickedIndex: Int, isCorrect: Bool, timestamp: Date = Date()) {
        self.cardId = cardId
        self.pickedIndex = pickedIndex
        self.isCorrect = isCorrect
        self.timestamp = timestamp
    }
}

public struct QuizSessionResult: Equatable, Sendable, Hashable {
    public let pack: CardPack
    public let answers: [AnswerRecord]

    public init(pack: CardPack, answers: [AnswerRecord]) {
        self.pack = pack
        self.answers = answers
    }

    public var correctCount: Int { answers.filter(\.isCorrect).count }
    public var total: Int { answers.count }
    public var ratio: Double { total == 0 ? 0 : Double(correctCount) / Double(total) }
    public var percent: Int { Int((ratio * 100).rounded()) }

    public var gainedConceptTags: [String] {
        var set = Set<String>()
        for (idx, card) in pack.cards.enumerated() where idx < answers.count && answers[idx].isCorrect {
            for tag in card.conceptTags { set.insert(tag) }
        }
        return Array(set).sorted()
    }

    public var weakConceptTags: [String] {
        var set = Set<String>()
        for (idx, card) in pack.cards.enumerated() where idx < answers.count && !answers[idx].isCorrect {
            for tag in card.conceptTags { set.insert(tag) }
        }
        return Array(set).sorted()
    }
}

// MARK: - User progress (long-lived)

public struct UserProgress: Codable, Equatable, Sendable {
    public var streakDays: Int
    public var lastSessionDate: Date?
    public var totalConceptsLearned: Int
    public var conceptCounts: [String: Int]   // tag -> times encountered correctly
    public var weakTags: [String: Int]        // tag -> wrong-count
    public var lastSeenAt: [String: Date]     // tag -> when

    public init(
        streakDays: Int = 0,
        lastSessionDate: Date? = nil,
        totalConceptsLearned: Int = 0,
        conceptCounts: [String: Int] = [:],
        weakTags: [String: Int] = [:],
        lastSeenAt: [String: Date] = [:]
    ) {
        self.streakDays = streakDays
        self.lastSessionDate = lastSessionDate
        self.totalConceptsLearned = totalConceptsLearned
        self.conceptCounts = conceptCounts
        self.weakTags = weakTags
        self.lastSeenAt = lastSeenAt
    }
}

// MARK: - Active in-flight quiz session (for 이어풀기)

public struct ActiveQuizSession: Codable, Equatable, Sendable {
    public let packId: String
    public let currentIndex: Int
    public let totalCards: Int
    public let answers: [AnswerRecord]
    public let updatedAt: Date

    public init(packId: String, currentIndex: Int, totalCards: Int, answers: [AnswerRecord], updatedAt: Date = Date()) {
        self.packId = packId
        self.currentIndex = currentIndex
        self.totalCards = totalCards
        self.answers = answers
        self.updatedAt = updatedAt
    }

    public var isComplete: Bool { currentIndex >= totalCards }

    /// Stale if older than 24 hours. Avoids surfacing very old sessions.
    public func isFresh(now: Date = Date(), maxAge: TimeInterval = 86400) -> Bool {
        now.timeIntervalSince(updatedAt) <= maxAge
    }
}

public protocol ActiveSessionStore: Sendable {
    func loadActiveSession() -> ActiveQuizSession?
    func saveActiveSession(_ session: ActiveQuizSession)
    func clearActiveSession()
}

// MARK: - Repository protocols

public protocol CardPackRepository: Sendable {
    func loadAllPacks() async throws -> [CardPack]
    func packs(for domain: LearningDomain?) async throws -> [CardPack]
    func pack(byId id: String) async throws -> CardPack?
}

public protocol UserPreferencesStore: Sendable {
    func loadDifficultyPreference() -> UserDifficultyPreference
    func saveDifficultyPreference(_ pref: UserDifficultyPreference)

    func loadSessionMood() -> SessionMood
    func saveSessionMood(_ mood: SessionMood)

    func hasCompletedOnboarding() -> Bool
    func setHasCompletedOnboarding(_ value: Bool)

    func selectedDomains() -> [LearningDomain]
    func saveSelectedDomains(_ domains: [LearningDomain])
}

public protocol UserProgressStore: Sendable {
    func loadProgress() -> UserProgress
    func saveProgress(_ progress: UserProgress)
    func record(session: QuizSessionResult)
}

// MARK: - Errors

public enum DomainError: Error, Sendable, Equatable {
    case packNotFound(id: String)
    case bundleResourceMissing(name: String)
    case decodingFailed(reason: String)
}
