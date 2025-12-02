/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A common way to present alerts in the app.
*/

import Foundation
import SwiftUI

public struct Alert: Identifiable {
  
  public var id = UUID()
  public var title: String
  public var message: String?
  public var buttons: [Self.Button]
  
  public init(title: String = "Alert",
              message: String? = nil,
              buttons: [Self.Button] = []) {
    self.title = title
    self.message = message
    self.buttons = buttons
  }
  
  public struct Button: Identifiable {
    
    public var id = UUID()
    public var label: String
    public var action: () -> Void
    
    public init(label: String, action: @escaping () -> Void = { }) {
      self.label = label
      self.action = action
    }
  }
}

// MARK: -

/** Manages a queue of alerts to display in the app.

 To display the alerts, use the `.presentingAlerts` view modifier
 on one of your root views, and pass it your app's `AlertManager` instance. You can then pass around that alert manager instance in your
 program to present alerts from anywhere including controller code, sub views, etc.
 
 ```
 @main
 struct MyApp: App {
 
    var alertManager = AlertManager()
 
     var body: some Scene {
         WindowGroup {
             ContentView()
                 .environment(alertManager)
                 .presentingAlerts(from: alertManager)
         }
     }
 }
 
 struct ContentView: View {
     
     @EnvironmentObject var alertManager = AlertManager()
     
     var body: some View {
         VStack  {
             Button("show alert with buttons", action: showAlertWithButtons)
             Button("show error alert", action: showErrorAlert)
         }
     }
     
     private func showErrorAlert() {
         let error = NSError(code: 9, localizedDescription: "This is the error's `localizedDescription`")
         alertManager.present(error: error)
     }
     
     private func showAlertWithTwoButtons() {
         let alert = Alert(title: "Alert with 2 buttons", message: "(they don't do anything)", buttons: [
             .init(label: "Button A"),
             .init(label: "Button B")
         ])
         alertManager.present(alert)
     }
 }
 ```
*/
@MainActor
public class AlertManager: ObservableObject {
  
  /// The alert that the app is currently displaying.
  @Published public var currentAlert: Alert? = nil
  
  /// The list of alerts that need to be displayed in order, starting with index 0.
  private var queue: [Alert] = []
  
  public nonisolated init() { }
  
  /// Presents the alert, or adds it to the queue if the app is already presenting an alert.
  public func present(_ newAlert: Alert) {
    if currentAlert == nil {
      currentAlert = newAlert
    } else { // The app is already showing an alert, add the new one to the end of the queue.
      queue.append(newAlert)
    }
  }
  
  /// Presents an alert with a single "ok" button.
  public func present(title: String, message: String? = nil) {
    let alert = Alert(title: title, message: message, buttons: [
      .init(label: "ok")
    ])
    present(alert)
  }
  
  /// A convenience method for showing an alert that displays an `Error` with a single "ok" button.
  public func present(error: Error, title: String = "Error") {
    let alert = Alert(title: title, message: String(describing: error), buttons: [
      .init(label: "ok")
    ])
    present(alert)
  }
  
  /// Dismisses the current alert and shows the next one, if there is one in the queue.
  public func dismissCurrentAlert() {
    if let next = queue.first {
      currentAlert = next
      queue = Array(queue.dropFirst())
    } else {
      currentAlert = nil
    }
  }
}

// MARK: -

@available(macOS 12.0, watchOS 8.0, iOS 15.0, tvOS 15.0, *)
public struct AlertPresenter: ViewModifier {
  
  @ObservedObject public var alertManager: AlertManager
  
  private var isPresented: Binding<Bool> {
    .init {
      alertManager.currentAlert != nil
    } set: { show in
      if !show {
        alertManager.dismissCurrentAlert()
      }
    }
  }
  
  public func body(content: Content) -> some View {
    content
      .alert(alertManager.currentAlert?.title ?? "nil",
             isPresented: isPresented,
             presenting: alertManager.currentAlert,
             actions: makeActions(for:),
             message: makeMessage(for:))
  }
  
  @ViewBuilder
  private func makeActions(for alert: Alert) -> some View {
    ForEach(alert.buttons) { button in
      Button(action: button.action) {
        Text(button.label)
      }
    }
  }
  
  @ViewBuilder
  private func makeMessage(for alert: Alert) -> some View {
    if let message = alert.message {
      Text(message)
    }
  }
}

// MARK: -

extension AlertManager {
  
  func present(title: String, message: String? = nil, buttons: [Alert.Button] = []) {
    let alert = Alert(title: title, message: message, buttons: buttons)
    self.present(alert)
  }
}

// MARK: -

extension View {
  
  @available(macOS 12.0, watchOS 8.0, iOS 15.0, tvOS 15.0, *)
  public func presentingAlerts(from alertManager: AlertManager) -> some View {
    return self.modifier(AlertPresenter(alertManager: alertManager))
  }
}
