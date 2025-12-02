/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The GoatListReceivable protocol defines a goatList variable for each eligible agent.
*/

import Foundation

protocol GoatListReceivable {
    var goatList: [Goat] { get set }
}
