/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A main view controller for the sample app.
*/

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var gridView: GridView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.tapped(_:)))
        view.addGestureRecognizer(tap)
    }
    
    @objc
    func tapped(_ gesture: UIGestureRecognizer) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard
            let navController = storyboard.instantiateViewController(withIdentifier: "Options") as? UINavigationController,
            let optionsViewController = navController.topViewController as? OptionsViewController
        else { return }
        
        optionsViewController.options = gridView.options
        optionsViewController.updateOption = { key, value in
            self.gridView.options[key] = value
        }
        self.show(navController, sender: self)
    }
}
