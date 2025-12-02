/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A tableview for displaying positive diagnoses.
*/

import UIKit

class PositiveDiagnosesTableViewController: UITableViewController {

    let reuseIdentifier = "positiveDiagnosisCell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Positive Diagnoses"
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return LocalStore.shared.testResults.values.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dict = LocalStore.shared.testResults
        let values = Array(dict.values).sorted { (testResult1, testResult2) -> Bool in
            return testResult1.dateAdministered < testResult2.dateAdministered
        }
        let testResult = values[indexPath.row]
        var cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: reuseIdentifier)
        }
        
        if testResult.isShared {
            cell?.accessoryType = .checkmark
        } else {
            cell?.accessoryType = .none
        }
        cell?.textLabel?.text = "COVID-19 Positive"
        
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        formatter.formattingContext = .dynamic
        
        var detailText = DateFormatter.localizedString(from: testResult.dateAdministered, dateStyle: .long, timeStyle: .none)
        detailText += (testResult.isShared) ? " - Shared" : " - Not Shared (tap to share)"
        cell?.detailTextLabel?.text = detailText

        return cell!
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let dict = LocalStore.shared.testResults
        let values = Array(dict.values).sorted { (testResult1, testResult2) -> Bool in
            return testResult1.dateAdministered < testResult2.dateAdministered
        }
        var testResult = values[indexPath.row]
        if !testResult.isShared {
            let alert = UIAlertController(title: "Share this diagnosis?",
                                          message: "{actual copy to be provided by PHA}",
                                          preferredStyle: .actionSheet)
            let cancelActionButton = UIAlertAction(title: "No", style: .cancel, handler: nil)
            alert.addAction(cancelActionButton)
            let shareActionButton = UIAlertAction(title: "Yes", style: .destructive) { (action) in
                ExposureManager.shared.getAndPostDiagnosisKeys(testResult: testResult) { error in
                    if error != nil {
                        print("error sharing positive result")
                    } else {
                        testResult.isShared = true
                        self.tableView.reloadData()
                        LocalStore.shared.testResults[testResult.id] = testResult
                    }
                    
                }
                self.tableView.reloadData()
            }
            alert.addAction(shareActionButton)
            self.present(alert, animated: true, completion: nil)
        }
    }
}
