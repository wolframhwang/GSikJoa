import Foundation
import Domain

@MainActor
@Observable
public final class QuizViewModel {
    public let pack: CardPack
    public private(set) var currentIndex: Int
    public private(set) var pickedIndex: Int? = nil
    public private(set) var revealed: Bool = false
    public private(set) var answers: [AnswerRecord]
    public private(set) var shakeTrigger: Int = 0

    public init(pack: CardPack, resumeFrom: ActiveQuizSession? = nil) {
        self.pack = pack
        if let resume = resumeFrom, resume.packId == pack.packId, resume.currentIndex < pack.cards.count {
            self.currentIndex = resume.currentIndex
            self.answers = resume.answers
        } else {
            self.currentIndex = 0
            self.answers = []
        }
    }

    public var currentCard: QuizCard { pack.cards[currentIndex] }
    public var totalCards: Int { pack.cards.count }
    public var isLastCard: Bool { currentIndex + 1 >= totalCards }
    public var isCorrect: Bool { revealed && pickedIndex == currentCard.answerIndex }
    public var isWrong: Bool { revealed && pickedIndex != nil && pickedIndex != currentCard.answerIndex }

    public func pick(_ index: Int) {
        guard !revealed else { return }
        pickedIndex = index
    }

    public func submit() {
        guard let picked = pickedIndex, !revealed else { return }
        let card = currentCard
        let correct = picked == card.answerIndex
        revealed = true
        answers.append(AnswerRecord(cardId: card.id, pickedIndex: picked, isCorrect: correct))
        if !correct {
            shakeTrigger += 1
        }
    }

    public func advance() -> QuizSessionResult? {
        if isLastCard {
            return QuizSessionResult(pack: pack, answers: answers)
        }
        currentIndex += 1
        pickedIndex = nil
        revealed = false
        return nil
    }

    public var progressValue: Double {
        Double(currentIndex) + (revealed ? 1 : 0)
    }

    /// Snapshot for persistence — call when user exits mid-session.
    public func snapshot() -> ActiveQuizSession {
        ActiveQuizSession(
            packId: pack.packId,
            currentIndex: currentIndex,
            totalCards: totalCards,
            answers: answers
        )
    }
}
