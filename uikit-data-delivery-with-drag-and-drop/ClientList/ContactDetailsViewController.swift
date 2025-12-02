/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Contact Details View.
*/

import UIKit

class ContactDetailsViewController: UIViewController {
	var contactCard: ContactCard!

	@IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var contactPhoto: UIImageView!

	// MARK: - View Controller Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

		title = contactCard.name

		navigationItem.largeTitleDisplayMode = UINavigationItem.LargeTitleDisplayMode.never

		nameLabel.text = contactCard.name
        phoneLabel.text = contactCard.phoneNumber
        contactPhoto.image = contactCard.photo
    }

}
