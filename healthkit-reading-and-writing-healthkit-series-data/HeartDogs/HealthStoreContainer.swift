/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A protocol for objects that access the health store.
*/

import HealthKit

protocol HealthStoreContainer {
    // A required property that contains the health store.
    var healthStore: HKHealthStore! { get set }
}
