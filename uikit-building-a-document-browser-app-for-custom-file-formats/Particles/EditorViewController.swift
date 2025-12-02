/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller that hosts a table view with a list of settings that modify the properties of the particle system.
*/

import UIKit
import SceneKit
import MobileCoreServices

class EditorViewController: UITableViewController, UIDocumentPickerDelegate {
    
    enum Section: String {
        case settings
    }
    
    private struct EditorSetting: Hashable {
        let keyPath: String
        let label: String
        let min: Float
        let max: Float
        let transformer: ValueTransformer?
        
        func value(_ slider: UISlider) -> Any? {
            return transformer == nil ? slider.value : transformer!.transformedValue(slider.value)
        }
        
        func reversedValue(_ value: Any) -> Float {
            if transformer == nil {
                guard let value = value as? Float else { fatalError() }
                return value
            } else {
                if let reverseTransformedValue = transformer!.reverseTransformedValue(value) {
                    guard let reverseTransformedValue = reverseTransformedValue as? Float else { fatalError() }
                    return reverseTransformedValue
                } else {
                    return 0.0
                }
            }
        }
    }
    
    private class PETableViewCell: UITableViewCell {
        var label = UILabel()
        var slider = UISlider()
        
        override func prepareForReuse() {
            super.prepareForReuse()
            for subview in contentView.subviews {
                subview.removeFromSuperview()
            }
        }
    }
    
    private class FloatToColorTransformer: ValueTransformer {
        
        override func transformedValue(_ value: Any?) -> Any? {
            guard let floatValue = value as? Float else { return nil }
            return UIColor(hue: CGFloat(floatValue), saturation: 0.75, brightness: 1.0, alpha: 1.0)
        }
        
        override func reverseTransformedValue(_ value: Any?) -> Any? {
            guard let color = value as? UIColor else { return nil }
            var hue: CGFloat = 0
            if color.getHue(&hue, saturation: nil, brightness: nil, alpha: nil) {
                return Float(hue)
            } else {
                return nil
            }
        }
    }
    
    private lazy var dataSource = makeDataSource()
    
    var document: Document? {
        didSet {
            // Feed the Inspector with the values of the particle system.
            readValues()
        }
    }
    
    private var particleSystem: SCNParticleSystem? {
        return document?.particleSystem
    }
    
    private var settings = [
        EditorSetting(keyPath: "birthRate",
                      label: "Birth Rate",
                      min: 0.1, max: 100.0,
                      transformer: nil),
        EditorSetting(keyPath: "particleLifeSpan",
                      label: "Lifespan",
                      min: 0.1, max: 100.0,
                      transformer: nil),
        EditorSetting(keyPath: "particleSize",
                      label: "Size",
                      min: 0.1, max: 5.0,
                      transformer: nil),
        EditorSetting(keyPath: "particleSizeVariation",
                      label: "Size Variation",
                      min: 0.1, max: 10.0,
                      transformer: nil),
        EditorSetting(keyPath: "particleAngle",
                      label: "Spreading Angle",
                      min: 0.1, max: 100.0,
                      transformer: nil),
        EditorSetting(keyPath: "particleColor",
                      label: "Color",
                      min: 0.0, max: 1.0,
                      transformer: FloatToColorTransformer())
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsSelection = false
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .darkGray
        tableView.separatorStyle = .none
        tableView.register(PETableViewCell.self, forCellReuseIdentifier: "SettingsRow")
        tableView.dataSource = self.dataSource
        var snap = NSDiffableDataSourceSnapshot<Section, EditorSetting>()
        snap.appendSections([.settings])
        snap.appendItems(self.settings, toSection: .settings)
        self.dataSource.apply(snap)
        
        navigationItem.title = "Inspector"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(pickParticleImage)
        )
    }
    
    private func makeDataSource() -> UITableViewDiffableDataSource<Section, EditorSetting> {
        let reuseIdentifier = "SettingsRow"

        return UITableViewDiffableDataSource(
            tableView: tableView,
            cellProvider: { [weak self] tableView, indexPath, setting in
                let reusableCell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? PETableViewCell
                let cell = reusableCell ?? PETableViewCell()
                
                let contentView = cell.contentView
                let horizontalInset: CGFloat = 15.0
                
                // Label
                let label = cell.label
                label.textColor = .white
                label.text = setting.label
                label.translatesAutoresizingMaskIntoConstraints = false
                contentView.addSubview(label)
                NSLayoutConstraint.activate([
                    label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalInset),
                    label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10.0)
                ])
                
                // Slider
                let slider = cell.slider
                slider.maximumValue = setting.max
                slider.minimumValue = setting.min
                slider.tag = indexPath.row
                if let self = self {
                    slider.addTarget(self, action: #selector(self.valuedChanged(_:)), for: .valueChanged)
                }
                slider.translatesAutoresizingMaskIntoConstraints = false
                contentView.addSubview(slider)
                let constraints = [
                    slider.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: horizontalInset),
                    slider.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -horizontalInset),
                    slider.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10.0)
                ]
                constraints.forEach({ $0.priority = UILayoutPriority(rawValue: 750) })
                NSLayoutConstraint.activate(constraints)
                
                // Apply the current value of the particle system.
                if let particleSystem = self?.particleSystem, let value = particleSystem.value(forKey: setting.keyPath) {
                    slider.value = setting.reversedValue(value)
                }
                
                cell.backgroundColor = indexPath.row % 2 == 0 ? .darkGray : #colorLiteral(red: 0.4777468443, green: 0.4777468443, blue: 0.4777468443, alpha: 1)
                
                return cell
            }
        )
    }
    
    @objc
    func scheduleAutosave() {
        document?.updateChangeCount(.done)
    }
    
    func readValues() {
        guard let particleSystem = particleSystem else { return }
        for (idx, setting) in settings.enumerated() {
            if let cell = tableView.cellForRow(at: IndexPath(row: idx, section: 0)) as? PETableViewCell {
                if let value = particleSystem.value(forKey: setting.keyPath) {
                    cell.slider.value = setting.reversedValue(value)
                }
            }
        }
    }
    
    // MARK: UI Actions
    
    @objc
    func valuedChanged(_ slider: UISlider) {
        let setting = settings[slider.tag]
        guard let value = setting.value(slider) else { return }
        
        // Apply the value and trigger a deferred save.
        particleSystem?.setValue(value, forKey: setting.keyPath)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        perform(#selector(scheduleAutosave), with: nil, afterDelay: 1.0)
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75.0
    }
    
    @objc
    func pickParticleImage(sender: UIBarButtonItem) {
        let pickerViewController = UIDocumentPickerViewController(documentTypes: [kUTTypeImage as String], in: .import)
        pickerViewController.delegate = self
        present(pickerViewController, animated: true)
    }
    
    // MARK: UIDocumentPickerDelegate
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        assert(urls.count == 1)
        let image = UIImage(contentsOfFile: urls.first!.path)
        particleSystem?.particleImage = image
    }
}

