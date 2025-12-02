/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The meter value lookup table.
*/

import Foundation

struct MeterTable {

    // The decibel value of the minimum displayed amplitude.
    private let kMinDB: Float = -60.0

    // The table needs to be large enough so that there are no large gaps in the response.
    private let tableSize = 300
    
    private let scaleFactor: Float
    private var meterTable = [Float]()
    
    init() {
        let dbResolution = kMinDB / Float(tableSize - 1)
        scaleFactor = 1.0 / dbResolution

        // This controls the curvature of the response.
        // 2.0 is the square root, 3.0 is the cube root.
        let root: Float = 2.0

        let rroot = 1.0 / root
        let minAmp = dbToAmp(dBValue: kMinDB)
        let ampRange = 1.0 - minAmp
        let invAmpRange = 1.0 / ampRange
        
        for index in 0..<tableSize {
            let decibels = Float(index) * dbResolution
            let amp = dbToAmp(dBValue: decibels)
            let adjAmp = (amp - minAmp) * invAmpRange
            meterTable.append(powf(adjAmp, rroot))
        }
    }
    
    private func dbToAmp(dBValue: Float) -> Float {
        return powf(10.0, 0.05 * dBValue)
    }
    
    func valueForPower(_ power: Float) -> Float {
        if power < kMinDB {
            return 0.0
        } else if power >= 0.0 {
            return 1.0
        } else {
            let index = Int(power) * Int(scaleFactor)
            return meterTable[index]
        }
    }
}
