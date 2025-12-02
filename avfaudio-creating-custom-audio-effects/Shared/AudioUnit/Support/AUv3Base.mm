/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A base class to allow for pure Objective-C++ access to realtime DSP code.
*/

#import "AUv3Base.h"


@interface AUv3Base ()
@property AUAudioUnitBusArray *inputBusArray;
@property AUAudioUnitBusArray *outputBusArray;
@end

@implementation AUv3Base
- (instancetype)initWithComponentDescription:(AudioComponentDescription)componentDescription options:(AudioComponentInstantiationOptions)options error:(NSError *__autoreleasing  _Nullable *)outError {
	self = [super initWithComponentDescription:componentDescription options:(AudioComponentInstantiationOptions)options error:(NSError *__autoreleasing  _Nullable *)outError];
	if (self) {
		// Create adapter to communicate to underlying C++ DSP code
		_kernelAdapter = [[FilterDSPKernelAdapter alloc] init];

		self.maximumFramesToRender = _kernelAdapter.maximumFramesToRender;

		[self setupAudioBuses];
	}
	return self;
}

// Create a list of I/O buses for your audio unit.
// Add additional buses for more channels / side-chain.
- (void)setupAudioBuses {
	// Create the input and output bus arrays.
	_inputBusArray  = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self
															 busType:AUAudioUnitBusTypeInput
															  busses: @[_kernelAdapter.inputBus]];
	_outputBusArray = [[AUAudioUnitBusArray alloc] initWithAudioUnit:self
															 busType:AUAudioUnitBusTypeOutput
															  busses: @[_kernelAdapter.outputBus]];
}

// An audio unit's audio input connection points.
// Subclassers must override this property getter and should return the same object every time.
- (AUAudioUnitBusArray *)inputBusses {
	return _inputBusArray;
}

// An audio unit's audio output connection points.
// Subclassers must override this property getter and should return the same object every time.
- (AUAudioUnitBusArray *)outputBusses {
	return _outputBusArray;
}

// Subclassers must provide a AUInternalRenderBlock (via a getter) to implement rendering.
- (AUInternalRenderBlock)internalRenderBlock {
	return _kernelAdapter.internalRenderBlock;
}
@end
