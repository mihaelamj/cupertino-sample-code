/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The hosting controller example.
*/

import UIKit
import SwiftUI

// A model object that represents an alert that can be enabled when certain heart conditions are detected.
// This class conforms to the ObservableObject protocol, which enables SwiftUI views using this object to
// automatically update when properties annotated with the @Published property wrapper change, and also
// allows SwiftUI to write back changes to these properties as well.
@MainActor
private class HeartHealthAlert: ObservableObject {
    // The name of the symbol displayed for this alert.
    @Published var systemImageName: String
    // The title of the alert.
    @Published var title: String
    // A description of the alert, shown when the alert is enabled.
    @Published var description: String
    // Whether the alert is enabled.
    @Published var isEnabled: Bool {
        didSet {
            if oldValue != isEnabled {
                // SwiftUI views that use this property are automatically updated whenever it changes.
                // For UIKit views that depend on this state, this example posts a notification as a
                // simple mechanism to update them, but a real application may use whatever facility
                // fits best within the application's architecture to trigger those updates.
                NotificationCenter.default.post(name: .heartHealthAlertEnabledDidChange, object: self)
            }
        }
    }
    
    init(systemImageName: String, title: String, description: String, isEnabled: Bool = false) {
        self.systemImageName = systemImageName
        self.title = title
        self.description = description
        self.isEnabled = isEnabled
    }
}

private extension HeartHealthAlert {
    // Returns the default heart health alerts.
    static func getDefaultAlerts() -> [HeartHealthAlert] {
        [
            HeartHealthAlert(systemImageName: "bolt.heart.fill",
                             title: "Irregular Rhythm",
                             description: "You will be notified when an irregular heart rhythm is detected."),
            HeartHealthAlert(systemImageName: "arrow.up.heart.fill",
                             title: "High Heart Rate",
                             description: "You will be notified when your heart rate rises above normal levels."),
            HeartHealthAlert(systemImageName: "arrow.down.heart.fill",
                             title: "Low Heart Rate",
                             description: "You will be notified when your heart rate falls below normal levels.")
        ]
    }
}

private extension NSNotification.Name {
    // A notification that is posted when a heart health alert is enabled or disabled.
    static let heartHealthAlertEnabledDidChange = Notification.Name("com.example.UseSwiftUIWithUIKit.heartHealthAlertEnabledDidChange")
}

// A SwiftUI view that allows the user to enable or disable a heart health alert.
private struct HeartHealthAlertView: View {
    // Stores the heart health alert that is displayed by this view. Using the @ObservedObject
    // property wrapper here ensures that SwiftUI will automatically refresh the view when any
    // of the @Published properties of the ObservableObject change.
    @ObservedObject var alert: HeartHealthAlert
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: alert.systemImageName)
                    .imageScale(.large)
                Text(alert.title)
                Spacer()
                // The Toggle (on/off switch) displayed in this view is created with a binding to the
                // isEnabled property of the alert. When the user toggles the alert on or off, SwiftUI
                // will directly set the isEnabled property of the model object to the new value.
                Toggle("Enabled", isOn: $alert.isEnabled)
                    .labelsHidden()
            }
            // The extra description text is only added to the view when the alert is enabled.
            if alert.isEnabled {
                Text(alert.description)
                    .font(.caption)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemFill))
        )
    }
}

class HostingControllerViewController: UIViewController {
    
    // An array of the heart health alert model objects that are displayed by this view controller.
    private var alerts = HeartHealthAlert.getDefaultAlerts()
    
    // Returns the number of alerts that are currently enabled.
    private var alertsEnabledCount: Int {
        var count = 0
        for alert in alerts where alert.isEnabled {
            count += 1
        }
        return count
    }
    
    // Stores the hosting controllers that each display a SwiftUI heart health alert view.
    private var hostingControllers = [UIHostingController<HeartHealthAlertView>]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Heart Health Alerts"
        view.backgroundColor = .systemBackground
        
        // Create the hosting controllers and set up the stack view.
        createHostingControllers()
        setUpStackView()
        
        // Update the UIKit views based on the current state of the alerts.
        updateSummaryLabel()
        updateBarButtonItem()
        
        // Register for notifications when heart health alerts are enabled or disabled, in order to update the UIKit views as necessary.
        let defaultCenter = NotificationCenter.default
        defaultCenter.addObserver(self, selector: #selector(heartHealthAlertDidChange(_:)), name: .heartHealthAlertEnabledDidChange, object: nil)
    }
    
    // Creates a hosting controller for each heart health alert.
    private func createHostingControllers() {
        for alert in alerts {
            let alertView = HeartHealthAlertView(alert: alert)
            let hostingController = UIHostingController(rootView: alertView)
            
            // Set the sizing options of the hosting controller so that it automatically updates the
            // intrinsicContentSize of its view based on the ideal size of the SwiftUI content.
            hostingController.sizingOptions = .intrinsicContentSize
            
            hostingControllers.append(hostingController)
        }
    }
    
    // Embeds each hosting controller's view in a stack view, and adds the stack view to this view controller's view.
    private func setUpStackView() {
        // Collect the view from each hosting controller, as well as the summary label.
        var views: [UIView] = hostingControllers.map { $0.view }
        views.append(summaryLabel)
        
        // Add each hosting controller as a child view controller.
        hostingControllers.forEach { addChild($0) }
        
        // Create a stack view that contains all the views, and add it as a subview to the view
        // of this view controller.
        let spacing = 10.0
        let stackView = UIStackView(arrangedSubviews: views)
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        stackView.spacing = spacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: spacing)
        ])
        
        // Notify each hosting controller that it has now moved to a new parent view controller.
        hostingControllers.forEach { $0.didMove(toParent: self) }
    }
    
    // This method is called whenever a heart health alert is enabled or disabled.
    @objc
    private func heartHealthAlertDidChange(_ notification: NSNotification) {
        // Update the UIKit parts of this view controller as necessary based on which alerts are now enabled.
        // There is no need to update any SwiftUI views in the hosting controllers here, as those are
        // refreshed automatically because the HeartHealthAlert is an ObservableObject.
        updateBarButtonItem()
        updateSummaryLabel()
    }
    
    // Updates the right bar button item to enable or disable all alerts, based on whether any are currently enabled.
    private func updateBarButtonItem() {
        let title: String
        let action: UIAction
        if alertsEnabledCount > 0 {
            title = "Disable All"
            action = UIAction { [unowned self] _ in
                alerts.forEach { $0.isEnabled = false }
            }
        } else {
            title = "Enable All"
            action = UIAction { [unowned self] _ in
                alerts.forEach { $0.isEnabled = true }
            }
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: title, primaryAction: action)
    }
    
    // Returns a UILabel that displays the total number of heart health alerts enabled.
    private lazy var summaryLabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    // Updates the summary label to display the total number of enabled alerts.
    private func updateSummaryLabel() {
        let enabledCount = alertsEnabledCount
        if enabledCount == 0 {
            summaryLabel.text = "No Alerts Enabled"
        } else if enabledCount == 1 {
            summaryLabel.text = "\(enabledCount.formatted(.number)) Alert Enabled"
        } else {
            summaryLabel.text = "\(enabledCount.formatted(.number)) Alerts Enabled"
        }
    }
    
}
