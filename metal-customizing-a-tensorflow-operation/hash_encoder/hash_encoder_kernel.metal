/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The Metal kernels for this sample.
*/

#include <metal_stdlib>
using namespace metal;

// The Atomic float implementation using polling.
float atomic_fetch_add_relaxed(device float* addr, float value) {
    device atomic_uint* uintAddr = reinterpret_cast<device atomic_uint*>(addr);
    uint expected = atomic_load_explicit(uintAddr, memory_order_relaxed);
    float updated = as_type<float>(expected) + value;
    while (!atomic_compare_exchange_weak_explicit(uintAddr, &expected, as_type<uint>(updated),
                                                  memory_order_relaxed, memory_order_relaxed)) {
        updated = as_type<float>(expected) + value;
    }
    updated = as_type<float>(expected) + value;
    return as_type<float>(expected);
}

// Ensure N_DIMS is less than or equal to seven.
template <uint32_t N_DIMS>
uint32_t FastHash(const uint32_t pos_grid[N_DIMS]) {
    constexpr uint32_t primes[7] = {1,          2654435761, 805459861, 3674653429,
                                    2097192037, 1434869437, 2165219737};
    uint32_t result = 0;
    for (uint32_t i = 0; i < N_DIMS; ++i) {
        result ^= pos_grid[i] * primes[i];
    }
    return result;
}

// Get the hash table index from the grid position.
template <uint32_t N_DIMS, uint32_t N_FEATURES_PER_LEVEL>
uint32_t GridPos2HashIndex(const uint32_t feature, const uint32_t hashmap_size,
                   const uint32_t grid_resolution, const uint32_t pos_grid[N_DIMS]) {
    uint32_t stride = 1;
    uint32_t index = 0;

    for (uint32_t d = 0; d < N_DIMS && stride <= hashmap_size; d++) {
        index += pos_grid[d] * stride;
        stride *= grid_resolution;
    }

    if (hashmap_size < stride) {
        index = FastHash<N_DIMS>(pos_grid);
    }

    return (index % hashmap_size) * N_FEATURES_PER_LEVEL + feature;
}

// The hash encode forward kernel function.
template <int32_t N_DIMS, int32_t N_FEATURES_PER_LEVEL>
void HashEncodeForwardKernel(// inputs
                             const device float* inputs, const device float* embeddings,
                             const device int* offsets, 
                             // output
                             device float* outputs,
                             // attributes
                             int n_batches, int n_levels, float log2_per_level_scale,
                             int resolution_coarsest,
                             // thread id
                             uint3 tid) {

    const uint32_t b = tid[0];
    const uint32_t level = tid[1];

    if (b >= uint32_t(n_batches) || level >= uint32_t(n_levels)) return;

    // Locate the pointer address.
    const device float* embeddings_ptr = embeddings + offsets[level] * N_FEATURES_PER_LEVEL;
    const device float* inputs_ptr = inputs + b * N_DIMS;
    device float* outputs_ptr =
        outputs + b * n_levels * N_FEATURES_PER_LEVEL + level * N_FEATURES_PER_LEVEL;

    const uint32_t hashmap_size = offsets[level + 1] - offsets[level];
    const float scale =
        metal::exp2(float(level * log2_per_level_scale)) * resolution_coarsest - 1.0f;
    const uint32_t resolution = (uint32_t)metal::ceil(scale) + 1;

    // Calculate coordinate.
    float pos[N_DIMS];
    uint32_t pos_grid[N_DIMS];

    for (uint32_t d = 0; d < N_DIMS; d++) {
        pos[d] = (float)inputs_ptr[d] * scale + 0.5f;
        pos_grid[d] = metal::floor(pos[d]);
        pos[d] -= (float)pos_grid[d];
    }

    float results[N_FEATURES_PER_LEVEL] = {0};

    for (uint32_t idx = 0; idx < (1 << N_DIMS); idx++) {
        float w = 1;
        uint32_t pos_grid_local[N_DIMS];

        for (uint32_t d = 0; d < N_DIMS; d++) {
            if ((idx & (1 << d)) == 0) {
                w *= 1 - pos[d];
                pos_grid_local[d] = pos_grid[d];
            } else {
                w *= pos[d];
                pos_grid_local[d] = pos_grid[d] + 1;
            }
        }

        uint32_t index =
            GridPos2HashIndex<N_DIMS, N_FEATURES_PER_LEVEL>(0, hashmap_size, resolution, pos_grid_local);

        // Writing to a local variable (register).
        for (uint32_t ch = 0; ch < N_FEATURES_PER_LEVEL; ch++) {
            results[ch] += w * embeddings_ptr[index + ch];
        }
    }

    // Writing to the output (device memory).
    for (uint32_t ch = 0; ch < N_FEATURES_PER_LEVEL; ch++) {
        outputs_ptr[ch] = results[ch];
    }
}

// The hash encode forward kernel function templatized with N_DIMS.
template <int32_t N_DIMS>
void HashEncodeForwardWrapper(// inputs
                              const device float* inputs, const device float* embeddings,
                              const device int* offsets, 
                              // output
                              device float* outputs,
                              // attributes
                              int n_batches, int n_features, int n_levels,
                              float log2_per_level_scale, int resolution_coarsest,
                              // thread id
                              uint3 tid) {
    switch (n_features) {
        case 1:
            HashEncodeForwardKernel<N_DIMS, 1>(inputs, embeddings, offsets, outputs, n_batches,
                                               n_levels, log2_per_level_scale, resolution_coarsest,
                                               tid);
            break;
        case 2:
            HashEncodeForwardKernel<N_DIMS, 2>(inputs, embeddings, offsets, outputs, n_batches,
                                               n_levels, log2_per_level_scale, resolution_coarsest,
                                               tid);
            break;
        case 3:
            HashEncodeForwardKernel<N_DIMS, 3>(inputs, embeddings, offsets, outputs, n_batches,
                                               n_levels, log2_per_level_scale, resolution_coarsest,
                                               tid);
            break;
        case 4:
            HashEncodeForwardKernel<N_DIMS, 4>(inputs, embeddings, offsets, outputs, n_batches,
                                               n_levels, log2_per_level_scale, resolution_coarsest,
                                               tid);
            break;
        case 5:
            HashEncodeForwardKernel<N_DIMS, 5>(inputs, embeddings, offsets, outputs, n_batches,
                                               n_levels, log2_per_level_scale, resolution_coarsest,
                                               tid);
            break;
        case 6:
            HashEncodeForwardKernel<N_DIMS, 6>(inputs, embeddings, offsets, outputs, n_batches,
                                               n_levels, log2_per_level_scale, resolution_coarsest,
                                               tid);
            break;
        case 7:
            HashEncodeForwardKernel<N_DIMS, 7>(inputs, embeddings, offsets, outputs, n_batches,
                                               n_levels, log2_per_level_scale, resolution_coarsest,
                                               tid);
            break;
        case 8:
            HashEncodeForwardKernel<N_DIMS, 8>(inputs, embeddings, offsets, outputs, n_batches,
                                               n_levels, log2_per_level_scale, resolution_coarsest,
                                               tid);
            break;
        default:
            break;
    }
}

// The hash encode forward kernel function.
kernel void HashEncodeForward(
    // inputs
    const device float* inputs [[buffer(0)]], const device float* embeddings [[buffer(1)]],
    const device int* offsets [[buffer(2)]], 
    // output
    device float* outputs [[buffer(3)]],
    // attributes
    constant int& n_batches [[buffer(4)]], constant int& n_dims [[buffer(5)]],
    constant int& n_features_per_level [[buffer(6)]], constant int& n_levels [[buffer(7)]],
    constant float& log2_per_level_scale [[buffer(8)]],
    constant int& resolution_coarsest [[buffer(9)]],
    // thread id
    uint3 tid [[thread_position_in_grid]]) {

    switch (n_dims) {
        case 2:
            HashEncodeForwardWrapper<2>(inputs, embeddings, offsets, outputs, n_batches,
                                        n_features_per_level, n_levels, log2_per_level_scale,
                                        resolution_coarsest, tid);
            break;
        case 3:
            HashEncodeForwardWrapper<3>(inputs, embeddings, offsets, outputs, n_batches,
                                        n_features_per_level, n_levels, log2_per_level_scale,
                                        resolution_coarsest, tid);
            break;
        default:
            return;
    }
}

// The hash encode backward kernel function templatized
// with N_DIMS and N_FEATURES_PER_LEVEL
template <int32_t N_DIMS, int32_t N_FEATURES_PER_LEVEL>
void HashEncodeBackwardKernel(// inputs
                              const device float* upstreams, const device float* inputs,
                              const device float* embeddings, const device int* offsets,
                              // output
                              device float* outputs,
                              // attributes
                              int n_batches, int n_levels, float log2_per_level_scale,
                              int resolution_coarsest,
                              // thread id
                              uint3 tid) {

    const uint32_t b = tid[0];
    const uint32_t level = tid[1];

    if (b >= uint32_t(n_batches) || level >= uint32_t(n_levels)) return;

    // Locate the pointer address.
    const device float* upstreams_ptr =
        upstreams + b * n_levels * N_FEATURES_PER_LEVEL + level * N_FEATURES_PER_LEVEL;
    const device float* inputs_ptr = inputs + b * N_DIMS;
    device float* outputs_ptr = outputs + offsets[level] * N_FEATURES_PER_LEVEL;

    const uint32_t hashmap_size = offsets[level + 1] - offsets[level];
    const float scale =
        metal::exp2(float(level * log2_per_level_scale)) * resolution_coarsest - 1.0f;
    const uint32_t resolution = (uint32_t)metal::ceil(scale) + 1;

    // Calculate the coordinate.
    float pos[N_DIMS];
    uint32_t pos_grid[N_DIMS];

    for (uint32_t d = 0; d < N_DIMS; d++) {
        pos[d] = (float)inputs_ptr[d] * scale + 0.5f;
        pos_grid[d] = metal::floor(pos[d]);
        pos[d] -= (float)pos_grid[d];
    }

    // Execute bilinear interpolation.
    for (uint32_t idx = 0; idx < (1 << N_DIMS); idx++) {
        float w = 1.0;
        uint32_t pos_grid_local[N_DIMS];

        for (uint32_t d = 0; d < N_DIMS; d++) {
            if ((idx & (1 << d)) == 0) {
                w *= 1 - pos[d];
                pos_grid_local[d] = pos_grid[d];
            } else {
                w *= pos[d];
                pos_grid_local[d] = pos_grid[d] + 1;
            }
        }

        // Convert from the pixel coordinate to the hash table offset.
        uint32_t index =
            GridPos2HashIndex<N_DIMS, N_FEATURES_PER_LEVEL>(0, hashmap_size, resolution, pos_grid_local);
        for (uint32_t c = 0; c < N_FEATURES_PER_LEVEL; c++) {
            // Atomic manner, correctness in ensured, but the performance is lowered.
            // atomic_fetch_add_relaxed(outputs_ptr + index + c, w * upstreams_ptr[c]);

            // Non-atomic manner, better performance and empirically working well.
            outputs_ptr[index + c] += w * upstreams_ptr[c];
        }
    }
}

// The hash encode backward kernel function templatized with N_DIMS.
template <int32_t N_DIMS>
void HashEncodeBackwardWrapper(// inputs
                               const device float* upstreams, const device float* inputs,
                               const device float* embeddings, const device int* offsets,
                               // output
                               device float* outputs,
                               // attributes
                               int n_batches, int n_features, int n_levels,
                               float log2_per_level_scale, int resolution_coarsest,
                               // thread id
                               uint3 tid) {
    switch (n_features) {
        case 1:
            HashEncodeBackwardKernel<N_DIMS, 1>(upstreams, inputs, embeddings, offsets, outputs,
                                                n_batches, n_levels, log2_per_level_scale,
                                                resolution_coarsest, tid);
            break;
        case 2:
            HashEncodeBackwardKernel<N_DIMS, 2>(upstreams, inputs, embeddings, offsets, outputs,
                                                n_batches, n_levels, log2_per_level_scale,
                                                resolution_coarsest, tid);
            break;
        case 3:
            HashEncodeBackwardKernel<N_DIMS, 3>(upstreams, inputs, embeddings, offsets, outputs,
                                                n_batches, n_levels, log2_per_level_scale,
                                                resolution_coarsest, tid);
            break;
        case 4:
            HashEncodeBackwardKernel<N_DIMS, 4>(upstreams, inputs, embeddings, offsets, outputs,
                                                n_batches, n_levels, log2_per_level_scale,
                                                resolution_coarsest, tid);
            break;
        case 5:
            HashEncodeBackwardKernel<N_DIMS, 5>(upstreams, inputs, embeddings, offsets, outputs,
                                                n_batches, n_levels, log2_per_level_scale,
                                                resolution_coarsest, tid);
            break;
        case 6:
            HashEncodeBackwardKernel<N_DIMS, 6>(upstreams, inputs, embeddings, offsets, outputs,
                                                n_batches, n_levels, log2_per_level_scale,
                                                resolution_coarsest, tid);
            break;
        case 7:
            HashEncodeBackwardKernel<N_DIMS, 7>(upstreams, inputs, embeddings, offsets, outputs,
                                                n_batches, n_levels, log2_per_level_scale,
                                                resolution_coarsest, tid);
            break;
        case 8:
            HashEncodeBackwardKernel<N_DIMS, 8>(upstreams, inputs, embeddings, offsets, outputs,
                                                n_batches, n_levels, log2_per_level_scale,
                                                resolution_coarsest, tid);
            break;
        default:
            break;
    }
}

// The hash encode backward kernel function.
kernel void HashEncodeBackward(// inputs
                               const device float* upstreams, const device float* inputs,
                               const device float* embeddings, const device int* offsets,
                               // output
                               device float* outputs,
                               // attributes
                               constant int& n_batches, constant int& n_dims,
                               constant int& n_features_per_level, constant int& n_levels,
                               constant float& log2_per_level_scale,
                               constant int& resolution_coarsest,
                               // thread id
                               uint3 tid [[thread_position_in_grid]]) {

    switch (n_dims) {
        case 2:
            HashEncodeBackwardWrapper<2>(upstreams, inputs, embeddings, offsets, outputs, n_batches,
                                         n_features_per_level, n_levels, log2_per_level_scale,
                                         resolution_coarsest, tid);
            break;
        case 3:
            HashEncodeBackwardWrapper<3>(upstreams, inputs, embeddings, offsets, outputs, n_batches,
                                         n_features_per_level, n_levels, log2_per_level_scale,
                                         resolution_coarsest, tid);
            break;
        default:
            return;
    }
}

// The buffer value reset functions.
[[kernel]] void SetFloat(device float* buffer, constant float& value, constant uint& size,
                         uint tid [[thread_position_in_grid]]) {
    if (tid >= size) return;
    buffer[tid] = value;
}
[[kernel]] void SetInt(device int* buffer, constant int& value, constant uint& size,
                       uint tid [[thread_position_in_grid]]) {
    if (tid >= size) return;
    buffer[tid] = value;
}
