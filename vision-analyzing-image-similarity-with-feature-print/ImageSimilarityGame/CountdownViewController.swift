/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
ViewController handling the countdown timer.
*/

import UIKit
import AudioToolbox

class CountdownViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet var startButton: UIButton!
    @IBOutlet var picker: UIPickerView!
    
    let introLabels = ["Ready...", "Set...", "GO!"]
    var duration = 0 {
        didSet {
            picker.reloadComponent(0)
        }
    }
    var timer: Timer?
    var completion: (() -> Void)?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func start() {
        if timer != nil {
            stop()
        }
        
        let picker = self.picker!
        picker.selectRow(0, inComponent: 0, animated: false)
        startButton.isHidden = true
        picker.isHidden = false
        playSound(forRow: 0)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            let currentIndex = picker.selectedRow(inComponent: 0)
            if currentIndex == self.pickerView(picker, numberOfRowsInComponent: 0) - 1 {
                timer.invalidate()
                self.timer = nil
                self.completion?()
            } else {
                picker.selectRow(currentIndex + 1, inComponent: 0, animated: true)
                self.playSound(forRow: currentIndex + 1)
            }
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        startButton.isHidden = false
        picker.isHidden = true
    }
    
    func playSound(forRow row: Int) {
        // Sound ID is saved in tag property of row's view.
        guard let rowView = picker.view(forRow: row, forComponent: 0) else {
            return
        }
        AudioServicesPlaySystemSound(SystemSoundID(rowView.tag))
    }
    
    @IBAction func startTimer(_ sender: Any) {
        start()
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return duration + introLabels.count
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 80
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 60, weight: .heavy)

        let labelText: String!
        let textColor: UIColor!
        let soundID: Int!
        let introLabelsCount = introLabels.count
        let durationForRow = duration - (row - introLabelsCount)
        switch row {
        case 0 ..< introLabelsCount:
            labelText = introLabels[row]
            textColor = #colorLiteral(red: 0, green: 0.6194896698, blue: 0.9697119594, alpha: 1)
            soundID = 1103
        default:
            labelText = ("\(durationForRow)")
            if durationForRow <= 3 {
                // Draw last 3 seconds in red.
                textColor = #colorLiteral(red: 0.9910523295, green: 0, blue: 0, alpha: 1)
                soundID = 1103
            } else {
                textColor = #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
                soundID = (durationForRow % 2 == 0 ? 1104 : 1105)
            }
        }
        label.text = labelText
        label.textColor = textColor
        label.tag = soundID
        return label
    }
}
