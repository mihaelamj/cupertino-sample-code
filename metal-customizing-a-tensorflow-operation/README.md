# Customizing a TensorFlow operation

Implement a custom operation that uses Metal kernels to accelerate neural-network training performance.

## Overview

- Note: This sample code project is associated with WWDC22 session [10063: Accelerate machine learning with Metal](https://developer.apple.com/wwdc22/10063/).

## Configure the sample code

1. Follow the instructions in [Get started with tensorflow-metal](https://developer.apple.com/metal/tensorflow-plugin/).

2. Install ffmpeg using `brew`.

    ```shell
    brew install ffmpeg
    ```

3. Install the required Python packages.

    ```shell
    pip install -r requirements.txt
    ```

4. Use `make` to build the custom operation with Xcode.

    ```shell
    cd hash_encoder
    make
    cd ..
    ```

5. Run the sample.

    ```shell
    python tiny_nerf_hash.py
    ```

6. View the resutls in the `result_nerf_hash` folder.

- To compare the performance benefits provided by this sample, you can run the original NeRF sample code included with the project.  View the resutls in the `result_nerf_mlp` folder.

    ```shell
    python tiny_nerf_mlp.py
    ```

- Note: The sample uses low-resolution (100x100) images by default. You can alternatively use a high-resolution version of the data to produce a clearer rendering.

