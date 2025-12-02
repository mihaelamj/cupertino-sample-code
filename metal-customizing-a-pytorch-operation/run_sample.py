'''
Copyright © 2023 Apple Inc.

See LICENSE folder for this sample’s licensing information.

Abstract:
The code to run the compiled soft shrink kernel.
'''

# Allow soft shrink op to run through CPU fallback if it's not implemented.
import os
os.environ["PYTORCH_ENABLE_MPS_FALLBACK"] = "1"

from compiler import *
from softshrink import *
import time

# Tests the speedup of the custom soft shrink kernel.
def test_speedup():
    custom_mps_softshrink = 0
    default_softshrink = 0
    x = torch.randn(256, 784, device=mps_device)
    default_model = SoftshrinkModel().to(mps_device)
    custom_model = CustomMPSSoftshrinkModel().to(mps_device)

    # Measures time.
    for _ in range(100):
        start = time.time()
        default_model.forward(x)
        torch.mps.synchronize()
        default_softshrink += time.time() - start

        start = time.time()
        custom_model.forward(x)
        torch.mps.synchronize()
        custom_mps_softshrink += time.time() - start

    speedup = default_softshrink / custom_mps_softshrink
    print('Default Softshrink: {:.3f} us | Custom Kernel MPS Softshrink {:.3f} us ({:.3f} times faster)'.format(
        default_softshrink * 1e6/1e5, custom_mps_softshrink * 1e6/1e5, speedup))

# Tests the correctness of the custom soft shrink kernel.
def test_correctness():
    custom_softshrink = MPSSoftshrink()
    default_softshrink = nn.Softshrink()

    input_data = torch.randn(256, 784, 326, device=mps_device, dtype=torch.float)

    output_custom_softshrink_op = custom_softshrink(input_data)
    output_default_softshrink_op = default_softshrink(input_data)

    torch.testing.assert_close(output_custom_softshrink_op, output_default_softshrink_op)

def test_softshrink():
    test_correctness()
    test_speedup()

if __name__ == "__main__":
    test_softshrink()
