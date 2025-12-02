/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A collection of helper extensions for the app.
*/
import Foundation
import UIKit

extension String {
    // Turns an emoji into an image.
    func image() -> UIImage? {
        let size = CGSize(width: 30, height: 30)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.clear.set()
        let rect = CGRect(origin: .zero, size: size)
        UIRectFill(CGRect(origin: .zero, size: size))
        (self as AnyObject).draw(in: rect, withAttributes: [.font: UIFont.systemFont(ofSize: 15)])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

extension UILabel {
    // Turns a label into an image.
    func image() -> UIImage? {
        textColor = .cornflowerBlue
        numberOfLines = 0
        adjustsFontSizeToFitWidth = true
        minimumScaleFactor = 0.5
        sizeToFit()
        UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

var formatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE"
    return formatter
}

extension UIColor {
    static var cornflowerBlue: UIColor {
        return UIColor(displayP3Red: 100.0 / 255.0, green: 149.0 / 255.0, blue: 237.0 / 255.0, alpha: 1.0)
    }
}
