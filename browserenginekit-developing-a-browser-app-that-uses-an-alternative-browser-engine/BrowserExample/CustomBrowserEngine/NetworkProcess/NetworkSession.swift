/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A class that wraps URL session tasks and sends their results as XPC replies.
*/

import Foundation
import XPC
import os.log

private let log = Logger(subsystem: Constants.logSubsystem, category: String(describing: NetworkSession.self))

/// A wrapper around a URLSession that performs tasks and sends responses back over an XPC connection
///
public class NetworkSession: NSObject {
    
  private var urlSession: URLSession!
  
  public override init() {
    super.init()
    let config: URLSessionConfiguration = .default
    self.urlSession = URLSession(configuration: config, delegate: self, delegateQueue: .main)
  }
  
  public func perform(task: NetworkExtensionTask, with event: xpc_object_t, for connection: xpc_connection_t) {
    switch task {
    case .data(let url):
      log.log("performing data task with \(url.absoluteString) for \(String(describing: connection))")
      
      var request = URLRequest(url: url)
      request.timeoutInterval = 15
      
      let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
        log.log("finished data task with \(String(describing: response)), \(String(describing: error))")
        self?.dataTaskCompletionHandler(for: connection, with: event, data: data, response: response, error: error)
      }
      
      task.resume()
    default:
      log.error("\(#function): unsupported task type")
    }
  }
  
  private func dataTaskCompletionHandler(for connection: xpc_connection_t,
                                         with event: xpc_object_t,
                                         data: Data?,
                                         response: URLResponse?, error: Error?) {
    do {
      let result = NetworkTaskResult(response: response as? HTTPURLResponse, data: data, error: error)
      try connection.send(result, replyingTo: event)
    } catch let error {
      log.error("failed to send reply for data task to \(String(describing: connection)): \(String(describing: error))")
    }
  }
}

// MARK: -

extension NetworkSession: URLSessionDelegate {
  
  public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: (any Error)?) {
    log.error("url session did become invalid with error: \(String(describing: error))")
  }
}
