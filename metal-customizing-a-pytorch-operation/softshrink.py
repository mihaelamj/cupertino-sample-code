'''
Copyright © 2023 Apple Inc.

See LICENSE folder for this sample’s licensing information.

Abstract:
The code defining the custom and default soft shrink models.
'''

import torch
from torch import nn
from compiler import *

assert torch.backends.mps.is_available()
mps_device = torch.device("mps")  # Device object representing GPU.

# Wrapper over the custom MPS soft shrink kernel.
class MPSSoftshrink(nn.Module):
    __constants__ = ["lambd"]
    lambd: float

    def __init__(self, lambd: float = 0.5) -> None:
        super().__init__()
        self.lambd = lambd

    def forward(self, input):
        return compiled_lib.mps_softshrink(input, self.lambd)

    def extra_repr(self):
        return str(self.lambd)

# Wrapper over the Sequential layer, using the custom MPS kernel soft shrink implementation.
class CustomMPSSoftshrinkModel(nn.Module):
    def __init__(
        self,
        input_size: int = 784,
        lin1_size: int = 256,
        lin2_size: int = 256,
        lin3_size: int = 256,
        output_size: int = 10,
    ):
        super().__init__()

        self.model = nn.Sequential(
            nn.Linear(input_size, lin1_size),
            MPSSoftshrink(),
            nn.Linear(lin1_size, lin2_size),
            MPSSoftshrink(),
            nn.Linear(lin2_size, lin3_size),
            MPSSoftshrink(),
            nn.Linear(lin3_size, output_size),
        )

    def forward(self, x):
        return self.model(x)

# Wrapper over the Sequential layer, using the default soft shrink implementation.
class SoftshrinkModel(nn.Module):
    def __init__(
        self,
        input_size: int = 784,
        lin1_size: int = 256,
        lin2_size: int = 256,
        lin3_size: int = 256,
        output_size: int = 10,
    ):
        super().__init__()

        self.model = nn.Sequential(
            nn.Linear(input_size, lin1_size),
            nn.Softshrink(),
            nn.Linear(lin1_size, lin2_size),
            nn.Softshrink(),
            nn.Linear(lin2_size, lin3_size),
            nn.Softshrink(),
            nn.Linear(lin3_size, output_size),
        )

    def forward(self, x):
        return self.model(x)