/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
GoatTableViewCell defines an IBOutlet to a UILabel which will render on the table cells of the sample app.
*/
import UIKit

class GoatTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
    }
    
}
