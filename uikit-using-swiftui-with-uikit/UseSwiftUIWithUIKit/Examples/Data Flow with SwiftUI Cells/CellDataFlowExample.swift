/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The cell data flow example.
*/

import UIKit
import SwiftUI

// The list of medical conditions only has a single section.
private enum Section: Hashable {
    case main
}

// A model object that represents one medical condition. This class conforms to the ObservableObject protocol,
// which enables SwiftUI views using this object to automatically update when the property annotated with the
// @Published property wrapper changes, and also allows SwiftUI to write back changes to this property as well.
@MainActor
private class MedicalCondition: Identifiable, ObservableObject {
    // A stable, unique identifier for the medical condition. This property satisfies the requirements
    // of the Identifiable protocol.
    let id: UUID
    
    // The text of the medical condition.
    @Published var text: String
    
    init(id: UUID, text: String) {
        self.id = id
        self.text = text
    }
}

private extension MedicalCondition {
    // Returns an array of default medical conditions.
    static func getDefaultConditions() -> [MedicalCondition] {
        let names = [
            "Diabetes",
            "Hypertension",
            "Migraines",
            "Pregnancy",
            "Osteoporosis",
            "Arthritis"
        ]
        return names.map { MedicalCondition(id: UUID(), text: $0) }
    }
}

// A class that stores a collection of medical conditions, and provides methods to access medical conditions from
// the collection and mutate the collection of medical conditions.
@MainActor
private class DataStore {
    // The stored medical conditions. A tuple is used to store them in two data structures: an array to maintain ordering,
    // and a dictionary for constant-time lookups of medical conditions by their unique identifiers.
    private var data: (conditions: [MedicalCondition], conditionsByID: [MedicalCondition.ID: MedicalCondition]) = ([], [:]) {
        didSet {
            // Notify observers that the collection of medical conditions changed. Note that this notification is only posted for
            // changes to the collection of data itself (when medical conditions are inserted, deleted, or reordered), but not
            // for changes to the properties of each medical condition.
            NotificationCenter.default.post(name: .medicalConditionsDidChange, object: nil)
        }
    }
    
    // Returns an array of all stored medical conditions.
    var allMedicalConditions: [MedicalCondition] {
        data.conditions
    }
    
    // Returns the medical condition for the specified identifier.
    func medicalCondition(for id: MedicalCondition.ID) -> MedicalCondition? {
        data.conditionsByID[id]
    }
    
    // Populates the data store with the default set of medical conditions.
    func populateDefaultMedicalConditions() {
        var conditions = [MedicalCondition]()
        var conditionsByID = [MedicalCondition.ID: MedicalCondition]()
        for condition in MedicalCondition.getDefaultConditions() {
            conditions.append(condition)
            conditionsByID[condition.id] = condition
        }
        data = (conditions, conditionsByID)
    }
    
    // Adds a new medical condition to the data store.
    func addNewMedicalCondition() {
        var conditions = data.conditions
        var conditionsByID = data.conditionsByID
        let condition = MedicalCondition(id: UUID(), text: "")
        conditions.append(condition)
        conditionsByID[condition.id] = condition
        data = (conditions, conditionsByID)
    }
    
    // Deletes the specified medical condition from the data store.
    func delete(_ condition: MedicalCondition) {
        var conditions = data.conditions
        var conditionsByID = data.conditionsByID
        conditions.removeAll { $0.id == condition.id }
        conditionsByID[condition.id] = nil
        data = (conditions, conditionsByID)
    }
    
    // Shuffles the medical conditions in the data store to randomize their order.
    func shuffleMedicalConditions() {
        data.conditions.shuffle()
    }
    
    // Sorts the medical conditions in the data store alphabetically.
    func sortMedicalConditions() {
        data.conditions.sort { $0.text.localizedCaseInsensitiveCompare($1.text) == .orderedAscending }
    }
}

private extension NSNotification.Name {
    // A notification that is posted when medical conditions are added, reordered, or deleted in the data store.
    static let medicalConditionsDidChange = Notification.Name("com.example.UseSwiftUIWithUIKit.medicalConditionsDidChange")
}

// A SwiftUI view used inside each cell that displays a medical condition.
private struct MedicalConditionView: View {
    // Stores the medical condition that is displayed by this view. Using the @ObservedObject
    // property wrapper here ensures that SwiftUI will automatically refresh the view when any
    // of the @Published properties of the ObservableObject change, and also allows a binding
    // to be created to the medical condition's text so that SwiftUI can write back changes to
    // that property when the user types into the text field.
    @ObservedObject var condition: MedicalCondition
    
    // Whether the medical condition in the cell should be editable.
    var isEditable: Bool
    
    var body: some View {
        TextField("Condition", text: $condition.text)
            .alignmentGuide(.listRowSeparatorLeading) { $0[.leading] }
            .disabled(!isEditable)
    }
}

// The view controller which manages a collection view of medical conditions.
class MedicalConditionsViewController: UIViewController {
    
    // The data store that manages the collection of medical conditions displayed by this view controller.
    private var dataStore = DataStore()
    
    // The collection view which will display a list of medical conditions.
    private var collectionView: UICollectionView!
    // The diffable data source which is responsible for updating the collection view to insert, delete, and move cells
    // when the underlying collection of medical conditions in the data store is modified.
    private var dataSource: UICollectionViewDiffableDataSource<Section, MedicalCondition.ID>!
    
    override func loadView() {
        setUpCollectionView()
        view = collectionView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Conditions"
        
        // Set up the navigation bar and toolbar items.
        updateBarButtonItems()
        setUpToolbarItems()
        
        let defaultCenter = NotificationCenter.default
        
        // Register for notifications when medical conditions are added, reordered, or deleted.
        defaultCenter.addObserver(self, selector: #selector(medicalConditionsDidChange(_:)), name: .medicalConditionsDidChange, object: nil)
        
        // Register for notifications when the keyboard shows or hides, in order to update the collection view insets.
        defaultCenter.addObserver(self, selector: #selector(updateKeyboardInset(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        defaultCenter.addObserver(self, selector: #selector(updateKeyboardInset(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Populate the data store with the default medical conditions.
        dataStore.populateDefaultMedicalConditions()
    }
    
    private var toolbarCountLabel: UILabel!
    
    // Configures the toolbar to display a count label.
    private func setUpToolbarItems() {
        toolbarCountLabel = UILabel()
        toolbarCountLabel.font = .preferredFont(forTextStyle: .caption1)
        toolbarCountLabel.textColor = .secondaryLabel
        updateToolbarCountLabel()
        setToolbarItems([UIBarButtonItem(systemItem: .flexibleSpace),
                         UIBarButtonItem(customView: toolbarCountLabel),
                         UIBarButtonItem(systemItem: .flexibleSpace)], animated: false)
        navigationController?.isToolbarHidden = false
    }
    
    // Updates the toolbar count label to display the total number of medical conditions.
    private func updateToolbarCountLabel() {
        let totalConditions = dataStore.allMedicalConditions.count
        if totalConditions == 0 {
            toolbarCountLabel?.text = "No Medical Conditions"
        } else if totalConditions == 1 {
            toolbarCountLabel?.text = "\(totalConditions.formatted(.number)) Medical Condition"
        } else {
            toolbarCountLabel?.text = "\(totalConditions.formatted(.number)) Medical Conditions"
        }
        toolbarCountLabel.sizeToFit()
    }
    
    // Updates the right bar button items, based on whether the collection view is currently editing.
    private func updateBarButtonItems() {
        let editingItem: UIBarButtonItem.SystemItem = collectionView.isEditing ? .done : .edit
        var barButtonItems = [
            UIBarButtonItem(systemItem: editingItem, primaryAction: UIAction { [weak self] _ in
                self?.toggleEditing()
            })
        ]
        
        if collectionView.isEditing {
            barButtonItems.append(UIBarButtonItem(title: "New", primaryAction: UIAction { [weak self] _ in
                self?.dataStore.addNewMedicalCondition()
            }))
        } else {
            barButtonItems.append(UIBarButtonItem(title: "Shuffle", primaryAction: UIAction { [weak self] _ in
                self?.dataStore.shuffleMedicalConditions()
            }))
            barButtonItems.append(UIBarButtonItem(title: "Sort", primaryAction: UIAction { [weak self] _ in
                self?.dataStore.sortMedicalConditions()
            }))
        }
        
        navigationItem.rightBarButtonItems = barButtonItems
    }
    
    // Toggles the editing state of the collection view.
    private func toggleEditing() {
        let wasEditing = collectionView.isEditing
        collectionView.isEditing = !wasEditing
        updateBarButtonItems()
        if wasEditing {
            dismissKeyboard()
        }
    }
    
    // This method is called whenever the collection of data changes: when a new medical condition is added,
    // or an existing medical condition is deleted, or a medical condition is reordered. Note that it is not
    // called when properties of an individual medical condition change.
    @objc
    private func medicalConditionsDidChange(_ notification: NSNotification) {
        applyUpdatedSnapshot()
        updateToolbarCountLabel()
    }
    
    // Creates the collection view with a list layout, and a diffable data source wired to the collection view.
    private func setUpCollectionView() {
        let listConfig = UICollectionLayoutListConfiguration(appearance: .plain)
        let layout = UICollectionViewCompositionalLayout.list(using: listConfig)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.allowsSelection = false
        
        // Create a cell registration that configures a list cell to display a medical condition.
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, MedicalCondition> { [unowned self] cell, indexPath, item in
            configureMedicalConditionCell(cell, for: item)
        }
        
        dataSource = UICollectionViewDiffableDataSource(collectionView: collectionView) { [unowned self] collectionView, indexPath, itemIdentifier in
            // Fetch the medical condition from the data store, using the identifier passed from the diffable data source.
            let item = dataStore.medicalCondition(for: itemIdentifier)!
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
        }
    }
    
    // Whether a snapshot has been applied to the diffable data source yet.
    private var didApplyInitialSnapshot = false
    
    // Applies a new snapshot to the diffable data source based on the current medical conditions in the data store.
    private func applyUpdatedSnapshot() {
        // Start with an empty snapshot each time.
        var snapshot = NSDiffableDataSourceSnapshot<Section, MedicalCondition.ID>()
        // This list only has a single section.
        snapshot.appendSections([.main])
        // Generate an array containing the unique identifiers for each medical condition, and add those identifiers
        // to the snapshot. It is important to populate the snapshot with stable identifiers for each model object,
        // and not the model objects themselves, so that the diffable data source can accurately track the identity
        // of each item and generate the correct updates to the collection view as new snapshots are applied.
        let itemIdentifiers = dataStore.allMedicalConditions.map { $0.id }
        snapshot.appendItems(itemIdentifiers, toSection: .main)
        
        // Apply the new snapshot to the diffable data source, animating the changes as long
        // as this is not the initial snapshot being applied to the diffable data source.
        let shouldAnimate = didApplyInitialSnapshot
        dataSource.apply(snapshot, animatingDifferences: shouldAnimate)
        didApplyInitialSnapshot = true
    }
    
    // Configures a list cell to display a medical condition.
    private func configureMedicalConditionCell(_ cell: UICollectionViewListCell, for item: MedicalCondition) {
        cell.accessories = [.delete()]
        // Create a handler to execute when the cell's delete swipe action button is triggered.
        let deleteHandler: () -> Void = { [weak self] in
            // Make sure to use the item itself (or its stable identifier) in any escaping closures, such as
            // this delete handler. Do not capture the index path of the cell, as a cell's index path will
            // change when other items before it are inserted or deleted, leaving the closure with a stale
            // index path that will cause the wrong item to be deleted!
            self?.dataStore.delete(item)
        }
        
        // Configure the cell with a UIHostingConfiguration inside the cell's configurationUpdateHandler so
        // that the SwiftUI content in the cell can change based on whether the cell is editing. This handler
        // is executed before the cell first becomes visible, and anytime the cell's state changes.
        cell.configurationUpdateHandler = { cell, state in
            cell.contentConfiguration = UIHostingConfiguration {
                MedicalConditionView(condition: item, isEditable: state.isEditing)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive, action: deleteHandler) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }
    
    // Stores the total amount that the keyboard overlaps the collection view from the bottom edge.
    private var keyboardOverlap = 0.0
    
    // Updates the insets of the collection view when the keyboard shows or hides, to ensure content
    // can scroll out from underneath the keyboard.
    @objc
    private func updateKeyboardInset(_ notification: NSNotification? = nil) {
        guard let window = collectionView.window else { return }
        
        if let info = notification?.userInfo,
           let keyboardFrame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let rectInView = window.screen.coordinateSpace.convert(keyboardFrame, to: collectionView)
            keyboardOverlap = collectionView.bounds.maxY - rectInView.minY
        }
        
        let keyboardInset = max(0, keyboardOverlap - view.safeAreaInsets.bottom)
        let insets = UIEdgeInsets(top: 0, left: 0, bottom: keyboardInset, right: 0)
        collectionView.contentInset = insets
        collectionView.scrollIndicatorInsets = insets
    }
    
    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateKeyboardInset()
    }
    
    // Dismisses the keyboard by asking the current first responder to resign.
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
}
