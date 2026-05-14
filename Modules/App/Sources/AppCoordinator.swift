import SwiftUI
import Combine
import Domain
import Data
import DesignSystem

@MainActor
final class AppCoordinator: ObservableObject {
    enum Stage: Equatable {
        case launching
        case onboarding
        case main
    }

    enum Tab: String, CaseIterable, Hashable {
        case home, packs, vault, me

        var label: String {
            switch self {
            case .home: return "홈"
            case .packs: return "카드팩"
            case .vault: return "보관함"
            case .me: return "나"
            }
        }
        var glyph: String {
            switch self {
            case .home: return "⌂"
            case .packs: return "▤"
            case .vault: return "✦"
            case .me: return "◉"
            }
        }
    }

    // Dependencies
    private let cardPackRepository: CardPackRepository
    private let preferencesStore: UserPreferencesStore
    private let progressStore: UserProgressStore
    private let activeSessionStore: ActiveSessionStore

    // State
    @Published var stage: Stage = .launching
    @Published var tab: Tab = .home
    @Published var packs: [CardPack] = []
    @Published var preference: UserDifficultyPreference = .init()
    @Published var sessionMood: SessionMood = .normal
    @Published var progress: UserProgress = .init()
    @Published var paletteId: String = "ocean"

    @Published var activePack: CardPack? = nil
    @Published var sessionResult: QuizSessionResult? = nil
    @Published var resumeSession: ActiveQuizSession? = nil

    var activePalette: AppPalette { AppPalette.byId(paletteId) }

    init(
        cardPackRepository: CardPackRepository,
        preferencesStore: UserPreferencesStore,
        progressStore: UserProgressStore,
        activeSessionStore: ActiveSessionStore
    ) {
        self.cardPackRepository = cardPackRepository
        self.preferencesStore = preferencesStore
        self.progressStore = progressStore
        self.activeSessionStore = activeSessionStore
    }

    func bootstrap() async {
        preference = preferencesStore.loadDifficultyPreference()
        sessionMood = preferencesStore.loadSessionMood()
        progress = progressStore.loadProgress()
        do {
            packs = try await cardPackRepository.loadAllPacks()
        } catch {
            packs = []
        }
        // Restore in-flight session only if fresh and pack still exists.
        if let saved = activeSessionStore.loadActiveSession(),
           saved.isFresh(),
           !saved.isComplete,
           packs.contains(where: { $0.packId == saved.packId }) {
            resumeSession = saved
        } else {
            activeSessionStore.clearActiveSession()
            resumeSession = nil
        }
        stage = preferencesStore.hasCompletedOnboarding() ? .main : .onboarding
    }

    // MARK: - Onboarding

    func completeOnboarding(domains: [LearningDomain], preference: UserDifficultyPreference) {
        preferencesStore.saveSelectedDomains(domains)
        preferencesStore.saveDifficultyPreference(preference)
        preferencesStore.setHasCompletedOnboarding(true)
        self.preference = preference
        stage = .main
    }

    // MARK: - Quiz flow

    func startPack(_ pack: CardPack) {
        activePack = pack
        sessionResult = nil
        // Starting a new pack from scratch — clear any unrelated saved progress.
        if let resume = resumeSession, resume.packId != pack.packId {
            activeSessionStore.clearActiveSession()
            resumeSession = nil
        }
    }

    /// Resume an in-flight session.
    func resumeActiveSession() {
        guard let saved = resumeSession,
              let pack = packs.first(where: { $0.packId == saved.packId }) else { return }
        activePack = pack
        sessionResult = nil
    }

    /// Currently-active session for the pack being played, if any. Used to seed QuizViewModel.
    func resumeStateFor(pack: CardPack) -> ActiveQuizSession? {
        guard let resume = resumeSession, resume.packId == pack.packId else { return nil }
        return resume
    }

    func completeSession(_ result: QuizSessionResult) {
        progressStore.record(session: result)
        progress = progressStore.loadProgress()
        sessionResult = result
        // Completed → drop any in-flight save for this pack.
        activeSessionStore.clearActiveSession()
        resumeSession = nil
    }

    /// User exited the quiz mid-session. Persist progress so we can offer 이어풀기 later.
    func saveActiveSnapshot(_ snapshot: ActiveQuizSession) {
        if snapshot.currentIndex > 0 || !snapshot.answers.isEmpty {
            activeSessionStore.saveActiveSession(snapshot)
            resumeSession = snapshot
        }
        activePack = nil
        sessionResult = nil
    }

    func dismissResult() {
        activePack = nil
        sessionResult = nil
    }

    func playAgain() {
        sessionResult = nil
    }

    // MARK: - Home suggestions

    /// Score formula:
    /// - 100 base
    /// - −10 per spice-level distance from mood-adjusted target
    /// - +30 if pack contains any of the user's weak concept tags (변형 복습 bias)
    var recommendedPacks: [CardPack] {
        let mood = sessionMood
        let pref = preference
        let weakSet = Set(progress.weakTags.keys)
        let scored = packs.map { pack -> (CardPack, Int) in
            let target = mood.adjusted(base: pref.difficulty(for: pack.domain))
            let diffDelta = abs(pack.difficulty.spiceLevel - target.spiceLevel)
            var score = 100 - diffDelta * 10
            if packContainsAny(pack: pack, tags: weakSet) {
                score += 30
            }
            return (pack, score)
        }
        return scored
            .sorted { $0.1 > $1.1 }
            .map(\.0)
    }

    /// True if a pack should be flagged as "약점 복습" — it has cards with tags the user has missed.
    func isReviewPick(_ pack: CardPack) -> Bool {
        let weakSet = Set(progress.weakTags.keys)
        return packContainsAny(pack: pack, tags: weakSet)
    }

    private func packContainsAny(pack: CardPack, tags: Set<String>) -> Bool {
        guard !tags.isEmpty else { return false }
        for card in pack.cards {
            for tag in card.conceptTags where tags.contains(tag) {
                return true
            }
        }
        return false
    }

    // MARK: - Difficulty preference (settings)

    func setPreference(_ pref: UserDifficultyPreference) {
        preference = pref
        preferencesStore.saveDifficultyPreference(pref)
    }

    func setSessionMood(_ mood: SessionMood) {
        sessionMood = mood
        preferencesStore.saveSessionMood(mood)
    }

    func setPaletteId(_ id: String) {
        paletteId = id
    }

    // MARK: - Concept vault

    var conceptItems: [(tag: String, domain: LearningDomain, count: Int, lastSeenLabel: String)] {
        progress.conceptCounts
            .sorted { $0.value > $1.value }
            .map { (tag, count) in
                let domain = guessDomain(for: tag)
                let lastDate = progress.lastSeenAt[tag]
                let label = lastDate.map { d -> String in
                    let cal = Calendar.current
                    if cal.isDateInToday(d) { return "오늘" }
                    if cal.isDateInYesterday(d) { return "어제" }
                    let days = cal.dateComponents([.day], from: d, to: Date()).day ?? 0
                    if days < 7 { return "\(days)일 전" }
                    return "오래 전"
                } ?? "—"
                return (tag, domain, count, label)
            }
    }

    private func guessDomain(for tag: String) -> LearningDomain {
        for pack in packs {
            for card in pack.cards where card.conceptTags.contains(tag) {
                return pack.domain
            }
        }
        return .economy
    }

    // MARK: - Streak grid for Settings

    var thisWeekFilled: [Bool] {
        // Mon..Sun. Mark today and prior streak days as filled (best-effort proxy).
        var arr = Array(repeating: false, count: 7)
        let cal = Calendar.current
        let today = cal.component(.weekday, from: Date()) // 1=Sun..7=Sat
        let mondayIndex = ((today - 2) + 7) % 7  // 0=Mon..6=Sun
        // Mark today and back as many days as the streak.
        let mark = min(progress.streakDays, 7)
        for offset in 0..<mark {
            let idx = mondayIndex - offset
            if idx >= 0 { arr[idx] = true }
        }
        return arr
    }

    // MARK: - Mascot message

    var homeMascotMessage: String {
        if let weakest = progress.weakTags.max(by: { $0.value < $1.value })?.key {
            return "\"\(weakest)\" 다시 만나러 가볼래요?"
        }
        if progress.streakDays >= 3 {
            return "\(progress.streakDays)일째예요! 오늘도 가볍게."
        }
        return "오늘도 한 입씩 씹어볼까요?"
    }

    var weakConceptCount: Int { progress.weakTags.count }

    /// Pack matching the saved resume session, if any.
    var resumePack: CardPack? {
        guard let resume = resumeSession else { return nil }
        return packs.first(where: { $0.packId == resume.packId })
    }
}
