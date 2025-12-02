/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Utilities for the compute system.
*/

import Metal

// The device Metal selects as the default.
let metalDevice: MTLDevice? = MTLCreateSystemDefaultDevice()

// Makes a command queue with the given label.
func makeCommandQueue(labeled label: String) -> MTLCommandQueue? {
    guard let metalDevice, let queue = metalDevice.makeCommandQueue() else {
        return nil
    }
    queue.label = label
    return queue
}

// Makes a command buffer for the given command queue.
func makeCommandBuffer(commandQueue: MTLCommandQueue?) -> MTLCommandBuffer? {
    guard let commandBuffer = commandQueue?.makeCommandBuffer() else {
        return nil
    }
    return commandBuffer
}

// Makes a compute command encoder for the given command buffer.
func makeComputeEncoder(commandBuffer: MTLCommandBuffer?) -> MTLComputeCommandEncoder? {
    guard let computeEncoder = commandBuffer?.makeComputeCommandEncoder() else {
        return nil
    }
    return computeEncoder
}

// Makes a compute pipeline for the compute function with the given name.
func makeComputePipeline(named name: String) -> MTLComputePipelineState? {
    guard let function = metalDevice?.makeDefaultLibrary()?.makeFunction(name: name) else {
        return nil
    }
    return try? metalDevice?.makeComputePipelineState(function: function)
}
