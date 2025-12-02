/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller showing a single quiz question or the quiz results.
*/

import UIKit

class QuizViewController: UITableViewController {
    
    /// The quiz we are presenting.
    var quiz: Quiz? {
        didSet {
            guard let quiz = quiz else { return }

            if quiz.isOver {
                navigationItem.title = "\(quiz.title) Results"
                navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(tapDone(_:)))
                tableView.allowsSelection = false
                
                // When showing the results, also record them to ClassKit.
                quiz.record()

            } else {
                navigationItem.title = "\(quiz.title) Question \(quiz.questionIndex + 1)"
                navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Hint", style: .plain, target: self, action: #selector(tapHint(_:)))
            }

            navigationItem.hidesBackButton = true
        }
    }
    
    // MARK: - Actions

    @objc
    func tapHint(_ sender: UIBarButtonItem) {
        guard let quiz = quiz else { return }
        
        // Disable the hint button until we are done showing the hint.
        sender.isEnabled = false
        
        // Count hints.
        quiz.currentQuestion.hints += 1
        
        // Find an answer we know to be wrong.
        let hintIndex = (quiz.currentQuestion.correctAnswerIndex + 1) % quiz.currentQuestion.answers.count
        let indexPath = IndexPath(row: hintIndex, section: 0)
        
        // Get the corresponding cell.
        if let cell = tableView.cellForRow(at: indexPath) {
            
            // Make it disappear and then reappear after a second.
            UIView.animate(withDuration: 0.2, animations: { cell.alpha = 0 }) { _ in
                UIView.animate(withDuration: 0.2, delay: 1, options: .curveEaseInOut, animations: { cell.alpha = 1 }) { _ in
                    sender.isEnabled = true
                }
            }
        }
    }

    @objc
    func tapDone(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    // MARK: - Table view data source
    
    /// Returns the number of sections.
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    /// Returns the total number of possible answers or questions.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let quiz = quiz else { return 0 }
        return quiz.isOver ? quiz.questions.count : quiz.currentQuestion.answers.count
    }
    
    /// Creates a row holding one of the possible answers or one of the questions.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "QuizCellIdentifier", for: indexPath)
        guard let quiz = quiz else { return cell }

        if quiz.isOver {
            // Find the question.
            let question = quiz.questions[indexPath.row]
            
            // Put the question and answer in the cell.
            cell.textLabel?.text = question.text
            cell.detailTextLabel?.text = question.response
            
            cell.detailTextLabel?.textColor = question.isCorrect ? .green : .red

        } else {
            // Get a letter to add to the front of the answer
            let ascii = indexPath.row + 65
            let letter = Character(Unicode.Scalar(ascii)!)
            
            cell.textLabel?.text = "\(letter). \(quiz.currentQuestion.answers[indexPath.row])"
            cell.detailTextLabel?.text = ""
        }
        
        return cell
    }
    
    /// Creates a section header with a question or the summary.
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UILabel()
        guard let quiz = quiz else { return view }

        view.text = quiz.isOver ? "Your Score: \(quiz.correctCount) / \(quiz.questions.count)" : quiz.currentQuestion.text
        view.textAlignment = .center
        view.numberOfLines = 0
        view.font = UIFont.systemFont(ofSize: 32, weight: .light)
        
        return view
    }
    
    /// Records an answer.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let quiz = quiz else { return }
        quiz.setAnswer(index: indexPath.row)

        // Show the next question.
        if let quizVC = storyboard?.instantiateViewController(withIdentifier: "QuizViewController") as? QuizViewController {
            quizVC.quiz = quiz
            navigationController?.pushViewController(quizVC, animated: true)
        }
    }
}
