/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A table view cell used to display a feed entry from the database.
*/

import UIKit

class FeedEntryTableViewCell: UITableViewCell {
    @IBOutlet private var colorView: ColorView!

    var feedEntry: FeedEntry? {
        didSet {
            updateCell()
        }
    }
    
    private func updateCell() {
        guard let firstColor = feedEntry?.firstColor,
            let secondColor = feedEntry?.secondColor,
            let gradientDirection = feedEntry?.gradientDirection,
            let timestamp = feedEntry?.timestamp else {
                return
            }

        colorView.parameters = ColorView.Parameters(firstColor: UIColor(firstColor),
                                                    secondColor: UIColor(secondColor),
                                                    gradientDirection: gradientDirection,
                                                    text: timestamp.shortDescription)
    }
}

extension UIColor {
    convenience init (_ color: Color) {
        self.init(red: CGFloat(color.red), green: CGFloat(color.green), blue: CGFloat(color.blue), alpha: 1.0)
    }
}

extension Date {
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d h:mma"
        return formatter
    }()
    
    var shortDescription: String {
        return Date.shortDateFormatter.string(from: self)
    }
}
