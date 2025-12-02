/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Data for table contents
*/

import UIKit
import ExposureNotification

let cellTitle = "title"
let showDisclosureIndicator = "showDisclosureIndicator"
let textColor = "textColor"

enum TableViewSections: Int, CaseIterable {
    case status = 0, share, developer
    
    var title: String {
        return sectionTitles[rawValue]
    }
    
    var data: [TableRowData] {
        switch self {
            case .status:
                return statusSections
            case .share:
                return shareSections
            case .developer:
                return developerSections
        }
    }
    
    var rowCount: Int {
        switch self {
            case .status:
                return statusSections.count
            case .share:
                return shareSections.count
            case .developer:
                return developerSections.count
        }
    }
    
    func dataForRow(_ row: Int) -> TableRowData {
        return data[row]
    }
}

fileprivate let sectionTitles = ["Exposures", "Testing & Diagnoses", "Developer"]

struct TableRowData {
    var title: String
    var showDisclosureIndicator: Bool
    var segueIdentifier: String?
    var dynamicTitle: (() -> String)?
    var prepareViewControllerAction: ((_ viewController: UIViewController) -> Void)?
    var tapAction: (() -> Error?)?
    
    init(_ inTitle: String,
         _ inShowDisclosureIndicator: Bool = false,
         _ inSegueIdentifier: String? = nil,
         _ inDynamicTitle: (() -> String)? = nil,
         _ inPrepareViewControllerAction: ((_ viewController: UIViewController) -> Void)? = nil,
         _ inTapAction:(() -> Error?)? = nil) {
        title = inTitle
        showDisclosureIndicator = inShowDisclosureIndicator
        segueIdentifier = inSegueIdentifier
        dynamicTitle = inDynamicTitle
        prepareViewControllerAction = inPrepareViewControllerAction
        tapAction = inTapAction
    }
}

fileprivate let statusSections = [
    TableRowData("Exposure Notifications Status", false, nil, { () -> String in
        if ExposureManager.shared.manager.exposureNotificationStatus == .unauthorized {
            return "Status: Not Authorized"
        }
        if getSupportedExposureNotificationsVersion() == .unsupported {
            return "Status: Unsupported"
        }
        if ExposureManager.shared.manager.exposureNotificationEnabled {
            return "Status: Enabled"
        } else {
            return "Status: Disabled"
        }
    }),
    TableRowData("Enable Exposure Notifications", false, nil, { () -> String in
        if ExposureManager.shared.manager.exposureNotificationStatus == .unauthorized {
            return "Enable in Settings"
        }
        if ExposureManager.shared.manager.exposureNotificationEnabled {
            return "Disable Exposure Notifications"
        }
        return "Enable Exposure Notifications"
    }, nil, {  () -> Error? in
        if ExposureManager.shared.manager.exposureNotificationStatus == .unauthorized {
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            return nil
        }
        var localError: Error? = nil
        if ExposureManager.shared.manager.exposureNotificationEnabled {
            ExposureManager.shared.manager.setExposureNotificationEnabled(false) { (error) in
                if let error = error {
                    localError = error
                }
            }
            return localError
        } else {
            var localError: Error? = nil
            ExposureManager.shared.manager.setExposureNotificationEnabled(true) { (error) in
                if let error = error {
                    localError = error
                }
            }
            return localError
        }
    }),
    TableRowData("Recent Exposures", true, "ShowRecentExposures")
]

fileprivate let shareSections = [
    TableRowData("Show Positive Diagnoses", true, "ShowPositiveDiagnoses")
]

fileprivate let developerSections = [
    TableRowData("Detect Exposures Now", false, nil, nil, nil, {
        _ = ExposureManager.shared.detectExposures()
        return nil
    }),
    TableRowData("Simulate Exposure", false, nil, nil, nil, {
        let exposure = Exposure(date: Date() - TimeInterval.random(in: 1...4) * 24 * 60 * 60)
        LocalStore.shared.exposures.append(exposure)
        return nil
    }),
    TableRowData("Simulate Exposure Detection Error", false, nil, nil, nil, {
        LocalStore.shared.exposureDetectionErrorLocalizedDescription = "Unable to connect to server."
        return nil
    }),
    TableRowData("Simulate Positive Diagnosis", false, nil, nil, nil, {
        let testResult = TestResult(id: UUID(),
                                    isAdded: true,
                                    dateAdministered: Date() - TimeInterval.random(in: 0...4) * 24 * 60 * 60,
                                    isShared: .random())
        LocalStore.shared.testResults[testResult.id] = testResult
        return nil
    }),
    TableRowData("Reset Exposure Detection Error", false, nil, nil, nil, {
        LocalStore.shared.exposureDetectionErrorLocalizedDescription = nil
        return nil
    }),
    TableRowData("Reset Exposures", false, nil, nil, nil, {
        LocalStore.shared.nextDiagnosisKeyFileIndex = 0
        LocalStore.shared.exposures = []
        LocalStore.shared.dateLastPerformedExposureDetection = nil
        return nil
    }),
    TableRowData("Reset Test Results", false, nil, nil, nil, {
        LocalStore.shared.testResults = [:]
        return nil
    }),
    TableRowData("Diagnosis Keys in Local Server", true, "ShowDiagnosisKeys", nil, nil, nil),
    TableRowData("Get and Post Diagnosis Keys", false, nil, nil, nil, {
        var localError: Error? = nil
        ExposureManager.shared.getAndPostTestDiagnosisKeys { error in
            if let error = error {
                localError = error
            }
        }
        return localError
    }),
    TableRowData("Reset Diagnosis Keys", false, nil, nil, nil, {
        Server.shared.diagnosisKeys = []
        return nil
    })
]
