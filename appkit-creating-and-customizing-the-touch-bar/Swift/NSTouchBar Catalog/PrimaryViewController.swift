/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The primary view controller that gives access to all test cases in this sample.
*/

import Cocoa

class PrimaryViewController: NSViewController, NSTableViewDelegate {
    struct TestCaseKey {
        static let root = "tests" // Key to the main dictionary containing all the test dictionaries.
        
        // Keys to the NSDictionary for each test item.
        static let name = "testName" // The test's title for the table view.
        static let kind = "testKind" // The test's storyboard name to load.
    }
    
    @IBOutlet weak var contentArray: NSArrayController!
    @IBOutlet weak var tableView: NSTableView!
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Load the tests from the plist database, add them to the array controller.
        guard let fileURL = Bundle.main.url(forResource: "Tests", withExtension: "plist"),
            let plistContent = NSDictionary(contentsOf: fileURL),
            let testData = plistContent[TestCaseKey.root] as? [[String: String]] else { return }
        
        tableView.delegate = self
        contentArray.add(contentsOf: testData)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(PrimaryViewController.selectionDidChange(_:)),
                                               name: NSTableView.selectionDidChangeNotification,
                                               object: tableView)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        // Start by showing the first button example.
        contentArray.setSelectionIndex(0)
    }
    
    @objc
    func selectionDidChange(_ notification: Notification) {
        if let splitViewController = view.window!.contentViewController as? NSSplitViewController {
            var viewController = NSViewController()
            var splitViewItem = NSSplitViewItem()
            
            if tableView.selectedRow == -1 {
                // No selection, so provide an empty detail view controller.
                let storyboard = NSStoryboard(name: "Main", bundle: nil)
                viewController =
                    (storyboard.instantiateController(withIdentifier:
                        NSStoryboard.Name("DetailViewController")) as? NSViewController)!
                splitViewItem = NSSplitViewItem(viewController: viewController)
                view.window!.subtitle = ""
            } else {
                // You have a valid selection, load the right storyboard for the detail view controller.
                guard let arrangedObjects = contentArray.arrangedObjects as? [AnyObject],
                    let testCase = arrangedObjects[tableView.selectedRow] as? [String: String],
                    let storyboardName = testCase[TestCaseKey.kind]
                    else { return }
                
                viewController = (NSStoryboard(name: NSStoryboard.Name(storyboardName),
                                               bundle: nil).instantiateInitialController() as? NSViewController)!
                splitViewItem = NSSplitViewItem(viewController: viewController)
                
                if let testName = testCase[TestCaseKey.name] {
                    view.window!.subtitle = testName
                }
            }
            
            splitViewController.splitViewItems[1] = splitViewItem
            
            /** Bind the NSTouchBar instance of the primary view controller to the one of the detal view controller
                so that the bar always shows up for whichever is the first respoonder.
            */
            unbind(NSBindingName(rawValue: #keyPath(touchBar))) // unbind first
            bind(NSBindingName(rawValue: #keyPath(touchBar)), to: viewController, withKeyPath: #keyPath(touchBar), options: nil)
        }
    }

    deinit {
        unbind(NSBindingName(rawValue: #keyPath(touchBar)))
    }
}

