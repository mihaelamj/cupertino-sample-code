/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model generated from random data to display in the table view.
*/

import Foundation

struct FillerModel {
    
    let title: String
    let descriptionText: String
    
    static func generateFillerItems(count: Int) -> [FillerModel] {
        var items = [FillerModel]()
        var counter = 0
        repeat {
            items.append(generateFillerItem())
            counter += 1
        } while counter < count
        return items
    }
    
    static private func newlineSeparatedStrings(from filePath: String) -> [String] {
        do {
            let stringRaw = try String(contentsOfFile: filePath)
            let titles = stringRaw.components(separatedBy: "\n")
            return titles.filter { (title) -> Bool in
                return !title.isEmpty
            }
        } catch {
            return ["<unknown>"]
        }
    }
    
    static private var titles: [String] = {
        guard let filePath = Bundle.main.path(forResource: "lipsum_titles", ofType: "txt") else { return ["Title"] }
        return newlineSeparatedStrings(from: filePath)
    }()
    
    static private var descriptions: [String] = {
        guard let filePath = Bundle.main.path(forResource: "lipsum_descriptions", ofType: "txt") else { return ["Description"] }
        return newlineSeparatedStrings(from: filePath)
    }()
    
    static private func randomNumber(upperLimit: Int) -> Int {
        return Int(arc4random() % UInt32(upperLimit))
    }
    
    static private func randomText(from array: [String]) -> String {
        return array[randomNumber(upperLimit: array.count)]
    }
    
    static private func generateFillerItem() -> FillerModel {
        let title = randomText(from: titles)
        let descriptionText = randomText(from: descriptions)
        return FillerModel(title: title, descriptionText: descriptionText)
    }
}
