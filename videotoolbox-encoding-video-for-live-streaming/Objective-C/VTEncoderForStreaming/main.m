/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A Video Toolbox encoder sample app for live streaming.
*/

#import <AVFoundation/AVFoundation.h>
#import "VTEncoderUtil.h"
#import "VTEncoderForStreaming.h"

static const char *defaultDestMoviePath = "out.mov";
static const int64_t defaultFrameCount = 0;
static const FourCharCode defaultPixelFormat = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
static const CMVideoCodecType defaultCodec = kCMVideoCodecType_H264;
static const int32_t defaultDestWidth = 1280;
static const int32_t defaultDestHeight = 720;

static void usage(const char *appName)
{
    if(! appName) {
        fprintf(stderr, "usage: internal Error\n");
        return;
    }

    fprintf(stderr, "Usage: %s source_movie [options]\n\n", appName);

    fprintf(stderr, "\t--bitrate <n>            : destination movie target bit rate in bps (default: unset)\n");
    fprintf(stderr, "\t--cbr                    : pad encoded frame for constant bit rate\n");
    fprintf(stderr, "\t--codec <s>              : codec fourCC to encode with. Use 'avc1' or 'hvc1' (default: %s)\n", fourCCToString(defaultCodec));
    fprintf(stderr, "\t--dimensions <n n>       : destination movie width and height (default: %d %d)\n", defaultDestWidth, defaultDestHeight);
    fprintf(stderr, "\t--frames <n>             : max number of frames to encode (default: all frames)\n");
    fprintf(stderr, "\t--keyframe-duration <f>  : max key frame interval in sec (default: unset)\n");
    fprintf(stderr, "\t--keyframe-interval <n>  : max key frame interval in number of frames (default: unset)\n");
    fprintf(stderr, "\t--look-ahead-frames <n>  : number of frames to use for additional analysis (default: unset)\n");
    fprintf(stderr, "\t--out <s>                : destination movie file to write output video frames to (default: %s)\n", defaultDestMoviePath);
    fprintf(stderr, "\t--pixel-format <s>       : pixel format to encode with. Use '420v' or 'BGRA' (default: %s)\n", fourCCToString(defaultPixelFormat));
    fprintf(stderr, "\t--preset <s>             : encode preset. Use 'balanced', 'highQuality', or 'highSpeed' (default: unset)\n");
    fprintf(stderr, "\t--profile <s>            : codec profile. Use 'main', 'high', or 'main10' if codec supports it (default: unset)\n");
    fprintf(stderr, "\t--spatial-adaptive-qp <s>: control spatial adaptation of the quantization parameter based on per-frame statistics. Use 'default' or 'disabled' (default: unset)\n");
    fprintf(stderr, "\t--verbose                : print noisy status\n");
    fprintf(stderr, "\t-h, --help               : print this usage\n\n");
}

static void dumpOptions(Options *options)
{
    if(! options) {
        fprintf(stderr, "dumpOptions: internal Error\n");
        return;
    }

    fprintf(stderr, "\nApplication parameters\n");
    fprintf(stderr, "\tsource movie          : %s\n", options->sourceMoviePath);
    if(options->destBitRate) {
        fprintf(stderr, "\t--bitrate             : %d bps\n", options->destBitRate);
    } else {
        fprintf(stderr, "\t--bitrate             : not set\n");
    }
    fprintf(stderr, "\t--cbr                 : %s\n", (options->constantBitRateMode) ? "yes" : "no");
    fprintf(stderr, "\t--codec               : %s\n", fourCCToString(options->codec));
    fprintf(stderr, "\t--dimensions          : %d x %d\n", options->destWidth, options->destHeight);
    fprintf(stderr, "\t--frames              : %llu frames\n", options->frameCount);
    if(options->maxKeyFrameIntervalDuration) {
        fprintf(stderr, "\t--keyframe-duration   : %.2f sec\n", options->maxKeyFrameIntervalDuration);
    } else {
        fprintf(stderr, "\t--keyframe-duration   : not set\n");
    }
    if(options->maxKeyFrameInterval) {
        fprintf(stderr, "\t--keyframe-interval   : %d frames\n", options->maxKeyFrameInterval);
    } else {
        fprintf(stderr, "\t--keyframe-interval   : not set\n");
    }
    if(options->lookAheadFramesIsSet) {
        fprintf(stderr, "\t--look-ahead-frames   : %d frames\n", options->lookAheadFrames);
    } else {
        fprintf(stderr, "\t--look-ahead-frames   : not set\n");
    }
    fprintf(stderr, "\t--out                 : %s\n", options->destMoviePath);
    fprintf(stderr, "\t--pixel-format        : %s\n", fourCCToString(options->pixelFormat));
    if(options->preset) {
        fprintf(stderr, "\t--preset              : %s\n", presetToString(options->preset));
    } else {
        fprintf(stderr, "\t--preset              : not set\n");
    }
    if(options->profile) {
        fprintf(stderr, "\t--profile             : %s\n", profileToString(options->profile));
    } else {
        fprintf(stderr, "\t--profile             : not set\n");
    }
    if(options->spatialAdaptiveQPIsSet) {
        fprintf(stderr, "\t--spatial-adaptive-qp : %s\n", qpModulationLevelToString(options->spatialAdaptiveQP));
    } else {
        fprintf(stderr, "\t--spatial-adaptive-qp : not set\n");
    }
    fprintf(stderr, "\n");
}

static OSStatus parseOptions(int argc, const char * argv[], Options *options)
{
    OSStatus err = noErr;
    const char *appName = NULL;
    const char *profileName = NULL;
    BOOL printUsage = false;

    if((argc < 1) || (! argv) || (! options)) {
        fprintf(stderr, "parseOptions: internal error.\n");
        err = -1;
        goto bail;
    }

    appName = getApplicationName(argv[0]);

    if((argc < 2) || (0 == strcmp(argv[1], "--help")) || (0 == strcmp(argv[1], "-h"))) {
        err = -1;
        printUsage = true;
        goto bail;
    }

    memset((void*)options, 0, sizeof(Options));
    options->destMoviePath = defaultDestMoviePath;
    options->frameCount = defaultFrameCount;
    options->pixelFormat = defaultPixelFormat;
    options->codec = kCMVideoCodecType_H264;
    options->preset = NULL;
    options->profile = NULL;
    options->destWidth = defaultDestWidth;
    options->destHeight = defaultDestHeight;
    options->destBitRate = 0;
    options->maxKeyFrameInterval = 0;
    options->maxKeyFrameIntervalDuration = 0.0;
    options->lookAheadFramesIsSet = false;
    options->spatialAdaptiveQPIsSet = false;
    options->constantBitRateMode = false;
    options->verbose = false;
    options->replace = true;

    options->sourceMoviePath = argv[1];
    argc -= 1;
    argv += 1;

    while(argc > 1) {
        if(0 == strcmp(argv[1], "--help") || 0 == strcmp(argv[1], "-h")) {
            err = -1;
            printUsage = true;
            goto bail;
        }

        if(0 == strcmp(argv[1], "--bitrate")) {
            checkArgCount(3);
            options->destBitRate = (int32_t)strtol(argv[2], NULL, 0);
            if(options->destBitRate <= 0) {
                fprintf(stderr, "Error: destination movie target bit rate must be greater than 0.\n");
                err = -1;
                goto bail;
            }
            argc -= 2;
            argv += 2;
        }
        else if(0 == strcmp(argv[1], "--cbr")) {
            options->constantBitRateMode = true;
            argc--;
            argv++;
        }
        else if(0 == strcmp(argv[1], "--codec")) {
            checkArgCount(3);
            options->codec = EndianU32_BtoN(*(uint32_t *) argv[2]);
            err = validateCodecType(options->codec);
            if(err) {
                fprintf(stderr, "Error: %s doesn't support codec type '%s'.\n", appName, fourCCToString(options->codec));
                err = -1;
                goto bail;
            }
            argc -= 2;
            argv += 2;
        }
        else if(0 == strcmp(argv[1], "--dimensions")) {
            checkArgCount(4);
            options->destWidth = (int32_t)strtol(argv[2], NULL, 0);
            options->destHeight = (int32_t)strtol(argv[3], NULL, 0);
            if(options->destWidth < 64) {
                fprintf(stderr, "Error: destination movie width must be 64 or greater.\n");
                err = -1;
                goto bail;
            }
            if(options->destHeight < 64) {
                fprintf(stderr, "Error: destination movie height must be 64 or greater.\n");
                err = -1;
                goto bail;
            }
            argc -= 3;
            argv += 3;
        }
        else if(0 == strcmp(argv[1], "--frames")) {
            checkArgCount(3);
            options->frameCount = (int64_t)strtol(argv[2], NULL, 0);
            if(options->frameCount <= 0) {
                fprintf(stderr, "Error: number of frames must be greater than 0.\n");
                err = -1;
                goto bail;
            }
            argc -= 2;
            argv += 2;
        }
        else if(0 == strcmp(argv[1], "--keyframe-duration")) {
            checkArgCount(3);
            options->maxKeyFrameIntervalDuration = (Float64)strtof(argv[2], NULL);
            if(options->maxKeyFrameIntervalDuration <= 0) {
                fprintf(stderr, "Error: destination movie key frame duration must be greater than 0.\n");
                err = -1;
                goto bail;
            }
            argc -= 2;
            argv += 2;
        }
        else if(0 == strcmp(argv[1], "--keyframe-interval")) {
            checkArgCount(3);
            options->maxKeyFrameInterval = (int32_t)strtol(argv[2], NULL, 0);
            if(options->maxKeyFrameInterval <= 0) {
                fprintf(stderr, "Error: destination movie key frame interval must be greater than 0.\n");
                err = -1;
                goto bail;
            }
            argc -= 2;
            argv += 2;
        }
        else if(0 == strcmp(argv[1], "--look-ahead-frames")) {
            checkArgCount(3);
            options->lookAheadFrames = (int32_t)strtol(argv[2], NULL, 0);
            options->lookAheadFramesIsSet = true;
            argc -= 2;
            argv += 2;
        }
        else if(0 == strcmp(argv[1], "--spatial-adaptive-qp")) {
            checkArgCount(3);
            err = parseQPModulationLevel(argv[2], &options->spatialAdaptiveQP);
            if(err != noErr) {
                fprintf(stderr, "Error: unknown value for --spatial-adaptive-qp '%s' supported values are [default,disabled].\n", argv[2]);
                err = -1;
                goto bail;
            }
            options->spatialAdaptiveQPIsSet = true;
            argc -= 2;
            argv += 2;
        }
        else if(0 == strcmp(argv[1], "--out")) {
            checkArgCount(3);
            options->destMoviePath = argv[2];
            argc -= 2;
            argv += 2;
        }
        else if(0 == strcmp(argv[1], "--pixel-format")) {
            checkArgCount(3);
            options->pixelFormat = EndianU32_BtoN(*(uint32_t *) argv[2]);
            err = validatePixelFormat(options->pixelFormat);
            if(err) {
                fprintf(stderr, "Error: %s doesn't support pixel format '%s'.\n", appName, fourCCToString(options->pixelFormat));
                err = -1;
                goto bail;
            }
            argc -= 2;
            argv += 2;
        }
        else if(0 == strcmp(argv[1], "--preset")) {
            checkArgCount(3);
            err = parsePreset(argv[2], &options->preset);
            if(err != noErr) {
                fprintf(stderr, "Error: unknown value for --preset '%s', supported values are [balanced,highQuality,highSpeed].\n", argv[2]);
                err = -1;
                goto bail;
            }
            argc -= 2;
            argv += 2;
        }
        else if(0 == strcmp(argv[1], "--profile")) {
            checkArgCount(3);
            profileName = argv[2];
            argc -= 2;
            argv += 2;
        }
        else if(0 == strcmp(argv[1], "--verbose")) {
            options->verbose = true;
            argc--;
            argv++;
        }
        else {
            fprintf(stderr, "Error: unknown option '%s'.\n", argv[1]);
            err = -1;
            goto bail;
        }
    }

    if(! options->sourceMoviePath) {
        fprintf(stderr, "Error: source movie file name was not provided.\n");
        err = -1;
        goto bail;
    }

    if(options->preset && options->constantBitRateMode) {
        fprintf(stderr, "Error: --preset is not compatible with --cbr.\n");
        err = -1;
        goto bail;
    }

    if(options->codec == kCMVideoCodecType_HEVC && options->constantBitRateMode) {
        fprintf(stderr, "Error: '%s' does not support --cbr.\n", fourCCToString(kCMVideoCodecType_HEVC));
        err = -1;
        goto bail;
    }

    if(profileName) {
        err = parseProfile(profileName, options->codec, &options->profile);
        if(err != noErr) {
            fprintf(stderr, "Error: '%s' doesn't support '%s' profile.\n", fourCCToString(options->codec), profileName);
            err = -1;
            goto bail;
        }
    }

    if(options->verbose) {
        dumpOptions(options);
    }

bail:
    if(printUsage) {
        usage(appName);
    }
    
    return err;
}

int main(int argc, const char * argv[])
{
    OSStatus err = noErr;
    Options options = {0};
    const char *newDestPath = NULL;

    err = parseOptions(argc, argv, &options);
    if(err) {
        goto bail;
    }

    options.destFileType = createNewMoviePathIfNecessaryAndGetFileType(options.destMoviePath, &newDestPath);

    if(newDestPath) {
        options.destMoviePath = newDestPath;
    }
    if(! strcmp(options.sourceMoviePath, options.destMoviePath)) {
        fprintf(stderr, "Error: source movie and destination movie are the same.\n");
        err = -1;
        goto bail;
    }

    @autoreleasepool {
        err = processVideoStreaming(&options);
        if(err) {
            goto bail;
        }
    }

bail:
    if(newDestPath) {
        free((void *)newDestPath);
    }

    if(err) {
        exit(1);
    }
}
