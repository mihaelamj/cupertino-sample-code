/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Convenience wrapper to work with MPSGraph to run training and inference
*/

import Foundation
import MetalPerformanceShaders
import MetalPerformanceShadersGraph

func getRandomData(numValues: UInt, minimum: Float, maximum: Float) -> [Float] {
    return (1...numValues).map { _ in Float.random(in: minimum..<maximum) }
}

class MNISTClassifierGraph: NSObject {
 
    var graph: MPSGraph
    var sourcePlaceholderTensor: MPSGraphTensor
    var labelsPlaceholderTensor: MPSGraphTensor
    var targetTrainingTensors: [MPSGraphTensor]
    var targetInferenceTensors: [MPSGraphTensor]
    var targetTrainingOps: [MPSGraphOperation]
    var targetInferenceOps: [MPSGraphOperation]

    static func addConvLayer(graph: MPSGraph,
                             sourceTensor: MPSGraphTensor,
                             weightsShape: [NSNumber],
                             desc: MPSGraphConvolution2DOpDescriptor,
                             variableTensors: inout [MPSGraphTensor]) -> MPSGraphTensor {
        assert(weightsShape.count == 4)

        var weightCount = 1
        for length in weightsShape {
            weightCount *= length.intValue
        }
        
        let biasCount = weightsShape[3].intValue
        
        let convWeightsValues = getRandomData(numValues: UInt(weightCount), minimum: -0.2, maximum: 0.2)
        let convWeights = graph.variable(with: Data(bytes: convWeightsValues, count: weightCount * 4),
                                         shape: weightsShape,
                                         dataType: .float32,
                                         name: nil)

        let convBiasesValues = [Float](repeating: 0.1, count: biasCount)
        let convBiases = graph.variable(with: Data(bytes: convBiasesValues, count: biasCount * 4),
                                        shape: [biasCount as NSNumber],
                                        dataType: .float32,
                                        name: nil)
        
        let convTensor = graph.convolution2D(sourceTensor,
                                             weights: convWeights,
                                             descriptor: desc,
                                             name: nil)
        
        let convBiasTensor = graph.addition(convTensor,
                                            convBiases,
                                            name: nil)
        
        let convActivationTensor = graph.reLU(with: convBiasTensor,
                                              name: nil)
        
        variableTensors += [convWeights, convBiases]
        
        return convActivationTensor
    }
    
    static func addFullyConnectedLayer(graph: MPSGraph,
                                       sourceTensor: MPSGraphTensor,
                                       weightsShape: [NSNumber],
                                       hasActivation: Bool,
                                       variableTensors: inout [MPSGraphTensor]) -> MPSGraphTensor {
        assert(weightsShape.count == 2)

        var weightCount = 1
        for length in weightsShape {
            weightCount *= length.intValue
        }
        
        let biasCount = weightsShape[1].intValue
        
        let fc0WeightsValues = getRandomData(numValues: UInt(weightCount), minimum: -0.2, maximum: 0.2)
        let fc0BiasesValues = [Float](repeating: 0.1, count: biasCount)

        let fcWeights = graph.variable(with: Data(bytes: fc0WeightsValues, count: weightCount * 4),
                                       shape: weightsShape,
                                       dataType: .float32,
                                       name: nil)
        let fcBiases = graph.variable(with: Data(bytes: fc0BiasesValues, count: biasCount * 4),
                                      shape: [biasCount as NSNumber],
                                      dataType: .float32,
                                      name: nil)
        
        let fcTensor = graph.matrixMultiplication(primary: sourceTensor,
                                                  secondary: fcWeights,
                                                  name: nil)
        
        let fcBiasTensor = graph.addition(fcTensor,
                                          fcBiases,
                                          name: nil)
        
        variableTensors += [fcWeights, fcBiases]

        if !hasActivation {
            return fcBiasTensor
        }
        
        let fcActivationTensor = graph.reLU(with: fcBiasTensor,
                                            name: nil)

        return fcActivationTensor
    }
    
    static func getAssignOperations(graph: MPSGraph, lossTensor: MPSGraphTensor, variableTensors: [MPSGraphTensor]) -> [MPSGraphOperation] {
        let gradTensors = graph.gradients(of: lossTensor, with: variableTensors, name: nil)
     
        let lambdaTensor = graph.constant(lambda, shape: [1], dataType: .float32)

        var updateOps: [MPSGraphOperation] = []
        for (key, value) in gradTensors {
            let updateTensor = graph.stochasticGradientDescent(learningRate: lambdaTensor,
                                                               values: key,
                                                               gradient: value,
                                                               name: nil)
            
            let assign = graph.assign(key, tensor: updateTensor, name: nil)
            
            updateOps += [assign]
        }
        
        return updateOps
    }
    
    let convDesc = MPSGraphConvolution2DOpDescriptor(strideInX: 1,
                                                     strideInY: 1,
                                                     dilationRateInX: 1,
                                                     dilationRateInY: 1,
                                                     groups: 1,
                                                     paddingStyle: .TF_SAME,
                                                     dataLayout: .NHWC,
                                                     weightsLayout: .HWIO)!
    
    let poolDesc = MPSGraphPooling2DOpDescriptor(kernelWidth: 2,
                                                 kernelHeight: 2,
                                                 strideInX: 2,
                                                 strideInY: 2,
                                                 paddingStyle: .TF_SAME,
                                                 dataLayout: .NHWC)!
    
    override init () {
        graph = MPSGraph()

        sourcePlaceholderTensor = graph.placeholder(shape: [batchSize as NSNumber, MNISTSize * MNISTSize as NSNumber], name: nil)
        labelsPlaceholderTensor = graph.placeholder(shape: [batchSize as NSNumber, MNISTNumClasses as NSNumber], name: nil)
        
        var variableTensors = [MPSGraphTensor]()
        
        let reshapedInput = graph.reshape(sourcePlaceholderTensor,
                                          shape: [batchSize as NSNumber, MNISTSize as NSNumber, MNISTSize as NSNumber, 1],
                                          name: nil)
        
        let conv0Tensor = MNISTClassifierGraph.addConvLayer(graph: graph, sourceTensor: reshapedInput,
                                                            weightsShape: [5, 5, 1, 32],
                                                            desc: convDesc, variableTensors: &variableTensors)
        
        let pool0Tensor = graph.maxPooling2D(withSourceTensor: conv0Tensor, descriptor: poolDesc, name: nil)

        let conv1Tensor = MNISTClassifierGraph.addConvLayer(graph: graph, sourceTensor: pool0Tensor,
                                                            weightsShape: [5, 5, 32, 64],
                                                            desc: convDesc, variableTensors: &variableTensors)
        
        let pool1Tensor = graph.maxPooling2D(withSourceTensor: conv1Tensor, descriptor: poolDesc, name: nil)
        
        let reshapeTensor = graph.reshape(pool1Tensor, shape: [-1, 64 * 7 * 7 as NSNumber], name: nil)
        
        let fc0Tensor = MNISTClassifierGraph.addFullyConnectedLayer(graph: graph,
                                                                    sourceTensor: reshapeTensor,
                                                                    weightsShape: [7 * 7 * 64 as NSNumber, 1024],
                                                                    hasActivation: true,
                                                                    variableTensors: &variableTensors)
        
        let fc1Tensor = MNISTClassifierGraph.addFullyConnectedLayer(graph: graph,
                                                                    sourceTensor: fc0Tensor,
                                                                    weightsShape: [1024, 10],
                                                                    hasActivation: false,
                                                                    variableTensors: &variableTensors)
        
        let softmaxTensor = graph.softMax(with: fc1Tensor, axis: -1, name: nil)
        
        let lossTensor = graph.softMaxCrossEntropy(fc1Tensor,
                                                   labels: labelsPlaceholderTensor,
                                                   axis: -1,
                                                   reuctionType: .sum,
                                                   name: nil)
        
        let batchSizeTensor = graph.constant(Double(batchSize), shape: [1], dataType: .float32)
        let lossMeanTensor = graph.division(lossTensor, batchSizeTensor, name: nil)
        
        targetInferenceTensors = [softmaxTensor]
        targetInferenceOps = []
        
        targetTrainingTensors = [lossMeanTensor]
        targetTrainingOps = MNISTClassifierGraph.getAssignOperations(graph: graph, lossTensor: lossMeanTensor, variableTensors: variableTensors)

        super.init()
    }

    let doubleBufferingSemaphore = DispatchSemaphore(value: 2)

    // Encode training batch to command buffer using double buffering
    func encodeTrainingBatch(commandBuffer: MPSCommandBuffer,
                             sourceTensorData: MPSGraphTensorData,
                             labelsTensorData: MPSGraphTensorData,
                             completion: ((Float) -> Void)?) -> MPSGraphTensorData {
        doubleBufferingSemaphore.wait()

        let executionDesc = MPSGraphExecutionDescriptor()
        
        executionDesc.completionHandler = { (resultsDictionary, nil) in
            var loss: Float = 0
            
            let lossTensorData: MPSGraphTensorData = resultsDictionary[self.targetTrainingTensors[0]]!
            
            lossTensorData.mpsndarray().readBytes(&loss, strideBytes: nil)
            
            self.doubleBufferingSemaphore.signal()
            
            // Run completion function if provided
            if let completion = completion {
                DispatchQueue.main.async(execute: {
                    completion(loss)
                })
            }
        }

        let feed = [sourcePlaceholderTensor: sourceTensorData,
                    labelsPlaceholderTensor: labelsTensorData]
        
        let fetch = graph.encode(to: commandBuffer,
                                 feeds: feed,
                                 targetTensors: targetTrainingTensors,
                                 targetOperations: targetTrainingOps,
                                 executionDescriptor: executionDesc)

        return fetch[targetTrainingTensors[0]]!
    }

    // Encode inference batch to command buffer using double buffering
    func encodeInferenceBatch(commandBuffer: MPSCommandBuffer,
                              sourceTensorData: MPSGraphTensorData,
                              labelsTensorData: MPSGraphTensorData) -> MPSGraphTensorData {
        doubleBufferingSemaphore.wait()

        let executionDesc = MPSGraphExecutionDescriptor()
        let yLabels = labelsTensorData.mpsndarray()

        executionDesc.completionHandler = { (resultsDictionary, nil) in
            let outputTensorData: MPSGraphTensorData = resultsDictionary[self.targetInferenceTensors[0]]!
            
            var values = [Float](repeating: 0, count: Int(batchSize) * MNISTNumClasses)
            var labels = [Float](repeating: 0, count: Int(batchSize) * MNISTNumClasses)

            outputTensorData.mpsndarray().readBytes(&values, strideBytes: nil)
            yLabels.readBytes(&labels, strideBytes: nil)

            var ind = 0
            for _ in 0..<batchSize {
                var maxIndex = 0
                var maxValue: Float = 0
                var correctIndex = 0
                for classIdx in 0..<MNISTNumClasses {
                    if labels[ind] == 1.0 {
                        correctIndex = classIdx
                    }
                    if maxValue < values[ind] {
                        maxIndex = classIdx
                        maxValue = values[ind]
                    }
                    ind += 1
                }
                if maxIndex == correctIndex {
                    gCorrect += 1
                }
            }
            self.doubleBufferingSemaphore.signal()
        }
        
        let fetch = graph.encode(to: commandBuffer,
                                 feeds: [sourcePlaceholderTensor: sourceTensorData,
                                         labelsPlaceholderTensor: labelsTensorData],
                                 targetTensors: targetInferenceTensors,
                                 targetOperations: targetInferenceOps,
                                 executionDescriptor: executionDesc)
        
        return fetch[targetInferenceTensors[0]]!
    }
    
    // Run single inference case, call is blocking
    func encodeInferenceCase(sourceTensorData: MPSGraphTensorData) -> MPSGraphTensorData {
        let fetch = graph.run(with: gCommandQueue,
                              feeds: [sourcePlaceholderTensor: sourceTensorData],
                              targetTensors: targetInferenceTensors,
                              targetOperations: targetInferenceOps)

        return fetch[targetInferenceTensors[0]]!
    }
    
}
