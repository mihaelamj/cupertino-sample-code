'''
Copyright © 2023 Apple Inc.

See LICENSE folder for this sample’s licensing information.

Abstract:
The code for compiling the custom pytorch extension.
'''

import torch.utils.cpp_extension

compiled_lib = torch.utils.cpp_extension.load(
    name='CustomSoftshrink',
    sources=['CustomSoftshrink.mm'],
    extra_cflags=['-std=c++17'],
   )