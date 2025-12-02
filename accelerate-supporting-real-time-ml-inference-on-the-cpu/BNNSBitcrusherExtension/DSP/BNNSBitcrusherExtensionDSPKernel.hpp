/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The BNNS bitcrusher signal-processing file.
*/

#pragma once

#import <AudioToolbox/AudioToolbox.h>
#import <algorithm>
#import <vector>
#import <span>

#import <Accelerate/Accelerate.h>

#import "BNNSBitcrusherExtension-Swift.h"
#import "BNNSBitcrusherExtensionParameterAddresses.h"

/*
 `BNNSBitcrusherExtensionDSPKernel`
 As a non-Objective-C class, this is safe to use from the render thread.
 */
class BNNSBitcrusherExtensionDSPKernel {
    
private:
    bnns_graph_context_t context;
    size_t workspace_size;
    char* workspace;
    
    // Calculate the indices into the arguments array.
    size_t dst_index;
    size_t src_index;
    size_t resolution_index;
    size_t saturationGain_index;
    size_t dryWet_index;
    
    bnns_graph_argument_t arguments[5];
    
public:
    void initialize(int inputChannelCount, int outputChannelCount, double inSampleRate) {
        
        mSampleRate = inSampleRate;
        
        // Get the path to the `mlmodelc` file.
        NSBundle *main = [NSBundle mainBundle];
        NSString *mlmodelc_path = [main pathForResource:@"bitcrusher"
                                                 ofType:@"mlmodelc"];
        
        // Specify single-threaded execution.
        bnns_graph_compile_options_t options = BNNSGraphCompileOptionsMakeDefault();
        BNNSGraphCompileOptionsSetTargetSingleThread(options, true);
        
        // Compile the BNNS graph object.
        bnns_graph_t graph = BNNSGraphCompileFromFile(mlmodelc_path.UTF8String,
                                                      NULL, options);
        assert(graph.data);
        BNNSGraphCompileOptionsDestroy(options);
        
        // Create the context.
        context = BNNSGraphContextMake(graph);
        assert(context.data);
        
        // Set the argument type.
        BNNSGraphContextSetArgumentType(context, BNNSGraphArgumentTypePointer);
        
        // Specify the dynamic shape.
        uint64_t shape[] = {mMaxFramesToRender, 1, 1};
        bnns_graph_shape_t shapes[] = {
            (bnns_graph_shape_t) {.rank = 3, .shape = shape},
            (bnns_graph_shape_t) {.rank = 3, .shape = shape}
        };
        BNNSGraphContextSetDynamicShapes(context, NULL, 2, shapes);
        
        // Create the workspace.
        workspace_size = BNNSGraphContextGetWorkspaceSize(context, NULL) + NSPageSize();
        workspace = (char *)aligned_alloc(NSPageSize(), workspace_size);
        
        // Calculate the indices into the arguments array.
        dst_index = BNNSGraphGetArgumentPosition(graph, NULL, "dst");
        src_index = BNNSGraphGetArgumentPosition(graph, NULL, "src");
        resolution_index = BNNSGraphGetArgumentPosition(graph, NULL, "resolution");
        saturationGain_index = BNNSGraphGetArgumentPosition(graph, NULL, "saturationGain");
        dryWet_index = BNNSGraphGetArgumentPosition(graph, NULL, "dryWet");
    }
    
    void deInitialize() {
    }
    
    // MARK: - Bypass
    bool isBypassed() {
        return mBypassed;
    }
    
    void setBypass(bool shouldBypass) {
        mBypassed = shouldBypass;
    }
    
    // MARK: - Parameter Getter / Setter
    void setParameter(AUParameterAddress address, AUValue value) {
        switch (address) {
            case BNNSBitcrusherExtensionParameterAddress::resolution:
                mResolution = (float)value;
                break;
            case BNNSBitcrusherExtensionParameterAddress::saturationGain:
                mSaturationGain = (float)value;
                break;
            case BNNSBitcrusherExtensionParameterAddress::mix:
                mMix = (float)value;
                break;
        }
    }
    
    AUValue getParameter(AUParameterAddress address) {
        // Return the goal. It isn't thread-safe to return the ramping value.
        
        switch (address) {
            case BNNSBitcrusherExtensionParameterAddress::resolution:
                return (AUValue)mResolution;
            case BNNSBitcrusherExtensionParameterAddress::saturationGain:
                return (AUValue)mSaturationGain;
            case BNNSBitcrusherExtensionParameterAddress::mix:
                return (AUValue)mMix;
            default: return 0.f;
        }
    }
    
    // MARK: - Max Frames
    AUAudioFrameCount maximumFramesToRender() const {
        return mMaxFramesToRender;
    }
    
    void setMaximumFramesToRender(const AUAudioFrameCount &maxFrames) {
        mMaxFramesToRender = maxFrames;
    }
    
    // MARK: - Musical Context
    void setMusicalContextBlock(AUHostMusicalContextBlock contextBlock) {
        mMusicalContextBlock = contextBlock;
    }
    
    /**
     MARK: - Internal Process
     
     This function does the core signal processing.
     Do your custom DSP here.
     */
    void process(std::span<float const*> inputBuffers, std::span<float *> outputBuffers, AUEventSampleTime bufferStartTime, AUAudioFrameCount frameCount) {
        /*
         Note: For an audio unit with 'n' input channels to 'n' output channels, remove the assert below and
         modify the check in `[BNNSBitcrusherExtensionAudioUnit allocateRenderResourcesAndReturnError]`.
         */
        assert(inputBuffers.size() == outputBuffers.size());
        
        if (mBypassed) {
            // Pass the samples through.
            for (UInt32 channel = 0; channel < inputBuffers.size(); ++channel) {
                std::copy_n(inputBuffers[channel], frameCount, outputBuffers[channel]);
            }
            return;
        }
        
        for (UInt32 channel = 0; channel < inputBuffers.size(); ++channel) {
            
            // Set the size of the first dimension.
            BNNSGraphContextSetBatchSize(context, NULL, frameCount);
            
            // Specify the direct pointer to the output buffer.
            arguments[dst_index] = {
                .data_ptr = outputBuffers[channel],
                .data_ptr_size = frameCount * sizeof(outputBuffers[channel][0])
            };
            
            // Specify the direct pointer to the input buffer.
            arguments[src_index] = {
                .data_ptr = (float *)inputBuffers[channel],
                .data_ptr_size = frameCount * sizeof(inputBuffers[channel][0])
            };
            
            // Specify the direct pointer to the resolution scalar parameter.
            arguments[resolution_index] = {
                .data_ptr = &mResolution,
                .data_ptr_size = sizeof(float)
            };
            
            // Specify the direct pointer to the saturation-gain scalar parameter.
            arguments[saturationGain_index] = {
                .data_ptr = &mSaturationGain,
                .data_ptr_size = sizeof(float)
            };
            
            // Specify the direct pointer to the mix-scalar parameter.
            arguments[dryWet_index] = {
                .data_ptr = &mMix,
                .data_ptr_size = sizeof(float)
            };
            
            // Run the function.
            BNNSGraphContextExecute(context, NULL,
                                    5, arguments,
                                    workspace_size, workspace);
        }
    }
    
    void handleOneEvent(AUEventSampleTime now, AURenderEvent const *event) {
        switch (event->head.eventType) {
            case AURenderEventParameter: {
                handleParameterEvent(now, event->parameter);
                break;
            }
                
            default:
                break;
        }
    }
    
    void handleParameterEvent(AUEventSampleTime now, AUParameterEvent const& parameterEvent) {
        // Implement the handling of incoming parameter events as needed.
    }
    
    // MARK: Member Variables
    AUHostMusicalContextBlock mMusicalContextBlock;
    
    double mSampleRate = 44100.0;
    float mResolution = 0.0;
    float mSaturationGain = 0.0;
    float mMix = 0.0;
    bool mBypassed = false;
    AUAudioFrameCount mMaxFramesToRender = 1024;
    
};
