/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
`MacConfigViewController` shows the configuration used by the player.
*/

import Cocoa
import AVFoundation

class MacConfigViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource,
                               CommandCellViewDelegate, EnabledItemCellViewDelegate {
    
    @IBOutlet weak var commandTableView: NSTableView!
    
    // The asset player controlling playback.
    
    var assetPlayer: AssetPlayer!
    
    // A flattened list of index paths representing the indexes into the model's properties
    // corresponding to each table view row.
    
    var configPaths: [ConfigPath] = []
    
    // Update the UI when the data model is initialized.
    
    func updateConfig() {
        
        // Force the table view to reload after we recompute the index paths.
        
        configPaths = []
        defer { commandTableView.reloadData() }
        
        guard ConfigModel.shared != nil else { return }
        
        // Create an index path for the independent configuration properties,
        // plus an index path for the group.
        
        configPaths.append(ConfigPath(group: .settings))
        configPaths.append(ConfigPath(group: .settings, index: 0))

        // Create an index path for each asset, plus an index path for the group.
        
        configPaths.append(ConfigPath(group: .assets))
        
        for assetIndex in 0..<ConfigModel.shared.assets.count {
            configPaths.append(ConfigPath(group: .assets, index: assetIndex))
        }
        
        // Create an index path for each command, plus an index path for each group.
        
        for (collectionIndex, group) in ConfigModel.shared.commandCollections.enumerated() {
            
            configPaths.append(ConfigPath(group: .commands(collectionIndex)))
            
            for commandIndex in group.commands.indices {
                
                configPaths.append(ConfigPath(group: .commands(collectionIndex), index: commandIndex))
            }
        }
    }
    
    // MARK: Table View Data Source
    
    // Data source method: number of rows.
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        return configPaths.count
    }
    
    // MARK: Table View Delegate
    
    // Delegate method: create a cell for a row.
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        // Check for a normal, non-group row.
        
        if tableColumn != nil {
            
            let itemIndex: Int = configPaths[row].index
            
            switch configPaths[row].group {
                
            case .settings:
                return cellForExternalPlayback(tableView, row: row, item: itemIndex)

            case .assets:
                return cellForAsset(tableView, row: row, item: itemIndex)
                
            case .commands(let collectionIndex):
                return cellForCommand(tableView, row: row, commands: collectionIndex, item: itemIndex)
            }
        }
        
        // Check for a group row.
            
        else {
            
            guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("GroupCell"), owner: self) as? NSTableCellView
                else { return nil }
            
            switch configPaths[row].group {
                
            case .settings:
                cell.textField?.stringValue = "Settings"
                
            case .assets:
                cell.textField?.stringValue = "Playlist"
                
            case .commands(let collectionIndex):
                cell.textField?.stringValue = ConfigModel.shared.commandCollections[collectionIndex].collectionName
            }
            
            return cell
        }
    }
    
    // Helper method to create a cell for the external playback checkbox.
    
    private func cellForExternalPlayback(_ tableView: NSTableView, row: Int, item itemIndex: Int) -> NSTableCellView? {

        guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "EnabledItemCell"),
                                            owner: self) as? MacEnabledItemCellView
            else { return nil }
        
        cell.itemNameLabel?.stringValue = "Allow External Playback"
        cell.enabledButton?.state = ConfigModel.shared.allowsExternalPlayback ? .on : .off
        cell.configPath = configPaths[row]
        cell.delegate = self
        
        return cell
    }
    
    // Helper method to create a cell for an asset-enable checkbox.
    
    private func cellForAsset(_ tableView: NSTableView, row: Int, item itemIndex: Int) -> NSTableCellView? {
        
        guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "EnabledItemCell"),
                                            owner: self) as? MacEnabledItemCellView
            else { return nil }
        
        cell.itemNameLabel?.stringValue = ConfigModel.shared.assets[itemIndex].metadata.title
        cell.enabledButton?.state = ConfigModel.shared.assets[itemIndex].shouldPlay ? .on : .off
        cell.configPath = configPaths[row]
        cell.delegate = self
        
        return cell
    }
    
    // Helper method to create a cell for a group's register/disable checkboxes.
    
    private func cellForCommand(_ tableView: NSTableView, row: Int, commands collectionIndex: Int, item itemIndex: Int) -> NSTableCellView? {
        
        guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CommandCell"),
                                            owner: self) as? MacCommandCellView
            else { return nil }
        
        cell.commandNameLabel?.stringValue = ConfigModel.shared.commandCollections[collectionIndex].commands[itemIndex].commandName
        cell.disabledButton?.state = ConfigModel.shared.commandCollections[collectionIndex].commands[itemIndex].shouldDisable ? .on : .off
        cell.registeredButton?.state = ConfigModel.shared.commandCollections[collectionIndex].commands[itemIndex].shouldRegister ? .on : .off
        cell.configPath = configPaths[row]
        cell.delegate = self
        
        return cell
    }
    
    // Table view delegate method: indicate group rows.
    
    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        return configPaths[row].index == nil
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
    
    // MARK: Actions
    
    // Action method: opt into now-playability for the app.
    
    @IBAction func optIn(_ sender: Any?) {
        
        guard assetPlayer == nil else { return }
        
        // Create the asset player, if possible.
        
        do {
            assetPlayer = try AssetPlayer()
            
            let playerLayer = AVPlayerLayer(player: assetPlayer.player)
            let playerView = MacWindowController.shared.playerViewController.view
            playerView.layer = playerLayer
            playerView.wantsLayer = true
        }
        
        // Otherwise, display an error.
        
        catch {
            NSAlert(error: error).beginSheetModal(for: view.window!)
        }
    }
    
    // Action method: opt out of now-playability.
    
    @IBAction func optOut(_ sender: Any?) {
        
        guard assetPlayer != nil else { return }
        
        assetPlayer.optOut()
        assetPlayer = nil
    }
    
}
