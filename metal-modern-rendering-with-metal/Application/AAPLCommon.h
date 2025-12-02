/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Header for common application utilities.
*/

#import <Metal/Metal.h>
#import <simd/simd.h>

//-----------------------------------------
//-----------------------------------------
//-----------------------------------------

// Aligns a value to the next multiple of the alignment.
NSUInteger alignUp(const NSUInteger value, const NSUInteger alignment);

// Divides a value, rounding up.
NSUInteger divideRoundUp(const NSUInteger& numerator, const NSUInteger& denominator);
MTLSize divideRoundUp(const MTLSize& numerator, const MTLSize& denominator);

//-----------------------------------------
//-----------------------------------------
//-----------------------------------------

// Returns name of App/Executable.
NSString* getAppName();

// Returns/creates a file path useable for storing application data.
NSString* getOrCreateApplicationSupportPath();

// Creates a new pipeline with a label and asserts on failure.
id<MTLComputePipelineState> newComputePipelineState(id<MTLLibrary> library,
                                                    NSString *functionName,
                                                    NSString *label,
                                                    MTLFunctionConstantValues *functionConstants);

