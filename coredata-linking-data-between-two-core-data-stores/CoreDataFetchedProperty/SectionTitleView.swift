/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A UIView subclass that manages the section title for the main table view.
*/

import UIKit

class SectionTitleView: UIView {
    @IBOutlet weak var title: UILabel!
    var section: Int = -1
}
