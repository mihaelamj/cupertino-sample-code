/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
GoatTableViewController serves as the View Controller for the sample app's TableView.
     GoatTableViewController is responsible for utilizing MobileAgents for the sorting
     and adding functionality provided by the sample app.
*/

import UIKit

class GoatTableViewController: UITableViewController {
    
    var goatList = [Goat]()
    var goatListStop = GoatListStop()
    
    @IBAction func addGoat(_ sender: Any) {
        // Create edit and display agents to add a name to the list of goats
        // and display the new list on the UI.
        
        let editAgent = EditAgent(goatListStop: self.goatListStop)
        let displayAgent = DisplayAgent(goatListStop: self.goatListStop, goatTableViewController: self)
        
        let editStop = BackgroundProcessingStop()
        let displayStop = DisplayStop()
        
        DispatchQueue.main.async {
            editAgent.activateAtStop(stop: editStop, finalDestination: editStop)
            displayAgent.activateAtStop(stop: displayStop, finalDestination: displayStop)
        }
    }
    
    @IBAction func sortGoats(_ sender: Any) {
        // Create sort and display agents to sort the list of goats
        // and display the new list on the UI.
        let sortAgent = SortAgent(goatListStop: self.goatListStop)
        let displayAgent = DisplayAgent(goatListStop: self.goatListStop, goatTableViewController: self)
        
        let sortStop = BackgroundProcessingStop()
        let displayStop = DisplayStop()
        
        sortAgent.activateAtStop(stop: sortStop, finalDestination: sortStop)
        displayAgent.activateAtStop(stop: displayStop, finalDestination: displayStop)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        goatListStop.populateGoatList(goats: setupInitialGoatList())
        let displayAgent = DisplayAgent(goatListStop: self.goatListStop, goatTableViewController: self)
        let displayStop = DisplayStop()
        displayAgent.activateAtStop(stop: displayStop, finalDestination: displayStop)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return goatList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellIdentifier = "goatTableViewCell"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? GoatTableViewCell else {
            fatalError("Unable to dequeue a reusable cell with identifier " + cellIdentifier)
        }
        
        let goat = goatList[indexPath.row]
        cell.nameLabel.text = goat.name
        
        return cell
    }
    
    private func setupInitialGoatList() -> [Goat] {
        
        // Generate 100 Goats and use them as the initial view for the UI.
        var initialGoats = [Goat]()
        
        for goatNumber in 1...20 {
            guard let goat = Goat(name: GoatNames.generateGoatName()) else {
                fatalError("Unable to create initial goat " + String(goatNumber))
            }
            
            initialGoats.append(goat)
        }
        return initialGoats
    }
    
}
