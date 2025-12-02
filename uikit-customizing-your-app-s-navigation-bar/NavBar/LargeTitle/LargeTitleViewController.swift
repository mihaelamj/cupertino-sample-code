/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Demonstrates applying a large title to the UINavigationBar.
*/

import UIKit

class LargeTitleViewController: UITableViewController {

	/// The data source is an array of city names, populated from Cities.json.
	let dataSource = CitiesDataSource()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		tableView.dataSource = dataSource
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        var subtitleConfiguration = UIButton.Configuration.plain()
        subtitleConfiguration.title = "Subtitle Button"
        subtitleConfiguration.baseForegroundColor = .systemBlue
        
        let subtitleButton = UIButton(configuration: subtitleConfiguration)
        navigationItem.largeSubtitleView = subtitleButton
    }
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "pushSegue" {
			// This segue pushes a detailed view controller.
			if let indexPath = self.tableView.indexPathForSelectedRow {
				segue.destination.title = dataSource.city(index: indexPath.row)
			}
            
            // Don't display a large title for the destination view controller.
            segue.destination.navigationItem.largeTitleDisplayMode = .never
		} else {
			// This segue pops back up the navigation stack.
		}
	}

}
