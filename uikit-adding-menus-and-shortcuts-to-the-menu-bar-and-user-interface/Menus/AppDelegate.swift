/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main UIApplicationDelegate to this sample.
*/

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
        
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        /** The registration domain is volatile.  It doesn't persist across launches.
            Register the defaults at each launch; otherwise the system's default values are obtained when accessing
            the values of preferences for the user (via the Settings app) or this app (via set*:forKey:).
            Registering a set of default values ensures that this app always has a known good set of values to operate on.
        */
        registerDefaultsFromSettingsBundle()
        
        return true
    }

    // MARK: - Menus
    
    var menuController: MenuController!
    
    /** Add the various menus to the menu bar.
        The system only asks UIApplication and UIApplicationDelegate for the main menus.
        Main menus appear regardless of who is in the responder chain.
    
        Note: These menus and menu commands are localized to Chinese (Simplified) in this sample.
        To change the app to run in Chinese, refer to Xcode Help on Testing localizations:
            https://help.apple.com/xcode/mac/current/#/dev499a9529e
    */
    override func buildMenu(with builder: UIMenuBuilder) {
        /** First check if the builder object is using the main system menu, which is the main menu bar.
            To check if the builder is for a contextual menu, check for: UIMenuSystem.context.
         */
        if builder.system == .main {
            menuController = MenuController(with: builder)
            
            // Start off with just plain font style.
            fontMenuStyleStates.insert(MenuController.FontStyle.plain.rawValue)
        }
    }
    
    // The font style menu item check marks used in the Style menu.
    var fontMenuStyleStates = Set<String>()
    
    // Update the state of a given command by adjusting the Style menu.
    // Note: Only command groups that are added will be called to validate.
    override func validate(_ command: UICommand) {
        // Obtain the plist of the incoming command.
 
        if let fontStyleDict = command.propertyList as? [String: String] {
            // Check if the command comes from the Style menu.
            if let fontStyle = fontStyleDict[MenuController.CommandPListKeys.StylesIdentifierKey] {
                // Update the Style menu command state (checked or unchecked).
                command.state = fontMenuStyleStates.contains(fontStyle) ? .on : .off
            }
        } else {
            // Validate the disabled command. This keeps the menu item disabled.
            if let commandPlistString = command.propertyList as? String {
                if commandPlistString == MenuController.disabledCommand {
                    command.attributes = .disabled
                }
            }
        }
    }
            
    // MARK: - Menu Actions

    @objc
    // User chose Open from the File menu.
    func openAction(_ sender: AnyObject) {
        Swift.debugPrint(#function)
    }
    
    @objc
    // User chose an item from the menu grouping of city titles.
    func citiesMenuAction(_ sender: AnyObject) {
        if let keyCommand = sender as? UIKeyCommand {
            if let identifier = keyCommand.propertyList as? [String: String] {
                if let value = identifier[MenuController.CommandPListKeys.CitiesKeyIdentifier] {
                    Swift.debugPrint("City command = \(String(describing: value))")
                }
            }
        }
    }
    
    @objc
    // User chose an item from the menu grouping of town titles.
    func townsMenuAction(_ sender: AnyObject) {
        if let command = sender as? UICommand {
            if let identifier = command.propertyList as? [String: String] {
                if let value = identifier[MenuController.CommandPListKeys.TownsIdentifierKey] {
                    Swift.debugPrint("Town command = \(value)")
                }
            }
        }
    }
    
    @objc
    // User chose an item from the Navigation menu of key commands or performed that key command.
    func navigationMenuAction(_ sender: AnyObject) {
        if let keyCommand = sender as? UIKeyCommand {
            if let identifier = keyCommand.propertyList as? [String: String] {
                if let value = identifier[MenuController.CommandPListKeys.ArrowsKeyIdentifier] {
                    Swift.debugPrint("Navigation command = \(value)")
                }
            }
        }
    }
    
    @objc
    // User chose an item from the Font menu.
    func fontStyleAction(_ sender: AnyObject) {
        if let keyCommand = sender as? UICommand {
            if let fontStyleDict = keyCommand.propertyList as? [String: String] {
                if let fontStyle = fontStyleDict[MenuController.CommandPListKeys.StylesIdentifierKey] {
                    if fontMenuStyleStates.contains(fontStyle) {
                        fontMenuStyleStates.remove(fontStyle)
                    } else {
                        fontMenuStyleStates.insert(fontStyle)
                    }
                }
            }
        }
    }
    
    @objc
    // User chose an item from the Tools menu.
    func toolsMenuAction(_ sender: AnyObject) {
        if let command = sender as? UICommand {
            if let toolDict = command.propertyList as? [String: Int] {
                if let value = toolDict[MenuController.CommandPListKeys.ToolsIdentifierKey] {
                    if let enumValue = MenuController.ToolType(rawValue: value) {
                        switch enumValue {
                        case .pencil:
                            Swift.debugPrint("Pencil selected")
                        case .lasso:
                            Swift.debugPrint("Lasso selected")
                        case .scissors:
                            Swift.debugPrint("Scissors selected")
                        case .rotate:
                            Swift.debugPrint("Rotate selected")
                        }
                    }
                }
            }
        }
    }
    
    @objc
    // User has chosen the disabled item from the Tools menu.
    func disabledMenuAction(_ sender: AnyObject) { }
    
    // MARK: - Preferences
    
    enum BackgroundColor: Int {
        case blue = 1
        case teal = 2
        case indigo = 3
    }
    
    // Returns the UIColor representation of the stored preference color.
    class func backgroundColorValue(colorValue: BackgroundColor) -> UIColor {
        var returnColor = UIColor()
        switch colorValue {
        case .blue:
            returnColor = UIColor.systemBlue
        case .teal:
            returnColor = UIColor.systemTeal
        case .indigo:
            returnColor = UIColor.systemIndigo
        }
        return returnColor
    }
    
    // Locates the file representing the root page of the settings for this app and registers the loaded values as the app's defaults.
    func registerDefaultsFromSettingsBundle() {
        let settingsUrl =
            Bundle.main.url(forResource: "Settings", withExtension: "bundle")!.appendingPathComponent("Root.plist")
        let settingsPlist = NSDictionary(contentsOf: settingsUrl)!
        if let preferences = settingsPlist["PreferenceSpecifiers"] as? [NSDictionary] {
            var defaultsToRegister = [String: Any]()
    
            for prefItem in preferences {
                guard let key = prefItem["Key"] as? String else {
                    continue
                }
                defaultsToRegister[key] = prefItem["DefaultValue"]
            }
            UserDefaults.standard.register(defaults: defaultsToRegister)
        }
    }
    
}
