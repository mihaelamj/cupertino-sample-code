/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The view controller responsible for displaying autocompletions in a table view.
*/

import MapKit

class CompletionsViewController: UITableViewController {

    private static let reuseIdentifier = "autocompletionCell"

    var selectionHandler: (MKLocalSearchCompletion) -> Void = { _ in }

    var searchCompletions = [MKLocalSearchCompletion]() {
        didSet {
            tableView.contentOffset = .zero
            tableView.reloadData()
        }
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        selectionHandler(searchCompletions[indexPath.row])
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchCompletions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CompletionsViewController.reuseIdentifier,
                                                 for: indexPath)

        /*
         Configure the cell using the search completion from the index path row.
        */
        let result = searchCompletions[indexPath.row]
        cell.textLabel?.text = result.title
        cell.detailTextLabel?.text = result.subtitle

        return cell
    }
}
