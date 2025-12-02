/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller showing the contents of a single scene.
*/

import UIKit

class SceneViewController: UIViewController, UITextViewDelegate {

    @IBOutlet weak var sceneText: UITextView!
    
    var scene: Scene? {
        didSet {
            navigationItem.title = scene?.identifier ?? "Scene"
            if scene?.quiz != nil {
                navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Take Quiz",
                                                                    style: .done,
                                                                    target: self,
                                                                    action: #selector(tapQuiz(_:)))
            } else {
                navigationItem.rightBarButtonItem = nil
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // Make sure we're at the top after layout finishes.
        sceneText.contentOffset = .zero
    }

    /// - Tag: sceneDidAppear
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        scene?.startActivity()
    }

    /// - Tag: sceneWillDisappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        scene?.stopActivity()
    }

    /// Use scrolling as a proxy for reading progress.
    /// - Tag: sceneDidScroll
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let position = sceneText.contentOffset.y + sceneText.frame.size.height
        let total = sceneText.contentSize.height
        
        // The scroll view can bounce, so use care to bound the progress.
        let progress = Double(max(0, min(1, position / total)))
        
        scene?.update(progress: progress)
    }

    /// Handle the user tapping the "Take Quiz" button.
    @objc
    func tapQuiz(_ sender: UIBarButtonItem) {
        if let quiz = scene?.quiz {
            presentQuiz(quiz)
        }
    }
    
    /// Creates a new quiz instance and presents the first question.
    func presentQuiz(_ quiz: Quiz) {
        guard let quizVC = storyboard?.instantiateViewController(withIdentifier: "QuizViewController") as? QuizViewController else { return }

        quiz.reset()
        quizVC.quiz = quiz
        present(UINavigationController(rootViewController: quizVC), animated: true) {
            quiz.start()
        }
    }
}
