/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The play library.
*/

import Foundation

/// The collection of all plays that we know about.
class PlayLibrary: NSObject {

    /// The play library used throughout the app.
    static var shared = PlayLibrary()
    
    private(set) var plays: [Play] = []

    override init() {
        super.init()
        setupClassKit()
    }
    
    /// Adds a play to the play library.
    /// - Parameters:
    ///     - play: The play to add.
    ///     - creatingContexts: A Boolean indicating whether to create ClassKit contexts.
    ///
    /// - Tag: addPlay
    func addPlay(_ play: Play, creatingContexts: Bool = true) {
        if !plays.contains(where: { $0.title == play.title }) {
            plays.append(play)

            // Give ClassKit a chance to set up its contexts.
            if creatingContexts {
                setupContext(play: play)
            }
        }
    }
}

extension PlayLibrary {
    
    /// One built-in play.
    static var hamlet: Play {
        var hamlet = Play(title: "Hamlet")
        
        let sceneRangesByActNumber = [
            1: 1...5,
            2: 1...2,
            3: 1...4,
            4: 1...7,
            5: 1...2
        ]
        
        for case let (actNumber, sceneRange) in sceneRangesByActNumber.sorted(by: { $0.key < $1.key }) {
            var act = Act(number: actNumber, play: hamlet)
            for sceneNumber in sceneRange {
                let scene = Scene(number: sceneNumber, act: act)
                
                // We always create the same quiz here, but ideally we should
                //  create a quiz specific to the given scene.
                let question1 = Question(text: "Who is Hamlet?",
                                         answers: ["The Prince of Norway", "The Prince of Denmark", "The Prince of Thieves"],
                                         correctAnswerIndex: 1)
                let question2 = Question(text: "What is Hamlet's Quest?",
                                         answers: ["To avenge his father's murder", "To put on a play", "To seek the Holy Grail"],
                                         correctAnswerIndex: 0)
                let question3 = Question(text: "Where does Hamlet tell Ophelia to go?",
                                         answers: ["A winery", "A nursery", "A nunnery"],
                                         correctAnswerIndex: 2)
                
                scene.quiz = Quiz(title: "Act \(act.number) Scene \(scene.number) Quiz", questions: [question1, question2, question3], scene: scene)
                
                act.scenes.append(scene)
            }
            
            hamlet.acts.append(act)
        }

        return hamlet
    }
}
