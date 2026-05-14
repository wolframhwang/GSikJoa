import Foundation
import Domain

// MARK: - Preferences

public final class UserDefaultsPreferencesStore: UserPreferencesStore, @unchecked Sendable {
    private enum Key {
        static let difficultyPreference = "gsikjoa.difficultyPreference"
        static let sessionMood = "gsikjoa.sessionMood"
        static let onboardingCompleted = "gsikjoa.onboardingCompleted"
        static let selectedDomains = "gsikjoa.selectedDomains"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func loadDifficultyPreference() -> UserDifficultyPreference {
        guard
            let data = defaults.data(forKey: Key.difficultyPreference),
            let value = try? JSONDecoder().decode(UserDifficultyPreference.self, from: data)
        else {
            return UserDifficultyPreference()
        }
        return value
    }

    public func saveDifficultyPreference(_ pref: UserDifficultyPreference) {
        if let data = try? JSONEncoder().encode(pref) {
            defaults.set(data, forKey: Key.difficultyPreference)
        }
    }

    public func loadSessionMood() -> SessionMood {
        guard let raw = defaults.string(forKey: Key.sessionMood),
              let mood = SessionMood(rawValue: raw) else {
            return .normal
        }
        return mood
    }

    public func saveSessionMood(_ mood: SessionMood) {
        defaults.set(mood.rawValue, forKey: Key.sessionMood)
    }

    public func hasCompletedOnboarding() -> Bool {
        defaults.bool(forKey: Key.onboardingCompleted)
    }

    public func setHasCompletedOnboarding(_ value: Bool) {
        defaults.set(value, forKey: Key.onboardingCompleted)
    }

    public func selectedDomains() -> [LearningDomain] {
        guard let raw = defaults.array(forKey: Key.selectedDomains) as? [String] else {
            return LearningDomain.allCases
        }
        return raw.compactMap(LearningDomain.init(rawValue:))
    }

    public func saveSelectedDomains(_ domains: [LearningDomain]) {
        defaults.set(domains.map(\.rawValue), forKey: Key.selectedDomains)
    }
}

// MARK: - Active session

public final class UserDefaultsActiveSessionStore: ActiveSessionStore, @unchecked Sendable {
    private enum Key { static let active = "gsikjoa.activeSession" }
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func loadActiveSession() -> ActiveQuizSession? {
        guard
            let data = defaults.data(forKey: Key.active),
            let value = try? JSONDecoder().decode(ActiveQuizSession.self, from: data)
        else { return nil }
        return value
    }

    public func saveActiveSession(_ session: ActiveQuizSession) {
        if let data = try? JSONEncoder().encode(session) {
            defaults.set(data, forKey: Key.active)
        }
    }

    public func clearActiveSession() {
        defaults.removeObject(forKey: Key.active)
    }
}

// MARK: - Progress

public final class UserDefaultsProgressStore: UserProgressStore, @unchecked Sendable {
    private enum Key {
        static let progress = "gsikjoa.userProgress"
    }

    private let defaults: UserDefaults
    private let calendar: Calendar

    public init(defaults: UserDefaults = .standard, calendar: Calendar = .current) {
        self.defaults = defaults
        self.calendar = calendar
    }

    public func loadProgress() -> UserProgress {
        guard
            let data = defaults.data(forKey: Key.progress),
            let value = try? JSONDecoder().decode(UserProgress.self, from: data)
        else {
            return UserProgress()
        }
        return value
    }

    public func saveProgress(_ progress: UserProgress) {
        if let data = try? JSONEncoder().encode(progress) {
            defaults.set(data, forKey: Key.progress)
        }
    }

    public func record(session result: QuizSessionResult) {
        var progress = loadProgress()
        let now = Date()

        // Streak: bump if last session was yesterday, keep if same day, reset if older.
        if let last = progress.lastSessionDate {
            if calendar.isDateInToday(last) {
                // already counted today
            } else if calendar.isDateInYesterday(last) {
                progress.streakDays += 1
            } else {
                progress.streakDays = 1
            }
        } else {
            progress.streakDays = 1
        }
        progress.lastSessionDate = now

        // Concept counts (only correct).
        for (idx, card) in result.pack.cards.enumerated() where idx < result.answers.count {
            let answer = result.answers[idx]
            for tag in card.conceptTags {
                progress.lastSeenAt[tag] = now
                if answer.isCorrect {
                    progress.conceptCounts[tag, default: 0] += 1
                } else {
                    progress.weakTags[tag, default: 0] += 1
                }
            }
        }
        progress.totalConceptsLearned = progress.conceptCounts.count
        saveProgress(progress)
    }
}
