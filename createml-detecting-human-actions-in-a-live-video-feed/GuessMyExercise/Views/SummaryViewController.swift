/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The summary view shows a list of the actions paired with the aggregate times.
*/

import UIKit

/// Displays a table view of the actions with the time duration for each.
class SummaryViewController: UIViewController {
    /// The summary view controller's primary view.
    @IBOutlet weak var tableView: UITableView!

    /// The list of actions, sorted by descending time.
    private var sortedActions = [String]()

    /// The times of each action, keyed by the action's name.
    var actionFrameCounts: [String: Int]? {
        didSet {
            guard let frameCounts = actionFrameCounts else { return }

            // Clear out the previous list of actions.
            sortedActions.removeAll()

            // Create a list of the actions sorted by descending time.
            let sortedElements = frameCounts.sorted { $0.value > $1.value }
            sortedElements.forEach { entry in sortedActions.append(entry.key) }
        }
    }

    /// A closure the summary view controller calls after it disappears.
    var dismissalClosure: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        view?.overrideUserInterfaceStyle = .dark

        tableView.dataSource = self
        tableView.reloadData()
    }

    override func viewDidDisappear(_ animated: Bool) {
        // Call the dismissal closure, if there is one.
        dismissalClosure?()

        // Call the super class last.
        super.viewDidDisappear(animated)
    }
}

// MARK: - Table View Data Source
extension SummaryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return sortedActions.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let customCellName = "SummaryCellPrototype"
        let cell = tableView.dequeueReusableCell(withIdentifier: customCellName,
                                                 for: indexPath)

        guard let summaryCell = cell as? SummaryTableViewCell else {
            fatalError("Not an instance of `SummaryTableViewCell`.")
        }

        if let frameCounts = actionFrameCounts {
            let frameRate = ExerciseClassifier.frameRate

            let action = sortedActions[indexPath.row]
            let totalFrames = frameCounts[action] ?? 0
            let totalDuration = Double(totalFrames) / frameRate

            summaryCell.totalDuration = totalDuration
            summaryCell.actionLabel.text = action
        }

        return summaryCell
    }
}

// MARK: - Table Cell
///Displays the name of an action and the total time duration of that action.
class SummaryTableViewCell: UITableViewCell {
    /// Displays name of the action.
    @IBOutlet weak var actionLabel: UILabel!

    /// Displays the amount of time of the action.
    @IBOutlet weak var timeLabel: UILabel!

    /// Converts the floating point value into a string for the action label.
    ///
    /// For example, the time label shows "1.7s" for a value of `1.66666666666`.
    var totalDuration: Double = 0 {
        didSet { timeLabel.text = String(format: "%0.1fs", totalDuration) }
    }
}
