/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The representation of a single question on a quiz.
*/

import Foundation

/// A single question.
class Question {
    
    /// The text of the question.
    let text: String
    
    /// All the possible answers.
    let answers: [String]
    
    /// The index of the right answer.
    let correctAnswerIndex: Int
    
    /// The user's reseponse.
    var responseIndex: Int?
    
    /// How many times the user needed a hint.
    var hints = 0
    
    /// Initialize the question.
    init(text: String, answers: [String], correctAnswerIndex: Int) {
        self.text = text
        self.answers = answers
        self.correctAnswerIndex = correctAnswerIndex
    }
    
    /// Resets the question to the unanswered state.
    func reset() {
        responseIndex = nil
        hints = 0
    }
    
    /// Indicates whether the user's reseponse is correct.
    var isCorrect: Bool {
        return correctAnswerIndex == responseIndex
    }
    
    /// The answer that the user chose.
    var response: String? {
        guard let index = responseIndex else { return nil }
        return answers[index]
    }
}
