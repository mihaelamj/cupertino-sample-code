/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The network configuration constants.
*/

import WiFiAware
import Network

let appPerformanceMode: WAPerformanceMode = .realtime

let appAccessCategory: WAAccessCategory = .interactiveVideo
let appServiceClass: NWParameters.ServiceClass = appAccessCategory.serviceClass
