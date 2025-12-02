/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model object that represents a quiz.
*/

import Foundation

/// A quiz componsed of a list of questions.
class Quiz {
    /// The scene corresponding to the quiz.
    var scene: Scene
    
    /// The title of the quiz.
    var title: String
    
    /// A list of questions in the quiz.
    var questions: [Question]
    var questionIndex: Int = 0
    
    /// Initializes a quiz with a title, a list of questions, and the corresponding scene.
    init(title: String, questions: [Question], scene: Scene) {
        self.title = title
        self.questions = questions
        self.scene = scene
    }
    
    /// Resets the quiz.
    func reset() {
        questions.forEach { $0.reset() }
        questionIndex = 0
    }
    
    /// The total number of correct responses.
    var correctCount: Int {
        return questions.filter({ $0.isCorrect }).count
    }
    
    /// The score as a floating point value in the range [0..1].
    var score: Double {
        return Double(correctCount) / Double(questions.count)
    }
    
    /// The total number of hints used during this quiz.
    var hints: Int {
        return questions.map({ $0.hints }).reduce(0, +)
    }
    
    /// Tells the quiz that it is beginning.
    /// - Tag: startQuiz
    func start() {
        startActivity(asNew: true)
    }

    /// Records the answer to the current question and advances to the next.
    func setAnswer(index: Int) {
        currentQuestion.responseIndex = index
        questionIndex += 1

        // Record progress through the quiz.
        update(progress: Double(questionIndex) / Double(questions.count))
    }

    /// Tells the quiz to report results.
    /// - Tag: recordQuiz
    func record() {
        // The score is the primary metric for a quiz.
        addScore(score, title: "Score", primary: true)
        addQuantity(Double(hints), title: "Hints")
        markAsDone()
        stopActivity()
    }

    /// Returns the current question.
    var currentQuestion: Question {
        return questions[questionIndex]
    }
    
    /// Indicates that all the questions have been answered.
    var isOver: Bool {
        return questionIndex > questions.count - 1
    }
}
