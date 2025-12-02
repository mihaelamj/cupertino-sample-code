/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
This file contains everything essential: SwiftUI code to draw the user interface and code to load images and do the computations.
*/

import SwiftUI
import MetalPerformanceShadersGraph
import MetalKit

// MARK: Helper functions

/// The helper function that loads an `MPSImage` from a file.
func loadImage(filename: String, ext: String, device: MTLDevice, isSRGB: Bool) -> MPSImage {
    let srcUrl = Bundle.main.url(forResource: filename, withExtension: ext)
    let loader = MTKTextureLoader(device: device)
    let inputTex = try! loader.newTexture(URL: srcUrl!, options: [MTKTextureLoader.Option.SRGB: isSRGB])
    let srcImage = MPSImage(texture: inputTex, featureChannels: 4)
    return srcImage
}

/// The helper function that converts an `MPSImage` to a `CGImage` for displaying.
func convertToCGImage(image: MPSImage, useDeviceRGB: Bool) -> CGImage {
    let ctx = CIContext(mtlDevice: image.device)
    var ciOptions = [CIImageOption: Any]()
    if useDeviceRGB {
        ciOptions[CIImageOption.colorSpace] = CGColorSpaceCreateDeviceRGB()
    }
    let ciImage = CIImage(mtlTexture: image.texture, options: ciOptions)
    let ciImageFlipped = ciImage?.oriented(CGImagePropertyOrientation.downMirrored)
    let result = ctx.createCGImage(ciImageFlipped!, from: ciImage!.extent)
    return result!
}

/// The helper function to create an `UnsafeMutablePointer`.
func varToUnsafePtr<T>(ptr: UnsafeMutablePointer<T>) -> UnsafeMutablePointer<T> {
    return ptr
}

// MARK: Compute graphs

/// List the different types of MPSGraphs you need for the different functionality.
enum GraphType: CaseIterable {
    case full, showFilter, showFFTMag, showFFTPhase
}

/// The class used to create the MPSGraphs.
struct FFTGraph {
    
    var graph = MPSGraph()
    var sourceT: MPSGraphTensor? = nil
    var resT: MPSGraphTensor? = nil
    
    var limitT: MPSGraphTensor? = nil
    var limitArray: MPSNDArray? = nil
    
    var lowLimitT: MPSGraphTensor? = nil
    var lowLimitArray: MPSNDArray? = nil
    
    var scaleT: MPSGraphTensor? = nil
    var scaleArray: MPSNDArray? = nil
    
    /// The helper function that computes the phase of a complex tensor and scales it from 0 to 1.
    func computePhaseTensor(graph: MPSGraph, inputT: MPSGraphTensor) -> MPSGraphTensor {
        let reT = graph.realPartOfTensor(tensor: inputT, name: nil)
        let imT = graph.imaginaryPartOfTensor(tensor: inputT, name: nil)
        let tmpT = graph.atan2(withPrimaryTensor: imT, secondaryTensor: reT, name: nil)
        let piT = graph.constant(Double.pi, dataType: tmpT.dataType)
        let recipTwoPiT = graph.constant(Double(1.0) / (Double.pi * Double(2.0)), dataType: tmpT.dataType)
        let shiftT = graph.addition(tmpT, piT, name: nil)
        return graph.multiplication(shiftT, recipTwoPiT, name: nil)
    }
    
    /// The main computation function that computes the result tensor from input tensors for each different graph type.
    func computeResultTensor(graph: MPSGraph, doGraph: GraphType,
                             sourceT: MPSGraphTensor, upLimitT: MPSGraphTensor, lowLimitT: MPSGraphTensor) -> MPSGraphTensor {
        var resT: MPSGraphTensor? = nil
        // Intermediate tensors from operations, which perform the actual computations.
        let xfT = graph.cast(sourceT, to: MPSDataType.float16, name: nil)
        
        let desc = MPSGraphFFTDescriptor()
        desc.scalingMode = MPSGraphFFTScalingMode.unitary
        
        // Compute the value-to-frequency space transformation.
        let fftT = graph.realToHermiteanFFT(xfT, axes: [1, 2], descriptor: desc, name: nil)
        
        let shapeT = graph.shapeOf(fftT, name: nil)
        
        // Create a disc shape from the origin on the frequency space.
        let xCoord0T = graph.coordinate(alongAxis: 2, withShapeTensor: shapeT, name: nil)
        let yCoord0T = graph.coordinate(alongAxis: 1, withShapeTensor: shapeT, name: nil)
        
        // Check if the y-coordinate is past the center, and if yes, subtract the shape size to produce negative frequencies at the bottom.
        let heightT = graph.sliceTensor(shapeT, dimension: 0, start: 1, length: 1, name: nil)
        let yCoordDoubleT = graph.multiplication(yCoord0T, graph.constant(2.0, dataType: yCoord0T.dataType), name: nil)
        let isYLargeT = graph.greaterThan(yCoordDoubleT, heightT, name: nil)
        let yCoord1T = graph.select(predicate: isYLargeT,
                                    trueTensor: graph.subtraction(yCoord0T, heightT, name: nil),
                                    falseTensor: yCoord0T, name: nil)
        
        let xCoordT = graph.cast(xCoord0T, to: MPSDataType.float32, name: nil)
        let yCoordT = graph.cast(yCoord1T, to: MPSDataType.float32, name: nil)
        
        let r2T = graph.addition(graph.square(with: xCoordT, name: nil), graph.square(with: yCoordT, name: nil), name: nil)
        let limit2T = graph.square(with: limitT!, name: nil)
        let filterT1 = graph.lessThanOrEqualTo(r2T, limit2T, name: nil)
        
        let limitLow2T = graph.square(with: lowLimitT, name: nil)
        let filterT0 = graph.greaterThanOrEqualTo(r2T, limitLow2T, name: nil)
        let freqFilterT = graph.cast(graph.logicalAND(filterT1, filterT0, name: nil), to: MPSDataType.complexFloat16, name: nil)
        
        switch doGraph {
        case GraphType.showFilter:
            resT = freqFilterT
        case GraphType.full:
            let filteredT = graph.multiplication(fftT, freqFilterT, name: nil)
            // Finally, compute the frequency-to-value space transformation with the inverse transform.
            desc.inverse = true
            resT = graph.HermiteanToRealFFT(filteredT, axes: [1, 2], descriptor: desc, name: nil)
        case GraphType.showFFTMag:
            let tmpT = graph.absolute(with: fftT, name: nil)
            resT = graph.realPartOfTensor(tensor: tmpT, name: nil)
        case GraphType.showFFTPhase:
            resT = computePhaseTensor(graph: graph, inputT: fftT)
        }
        return resT!
    }
    
    // For initialization, you need the Metal device and the type of the graph specified.
    init(device: MTLDevice, doGraph: GraphType) {
        // Provide inputs for the placeholder tensors in the feeds:
        sourceT = graph.placeholder(shape: [-1, -1, -1, -1], dataType: MPSDataType.float32, name: "input")
        limitT = graph.placeholder(shape: [1], dataType: MPSDataType.float32, name: "upper limit")
        lowLimitT = graph.placeholder(shape: [1], dataType: MPSDataType.float32, name: "lower limit")
        scaleT = graph.placeholder(shape: [1], dataType: MPSDataType.float32, name: "result scale")
        
        resT = computeResultTensor(graph: graph, doGraph: doGraph, sourceT: sourceT!, upLimitT: limitT!, lowLimitT: lowLimitT!)
        
        // As post-processing steps, add scale by the user scale and 1 to the alpha channel.
        let oneT = graph.constant(Double(1.0), dataType: MPSDataType.float16)
        let zeroT = graph.constant(Double(0.0), dataType: MPSDataType.float16)
        let alphaT = graph.concatTensors([zeroT, zeroT, zeroT, oneT], dimension: -1, name: nil)
        resT = graph.multiplication(resT!, graph.cast(scaleT!, to: resT!.dataType, name: nil), name: nil)
        
        resT = graph.addition(resT!, graph.cast(alphaT, to: resT!.dataType, name: nil), name: nil)
        
        let arrayDesc = MPSNDArrayDescriptor(dataType: MPSDataType.float32, shape: [1])
        limitArray = MPSNDArray(device: device, descriptor: arrayDesc)
        lowLimitArray = MPSNDArray(device: device, descriptor: arrayDesc)
        scaleArray = MPSNDArray(device: device, descriptor: arrayDesc)
    }
    
    // Run the graph.
    func run(image: MPSImage, commandQueue: MTLCommandQueue, upperLimit: Float, lowerLimit: Float, scale: Float ) async -> MPSImage {
        let inputData = MPSGraphTensorData([image])
        let limitData = MPSGraphTensorData(limitArray!)
        let lowLimitData = MPSGraphTensorData(lowLimitArray!)
        let scaleData = MPSGraphTensorData(scaleArray!)
        var tmpUpperLimit = upperLimit
        limitArray?.writeBytes(varToUnsafePtr(ptr: &tmpUpperLimit), strideBytes: nil)
        var tmpLowerLimit = lowerLimit
        lowLimitArray?.writeBytes(varToUnsafePtr(ptr: &tmpLowerLimit), strideBytes: nil)
        var tmpScale = scale
        scaleArray?.writeBytes(varToUnsafePtr(ptr: &tmpScale), strideBytes: nil)
        
        // Encode the MPSGraph compute commands into a new `MPSCommandBuffer`.
        let cmdBuf = MPSCommandBuffer(from: commandQueue)
        let inputFeed = [sourceT!: inputData, limitT!: limitData, lowLimitT!: lowLimitData, scaleT!: scaleData]
        let fetch = graph.encode(to: cmdBuf, feeds: inputFeed, targetTensors: [resT!], targetOperations: nil, executionDescriptor: nil)
        let resArray = fetch[resT!]?.mpsndarray()
        
        let resDesc = resArray?.descriptor()
        let width = (resDesc?.sliceRange(forDimension: 1).length)!
        let height = (resDesc?.sliceRange(forDimension: 2).length)!
        
        let format = MPSImageFeatureChannelFormat.float16
        let imgDesc = MPSImageDescriptor(channelFormat: format, width: width, height: height, featureChannels: 4)
        let resImage = MPSImage(device: image.device, imageDescriptor: imgDesc)
        
        resArray?.exportData(with: cmdBuf, to: [resImage], offset: MPSImageCoordinate(x: 0, y: 0, channel: 0))
        cmdBuf.commit()
        cmdBuf.waitUntilCompleted()
        
        return resImage
    }
}

// MARK: UI code

struct ViewCtx {
    var graphs: [GraphType: FFTGraph] = Dictionary()
    var origImage: MPSImage? = nil
    var currentImage: MPSImage? = nil
    var commandQueue: MTLCommandQueue? = nil
    init() {
        let device = MTLCreateSystemDefaultDevice()!
        // Generate graphs.
        for graphType in GraphType.allCases {
            graphs[graphType] = FFTGraph(device: device, doGraph: graphType)
        }
        
        // Load the image, and set it as the current image to display.
        origImage = loadImage(filename: "Flowers_5_Hydrangea", ext: "jpeg", device: device, isSRGB: false)
        currentImage = origImage
        commandQueue = device.makeCommandQueue()
    }
}

struct ContentView: View {
    
    @State var upperLimit: Float = 25.0
    @State var lowerLimit: Float = 0.0
    @State var resultScale: Float = 1.0
    @State var ctx: ViewCtx = ViewCtx()
    @State var useOrigImage = true
    @State var currentGraph = GraphType.full
    
    func updateFFTImage(_ graphTy: GraphType) {
        if useOrigImage {
            ctx.currentImage = ctx.origImage
        } else {
            Task {
                // Do the graph computation asynchronously.
                ctx.currentImage = await ctx.graphs[graphTy]!.run(image: ctx.origImage!, commandQueue: ctx.commandQueue!,
                                                                  upperLimit: upperLimit, lowerLimit: lowerLimit, scale: resultScale)
            }
        }
    }
    
    var body: some View {
        // Generate the user interface as a vertical stack of elements that you want to display.
        VStack {
            Image(convertToCGImage(image: ctx.currentImage!, useDeviceRGB: true), scale: 1.5, label: Text(verbatim: "test"))
            Text("Graph type: " + String(describing: currentGraph))
            HStack {
                Button("Run FFT") {
                    useOrigImage = false
                    currentGraph = GraphType.full
                    updateFFTImage(currentGraph)
                }
                Button("Show filter") {
                    useOrigImage = false
                    currentGraph = GraphType.showFilter
                    updateFFTImage(currentGraph)
                }
                Button("Show FFT Magnitude") {
                    useOrigImage = false
                    currentGraph = GraphType.showFFTMag
                    updateFFTImage(currentGraph)
                }
                Button("Show FFT Phase") {
                    useOrigImage = false
                    currentGraph = GraphType.showFFTPhase
                    updateFFTImage(currentGraph)
                }
                Button("Show Original") {
                    useOrigImage = true
                    updateFFTImage(currentGraph)
                }
            }
            Slider(value: $upperLimit, in: 1...1000, onEditingChanged: { _ in updateFFTImage(currentGraph) })
            Text("Upper limit radius: \(upperLimit, specifier: "%.1f")")
            Slider(value: $lowerLimit, in: 0...100, onEditingChanged: { _ in updateFFTImage(currentGraph) })
            Text("Lower limit radius: \(lowerLimit, specifier: "%.1f")")
            Slider(value: $resultScale, in: 0...20, onEditingChanged: { _ in updateFFTImage(currentGraph) })
            Text("Result scale: \(resultScale, specifier: "%.1f")")
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

@main
struct MPSGraphFFTSampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
