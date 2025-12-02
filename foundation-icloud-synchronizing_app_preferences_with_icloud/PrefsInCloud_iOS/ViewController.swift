/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main view controller for this app.
*/

import UIKit

class ViewController: UIViewController {
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
        // Default color background locally is "white".
        UserDefaults.standard.register(defaults: [gBackgroundColorKey: ColorIndex.white.rawValue])

        // Make sure we're showing the latest color.
        updateUserInterface()
		
        // Setup out key value store.
        prepareKeyValueStoreForUse()
    }

    // MARK: - Updates
    
    func updateUserInterface() {
        if let valideColorIndex = ColorIndex(rawValue: chosenColorValue) {
            view.backgroundColor = valideColorIndex.color
        }
    }

    // MARK: - Segue Support
    
    @IBAction func unwindToMenu(segue: UIStoryboardSegue) {
        if let colorsTableViewController = segue.source as? ColorsTableViewController,
            let row = colorsTableViewController.selectedIndexPath?.row, ColorIndex(rawValue: row) != nil {
            chosenColorValue = row
        }
    }
	
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Pass on the available background colors to the table view
        guard let navController = segue.destination as? UINavigationController else { return }
        guard let destinationVC = navController.topViewController as? ColorsTableViewController else { return }
        
        destinationVC.colorStrings = [ColorIndex.white.name, ColorIndex.red.name,
                                      ColorIndex.green.name, ColorIndex.yellow.name]
        destinationVC.selectedIndexPath = IndexPath(row: chosenColorValue, section: 0)
    }
	
}

