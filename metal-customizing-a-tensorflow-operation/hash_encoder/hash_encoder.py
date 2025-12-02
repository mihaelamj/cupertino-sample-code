'''
See LICENSE folder for this sample’s licensing information.

Abstract:
The HashEncoder class.
'''

import tensorflow as tf
from tensorflow import keras
import numpy as np
import os
import subprocess
import pathlib

# Check whether the kernel needs to be recompiled.
compile = False
binary_path = os.path.join(os.path.dirname(__file__), 'hash_encoder_kernel.so')
print("Checking whether it needs to recompile...")
if os.path.exists(binary_path):
    metal_time = os.path.getmtime(os.path.join(
        os.path.dirname(__file__), 'hash_encoder_kernel.metal'))
    cc_time = os.path.getmtime(os.path.join(
        os.path.dirname(__file__), 'mtl_hash_encoder_kernel.cc'))
    bin_time = os.path.getmtime(binary_path)
    if cc_time > bin_time or metal_time > bin_time:
        print(f'Metal source code is newer, need to recompile.')
        compile = True
else:
    compile = True
if compile:
    print("Compiling Metal binary...")
    p = subprocess.Popen(["make"], cwd=os.path.dirname(__file__))
    code = p.wait()
    if code != 0:
        exit("Failed to compile .so")
print("Loading the .so binary...")
_backend = tf.load_op_library(os.path.join(pathlib.Path(
    __file__).parent.resolve(), 'hash_encoder_kernel.so'))


class _hash_encode:
    @staticmethod
    def forward(inputs, embeddings, hashmap_offsets, level_scale_ratio, resolution_coarsest):

        log2_per_level_scale = np.log2(level_scale_ratio)

        # A custom gradient tensorflow function to bind the forward/backward kernel.
        @tf.custom_gradient
        def forward_with_tensors_only(inputs, embeddings, hashmap_offsets):
            # Forward kernel call.
            outputs = _backend.hash_encode(
                inputs, embeddings, hashmap_offsets, log2_per_level_scale, resolution_coarsest)

            def grad(incoming_gradients):
                # The shape of "incoming_gradients": [B, L * C]
                
                # Backward kernel call.
                grad_embeddings = _backend.hash_encode_grad(
                    incoming_gradients, inputs, embeddings, hashmap_offsets, log2_per_level_scale, resolution_coarsest)
                return None, grad_embeddings, None

            return outputs, grad

        return forward_with_tensors_only(inputs, embeddings, hashmap_offsets)


hash_encode = _hash_encode.forward


class HashEncoder(keras.Model):
    def __init__(self, n_dim=3, n_levels=2, log2_hashmap_size=19, n_feature=2, resolution_coarsest=16, resolution_finest=256):
        super().__init__()

        # Input coordinate dimension, 2 or 3.
        self.n_dim = n_dim  
        # The number of levels: L.
        self.n_levels = n_levels  
        # The log2 of max. entries per level (hash table size): T, [14, 24].
        self.log2_hashmap_size = log2_hashmap_size
        # Number of feature channels per level: F, 2.
        self.n_feature = n_feature  
        # Coarsest resolution: N_{min}, 16.
        self.resolution_coarsest = resolution_coarsest
        # Finest resolution: N_{max}, [512, 524288].
        self.resolution_finest = resolution_finest

        # Compute the scale ratio between levels.
        self.level_scale_ratio = np.exp2(
            np.log2(resolution_finest / resolution_coarsest) / (n_levels - 1))

        # Compute the output feature channel.
        self.output_channel = n_levels * n_feature

        # Allocate parameters.
        self.hashmap_offsets = []
        offset = 0
        max_params = 2 ** log2_hashmap_size
        for i in range(n_levels):
            resolution = int(np.ceil(resolution_coarsest *
                             (self.level_scale_ratio ** i)))
            params_in_level = min(max_params, resolution ** n_dim)
            self.hashmap_offsets.append(offset)
            offset += params_in_level
        self.hashmap_offsets.append(offset)
        self.hashmap_offsets = tf.constant(
            np.array(self.hashmap_offsets, dtype=np.int32))

        # Embeddings parameters initialization.
        initializer = tf.random_normal_initializer(mean=0, stddev=1e-4)
        self.embeddings = tf.Variable(initializer(
            shape=(offset, n_feature), dtype=tf.float32), trainable=True)

    def call(self, inputs):
        # The inputs should be in the range of [0, 1].
        inputs = tf.reshape(inputs, (-1, self.n_dim))
        outputs = hash_encode(inputs, self.embeddings, self.hashmap_offsets,
                              self.level_scale_ratio, self.resolution_coarsest)
        return outputs
