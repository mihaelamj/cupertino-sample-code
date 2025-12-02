/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Main View Controller
*/

import UIKit
import ExposureNotification

class MainViewController: UITableViewController {
        
    var observers = [NSObjectProtocol]()
    var keyValueObservers = [NSKeyValueObservation]()
    
    private var segueRowData: TableRowData?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Exposure Notifications"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        switch getSupportedExposureNotificationsVersion() {
            case .version2:
                print("Using Exposure Notifications API Version 2")
            case .version1:
                print("Using Exposure Notifications API Version 1")
            case .unsupported:
                print("Exposure Notifications not supported on this version of iOS")
                let alert = UIAlertController(title: "Exposure Notifications Not Supported",
                                              message: "You are running a version of iOS that does " +
                                                "not support Exposure Notifications.",
                                              preferredStyle: .alert)
                self.present(alert, animated: true)
                return
        }
        
        // If EN status, or authorization status changes, we reload the table data
        observers.append(NotificationCenter.default.addObserver(forName: ExposureManager.authorizationStatusChangeNotification,
                                               object: nil, queue: nil) { [unowned self] notification in
            self.tableView.reloadData()
        })
        observers.append(NotificationCenter.default.addObserver(
            forName: Notification.Name("LocalStoreExposureDetectionErrorLocalizedDescriptionDidChange"),
            object: nil, queue: nil) { notification in
            print("Localized description did change notification received")
            
            if let errorMessage = LocalStore.shared.exposureDetectionErrorLocalizedDescription {
                self.showUserMessage("Local Store Error", errorMessage, true)
            } else {
                self.showUserMessage("Task Completed", "No error encountered", false)
            }
        })
        keyValueObservers.append(ExposureManager.shared.manager.observe(\.exposureNotificationStatus) { [unowned self] manager, change in
            self.tableView.reloadData()
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}

// MARK: - UITableViewDataSource -
extension MainViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return TableViewSections.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let whichSection = TableViewSections(rawValue: section) else { return 0 }
        return whichSection.rowCount
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let whichSection = TableViewSections(rawValue: indexPath.section) else {
            fatalError("No data found for section: \(indexPath.section), row \(indexPath.row)")
        }
        
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        
        let data = whichSection.dataForRow(indexPath.row)
        if let dynamicTitle = data.dynamicTitle {
            cell?.textLabel?.text = dynamicTitle()
        } else {
            cell?.textLabel?.text = data.title
        }
        
        if data.showDisclosureIndicator {
            cell?.accessoryType = .disclosureIndicator
        }
        
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let whichSection = TableViewSections(rawValue: section) else {
            fatalError("No data found for section: \(section)")
        }
        return whichSection.title
    }
}

// MARK: - UITableViewDelegate -
extension MainViewController {
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40.0
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let whichSection = TableViewSections(rawValue: section) else {
            fatalError("No data found for section: \(section)")
        }
        
        let horizontalInset = 10.0
        let insetWidth = Double(tableView.bounds.size.width) - (horizontalInset * 2.0)
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: 30.0))
        headerView.backgroundColor = UIColor(named: "ENHeaderBackgroundColor")
        let label = UILabel(frame: CGRect(x: horizontalInset,
                                          y: horizontalInset,
                                          width: insetWidth,
                                          height: 30.0))
        label.text = whichSection.title
        label.textColor = UIColor(named: "ENHeaderTextColor")
        label.font = .boldSystemFont(ofSize: 20)
        headerView.addSubview(label)
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let whichSection = TableViewSections(rawValue: indexPath.section) else {
            fatalError("No data found for section: \(indexPath.section)")
        }
        let rowData = whichSection.dataForRow(indexPath.row)
        if let error = rowData.tapAction?() {
            showUserMessage("Error", error.localizedDescription, true)
        }
        if let segueIdentifier = rowData.segueIdentifier {
            segueRowData = rowData
            performSegue(withIdentifier: segueIdentifier, sender: self)
        }
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let newViewController = segue.destination
        segueRowData?.prepareViewControllerAction?(newViewController)
        segueRowData = nil
    }
    
// MARK: - Notifications
    /// Uses an alert to communicate with the user. if `isError` is true, the message will be displayed
    /// until the user acknowledges it. If `isError` is false, it is displayed for a couple seconds, and then
    /// is dismissed automatically.
    func showUserMessage(_ title: String, _ message: String, _ isError: Bool = false) {
        let alertController = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)

        if isError {
            let cancelActionButton = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
            alertController.addAction(cancelActionButton)
        } else {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
                alertController.dismiss(animated: true)
            }
        }
        
        self.present(alertController, animated: true)
    }
    
}
