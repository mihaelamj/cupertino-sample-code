/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A UITableViewCell subclass for displaying a book record.
*/

import UIKit

class BookCell: UITableViewCell {

    @IBOutlet weak var title: UILabel!
    @IBOutlet weak var price: UILabel!
    @IBOutlet weak var publishDate: UILabel!
    @IBOutlet weak var abstract: UILabel!
}
