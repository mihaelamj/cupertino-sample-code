/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The code for registering a tensorflow custom op. 
*/

#include "tensorflow/core/framework/op.h"
#include "tensorflow/core/framework/shape_inference.h"

using namespace tensorflow;

REGISTER_OP("HashEncode")
    .Attr("T: {float}")
    // The input coordinates.
    .Input("inputs: float") 
    // The NGP embedding buffer.
    .Input("embeddings: T") 
    // The hashmap offsets of all levels.
    .Input("hashmap_offsets: int32")
    // The output.
    .Output("outputs: T") 
    // The scale ratio between levels (after log2).
    .Attr("log2_per_level_scale: float") 
    // The coarsest resolution.
    .Attr("resolution_coarsest: int")
    .SetShapeFn([](::tensorflow::shape_inference::InferenceContext *c) {
      // Batch size.
      auto B = c->Dim(c->input(0), 0); 
      // Dimension.
      auto D = c->Dim(c->input(0), 1); 
      // Number of levels
      auto L = c->Dim(c->input(2), 0); 
      // Feature channels per level.
      auto C = c->Dim(c->input(1), 1);
      c->set_output(0, c->MakeShape({B, c->Value(C)*(c->Value(L)-1)}));
      return Status::OK();
    });

REGISTER_OP("HashEncodeGrad")
    .Attr("T: {float}")
    // The incoming gradients.
    .Input("incoming_gradients: T") 
    // The input coordinates.
    .Input("inputs: float")
     // The NGP embedding buffer.
    .Input("embeddings: T")
    // The hashmap offsets of all levels.
    .Input("hashmap_offsets: int32") 
    // The output gradients.
    .Output("outputs: T")
    // The scale ratio between levels (after log2).
    .Attr("log2_per_level_scale: float")
    // The coarsest resolution.
    .Attr("resolution_coarsest: int")
    .SetShapeFn([](::tensorflow::shape_inference::InferenceContext *c) {
      // The output gradient buffer has the same shape as the embedding buffer.
      c->set_output(0, c->input(2));
      return Status::OK();
    });

#include "tensorflow/core/framework/op_kernel.h"

using namespace tensorflow;

// The CPU version forward kernel.
template <typename T> class HashEncodeOp : public OpKernel {
public:
  explicit HashEncodeOp(OpKernelConstruction *context) : OpKernel(context) {
    std::cout << "HashEncode create (CPU version) is not implemented!\n";
  }


  void Compute(OpKernelContext *context) override {
    std::cout << "HashEncode compute (CPU version) is not implemented!\n";
  }
};

// The CPU version backward kernel.
template <typename T> class HashEncodeGradOp : public OpKernel {
public:
  explicit HashEncodeGradOp(OpKernelConstruction *context) : OpKernel(context) {
    std::cout << "HashEncodeGrad create (CPU version) is no implemented\n";
  }


  void Compute(OpKernelContext *context) override {
    std::cout << "HashEncodeGrad compute (CPU version) is not implemented!\n";
  }
};

// Register the kernels.
#define REGISTER_HashEncode_CPU(T)                                             \
  REGISTER_KERNEL_BUILDER(Name("HashEncode").Device(DEVICE_CPU),               \
                          HashEncodeOp<T>);
REGISTER_HashEncode_CPU(float);

#define REGISTER_HashEncodeGrad_CPU(T)                                             \
  REGISTER_KERNEL_BUILDER(Name("HashEncodeGrad").Device(DEVICE_CPU),               \
                          HashEncodeGradOp<T>);
REGISTER_HashEncodeGrad_CPU(float);