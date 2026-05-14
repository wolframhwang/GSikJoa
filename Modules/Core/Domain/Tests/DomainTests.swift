import XCTest
@testable import Domain

final class DomainTests: XCTestCase {
    func test_difficulty_spiceLevel() {
        XCTAssertEqual(Difficulty.l1.spiceLevel, 1)
        XCTAssertEqual(Difficulty.l4.spiceLevel, 4)
    }

    func test_sessionMood_adjusted_easy_lowersDifficulty() {
        XCTAssertEqual(SessionMood.easy.adjusted(base: .l3), .l2)
        XCTAssertEqual(SessionMood.easy.adjusted(base: .l1), .l1)
    }

    func test_sessionMood_adjusted_hard_raisesDifficulty() {
        XCTAssertEqual(SessionMood.hard.adjusted(base: .l1), .l2)
        XCTAssertEqual(SessionMood.hard.adjusted(base: .l3), .l4)
        XCTAssertEqual(SessionMood.hard.adjusted(base: .l4), .l4)
    }

    func test_quizCard_decodes_without_notInvestmentAdvice() throws {
        let json = """
        {
            "id": "x", "type": "ox",
            "question": "?", "choices": ["O","X"],
            "answerIndex": 0, "explanation": ".",
            "conceptTags": ["t"]
        }
        """.data(using: .utf8)!
        let card = try JSONDecoder().decode(QuizCard.self, from: json)
        XCTAssertFalse(card.notInvestmentAdvice)
    }

    func test_quizSessionResult_ratio_and_tags() {
        let cards = [
            QuizCard(id: "a", type: .multipleChoice, question: "q", choices: ["1","2"], answerIndex: 0, explanation: "e", conceptTags: ["A"]),
            QuizCard(id: "b", type: .multipleChoice, question: "q", choices: ["1","2"], answerIndex: 0, explanation: "e", conceptTags: ["B"]),
        ]
        let pack = CardPack(packId: "p", title: "t", blurb: "b", domain: .economy, topicId: "x", difficulty: .l1, estimatedSeconds: 60, cards: cards)
        let result = QuizSessionResult(pack: pack, answers: [
            AnswerRecord(cardId: "a", pickedIndex: 0, isCorrect: true),
            AnswerRecord(cardId: "b", pickedIndex: 1, isCorrect: false),
        ])
        XCTAssertEqual(result.percent, 50)
        XCTAssertEqual(result.gainedConceptTags, ["A"])
        XCTAssertEqual(result.weakConceptTags, ["B"])
    }

    func test_userDifficultyPreference_setAndGet() {
        var pref = UserDifficultyPreference()
        pref.setDifficulty(.l4, for: .physics)
        XCTAssertEqual(pref.difficulty(for: .physics), .l4)
        XCTAssertEqual(pref.difficulty(for: .economy), .l2) // default
    }
}
