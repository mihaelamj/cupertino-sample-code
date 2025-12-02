/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller that manages a layout of known exposure events.
*/

import UIKit
import ExposureNotification

class ExposuresViewController: UITableViewController {
    
    var keyValueObservers = [NSKeyValueObservation]()
    var observers = [NSObjectProtocol]()
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        keyValueObservers.append(ExposureManager.shared.manager.observe(\.exposureNotificationStatus) { [unowned self] manager, change in
            self.updateTableView(animated: true, reloadingOverviewAndStatus: true)
        })
        
        observers.append(NotificationCenter.default.addObserver(forName: ExposureManager.authorizationStatusChangeNotification,
                                                                object: nil, queue: nil) { [unowned self] notification in
            self.updateTableView(animated: true, reloadingOverviewAndStatus: true)
        })
        
        observers.append(LocalStore.shared.$exposures.addObserver { [unowned self] in
            self.updateTableView(animated: true)
        })
        
        observers.append(LocalStore.shared.$dateLastPerformedExposureDetection.addObserver { [unowned self] in
            self.reloadStatusSection()
        })
        
        observers.append(LocalStore.shared.$exposureDetectionErrorLocalizedDescription.addObserver { [unowned self] in
            self.reloadStatusSection()
        })
        
        observers.append(NotificationCenter.default.addObserver(forName: UIApplication.significantTimeChangeNotification, object: nil, queue: nil) {
            [unowned self] _ in
            self.reloadStatusSection()
        })
    }
    
    deinit {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    enum Section: Int {
        case overview
        case status
        case exposures
    }
    
    enum Item: Hashable {
        case overviewAction
        case status
        case exposurePlaceholder
        case exposure(index: Int)
    }
    
    static let dateLastPerformedExposureDetectionFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        formatter.formattingContext = .dynamic
        return formatter
    }()
    
    class DataSource: UITableViewDiffableDataSource<Section, Item> {
        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            switch snapshot().sectionIdentifiers[section] {
            case .exposures:
                return NSLocalizedString("EXPOSURE_PAST_14_DAYS", comment: "Header")
            default:
                return nil
            }
        }
        
        override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
            switch snapshot().sectionIdentifiers[section] {
            case .status:
                var messages = [String]()
                if ENManager.authorizationStatus == .authorized && ExposureManager.shared.manager.exposureNotificationStatus == .active {
                    messages.append(NSLocalizedString("EXPOSURE_YOU_WILL_BE_NOTIFIED", comment: "Footer"))
                } else {
                    messages.append(NSLocalizedString("EXPOSURE_YOU_WILL_NOT_BE_NOTIFIED", comment: "Footer"))
                }
                if let localizedErrorDescription = LocalStore.shared.exposureDetectionErrorLocalizedDescription {
                    messages.append(String(format: NSLocalizedString("EXPOSURE_DETECTION_ERROR", comment: "Footer"), localizedErrorDescription))
                }
                if let date = LocalStore.shared.dateLastPerformedExposureDetection {
                    let dateString = ExposuresViewController.dateLastPerformedExposureDetectionFormatter.string(from: date)
                    messages.append(String(format: NSLocalizedString("EXPOSURE_LAST_CHECKED", comment: "Footer"), dateString))
                }
                return messages.joined(separator: " ")
            default:
                return nil
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        switch dataSource.snapshot().sectionIdentifiers[section] {
        case .overview:
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "OverviewHeader") as! TableHeaderView
            header.headerText = NSLocalizedString("EXPOSURE_NOTIFICATION_OFF", comment: "Header")
            switch ENManager.authorizationStatus {
            case .unknown:
                header.text = NSLocalizedString("EXPOSURE_NOTIFICATION_DISABLED_DIRECTIONS", comment: "Header")
            case .authorized where ExposureManager.shared.manager.exposureNotificationStatus == .bluetoothOff:
                header.text = NSLocalizedString("EXPOSURE_NOTIFICATION_BLUETOOTH_OFF_DIRECTIONS", comment: "Header")
            default:
                header.text = NSLocalizedString("EXPOSURE_NOTIFICATION_DENIED_DIRECTIONS", comment: "Header")
            }
            return header
        default:
            return nil
        }
    }
    
    var dataSource: DataSource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(TableHeaderView.self, forHeaderFooterViewReuseIdentifier: "OverviewHeader")
        dataSource = DataSource(tableView: tableView, cellProvider: { tableView, indexPath, item in
            switch item {
            case .overviewAction:
                let cell = tableView.dequeueReusableCell(withIdentifier: "OverviewAction", for: indexPath)
                switch ENManager.authorizationStatus {
                case .unknown:
                    cell.textLabel!.text = NSLocalizedString("EXPOSURE_NOTIFICATION_DISABLED_ACTION", comment: "Button")
                default:
                    cell.textLabel!.text = NSLocalizedString("GO_TO_SETTINGS", comment: "Button")
                }
                return cell
            case .status:
                let cell = tableView.dequeueReusableCell(withIdentifier: "Status", for: indexPath)
                switch ENManager.authorizationStatus {
                case .restricted:
                    cell.detailTextLabel!.text = NSLocalizedString("EXPOSURE_NOTIFICATION_STATE_RESTRICTED", comment: "Value")
                case .authorized:
                    switch ExposureManager.shared.manager.exposureNotificationStatus {
                    case .active:
                        cell.detailTextLabel!.text = NSLocalizedString("EXPOSURE_NOTIFICATION_STATE_ON", comment: "Value")
                    case .disabled:
                        cell.detailTextLabel!.text = NSLocalizedString("EXPOSURE_NOTIFICATION_STATE_OFF", comment: "Value")
                    case .bluetoothOff:
                        cell.detailTextLabel!.text = NSLocalizedString("EXPOSURE_NOTIFICATION_STATE_BLUETOOTH_OFF", comment: "Value")
                    case .restricted:
                        cell.detailTextLabel!.text = NSLocalizedString("EXPOSURE_NOTIFICATION_STATE_RESTRICTED", comment: "Value")
                    default:
                        cell.detailTextLabel!.text = NSLocalizedString("EXPOSURE_NOTIFICATION_STATE_UNKNOWN", comment: "Value")
                    }
                default:
                    cell.detailTextLabel!.text = NSLocalizedString("EXPOSURE_NOTIFICATION_STATE_OFF", comment: "Value")
                }
                return cell
            case .exposurePlaceholder:
                return tableView.dequeueReusableCell(withIdentifier: "ExposurePlaceholder", for: indexPath)
            case let .exposure(index):
                let cell = tableView.dequeueReusableCell(withIdentifier: "Exposure", for: indexPath)
                let exposure = LocalStore.shared.exposures[index]
                cell.textLabel!.text = NSLocalizedString("POSSIBLE_EXPOSURE", comment: "Text")
                cell.detailTextLabel!.text = DateFormatter.localizedString(from: exposure.date, dateStyle: .long, timeStyle: .none)
                return cell
            }
        })
        dataSource.defaultRowAnimation = .fade
        updateTableView(animated: false)
    }
    
    func updateTableView(animated: Bool, reloadingOverviewAndStatus: Bool = false) {
        guard isViewLoaded else { return }
        var snapshot = dataSource.snapshot()
        snapshot.deleteAllItems()
        let authorizationStatus = ENManager.authorizationStatus
        if authorizationStatus != .authorized || ExposureManager.shared.manager.exposureNotificationStatus == .bluetoothOff {
            snapshot.appendSections([.overview])
            if authorizationStatus != .authorized {
                snapshot.appendItems([.overviewAction], toSection: .overview)
            }
            if reloadingOverviewAndStatus {
                snapshot.reloadSections([.overview])
            }
        }
        snapshot.appendSections([.status, .exposures])
        snapshot.appendItems([.status], toSection: .status)
        if reloadingOverviewAndStatus {
            snapshot.reloadSections([.status])
        }
        let exposures = LocalStore.shared.exposures
        if exposures.isEmpty {
            snapshot.appendItems([.exposurePlaceholder], toSection: .exposures)
        } else {
            snapshot.appendItems(exposures.enumerated().reversed().map { .exposure(index: $0.offset) }, toSection: .exposures)
        }
        dataSource.apply(snapshot, animatingDifferences: tableView.window != nil ? animated : false)
    }
    
    func reloadStatusSection() {
        guard isViewLoaded else { return }
        var snapshot = dataSource.snapshot()
        snapshot.reloadSections([.status])
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        switch dataSource.itemIdentifier(for: indexPath)! {
        case .exposurePlaceholder:
            return false
        default:
            return true
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch dataSource.itemIdentifier(for: indexPath)! {
        case .overviewAction:
            switch ENManager.authorizationStatus {
            case .unknown:
                performSegue(withIdentifier: "ShowOnboarding", sender: nil)
            default:
                openSettings(from: self)
            }
        case let .exposure(index):
            let exposureDetailsViewController = ExposureDetailsViewController.make(value: LocalStore.shared.exposures[index])
            present(StepNavigationController(rootViewController: exposureDetailsViewController), animated: true, completion: nil)
        default:
            break
        }
    }
    
    @IBSegueAction func showOnboarding(_ coder: NSCoder) -> OnboardingViewController? {
        return OnboardingViewController(rootViewController: OnboardingViewController.EnableExposureNotificationsViewController.make(), coder: coder)
    }
}
