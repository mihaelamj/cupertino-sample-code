/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for the preprocessor values that control the configuration of the app.
*/

#define TBDR_RESOLVE 1

#pragma mark - MSAA Resolve Options

typedef NS_ENUM(NSInteger, AAPLResolveOption)
{
    AAPLResolveOptionBuiltin = 0,
    AAPLResolveOptionAverage = 1,
    AAPLResolveOptionHDR = 2,
    AAPLResolveOptionOptionsCount
};

static inline NSString* getLabelForAAPLResolveOption(AAPLResolveOption resolveOption)
{
    switch (resolveOption)
    {
        case AAPLResolveOptionBuiltin:
            return @"Built-in";
        case AAPLResolveOptionAverage:
            return @"Average";
        case AAPLResolveOptionHDR:
            return @"HDR";
        default:
            return @"";
    }
}

#pragma mark - MSAA Sample Count Options

typedef NS_ENUM(NSInteger, AAPLSampleCount)
{
    AAPLSampleCountTwo = 0,
    AAPLSampleCountFour,
    AAPLSampleCountEight,
    AAPLSampleCountOptionsCount
};

static inline NSString* getLabelForAAPLSampleCount(AAPLSampleCount sampleCount)
{
    switch (sampleCount)
    {
        case AAPLSampleCountTwo:
            return @"2";
        case AAPLSampleCountFour:
            return @"4";
        case AAPLSampleCountEight:
            return @"8";
        default:
            return @"";
    }
}

static inline NSInteger lookupSampleCount(AAPLSampleCount sampleCount)
{
    switch (sampleCount)
    {
        case AAPLSampleCountTwo:
            return 2;
        case AAPLSampleCountFour:
            return 4;
        case AAPLSampleCountEight:
            return 8;
        default:
            return 4;
    }
}

#pragma mark - MSAA Resolve Path Options

typedef NS_ENUM(NSInteger, AAPLResolveKernelPath)
{
    AAPLResolveKernelPathImmediate = 0,
    AAPLResolveKernelPathTileBased,
    AAPLResolveKernelPathOptionsCount
};

static inline NSString* getLabelForAAPLResolveKernelPath(AAPLResolveKernelPath resolveKernelPath)
{
    switch (resolveKernelPath)
    {
        case AAPLResolveKernelPathImmediate:
            return @"Immediate";
        case AAPLResolveKernelPathTileBased:
            return @"Tile-based";
        default:
            return @"";
    }
}

#pragma mark - Rendering Quality Options

typedef NS_ENUM(NSInteger, AAPLRenderingQuality)
{
    AAPLRenderingQualitySixteenth = 0,
    AAPLRenderingQualityEighth,
    AAPLRenderingQualityQuarter,
    AAPLRenderingQualityThird,
    AAPLRenderingQualityHalf,
    AAPLRenderingQualityOriginal,
    AAPLRenderingQualityOptionsCount,
};

static inline NSString* getLabelForAAPLRenderingQuality(AAPLRenderingQuality renderingQuality)
{
    switch (renderingQuality)
    {
        case AAPLRenderingQualitySixteenth:
            return @"1/16";
        case AAPLRenderingQualityEighth:
            return @"1/8";
        case AAPLRenderingQualityQuarter:
            return @"1/4";
        case AAPLRenderingQualityThird:
            return @"1/3";
        case AAPLRenderingQualityHalf:
            return @"1/2";
        case AAPLRenderingQualityOriginal:
            return @"Original";
        default:
            return @"";
    }
}

static inline float lookupQualityFactor(AAPLRenderingQuality RenderingQuality)
{
    switch (RenderingQuality)
    {
        case AAPLRenderingQualitySixteenth:
            return 0.0625;
        case AAPLRenderingQualityEighth:
            return 0.125;
        case AAPLRenderingQualityQuarter:
            return 0.25;
        case AAPLRenderingQualityThird:
            return 1.0 / 3.0;
        case AAPLRenderingQualityHalf:
            return 0.5;
        case AAPLRenderingQualityOriginal:
            return 1.0;
        default:
            return 1.0;
    }
}
