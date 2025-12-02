/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The code for registering a tensorflow custom op with Metal. 
*/

#include "tensorflow/core/framework/op.h"
#include "tensorflow/core/framework/shape_inference.h"

#include <filesystem>
#include <sys/_types/_int32_t.h>
#include <dlfcn.h>

#include "tensorflow/c/kernels.h"
#import <Metal/Metal.h>
#include <dispatch/dispatch.h>

@protocol TF_MetalStream

- (dispatch_queue_t)queue;
- (id<MTLCommandBuffer>)currentCommandBuffer;
- (void)commit;
- (void)commitAndWait;

@end

// The singleton class for kernel library.
class KernelLibrarySingleton {
   public:
    static KernelLibrarySingleton& getInstance() {
        if (sInstance == nullptr) {
            sInstance = new KernelLibrarySingleton();

            printf("Loading kernel library...\n");

            @autoreleasepool {
                // Finding the metallib path.
                NSString* libraryFile = @"hash_encoder_kernel.metallib"; 
                {
                    Dl_info info;
                    if (dladdr(reinterpret_cast<const void*>(&getInstance), &info) != 0) {
                        libraryFile =
                            [NSString stringWithCString:info.dli_fname
                                               encoding:[NSString defaultCStringEncoding]];
                        libraryFile =
                            [libraryFile stringByReplacingOccurrencesOfString:@".so"
                                                                   withString:@".metallib"];
                    }
                }
                id<MTLDevice> device = MTLCreateSystemDefaultDevice();

                NSError* error = nil;
                NSURL *libraryUrl = [NSURL URLWithString:libraryFile];
                library = [device newLibraryWithURL:libraryUrl error:&error];

                if (!library) {
                    printf("Compilation error: %s\n", [[error description] UTF8String]);
                    abort();
                }
            }
        }
        return *sInstance;
    }

   public:
    static id<MTLLibrary> library;

   private:
    KernelLibrarySingleton() {}
    static KernelLibrarySingleton* sInstance;
};

KernelLibrarySingleton* KernelLibrarySingleton::sInstance = nullptr;
id<MTLLibrary> KernelLibrarySingleton::library = nil;

std::vector<int64_t> getShape(TF_Tensor* tensor) {

    std::vector<int64_t> shape;

    const int dimensionCount = TF_NumDims(tensor);
    shape.resize(dimensionCount);

    for (int dim = 0; dim < dimensionCount; dim++) {
        shape[dim] = TF_Dim(tensor, dim);
    }
    return shape;
}

// The hash encode forward part.

typedef struct MetalHashEncodeOp {
    // The buffer data type.
    TF_DataType embeddings_data_type;
    // The scale ratio between levels (after log2).
    float log2_per_level_scale;  
    // The coarsest resolution.
    int32_t resolution_coarsest;  
} MetalHashEncodeOp;

static void* MetalHashEncodeOp_Create(TF_OpKernelConstruction* ctx) {
    auto* kernel = new MetalHashEncodeOp;

    TF_Status* s = TF_NewStatus();
    TF_OpKernelConstruction_GetAttrType(ctx, "T", &kernel->embeddings_data_type, s);

    if (TF_GetCode(s) == TF_OK) {
        TF_OpKernelConstruction_GetAttrFloat(ctx, "log2_per_level_scale", &kernel->log2_per_level_scale, s);
        TF_OpKernelConstruction_GetAttrInt32(ctx, "resolution_coarsest", &kernel->resolution_coarsest, s);
    }

    if (TF_GetCode(s) != TF_OK) {
        TF_OpKernelConstruction_Failure(ctx, s);
        delete kernel;
        kernel = nullptr;
    }

    TF_DeleteStatus(s);
    return kernel;
}

static void MetalHashEncodeOp_Delete(void* kernel) {
    delete static_cast<MetalHashEncodeOp*>(kernel);
}

static void MetalHashEncodeOp_Compute(void* kernel, TF_OpKernelContext* ctx) {
    auto* k = static_cast<MetalHashEncodeOp*>(kernel);

    TF_Status* status = TF_NewStatus();

    TF_Tensor* inputs = nullptr;
    TF_GetInput(ctx, 0, &inputs, status);

    TF_Tensor* embeddings = nullptr;
    TF_GetInput(ctx, 1, &embeddings, status);

    TF_Tensor* hashmap_offsets = nullptr;
    TF_GetInput(ctx, 2, &hashmap_offsets, status);

    TF_DataType dataType = TF_TensorType(embeddings);

    std::vector<int64_t> inputs_shape = getShape(inputs);
    std::vector<int64_t> embeddings_shape = getShape(embeddings);
    std::vector<int64_t> offsets_shape = getShape(hashmap_offsets);
    
    int32_t B = inputs_shape[0];
    int32_t D = inputs_shape[1];
    int32_t L = offsets_shape[0] - 1;
    int32_t C = embeddings_shape[1];
    
    std::vector<int64_t> output_shape{inputs_shape[0],
                                      embeddings_shape[embeddings_shape.size() - 1] * L};

    TF_Tensor* outputs = TF_AllocateOutput(ctx, 0, dataType, (int64_t*)output_shape.data(),
                                           output_shape.size(), 0, status);

    if (TF_GetCode(status) != TF_OK) {
        printf("allocation failed: %s\n", TF_Message(status));
        TF_OpKernelContext_Failure(ctx, status);
        TF_DeleteTensor(inputs);
        TF_DeleteTensor(embeddings);
        TF_DeleteTensor(hashmap_offsets);
        TF_DeleteTensor(outputs);
        TF_DeleteStatus(status);
        return;
    }

    @autoreleasepool {

        id<TF_MetalStream> metalStream = (id<TF_MetalStream>)(TF_GetStream(ctx, status));

        if (TF_GetCode(status) != TF_OK) {
            printf("no stream was found: %s\n", TF_Message(status));
            TF_OpKernelContext_Failure(ctx, status);
            TF_DeleteTensor(inputs);
            TF_DeleteTensor(embeddings);
            TF_DeleteTensor(hashmap_offsets);
            TF_DeleteTensor(outputs);
            TF_DeleteStatus(status);
            return;
        }

        dispatch_sync(metalStream.queue, ^() {
          @autoreleasepool {
              id<MTLCommandBuffer> commandBuffer = metalStream.currentCommandBuffer;
              id<MTLDevice> device = commandBuffer.device;

              NSError* error = nil;
              id<MTLLibrary> library = KernelLibrarySingleton::getInstance().library;

              id<MTLFunction> function = nil;

              function = [[library newFunctionWithName:@"HashEncodeForward"] autorelease];

              id<MTLComputePipelineState> pipeline =
                  [device newComputePipelineStateWithFunction:function error:&error];
              assert(pipeline);

              id<MTLBuffer> inputsBuffer = (id<MTLBuffer>)TF_TensorData(inputs);
              id<MTLBuffer> embeddingsBuffer = (id<MTLBuffer>)TF_TensorData(embeddings);
              id<MTLBuffer> offsetsBuffer = (id<MTLBuffer>)TF_TensorData(hashmap_offsets);
              id<MTLBuffer> outputsBuffer = (id<MTLBuffer>)TF_TensorData(outputs);

              id<MTLComputeCommandEncoder> encoder = commandBuffer.computeCommandEncoder;

              [encoder setComputePipelineState:pipeline];

              [encoder setBuffer:inputsBuffer offset:0 atIndex:0];
              [encoder setBuffer:embeddingsBuffer offset:0 atIndex:1];
              [encoder setBuffer:offsetsBuffer offset:0 atIndex:2];
              [encoder setBuffer:outputsBuffer offset:0 atIndex:3];

              [encoder setBytes:&B length:sizeof(B) atIndex:4];
              [encoder setBytes:&D length:sizeof(D) atIndex:5];
              [encoder setBytes:&C length:sizeof(C) atIndex:6];
              [encoder setBytes:&L length:sizeof(L) atIndex:7];
              [encoder setBytes:&k->log2_per_level_scale length:sizeof(k->log2_per_level_scale) atIndex:8];
              [encoder setBytes:&k->resolution_coarsest length:sizeof(k->resolution_coarsest) atIndex:9];

              // (ceil(B / 256), L, 1)  | (256, 1, 1)

              int threadsPerGroup = 256;
              int numInputPerGroup = ceil(float(B) / float(threadsPerGroup));
              MTLSize threadgroupsPerGrid = MTLSizeMake(numInputPerGroup, L, 1);
              MTLSize threadsPerThreadgroup = MTLSizeMake(threadsPerGroup, 1, 1);
              [encoder dispatchThreadgroups:threadgroupsPerGrid
                      threadsPerThreadgroup:threadsPerThreadgroup];

              [encoder endEncoding];
              [metalStream commit];
          }
        });
    }

    TF_DeleteTensor(inputs);
    TF_DeleteTensor(embeddings);
    TF_DeleteTensor(hashmap_offsets);
    TF_DeleteTensor(outputs);
    TF_DeleteStatus(status);
}

template <typename T>
void RegisterHashEncodeKernels(const char* device_type) {
    std::string opName("HashEncode");

    auto* builder = TF_NewKernelBuilder("HashEncode", device_type, &MetalHashEncodeOp_Create,
                                        &MetalHashEncodeOp_Compute, &MetalHashEncodeOp_Delete);

    TF_Status* status = TF_NewStatus();

    if (TF_OK != TF_GetCode(status))
        std::cout << " Error while registering " << opName << " kernel";

    TF_RegisterKernelBuilder((opName + "Op").c_str(), builder, status);

    if (TF_OK != TF_GetCode(status))
        std::cout << " Error while registering " << opName << " kernel";

    TF_DeleteStatus(status);
}

// The hash encode backward part.

typedef struct MetalHashEncodeGradOp {
    // The buffer data type.
    TF_DataType embeddings_data_type;
    // The scale ratio between levels (after log2).
    float log2_per_level_scale;  
    // The coarsest resolution.
    int32_t resolution_coarsest;
} MetalHashEncodeGradOp;

static void* MetalHashEncodeGradOp_Create(TF_OpKernelConstruction* ctx) {
    auto* kernel = new MetalHashEncodeGradOp;

    TF_Status* s = TF_NewStatus();
    TF_OpKernelConstruction_GetAttrType(ctx, "T", &kernel->embeddings_data_type, s);

    if (TF_GetCode(s) == TF_OK) {
        TF_OpKernelConstruction_GetAttrFloat(ctx, "log2_per_level_scale", &kernel->log2_per_level_scale, s);
        TF_OpKernelConstruction_GetAttrInt32(ctx, "resolution_coarsest", &kernel->resolution_coarsest, s);
    }

    if (TF_GetCode(s) != TF_OK) {
        TF_OpKernelConstruction_Failure(ctx, s);
        delete kernel;
        kernel = nullptr;
    }

    TF_DeleteStatus(s);
    return kernel;
}

static void MetalHashEncodeGradOp_Delete(void* kernel) {
    delete static_cast<MetalHashEncodeGradOp*>(kernel);
}


template<typename T>
static void Reset(
    id<MTLBuffer> buffer, id<MTLCommandBuffer> commandBuffer, 
    id<MTLLibrary> library, id<MTLDevice> device) { @autoreleasepool {
    NSError* error;
    NSString* funcName;
    if (std::is_same<T, float>::value) funcName = @"SetFloat";
    else if (std::is_same<T, int>::value) funcName = @"SetInt";
    else funcName = @"NotImplemented";

    auto function = [[library newFunctionWithName:funcName] autorelease];
    auto pipeline =
        [device newComputePipelineStateWithFunction:function error:&error];

    auto size = buffer.length / sizeof(T);
    T value = 0;

    MTLSize threadgroup_size;
    {
        auto w = [pipeline threadExecutionWidth];
        threadgroup_size = MTLSizeMake(w, 1, 1);
    }
    MTLSize threadgroup_per_grid;
    {
        auto w = (size + threadgroup_size.width - 1) / threadgroup_size.width;
        threadgroup_per_grid = MTLSizeMake(w, 1, 1);
    }

    auto encoder = commandBuffer.computeCommandEncoder;
    {
        uint bid = 0;
        [encoder setBuffer:buffer offset:0 atIndex:bid++];
        [encoder setBytes:&value length:sizeof(value) atIndex:bid++];
        [encoder setBytes:&size length:sizeof(size) atIndex:bid++];
        [encoder setComputePipelineState:pipeline];
        [encoder dispatchThreadgroups:threadgroup_per_grid
                threadsPerThreadgroup:threadgroup_size];
    }
    [encoder endEncoding];
}}

static void MetalHashEncodeGradOp_Compute(void* kernel, TF_OpKernelContext* ctx) {
    auto* k = static_cast<MetalHashEncodeGradOp*>(kernel);

    TF_Status* status = TF_NewStatus();

    TF_Tensor* upstreams = nullptr;
    TF_GetInput(ctx, 0, &upstreams, status);

    TF_Tensor* inputs = nullptr;
    TF_GetInput(ctx, 1, &inputs, status);

    TF_Tensor* embeddings = nullptr;
    TF_GetInput(ctx, 2, &embeddings, status);

    TF_Tensor* hashmap_offsets = nullptr;
    TF_GetInput(ctx, 3, &hashmap_offsets, status);

    TF_DataType dataType = TF_TensorType(embeddings);

    std::vector<int64_t> inputs_shape = getShape(inputs);
    std::vector<int64_t> embeddings_shape = getShape(embeddings);
    std::vector<int64_t> offsets_shape = getShape(hashmap_offsets);
    TF_Tensor* outputs = TF_AllocateOutput(ctx, 0, dataType, (int64_t*)embeddings_shape.data(),
                                           embeddings_shape.size(), 0, status);

    int32_t B = inputs_shape[0];
    int32_t D = inputs_shape[1];
    int32_t L = offsets_shape[0] - 1;
    int32_t C = embeddings_shape[1];

    if (TF_GetCode(status) != TF_OK) {
        printf("allocation failed: %s\n", TF_Message(status));
        TF_OpKernelContext_Failure(ctx, status);
        TF_DeleteTensor(upstreams);
        TF_DeleteTensor(inputs);
        TF_DeleteTensor(embeddings);
        TF_DeleteTensor(hashmap_offsets);
        TF_DeleteTensor(outputs);
        TF_DeleteStatus(status);
        return;
    }

    @autoreleasepool {

        id<TF_MetalStream> metalStream = (id<TF_MetalStream>)(TF_GetStream(ctx, status));

        if (TF_GetCode(status) != TF_OK) {
            printf("no stream was found: %s\n", TF_Message(status));
            TF_OpKernelContext_Failure(ctx, status);
            TF_DeleteTensor(upstreams);
            TF_DeleteTensor(inputs);
            TF_DeleteTensor(embeddings);
            TF_DeleteTensor(hashmap_offsets);
            TF_DeleteTensor(outputs);
            TF_DeleteStatus(status);
            return;
        }

        dispatch_sync(metalStream.queue, ^() { @autoreleasepool {
            id<MTLLibrary> library = KernelLibrarySingleton::getInstance().library;

            id<MTLCommandBuffer> commandBuffer = metalStream.currentCommandBuffer;
            auto device = commandBuffer.device;
            id<MTLBuffer> upstreamsBuffer = (id<MTLBuffer>)TF_TensorData(upstreams);
            id<MTLBuffer> inputsBuffer = (id<MTLBuffer>)TF_TensorData(inputs);
            id<MTLBuffer> embeddingsBuffer = (id<MTLBuffer>)TF_TensorData(embeddings);
            id<MTLBuffer> offsetsBuffer = (id<MTLBuffer>)TF_TensorData(hashmap_offsets);
            id<MTLBuffer> outputsBuffer = (id<MTLBuffer>)TF_TensorData(outputs);

            NSError* error = nil;

            // Reset the output buffer to 0.
            Reset<float>(outputsBuffer, commandBuffer, library, device);

            {
                id<MTLFunction> function = nil;
                function = [[library newFunctionWithName:@"HashEncodeBackward"] autorelease];

                id<MTLComputePipelineState> pipeline =
                    [device newComputePipelineStateWithFunction:function error:&error];
                assert(pipeline);
                id<MTLComputeCommandEncoder> encoder = commandBuffer.computeCommandEncoder;

                [encoder setComputePipelineState:pipeline];

                uint bid = 0;
                [encoder setBuffer:upstreamsBuffer offset:0 atIndex:bid++];
                [encoder setBuffer:inputsBuffer offset:0 atIndex:bid++];
                [encoder setBuffer:embeddingsBuffer offset:0 atIndex:bid++];
                [encoder setBuffer:offsetsBuffer offset:0 atIndex:bid++];
                [encoder setBuffer:outputsBuffer offset:0 atIndex:bid++];

                [encoder setBytes:&B length:sizeof(B) atIndex:bid++];
                [encoder setBytes:&D length:sizeof(D) atIndex:bid++];
                [encoder setBytes:&C length:sizeof(C) atIndex:bid++];
                [encoder setBytes:&L length:sizeof(L) atIndex:bid++];
                [encoder setBytes:&k->log2_per_level_scale length:sizeof(k->log2_per_level_scale) atIndex:bid++];
                [encoder setBytes:&k->resolution_coarsest length:sizeof(k->resolution_coarsest) atIndex:bid++];
                
                // (ceil(B / 256), L, 1)  | (256, 1, 1)
                int threadsPerGroup = 256;
                int numInputPerGroup = ceil(float(B) / float(threadsPerGroup));
                MTLSize threadgroupsPerGrid = MTLSizeMake(numInputPerGroup, L, 1);
                MTLSize threadsPerThreadgroup = MTLSizeMake(threadsPerGroup, 1, 1);
                [encoder dispatchThreadgroups:threadgroupsPerGrid
                        threadsPerThreadgroup:threadsPerThreadgroup];

                [encoder endEncoding];
            }

            [metalStream commit];
        }});
    }

    TF_DeleteTensor(upstreams);
    TF_DeleteTensor(inputs);
    TF_DeleteTensor(embeddings);
    TF_DeleteTensor(hashmap_offsets);
    TF_DeleteTensor(outputs);
    TF_DeleteStatus(status);
}

template <typename T>
void RegisterHashEncodeGradKernels(const char* device_type) {
    std::string opName("HashEncodeGrad");

    auto* builder =
        TF_NewKernelBuilder("HashEncodeGrad", device_type, &MetalHashEncodeGradOp_Create,
                            &MetalHashEncodeGradOp_Compute, &MetalHashEncodeGradOp_Delete);

    TF_Status* status = TF_NewStatus();

    if (TF_OK != TF_GetCode(status))
        std::cout << " Error while registering " << opName << " kernel";

    TF_RegisterKernelBuilder((opName + "Op").c_str(), builder, status);

    if (TF_OK != TF_GetCode(status))
        std::cout << " Error while registering " << opName << " kernel";

    TF_DeleteStatus(status);
}

// Instantiate the kernels.
class InitPlugin {
   public:
    InitPlugin() {
        RegisterHashEncodeKernels<float>("GPU");
        RegisterHashEncodeGradKernels<float>("GPU");
    }
};

InitPlugin gInitPlugin;
