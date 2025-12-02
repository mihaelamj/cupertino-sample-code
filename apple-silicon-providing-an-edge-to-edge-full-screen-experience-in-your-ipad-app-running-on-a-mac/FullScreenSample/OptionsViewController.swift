/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller that presents a set of display options.
*/

import UIKit

class OptionsViewController: UITableViewController {
    var options: [String: Bool] = [:]
    var updateOption: ((String, Bool) -> Void)? = nil
    
    private var sectionData: [[String]] = {
        return [
            [GridViewOptionsKey.showPixelGrid, GridViewOptionsKey.showPointsGrid],
            [GridViewOptionsKey.showBounds, GridViewOptionsKey.showSafeAreaInsets, GridViewOptionsKey.showOriginIndicator]
        ]
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func doneTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionData.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionData[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "OptionsCell", for: indexPath) as? OptionsCell
        else {
            fatalError()
        }
        
        let key = sectionData[indexPath.section][indexPath.row]
        cell.configureWith(text: key, isOn: options[key] ?? true) { [weak self] isOn in
            if let updateData = self?.updateOption {
                updateData(key, isOn)
            }
        }
        return cell
    }
}
