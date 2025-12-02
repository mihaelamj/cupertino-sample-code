/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Menu construction extensions for this sample.
*/

import UIKit

class MenuController {
    
    // Property list keys to access UICommand/UIKeyCommand values.
    struct CommandPListKeys {
        static let ArrowsKeyIdentifier = "id" // Arrow command-keys
        static let CitiesKeyIdentifier = "city" // City command-keys
        static let TownsIdentifierKey = "town" // Town commands
        static let StylesIdentifierKey = "font" // Font style commands
        static let ToolsIdentifierKey = "tool" // Tool commands
    }
    
    // The property list value for the specific disabled menu command under the "Tools" menu (pencil with slash).
    static let disabledCommand = "disabledCommand"
    
    enum ToolType: Int {
        case lasso = 0
        case pencil = 1
        case scissors = 2
        case rotate = 3
    }

    // MARK: - Menu Titles

    enum Cities: String, CaseIterable {
        case cupertino
        case sanFrancisco
        case sanJose
        case paris
        case rome
        func localizedString() -> String {
            return NSLocalizedString("\(self.rawValue)", comment: "")
        }
    }

    enum Towns: String, CaseIterable {
        case bigOakFlat
        case groveland
        case sonora
        func localizedString() -> String {
            return NSLocalizedString("\(self.rawValue)", comment: "")
        }
    }

    enum Tools: String, CaseIterable {
        case lasso
        case pencil
        case scissors
        case rotate
        func localizedString() -> String {
            return NSLocalizedString("\(self.rawValue)", comment: "")
        }
    }

    enum FontStyle: String, CaseIterable {
        case plain
        case bold
        case italic
        case underline
        func localizedString() -> String {
            return NSLocalizedString("\(self.rawValue)", comment: "")
        }
    }

    enum Arrows: String, CaseIterable {
        case rightArrow
        case leftArrow
        case upArrow
        case downArrow
        func localizedString() -> String {
            return NSLocalizedString("\(self.rawValue)", comment: "")
        }
    }
    
    init(with builder: UIMenuBuilder) {
        // First remove the menus in the menu bar that aren't needed, in this case the Format menu.
        builder.remove(menu: .format)
        
        // Create and add Open menu command at the beginning of the File menu.
        builder.insertChild(MenuController.openMenu(), atStartOfMenu: .file)
    
        // Create and add New menu command at the beginning of the File menu.
        builder.insertChild(MenuController.newMenu(), atStartOfMenu: .file)
        
        // Add the rest of the menus to the menu bar.

        // Add the Cities menu.
        builder.insertSibling(MenuController.citiesMenu(), beforeMenu: .window)
        
        // Add the Navigation menu.
        builder.insertSibling(MenuController.navigationMenu(), beforeMenu: .window)
        
        // Add the Style menu.
        builder.insertSibling(MenuController.fontStyleMenu(), beforeMenu: .window)
        
        // Add the Tools menu.
        builder.insertSibling(MenuController.toolsMenu(), beforeMenu: .window)
        
        // This example will show how to add a Copy as HTML command, right after Copy.
        addCopyCommand(builder)

        // Add Rename command (cmd-R), right after Select All.
        addRenameCommand(builder)
    }
        
    class func openMenu() -> UIMenu {
        let openCommand =
            UIKeyCommand(title: NSLocalizedString("OpenTitle", comment: ""),
                         image: nil,
                         action: #selector(AppDelegate.openAction),
                         input: "o",
                         modifierFlags: .command)
        let openMenu =
            UIMenu(title: "",
                   image: nil,
                   identifier: .openMenu,
                   options: .displayInline,
                   children: [openCommand])
        return openMenu
    }
    
    class func newMenu() -> UIMenu {
        /** Install Command-N and Command-Shift-N UIKeyCommands.
         
            Note: The discoverabilityTitle is used to display its command in the overlay window on the iPad
            when the command-key is held down and as the tooltip for the menu item.
         
            Note: If building and testing on the iPad Simulator make sure to select:
                "Hardware -> Keyboard -> Send Keyboard Shortcuts to Device".
         */
        
        // Create New Date menu key command.
        let newDateCommand =
            UIKeyCommand(title: NSLocalizedString("DateItemTitle", comment: ""),
                         image: nil,
                         action: #selector(PrimaryViewController.newAction(_:)),
                         input: "n",
                         modifierFlags: .command)
        // Add the discoverability title used for accessibility and when this key command is displayed in discoverability on the HUD.
        newDateCommand.discoverabilityTitle = NSLocalizedString("Command_N_DiscoveryTitle", comment: "")

        // Create the New Text menu command.
        let newTextCommand =
            UIKeyCommand(title: NSLocalizedString("TextItemTitle", comment: ""),
                         image: nil,
                         action: #selector(PrimaryViewController.newAction(_:)),
                         input: "n",
                         modifierFlags: [.command, .shift],
                         propertyList: ["Action": "NewText"])
        // Add the discoverability title used for accessibility and when this key command is displayed in discoverability on the HUD.
        newTextCommand.discoverabilityTitle = NSLocalizedString("Command_Shift_N_DiscoveryTitle", comment: "")
        
        // Return the New hierarchical menu.
        return UIMenu(title: NSLocalizedString("NewCommandTitle", comment: ""),
                      image: nil,
                      identifier: .newMenu,
                      options: .destructive,
                      children: [newDateCommand, newTextCommand])
    }
    
    class func citiesMenu() -> UIMenu {
        // Create the Cities menu group.
        let cities = Cities.allCases
        let cityChildrenCommands = zip(cities, 0...).map { (city, index) in
            UIKeyCommand(title: city.localizedString(),
                         image: nil,
                         action: #selector(AppDelegate.citiesMenuAction(_:)), // AppDelegare responds to this key command.
                         input: String(index),
                         modifierFlags: .command,
                         propertyList: [CommandPListKeys.CitiesKeyIdentifier: city.rawValue])
        }
        let citiesMenuGroup = UIMenu(title: "",
                                     image: nil,
                                     identifier: .citiesGroupMenu,
                                     options: .displayInline,
                                     children: cityChildrenCommands)
        
        // Create the Towns menu group.
        let towns = Towns.allCases
        let childrenCommands = towns.map { town in
            UICommand(title: town.localizedString(),
                      image: nil,
                      action: #selector(AppDelegate.townsMenuAction(_:)), // AppDelegare responds to this UICommand.
                      propertyList: [CommandPListKeys.TownsIdentifierKey: town.rawValue])
        }
        let townsMenuGroup = UIMenu(title: "",
                                    image: nil,
                                    identifier: .townsGroupMenu,
                                    options: .displayInline,
                                    children: childrenCommands)
        
        return UIMenu(title: NSLocalizedString("CitiesTitle", comment: ""),
                      image: nil,
                      identifier: .citiesMenu,
                      options: [],
                      children: [citiesMenuGroup, townsMenuGroup])
    }
 
    class func navigationMenu() -> UIMenu {
        let keyCommands = [ UIKeyCommand.inputRightArrow,
                            UIKeyCommand.inputLeftArrow,
                            UIKeyCommand.inputUpArrow,
                            UIKeyCommand.inputDownArrow ]
        let arrows = Arrows.allCases
        
        let arrowKeyChildrenCommands = zip(keyCommands, arrows).map { (command, arrow) in
            UIKeyCommand(title: arrow.localizedString(),
                         image: nil,
                         action: #selector(AppDelegate.navigationMenuAction(_:)),
                         input: command,
                         modifierFlags: .command,
                         propertyList: [CommandPListKeys.ArrowsKeyIdentifier: arrow.rawValue])
        }
        
        let arrowKeysGroup = UIMenu(title: "",
                      image: nil,
                      identifier: .arrowsMenu,
                      options: .displayInline,
                      children: arrowKeyChildrenCommands)
        
        return UIMenu(title: NSLocalizedString("NavigationTitle", comment: ""),
                      image: nil,
                      identifier: .navMenu,
                      options: [],
                      children: [arrowKeysGroup])
    }
    
    class func fontStyleMenu() -> UIMenu {
        let styleChildrenCommands = FontStyle.allCases.map { style in
            UICommand(title: style.localizedString(),
                      image: nil,
                      action: #selector(AppDelegate.fontStyleAction(_:)),
                      propertyList: [CommandPListKeys.StylesIdentifierKey: style.rawValue],
                      alternates: [])
        }
        
        return UIMenu(title: NSLocalizedString("StyleTitle", comment: ""),
                      image: nil,
                      identifier: .styleMenu,
                      options: [],
                      children: styleChildrenCommands)
    }
    
    class func toolsMenu() -> UIMenu {
        let lassoCommand = UICommand(title: Tools.lasso.localizedString(),
                                     image: UIImage(systemName: "lasso"),
                                     action: #selector(AppDelegate.toolsMenuAction(_:)),
                                     propertyList: [CommandPListKeys.ToolsIdentifierKey: ToolType.lasso.rawValue])
        
        let scissorsCommand = UICommand(title: Tools.scissors.localizedString(),
                                        image: UIImage(systemName: "scissors"),
                                        action: #selector(AppDelegate.toolsMenuAction(_:)),
                                        propertyList: [CommandPListKeys.ToolsIdentifierKey: ToolType.scissors.rawValue])
        
        let rotateCommand = UICommand(title: Tools.rotate.localizedString(),
                                      image: UIImage(systemName: "rotate.right"),
                                      action: #selector(AppDelegate.toolsMenuAction(_:)),
                                      propertyList: [CommandPListKeys.ToolsIdentifierKey: ToolType.rotate.rawValue])
        
        let pencilCommand = UICommand(title: Tools.pencil.localizedString(),
                                      image: UIImage(systemName: "pencil"),
                                      action: #selector(AppDelegate.toolsMenuAction(_:)),
                                      propertyList: [CommandPListKeys.ToolsIdentifierKey: ToolType.pencil.rawValue])

        // Note the following command is to be disabled, to show how to change a command's attributes.
        let disabledCommand = UICommand(title: Tools.pencil.localizedString(),
                                        image: UIImage(systemName: "pencil.slash"),
                                        action: #selector(AppDelegate.disabledMenuAction(_:)),
                                        propertyList: MenuController.disabledCommand)
        
        return UIMenu(title: NSLocalizedString("ToolsTitle", comment: ""),
                      image: nil,
                      identifier: .toolsMenu,
                      options: [],
                      children: [lassoCommand, scissorsCommand, rotateCommand, pencilCommand, disabledCommand])
    }
    
    // Insert the Copy as HTML menu item after Copy.
    func addCopyCommand(_ builder: UIMenuBuilder) {
        
        builder.replaceChildren(ofMenu: .standardEdit) { (oldChildren) -> [UIMenuElement] in
            // Find the index of Paste menu element.
            var indexOfPaste = 0
            for (index, menuElement) in oldChildren.enumerated() {
                if let keyCommand = menuElement as? UIKeyCommand {
                    let action = keyCommand.action
                    
                    if action == #selector(UIResponderStandardEditActions.copy(_:)) {
                        indexOfPaste = index
                        break
                    }
                }
            }
            // Create a Copy HTML key command.
            let copyHTMLCommand =
                UIKeyCommand(title: NSLocalizedString("copyashtml", comment: ""),
                             action: #selector(PrimaryViewController.copyHTMLAction),
                             input: "c",
                             modifierFlags: [.control, .command],
                             propertyList: [PrimaryViewController.CopyHTMLKey: PrimaryViewController.copyHTMLValue])
            
            // Insert Copy HTML before the Paste menu element, if found;
            // otherwise, insert Copy HTML at the beginning of the array.
            var newChildren = oldChildren
            newChildren.insert(copyHTMLCommand, at: indexOfPaste + 1)
            
            return newChildren
        }
    }
    
    // Insert the Rename menu item after Select All.
    func addRenameCommand(_ builder: UIMenuBuilder) {

        builder.replaceChildren(ofMenu: .standardEdit) { (oldChildren) -> [UIMenuElement] in
            // Find the index of the Select All menu element.
            var indexOfPaste = 0
            for (index, menuElement) in oldChildren.enumerated() {
                if let keyCommand = menuElement as? UIKeyCommand {
                    let action = keyCommand.action
                    
                    if action == #selector(UIResponderStandardEditActions.selectAll(_:)) {
                        indexOfPaste = index
                        break
                    }
                }
            }
            // Create a Rename key command.
            let renameKeyCommand = UIKeyCommand(title: NSLocalizedString("rename", comment: ""),
                                                action: #selector(PrimaryViewController.renameAction),
                                                input: "r",
                                                modifierFlags: [.command])
            
            // Insert Rename before the Select All menu element, if found;
            // otherwise, insert Rename at the beginning of the array.
            var newChildren = oldChildren
            newChildren.insert(renameKeyCommand, at: indexOfPaste + 1)
            
            return newChildren
        }
    }
    
}

extension UIMenu.Identifier {
    static var newMenu: UIMenu.Identifier { UIMenu.Identifier("com.example.apple-samplecode.menus.newMenu") }
    
    static var openMenu: UIMenu.Identifier { UIMenu.Identifier("com.example.apple-samplecode.menus.openMenu") }
   
    static var citiesMenu: UIMenu.Identifier { UIMenu.Identifier("com.example.apple-samplecode.menus.citiesMenu") }
    static var citiesGroupMenu: UIMenu.Identifier { UIMenu.Identifier("com.example.apple-samplecode.menus.citiesSubMenu") }
    static var townsGroupMenu: UIMenu.Identifier { UIMenu.Identifier("com.example.apple-samplecode.menus.townsSubMenu") }
    
    static var navMenu: UIMenu.Identifier { UIMenu.Identifier("com.example.apple-samplecode.menus.navigationMenu") }
    static var arrowsMenu: UIMenu.Identifier { UIMenu.Identifier("com.example.apple-samplecode.menus.arrowKeysSubMenu") }
    static var styleMenu: UIMenu.Identifier { UIMenu.Identifier("com.example.apple-samplecode.menus.fontStylesMenu") }
    static var toolsMenu: UIMenu.Identifier { UIMenu.Identifier("com.example.apple-samplecode.menus.toolsMenu") }
}
