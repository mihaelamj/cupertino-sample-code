/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A base subclass of the colors view controller containing an table view data source and an
 implementation of prepareForSegue:sender: to allow the `ColorItemViewController` to be shown.

 This view controller contains no code for implementing Peek and Pop, it exists solely to allow
 `ColorsViewControllerStoryboard` and `ColorsViewControllerCode` to contain nothing more than
 what is needed to implement Peek and Pop.
*/

import UIKit

class ColorsViewControllerBase: UITableViewController {

    let colorData = ColorData()

    // MARK: - View life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        // Register for updates when any ColorItem objects are updated or deleted.
        NotificationCenter.default.addObserver(self, selector: #selector(colorItemUpdated), name: .colorItemUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(colorItemDeleted), name: .colorItemDeleted, object: nil)
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return colorData.colors.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BasicCell", for: indexPath)

        let colorItem = colorData.colors[indexPath.row]

        cell.textLabel?.text = colorItem.name
        cell.imageView?.image = colorItem.starred ? #imageLiteral(resourceName: "StarFilled.pdf") : #imageLiteral(resourceName: "StarOutline.pdf")
        cell.imageView?.tintColor = colorItem.color

        return cell
    }

    // MARK: - Segue preparation

    /// - Tag: PrepareForSegue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let selectedTableViewCell = sender as? UITableViewCell,
            let indexPath = tableView.indexPath(for: selectedTableViewCell)
            else { preconditionFailure("Expected sender to be a valid table view cell") }

        guard let colorItemViewController = segue.destination as? ColorItemViewController
            else { preconditionFailure("Expected a ColorItemViewController") }

        // Pass over a reference to the ColorData object and the specific ColorItem being viewed.
        colorItemViewController.colorData = colorData
        colorItemViewController.colorItem = colorData.colors[indexPath.row]
    }

    // MARK: - Notification center observers

    @objc
    func colorItemUpdated(notification: Notification) {
        // As there are two instances of colorData between `ColorsViewControllerStoryboard` and
        // `ColorsViewControllerCode`, this method must only process notification callbacks when
        // the object for this notification exists in *this* view controller's colorData array.
        guard let colorItem = notification.object as? ColorItem,
            let arrayIndex = self.colorData.colors.firstIndex(of: colorItem)
            else { return }

        let indexPath = IndexPath(row: arrayIndex, section: 0)
        tableView.reloadRows(at: [ indexPath ], with: .automatic)
    }

    @objc
    func colorItemDeleted(notification: Notification) {
        // As there are two instances of colorData between `ColorsViewControllerStoryboard` and
        // `ColorsViewControllerCode`, this method must only process notification callbacks when
        // the instances of colorData match.
        if colorData !== notification.object as? ColorData { return }

        // Grab the index of the deleted object from the userInfo dictionary
        guard let userInfo = notification.userInfo,
            let arrayIndex = userInfo["index"] as? Int
            else { preconditionFailure("Expected an Int") }

        let indexPath = IndexPath(row: arrayIndex, section: 0)
        tableView.deleteRows(at: [ indexPath ], with: .automatic)
    }

}
