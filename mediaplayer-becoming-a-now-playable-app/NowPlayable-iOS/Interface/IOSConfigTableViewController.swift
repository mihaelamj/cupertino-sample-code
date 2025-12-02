/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
`IOSConfigTableViewController` provides content for the table view showing the player configuration.
*/

import UIKit

class IOSConfigTableViewController: UITableViewController, CommandCellViewDelegate, EnabledItemCellViewDelegate {
    
    // An array with a ConfigPath for each section of the table view.
    
    var sectionPaths: [ConfigPath] = []
    
    // Update the UI when the data model is initialized.
    
    func updateConfig() {
        
        sectionPaths = []
        defer { tableView.reloadData() }
        
        guard ConfigModel.shared != nil else { return }
        
        // Add a ConfigPath for the settings and assets, plus one for each
        // command collection.
        
        sectionPaths.append(ConfigPath(group: .settings))
        sectionPaths.append(ConfigPath(group: .assets))
        
        for collectionIndex in ConfigModel.shared.commandCollections.indices {
            sectionPaths.append(ConfigPath(group: .commands(collectionIndex)))
        }
    }
    
    // MARK: Table View Data Source
    
    // Data source method: number of sections.
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionPaths.count
    }
    
    // Data source method: number of rows in each section.
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch sectionPaths[section].group {
            
        case .settings: // Parameter settings section has 1 row.
            return 1
            
        case .assets: // One row for each asset
            return ConfigModel.shared.assets.count
            
        case .commands(let collectionIndex): // One row for each command
            return ConfigModel.shared.commandCollections[collectionIndex].commands.count
        }
    }
    
    // Data source method: title for each section.
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        switch sectionPaths[section].group {
            
        case .settings: // Parameter settings section title
            return "Settings"
            
        case .assets: // Assets section title
            return "Playlist"
            
        case .commands(let collectionIndex): // Command collection titles
            return ConfigModel.shared.commandCollections[collectionIndex].collectionName
        }
    }
    
    // Data source method: the cell for each row
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let itemIndex = indexPath.item
        
        switch sectionPaths[indexPath.section].group {
            
        case .settings: // external playback parameter row
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "EnabledItemCell") as? IOSEnabledItemCell
                else { fatalError("EnabledItemCell must be a registered cell") }
            
            cell.itemNameLabel.text = "Allow External Playback"
            cell.enabledButton.isOn = ConfigModel.shared.allowsExternalPlayback
            cell.configPath = ConfigPath(group: .settings, index: itemIndex)
            cell.delegate = self
            
            return cell
            
        case .assets: // an asset row
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "EnabledItemCell") as? IOSEnabledItemCell
                else { fatalError("EnabledItemCell must be a registered cell") }
            
            cell.itemNameLabel.text = ConfigModel.shared.assets[itemIndex].metadata.title
            cell.enabledButton.isOn = ConfigModel.shared.assets[itemIndex].shouldPlay
            cell.configPath = ConfigPath(group: .assets, index: itemIndex)
            cell.delegate = self
            
            return cell
            
        case .commands(let collectionIndex): // a command row
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "CommandCell") as? IOSCommandCell
                else { fatalError("CommandCell must be a registered cell") }
            
            cell.commandNameLabel.text = ConfigModel.shared.commandCollections[collectionIndex].commands[itemIndex].commandName
            cell.disabledButton.isOn = ConfigModel.shared.commandCollections[collectionIndex].commands[itemIndex].shouldDisable
            cell.registeredButton.isOn = ConfigModel.shared.commandCollections[collectionIndex].commands[itemIndex].shouldRegister
            cell.configPath = ConfigPath(group: .commands(collectionIndex), index: itemIndex)
            cell.delegate = self
            
            return cell
        }
    }
    
    // MARK: Cell Delegate
    
    // Delegate method: handle a change in state of an row that can be enabled.
    
    func updateEnabledItemState(_ configPath: ConfigPath, enabled shouldEnable: Bool) {
        
        switch configPath.group {
            
        case .settings:
            ConfigModel.shared.allowsExternalPlayback = shouldEnable
            
        case .assets:
            ConfigModel.shared.assets[configPath.index].shouldPlay = shouldEnable
            
        case .commands:
            break
        }
    }
    
    // Delegate method: handle a change in disabled state of a command row.
    
    func updateCommandDisabledState(_ configPath: ConfigPath, disabled shouldDisable: Bool) {
        
        let collectionIndex: Int = configPath.collectionIndex
        let commandIndex: Int = configPath.index
        
        ConfigModel.shared.commandCollections[collectionIndex].commands[commandIndex].shouldDisable = shouldDisable
    }
    
    // Delegate method: handle a change in registered state of a command row.
    
    func updateCommandRegisteredState(_ configPath: ConfigPath, registered shouldRegister: Bool) {
        
        let collectionIndex: Int = configPath.collectionIndex
        let commandIndex: Int = configPath.index
        
        ConfigModel.shared.commandCollections[collectionIndex].commands[commandIndex].shouldRegister = shouldRegister
    }
    
}
