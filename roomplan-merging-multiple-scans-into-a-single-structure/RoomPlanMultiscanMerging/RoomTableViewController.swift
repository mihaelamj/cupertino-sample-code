/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller for the app's intial view.
*/

import UIKit
import RoomPlan

class RoomTableViewController: UITableViewController {

    /// An array of URLs to rooms.
    private var rooms: [URL]!
    
    /// An object that builds a single structure by merging multiple rooms.
    private let structureBuilder = StructureBuilder(options: [.beautifyObjects])
    
    /// An object that holds a merged result.
    private var finalResults: CapturedStructure?
    private var mergeAndExportButton: UIBarButtonItem?

    /// Runs at initialization and displays the app's user interface.
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.rightBarButtonItem = self.editButtonItem
        tableView.allowsMultipleSelectionDuringEditing = true
        self.setupEditButtons()
        fetchRooms()
    }

    /// Configures the app's Edit button.
    private func setupEditButtons() {
        let flexButton = UIBarButtonItem(systemItem: .flexibleSpace)
        let mergeAndExportButton = UIBarButtonItem(title: "Merge and Export",
                                          style: .plain,
                                          target: self,
                                          action: #selector(mergeAndExport))

        toolbarItems = [flexButton, mergeAndExportButton, flexButton]
        self.mergeAndExportButton = mergeAndExportButton
    }

    /// Loads the previous scans from a file on disk.
    private func fetchRooms() {
        let myHomePath = Bundle.main.path(forResource: "MyHome", ofType: nil)
        guard let path = myHomePath else {
            return
        }

        let url = URL(filePath: path)
        rooms = url.subDirectories
    }
    
    /// Begins editing the app's table view.
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)

        let selectAllButtonItem = UIBarButtonItem(title: "Select All", style: .plain, target: self, action: #selector(selectAllRooms))
        self.navigationItem.leftBarButtonItem = selectAllButtonItem
        self.navigationItem.leftBarButtonItem?.isHidden = !editing
        navigationController?.setToolbarHidden(!editing, animated: true)
        self.enableMergeAndExportButton(enable: false)
    }

    // MARK: - Table view delegate

    /// Defines a height for the table's header.
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60
    }

    /// Defines the text and style of the table's header.
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: tableView.sectionHeaderHeight)
        let headerView = HeaderView(frame: frame, title: "My Home")
        return headerView
    }

    /// Defines a height for the table's rows.
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    /// Selects a table row and enables the Merge button for nonzero selections.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if selectedURLs()?.count != nil {
            enableMergeAndExportButton(enable: true)
        }
    }

    /// Deselects a table row and disables the Merge button if there isn't a selection present.
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if selectedURLs()?.count == nil {
            enableMergeAndExportButton(enable: false)
        }
    }

    // MARK: - Table view data source

    /// Defines the number of rows in the table.
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rooms.count
    }

    /// Provides a table view cell for the given index path.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RoomCell", for: indexPath)
        cell.textLabel?.text = room(for: indexPath).lastPathComponent
        return cell
    }

    /// Provides a room URL for the given table-view index-path.
    private func room(for indexPath: IndexPath) -> URL {
        return rooms[indexPath.row]
    }

    /// Retrieves room URLs for the table view's selected rows.
    private func selectedURLs() -> [URL]? {
        guard let indexPaths = tableView.indexPathsForSelectedRows, !indexPaths.isEmpty else { return nil }
        let urls: [URL] = indexPaths.map { indexPath in
            return room(for: indexPath)
        }

        return !urls.isEmpty ? urls : nil
    }

    /// Toggles the Merge button's visibility.
    private func enableMergeAndExportButton(enable: Bool) {
        guard let items = toolbarItems else {
            return
        }

        items.forEach { item in
            if item.action == #selector(self.mergeAndExport) {
                item.isEnabled = enable
            }
        }
    }

    /// Loads a captured room for the given URL.
    private func loadCapturedRoom(from url: URL) throws -> CapturedRoom? {
        let jsonData = try? Data(contentsOf: url)
        guard let data = jsonData else { return nil }
        let capturedRoom = try? JSONDecoder().decode(CapturedRoom.self, from: data)
        return capturedRoom
    }

    /// Creates a 3D model from the given selected room URLS.
    private func mergeSelectedRooms(urls: [URL]) {
        var capturedRoomArray: [CapturedRoom] = []
        for url in urls {
            let jsonURL = url.appending(path: "capturedRoom.json")
            guard let room = try? loadCapturedRoom(from: jsonURL) else { continue }
            capturedRoomArray.append(room)
        }

        Task {
            do {
                finalResults = try await structureBuilder.capturedStructure(from: capturedRoomArray)
            } catch {
                self.showAlert(title: "Merging Error", message: error.localizedDescription)
                return
            }

            let exportFolderURL: URL
            do {
                try exportFolderURL = createTmpExportFolder()
            } catch {
                self.showAlert(title: "Cannot create tmp export folder", message: error.localizedDescription)
                return
            }

            let meshDestinationURL = exportFolderURL.appending(path: "MergedRooms.usdz")
            do {
                try createExportData(meshDestinationURL: meshDestinationURL)
                let activityVC = UIActivityViewController(activityItems: [exportFolderURL], applicationActivities: nil)
                activityVC.modalPresentationStyle = .popover
                activityVC.popoverPresentationController?.sourceItem = mergeAndExportButton
                present(activityVC, animated: true, completion: nil)
            } catch {
                print("Error = \(error)")
            }
        }
    }

    /// Exports the given captured structure in JSON format to a URL.
    func exportJson(from capturedStructure: CapturedStructure, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(capturedStructure)
        try data.write(to: url)
    }

    /// Exports the merged captured structure in JSON and USDZ formats to a URL.
    private func createExportData(meshDestinationURL: URL?) throws {
        guard let meshDestinationURL, let finalResults else { return }
        let roomDestinationURL = meshDestinationURL.deletingPathExtension().appendingPathExtension("json")
        try exportJson(from: finalResults, to: roomDestinationURL)
        let metadataDestinationURL = meshDestinationURL.deletingPathExtension().appendingPathExtension("plist")
        try finalResults.export(to: meshDestinationURL,
                                metadataURL: metadataDestinationURL,
                                exportOptions: [.mesh])
    }

    /// Provides a temporary location on disk to export a 3D model to.
    private func createTmpExportFolder(
        tmpFolderURL: URL = FileManager.default.temporaryDirectory) throws -> URL {
        let exportFolderURL = tmpFolderURL.appending(path: "MultiscanMergedExport")
        if FileManager.default.fileExists(atPath: exportFolderURL.path()) {
            try FileManager.default.removeItem(at: exportFolderURL)
        }
        try FileManager.default.createDirectory(at: exportFolderURL,
                                                withIntermediateDirectories: true)
        return exportFolderURL
    }

    /// Merges all selected rooms.
    @objc
    private func mergeAndExport() {
        guard let urls = selectedURLs() else { return }
        mergeSelectedRooms(urls: urls)
    }

    /// Selects all rooms.
    @objc
    private func selectAllRooms() {
        if self.navigationItem.leftBarButtonItem?.title == "Select All" {
            self.navigationItem.leftBarButtonItem?.title = "Deselect All"
            for index in 0..<rooms.count {
                let indexPath = IndexPath(row: index, section: 0)
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
            enableMergeAndExportButton(enable: true)
        } else {
            self.navigationItem.leftBarButtonItem?.title = "Select All"
            for index in 0..<rooms.count {
                let indexPath = IndexPath(row: index, section: 0)
                tableView.deselectRow(at: indexPath, animated: false)
            }
            enableMergeAndExportButton(enable: false)
        }
    }
}

/// Displays an alert.
extension RoomTableViewController {
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        self.present(alert, animated: true, completion: nil)
    }
}
