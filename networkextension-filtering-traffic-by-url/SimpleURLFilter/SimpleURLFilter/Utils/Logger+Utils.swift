/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension to Logger
 The `static func createLogger(for atype: Any.Type) -> Logger` is added to provide a convenient
 way to create a Logger instance whose subsystem and category are populated, given a Type for
 which the logger is intended to be used.
*/

import OSLog

extension Logger {
    static func createLogger(for atype: Any) -> Logger {
        let bundle = Bundle.main
        let appName = bundle.infoDictionary?["CFBundleDisplayName"] as? String ?? bundle.infoDictionary?["CFBundleName"] as? String ?? "<unknown>"
        let typeName = String(describing: atype)
        return Logger(subsystem: appName, category: typeName)
    }
}
