/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The simple quartz-based audio level meter class.
*/

import UIKit

struct AudioLevels {
    let level: Float
    let peakLevel: Float
}

// The protocol for the object that provides peak and average power levels to adopt.
protocol AudioLevelProvider {
    var levels: AudioLevels { get }
}

class LevelMeterView: UIView {
    
    private struct ColorThreshold {
        let color: UIColor
        let maxValue: CGFloat
    }
    
    private var meterDisplayLink: CADisplayLink?
    
    private var level: CGFloat = 0
    private var peakLevel: CGFloat = 0
    
    private var isActive = false
    
    private let ledBorderColor     = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
    private let ledBackgroundColor = #colorLiteral(red: 0.921431005, green: 0.9214526415, blue: 0.9214410186, alpha: 1)
    private let bezelColor         = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
    private let borderWidth: CGFloat = 0.5
    
    private let ledCount = 24
    private lazy var leds: [CALayer] = {
        
        var layers = [CALayer]()
        
        for ledIndex in 0..<ledCount {
            
            // Calculate the current LED rectangle.
            let rectX = bounds.width * (CGFloat(ledIndex) / CGFloat(ledCount))
            let rectY = CGFloat(0)
            let width = bounds.width * (1.0 / CGFloat(ledCount))
            let height = bounds.height
            
            let ledRect = CGRect(x: rectX, y: rectY, width: width, height: height)
            
            // Create and configure the LED layer.
            let ledLayer = CALayer()
            // Inset so there is some space between LEDs.
            ledLayer.frame = ledRect.insetBy(dx: 0.0, dy: 0.0)
            ledLayer.borderWidth = borderWidth
            ledLayer.borderColor = ledBorderColor.cgColor
            ledLayer.backgroundColor = ledBackgroundColor.cgColor
            
            // Add the layer to the layer hierachy.
            layer.addSublayer(ledLayer)
            
            layers.append(ledLayer)
        }
        
        return layers
        
    }()
    
    private let thresholds = [
        // The LED color threshold values.
        ColorThreshold(color: #colorLiteral(red: 0, green: 1, blue: 0, alpha: 1), maxValue: 0.5),
        ColorThreshold(color: #colorLiteral(red: 1, green: 1, blue: 0, alpha: 1), maxValue: 0.8),
        ColorThreshold(color: #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1), maxValue: 1.0)
    ]
    
    // The class that provides the audio meter data needs to adopt AudioLevelProvider.
    var levelProvider: AudioLevelProvider?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        
        layer.borderWidth = borderWidth
        layer.borderColor = bezelColor.cgColor
        
        // Install the display link to update the meter.
        installDisplayLink()
    }
    
    // Updates the LED colors according to the current peak and average power levels.
    private func updateLEDs() {
        
        var lightMinValue = CGFloat(0)
        
        var peakLED = -1
        
        if peakLevel > 0 {
            peakLED = min(Int(peakLevel * CGFloat(ledCount)), ledCount)
        }
        
        for ledIndex in 0..<ledCount {
            
            guard var ledColor = thresholds.first?.color else { continue }
            let ledMaxValue = CGFloat(ledIndex + 1) / CGFloat(ledCount)
            
            // Calculate the LED's color.
            for colorIndex in 0..<thresholds.count - 1 {
                let curr = thresholds[colorIndex]
                let next = thresholds[colorIndex + 1]
                if curr.maxValue <= ledMaxValue {
                    ledColor = next.color
                }
            }
            
            // Calculate the LED light intensity.
            let lightIntensity: CGFloat
            if ledIndex == Int(peakLED) {
                lightIntensity = 1.0
            } else {
                lightIntensity = clamp(intensity: (level - lightMinValue) / (ledMaxValue - lightMinValue))
            }
            
            let fillColor: UIColor
            
            // Calculate the LED color for the current light intensity.
            switch lightIntensity {
            case 0:
                fillColor = ledBackgroundColor
            case 1:
                fillColor = ledColor
            default:
                guard let color = ledColor.cgColor.copy(alpha: lightIntensity) else { return }
                fillColor = UIColor(cgColor: color)
            }
            
            let ledLayer = leds[ledIndex]
            ledLayer.backgroundColor = fillColor.cgColor
            
            lightMinValue = ledMaxValue
        }
    }
    
    private func installDisplayLink() {
        meterDisplayLink = CADisplayLink(target: self, selector: #selector(updateMeter))
        meterDisplayLink?.preferredFramesPerSecond = 15
        meterDisplayLink?.add(to: .current, forMode: .common)
    }
    
    private func uninstallDisplayLink() {
        meterDisplayLink?.invalidate()
        meterDisplayLink = nil
    }
    
    @objc
    private func updateMeter() {
        guard let levels = levelProvider?.levels else { return }
        level = CGFloat(levels.level)
        peakLevel = CGFloat(levels.peakLevel)
        updateLEDs()
    }
    
    private func clamp(intensity: CGFloat) -> CGFloat {
        if intensity < 0.0 {
            return 0.0
        } else if intensity >= 1.0 {
            return 1.0
        } else {
            return intensity
        }
    }
    
    func reset() {
        level = 0
        peakLevel = 0
        updateLEDs()
    }
}
