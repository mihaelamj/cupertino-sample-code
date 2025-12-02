/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view for hosting activity view controllers in SwiftUI.
*/

import SwiftUI
import UIKit
import os.log

private let log = Logger(subsystem: Constants.logSubsystem, category: String(describing: ActivityViewController.self))

enum ActivityViewControllerConfiguration {
  
  case activityItems([Any], applicationActivities: [UIActivity]? = nil)
  case activityItemsConfiguration(UIActivityItemsConfigurationReading)
  
  func makeController() -> UIActivityViewController {
    switch self {
    case .activityItems(let items, let applicationActivities):
      return UIActivityViewController(activityItems: items, applicationActivities: applicationActivities)
    case .activityItemsConfiguration(let configuration):
      return UIActivityViewController(activityItemsConfiguration: configuration)
    }
  }
}

// MARK: -

/// A SwiftUI ``Button`` that presents a ``UIActivityViewController``
struct ActivityViewButton: View {
  
  @State private var isPresented: Bool = false
  
  let configuration: () -> ActivityViewControllerConfiguration
  
  var body: some View {
    Button {
      self.isPresented = true
    } label: {
      Image(systemName: "square.and.arrow.up")
    }
    .popover(isPresented: $isPresented) {
      ActivityViewController(configuration: configuration)
    }
  }
}

// MARK: -

/// A SwiftUI wrapper around a ``UIActivityViewController``
private struct ActivityViewController: UIViewControllerRepresentable {
  
  let configuration: () -> ActivityViewControllerConfiguration
  
  func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
    
    let config = configuration()
    let controller = config.makeController()
    log.log("making UIActivityViewController with config: \(String(describing: config))")
    
    controller.completionWithItemsHandler = { (activity, completed, returned, error) in
      if let error = error {
        log.error("UIActivityViewController finished with error: \(String(describing: error))")
      } else {
        let type = activity?.rawValue ?? "nil"
        let items = String(String(describing: returned))
        log.log("UIActivityViewController finished with activityType: \(type), completed: \(completed), returnedItems: \(items))")
      }
    }
    return controller
  }
  
  func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) { }
}
