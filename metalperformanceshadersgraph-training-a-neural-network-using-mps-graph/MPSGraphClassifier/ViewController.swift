/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Main view controller
*/

import UIKit
import simd
import SceneKit

import MetalPerformanceShaders
import MetalPerformanceShadersGraph

var gCorrect = 0

var gDevice = MTLCreateSystemDefaultDevice()!
var gCommandQueue = gDevice.makeCommandQueue()!

extension DispatchQueue {

    static func background(delay: Double = 0.0, background: (() -> Void)? = nil, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .userInitiated).async {
            background?()
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                    completion()
                })
            }
        }
    }
    
}

class ViewController: UIViewController, CanvasDelegate {
    
    @IBOutlet var sceneKitView: SCNView!
    @IBOutlet weak var toolbar: UIToolbar!
    
    var dataset: MNISTDataSet
    var classiferGraph: MNISTClassifierGraph
    
    var progressCube: ProgressCube?
    
    lazy var scene = setupSceneKit()
    let canvas = Canvas()
    let barChart = BarChart()
    let lossChart = BarChart()
    let titleLabel = UILabel()
    let yAxisLabel = UILabel()
    let xAxisLabel = UILabel()
    
    init() {
        dataset = MNISTDataSet()
        classiferGraph = MNISTClassifierGraph()
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        gDevice = MTLCreateSystemDefaultDevice()!
        gCommandQueue = gDevice.makeCommandQueue()!

        dataset = MNISTDataSet()
        classiferGraph = MNISTClassifierGraph()

        super.init(coder: coder)
    }
    
    var isTraining: Bool = false {
        didSet {
            if isTraining {
                titleLabel.updateText(text: NSString(format: "Training for %d iterations", numTrainingIterations) as String)
            }
            
            progressCube?.isPaused = !isRunning
        }
    }
    
    var isRunning: Bool = false {
        didSet {
            toolbar.toggleInteraction(isEnabled: !isRunning)

            if isRunning {
                dispatchWorkload()
            }
        }
    }
    
    enum DemoMode: String {
        case trainMode = "Train"
        case inferenceMode = "Inference"
    }
    
    var mode: DemoMode = .trainMode {
        didSet {
            switchDemo()
        }
    }
    
    let modeSegmentedControlItem: UIBarButtonItem = {
        let segmentedControl = UISegmentedControl(items: [DemoMode.trainMode.rawValue, DemoMode.inferenceMode.rawValue])

        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(nil, action: #selector(modeSegmentedControlChangeHandler), for: .valueChanged)
        
        return UIBarButtonItem(customView: segmentedControl)
    }()
    
    @objc
    func modeSegmentedControlChangeHandler(segmentedControl: UISegmentedControl) {
        guard
            let newModeName = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex),
            let newMode = DemoMode(rawValue: newModeName) else {
                return
        }

        mode = newMode
    }
    
    func addCharts() {
        // Add inference bar chart
        barChart.frame.size = CGSize(width: view.frame.size.width * 0.8, height: view.frame.size.height * 0.25)
        let barChartCenter = CGPoint(x: view.center.x, y: view.frame.size.height * 0.175)
        barChart.center = view.convert(barChartCenter, from: barChart)
        barChart.backgroundColor = backgroundGray
        barChart.labels = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
        
        // Add training loss bar chart
        lossChart.frame.size = CGSize(width: view.frame.size.width * 0.8, height: view.frame.size.height * 0.25)
        lossChart.center = view.convert(barChartCenter, from: lossChart)
        lossChart.backgroundColor = backgroundGray
        lossChart.gapRatio = 0
        lossChart.yMax = 0
        
        view.addSubview(barChart)
        view.addSubview(lossChart)
    }
    
    func addLabels() {
        // Add main title label
        titleLabel.frame.size = CGSize(width: view.frame.size.width * 0.8, height: view.frame.size.height * 0.3)
        let titleLabelCenter = CGPoint(x: view.center.x, y: view.frame.size.height * 0.35)
        titleLabel.center = view.convert(titleLabelCenter, from: titleLabel)
        titleLabel.textAlignment = .center
        
        // Add y axis label
        yAxisLabel.frame.size = CGSize(width: view.frame.size.width * 0.1, height: view.frame.size.height * 0.25)
        let yAxisLabelCenter = CGPoint(x: view.frame.size.width * 0.05, y: view.frame.size.height * 0.175)
        yAxisLabel.center = view.convert(yAxisLabelCenter, from: yAxisLabel)
        yAxisLabel.textAlignment = .center
        yAxisLabel.transform = CGAffineTransform(rotationAngle: CGFloat.pi * 1.5)
        yAxisLabel.text = ""
        
        // Add x axis label
        xAxisLabel.frame.size = CGSize(width: view.frame.size.width * 0.8, height: view.frame.size.height * 0.3)
        let xAxisLabelCenter = CGPoint(x: view.center.x, y: view.frame.size.height * 0.325)
        xAxisLabel.center = view.convert(xAxisLabelCenter, from: xAxisLabel)
        xAxisLabel.textAlignment = .center
        xAxisLabel.text = ""
        
        view.addSubview(titleLabel)
        view.addSubview(yAxisLabel)
        view.addSubview(xAxisLabel)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup toolbar
        toolbar.setItems([modeSegmentedControlItem,
                          UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
                          UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.play,
                                          target: self,
                                          action: #selector(runButtonTouchHandler))],
                         animated: false)
        switchDemo()
        
        progressCube = addProgressCube(outerSize: 0.5, delta: 0.1, inScene: scene)
        progressCube?.isPaused = true
        
        // Add canvas subview
        canvas.frame.size = CGSize(width: view.frame.size.height * 0.25, height: view.frame.size.height * 0.25)
        let canvasCenter = CGPoint(x: view.center.x, y: view.frame.size.height * 0.75)
        canvas.center = view.convert(canvasCenter, from: canvas)
        canvas.backgroundColor = UIColor.black
        canvas.delegate = self
        view.addSubview(canvas)
        
        addCharts()
        addLabels()
    }
    
    @objc
    func runButtonTouchHandler() {
        isRunning = true
    }
    
    func switchDemo() {
        canvas.isHidden = (mode == .trainMode)
        barChart.isHidden = (mode == .trainMode)
        lossChart.isHidden = (mode != .trainMode)
        yAxisLabel.isHidden = (mode != .trainMode)
        xAxisLabel.isHidden = (mode != .trainMode)
        switch mode {
        case .trainMode:
            titleLabel.updateText(text: "Press play to train")

        case .inferenceMode:
            barChart.values.removeAll()
            canvas.clearLines()

            titleLabel.updateText(text: "Draw a number")
        }
    }

    func dispatchWorkload() {
        switch mode {
            case .trainMode:
                isTraining = true
                // Training workload dispatched to brackground thread
                DispatchQueue.background(delay: 0, background: {
                                            self.runTrainingLoop()
                                         }, completion: {
                                            self.isRunning = false
                                            self.isTraining = false
                                         })
            case .inferenceMode:
                // Run inference over resized image
                runInferenceCase(image: canvas.getImage())
                
                // Reset the canvas
                canvas.clearLines()
        }
    }
    
    // Run the training loop
    func runTrainingLoop() {
        var latestCommandBuffer: MTLCommandBuffer? = nil
        gCompletedIterations = 0
        for _ in 0..<numTrainingIterations {
            latestCommandBuffer = runTrainingIterationBatch()
        }
        latestCommandBuffer?.waitUntilCompleted()
        evaluateTestSet()
    }
    
    // Run a training iteration batch
    func runTrainingIterationBatch() -> MTLCommandBuffer {
        let commandBuffer = MPSCommandBuffer(commandBuffer: gCommandQueue.makeCommandBuffer()!)
        
        var yLabels: MPSNDArray? = nil
        let xInput = dataset.getRandomTrainingBatch(device: gDevice, batchSize: batchSize, labels: &yLabels)
        _ = classiferGraph.encodeTrainingBatch(commandBuffer: commandBuffer,
                                               sourceTensorData: MPSGraphTensorData(xInput),
                                               labelsTensorData: MPSGraphTensorData(yLabels!),
                                               completion: updateProgressCubeAndLoss)
        
        commandBuffer.commit()
        
        return commandBuffer
    }
    
    var gCompletedIterations = 0
    let iterationUpdateSemaphore = DispatchSemaphore(value: 1)

    // Callback to update UI with training iteration completion
    func updateProgressCubeAndLoss(loss: Float) {
        iterationUpdateSemaphore.wait()
        gCompletedIterations += 1
        let newScale = (Float(gCompletedIterations) / Float(numTrainingIterations))
        
        progressCube?.updateProgressCube(scale: newScale)
        
        iterationUpdateSemaphore.signal()
        
        if lossChart.yMax < loss { lossChart.yMax = loss }
        
        if lossChart.values.isEmpty {
            yAxisLabel.text = "Loss"
            xAxisLabel.text = "Iterations"
        }
        
        lossChart.values.append(loss)
    }
    
    // Evaluate network on the test set
    func evaluateTestSet() {
        gCorrect = 0
        
        titleLabel.updateText(text: "Evaluating Network")

        var latestCommandBuffer: MTLCommandBuffer? = nil

        var yLabels: MPSNDArray? = nil
        var xInput: MPSNDArray? = nil
        
        // encoding each image
        for currImageIdx in stride(from: 0, to: dataset.totalNumberOfTestImages, by: Int(batchSize)) {
            let commandBuffer = MPSCommandBuffer(commandBuffer: gCommandQueue.makeCommandBuffer()!)
            
            xInput = dataset.getTrainingBatchWithDevice(device: gDevice,
                                                        batchIndex: Int(currImageIdx) / Int(batchSize),
                                                        batchSize: Int(batchSize),
                                                        labels: &yLabels)
            
            _ = classiferGraph.encodeInferenceBatch(commandBuffer: commandBuffer,
                                                    sourceTensorData: MPSGraphTensorData(xInput!),
                                                    labelsTensorData: MPSGraphTensorData(yLabels!))
            
            commandBuffer.commit()
            
            latestCommandBuffer = commandBuffer
        }
        latestCommandBuffer?.waitUntilCompleted()
        
        let accuracy = (Float(gCorrect) / Float(dataset.totalNumberOfTestImages)) * Float(100)

        NSLog("Test Set Accuracy = %f %%", accuracy)
        titleLabel.updateText(text: NSString(format: "Test Set Accuracy is %.2f %%", accuracy) as String)
    }
    
    var gInferenceInProgress = false
    
    // Drawing in progress, run inference with current input if not already running inference
    func canvasUpdated() {
        if gInferenceInProgress { return }
        gInferenceInProgress = true
        
        let image = canvas.getImage()

        DispatchQueue.background(delay: 0.0, background: {
            self.runInferenceCase(image: image)
        }, completion: {
            self.gInferenceInProgress = false
        })
    }
    
    // Run inference on a single image
    func runInferenceCase(image: UIImage) {
        DispatchQueue.main.async { self.flashCube(cube: self.progressCube!.outerCube) }
                
        let dataSize = MNISTSize * MNISTSize
        var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
        let context = CGContext(data: &pixelData,
                                width: MNISTSize,
                                height: MNISTSize,
                                bitsPerComponent: 8,
                                bytesPerRow: MNISTSize,
                                space: CGColorSpaceCreateDeviceGray(),
                                bitmapInfo: CGImageAlphaInfo.none.rawValue)
        context?.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: MNISTSize, height: MNISTSize))
        
        var pixelData2 = [Float](repeating: 0, count: Int(dataSize) * Int(batchSize))
        for num in 0..<Int(batchSize) {
            for ind in 0..<dataSize {
                pixelData2[num * dataSize + ind] = Float(pixelData[ind]) / Float(255)
            }
        }
        
        let inputDesc = MPSNDArrayDescriptor(dataType: .float32, shape: [batchSize as NSNumber, MNISTSize * MNISTSize as NSNumber])

        let arrayInput = MPSNDArray(device: gDevice, descriptor: inputDesc)
        arrayInput.writeBytes(&pixelData2, strideBytes: nil)
        
        let labelData = classiferGraph.encodeInferenceCase(sourceTensorData: MPSGraphTensorData(arrayInput))
        
        var labelValues = [Float](repeating: 0, count: Int(batchSize) * MNISTNumClasses)
        labelData.mpsndarray().readBytes(&labelValues, strideBytes: nil)
        
        var probs = [Float](repeating: 0, count: MNISTNumClasses)
        
        var maxIndex = 0
        var maxValue = Float(0)
        for ind in 0..<MNISTNumClasses {
            probs[ind] = labelValues[ind]
            if labelValues[ind] > maxValue {
                maxIndex = ind
                maxValue = labelValues[ind]
            }
        }
        
        DispatchQueue.main.async { self.barChart.values = probs }
        
        titleLabel.updateText(text: NSString(format: "User has drawn %d", maxIndex) as String)

        isRunning = false
    }
    
}
