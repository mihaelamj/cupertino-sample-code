/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view controller presenting the main view.
*/

import UIKit
import AVFoundation
import CoreAudioKit

class MainViewController: UIViewController {

    // MARK: - Outlets
    
    let audioUnitManager = AudioUnitManager()

    @IBOutlet weak var playButton: UIButton!

    @IBOutlet weak var addPresetButton: UIButton!

    @IBOutlet weak var showHideButton: UIButton!
    @IBOutlet weak var switchViewButton: UIButton!

    @IBOutlet weak var presetsTableView: UITableView!
    @IBOutlet weak var audioUnitsTableView: UITableView!
    
    @IBOutlet weak var noViewLabel: UILabel!
    @IBOutlet weak var viewContainer: UIView!

    @IBOutlet weak var presetsSegmentedControl: UISegmentedControl!
    @IBOutlet weak var audioUnitSegmentedControl: UISegmentedControl!

    // MARK: - Properties

    var presets: [Preset] {
        let isFactorySelected = presetsSegmentedControl.selectedSegmentIndex == 0
        return isFactorySelected ? audioUnitManager.factoryPresets : audioUnitManager.userPresets

    }
    var components = [Component]()

    var audioUnitViewController: UIViewController?
    
    var audioUnitView: UIView? { return audioUnitViewController?.view }
    
    var isEffectsSelected: Bool { return audioUnitSegmentedControl.selectedSegmentIndex == 0 }

    var deletedIndexPath: IndexPath?

    // MARK: - View Controller Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(userPresetsChanged),
                                               name: .userPresetsChanged, object: nil)

        // Load all default audio units registered with the system.
        loadAudioUnits()
    }

    // MARK: - View Controller Management

    func addAUViewController(_ controller: UIViewController) {

        audioUnitViewController = controller

        // Forward lifecycle events as needed.
        addChild(controller)

        if let auView = controller.view {
            auView.frame = viewContainer.bounds
            viewContainer.addSubview(auView)
        }
        controller.didMove(toParent: self)

        noViewLabel.isHidden = true
        showHideButton.isSelected = true
        switchViewButton.isEnabled = true
    }

    @discardableResult
    func removeAUViewController() -> Bool {

        guard let controller = audioUnitViewController,
            let audioUnitView = audioUnitView else { return false }

        // Forward lifecycle events as needed.
        controller.willMove(toParent: nil)
        audioUnitView.removeFromSuperview()
        controller.removeFromParent()

        audioUnitViewController = nil

        showHideButton.isSelected = false
        switchViewButton.isEnabled = false

        return true
    }
    
    // MARK: - Actions
    
    @IBAction func selectAudioUnitType(_ sender: UISegmentedControl) {
        
        // Remove the existing AU view controller, if presented.
        removeAUViewController()
        
        // Load audio units for selected type.
        loadAudioUnits(ofType: isEffectsSelected ? .effect : .instrument)
    }

    func loadAudioUnits(ofType type: AudioUnitType = .effect) {

        // Ensure audio playback is stopped before loading.
        audioUnitManager.stopPlayback()
        playButton.isSelected = false

        audioUnitManager.loadAudioUnits(ofType: type) { [weak self] audioUnits in
            guard let self = self else { return }

            self.components = audioUnits
            self.noViewLabel.isHidden = true

            self.audioUnitsTableView.reloadData()
            self.audioUnitsTableView.selectRow(at: IndexPath(row: 0, section: 0), animated: false, scrollPosition: .top)
            
            self.presetsTableView.reloadData()
        }
    }

    @IBAction func selectPresetType(_ sender: UISegmentedControl) {
        presetsTableView.reloadData()
        let indexPath = IndexPath(row: 0, section: 0)
        presetsTableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        addPresetButton.isEnabled = sender.selectedSegmentIndex == 1 && audioUnitManager.supportsUserPresets
    }

    @IBAction func addPreset(_ sender: Any) {

        let controller = UIAlertController(title: "Add Preset",
                                           message: "Enter preset name.",
                                           preferredStyle: .alert)
        controller.addTextField { textField in
            textField.placeholder = "Preset Name"
        }

        controller.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            guard let name = controller.textFields?.first?.text else { return }
            self.savePreset(named: name)
        })

        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(controller, animated: true)

    }

    func savePreset(named name: String) {
        do {
            try audioUnitManager.savePreset(Preset(name: name))
        } catch {
            print("Unable to save preset: \(error.localizedDescription)")
            let controller = UIAlertController.okAlert(title: "Error",
                                                       message: "Unable to save preset.")
            present(controller, animated: true)
        }
    }

    @objc
    func userPresetsChanged(notification: Notification) {
        guard let change = notification.object as? UserPresetsChange else { return }

        switch change.type {
        case .save:
            presetsTableView.reloadData()
            let indexPath = IndexPath(row: presets.count - 1, section: 0)
            presetsTableView.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
        case .delete:
            guard let indexPathToDelete = deletedIndexPath else { return }
            presetsTableView.deleteRows(at: [indexPathToDelete], with: .automatic)
            deletedIndexPath = nil
        case .external:
            presetsTableView.reloadData()
        default: ()
        }
    }

    @IBAction func togglePlay(_ sender: UIButton) {
        let isPlaying = audioUnitManager.togglePlayback()
        playButton.isSelected = isPlaying
    }

    @IBAction func toggleView(_ sender: UIButton) {

        // Remove the existing audio unit's view, if presented.
        guard !removeAUViewController() else { return }

        audioUnitManager.loadAudioUnitViewController { [weak self] viewController in
            guard let self = self else { return }

            guard let viewController = viewController else {
                // Show placeholder text that tells the user the audio unit has no view.
                self.noViewLabel.isHidden = false
                self.showHideButton.isSelected = false
                return
            }

            self.addAUViewController(viewController)
        }
    }

    @IBAction func switchViewMode(_ sender: UIButton) {
        audioUnitManager.toggleViewMode()
    }
}

// MARK: - Table View DataSource
extension MainViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case audioUnitsTableView:
            return components.count
        case presetsTableView:
            return presets.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        switch tableView {

        case audioUnitsTableView:
            cell.textLabel?.text = components[indexPath.row].name

        case presetsTableView:
            cell.textLabel?.text = presets[indexPath.row].name

        default:
            fatalError("Unknown table view")
        }

        return cell
    }
}

// MARK: - Table View Delegate
extension MainViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        switch tableView {

        case audioUnitsTableView:
            audioUnitManager.selectComponent(at: indexPath.row) { result in
                switch result {
                case .success:
                    self.presetsTableView.reloadData()
                    if self.presetsTableView.numberOfRows(inSection: 0) > 0 {
                        let indexPath = IndexPath(row: 0, section: 0)
                        self.presetsTableView.selectRow(at: indexPath, animated: false, scrollPosition: .top)
                    }
                    self.addPresetButton.isEnabled = self.audioUnitManager.supportsUserPresets &&
                                                        self.presetsSegmentedControl.selectedSegmentIndex == 1
                case .failure(let error):
                    print("Unable to select audio unit: \(error)")
                }
            }
            removeAUViewController()
            noViewLabel.isHidden = true

        case presetsTableView:
            audioUnitManager.currentPreset = presets[indexPath.row]

        default:
            fatalError("Unknown table view")
        }
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard tableView === presetsTableView else { return }
        if editingStyle == .delete {
            deletedIndexPath = indexPath
            do {
                try audioUnitManager.deletePreset(presets[indexPath.row])
            } catch {
                deletedIndexPath = nil
                print("Unable to delete preset: \(error.localizedDescription)")
                let controller = UIAlertController.okAlert(title: "Error",
                                                           message: "Unable to delete preset.")
                present(controller, animated: true)
            }
        }
    }
}

extension UIAlertController {

    class func okAlert(title: String, message: String) -> UIAlertController {
        let controller = UIAlertController(title: title,
                                           message: message,
                                           preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "OK", style: .default))
        return controller
    }
}
