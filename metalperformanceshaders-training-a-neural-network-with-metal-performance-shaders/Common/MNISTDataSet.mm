/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Convenience wrapper to work with the dataset.
*/

#import "MNISTDataSet.h"
#import <zlib.h>

/*
 *  Extend NSData to be able to gunzip .data files.
 */
@interface NSData (gunzip)

- (NSData *)gunzippedData;

@end

@implementation NSData (gunzip)

- (NSData *)gunzippedData
{

    z_stream stream;
    stream.zalloc = Z_NULL;
    stream.zfree = Z_NULL;
    stream.avail_in = (uint)self.length;
    stream.next_in = (Bytef *)self.bytes;
    stream.total_out = 0;
    stream.avail_out = 0;

    NSMutableData *output = nil;
    if (inflateInit2(&stream, 47) == Z_OK)
    {
        int status = Z_OK;
        output = [NSMutableData dataWithCapacity:self.length * 2];
        while (status == Z_OK)
        {
            if (stream.total_out >= output.length)
            {
                output.length += self.length / 2;
            }
            stream.next_out = (uint8_t *)output.mutableBytes + stream.total_out;
            stream.avail_out = (uInt)(output.length - stream.total_out);
            status = inflate (&stream, Z_SYNC_FLUSH);
        }
        if (inflateEnd(&stream) == Z_OK)
        {
            if (status == Z_STREAM_END)
            {
                output.length = stream.total_out;
            }
        }
    }

    return output;
}

@end

/*
 *  Helper function to uncompress .gz files to .data
 */
NSData *uncompress(NSData* compressedData){

    // Attempt to uncompress it.
    NSData *uncompressedData = [compressedData gunzippedData];
    if (!uncompressedData) {
        NSLog(@"Decompression failed");
    }
    return uncompressedData;
}

/*
 *  Helper function to download mnist dataset files.
 */
NSData *downloadFile(NSString *stringURL){
    NSLog(@"Downloading %@", stringURL);
    NSError *error = nil;
    NSURL  *url = [NSURL URLWithString:stringURL];
    NSData *urlData = [NSData dataWithContentsOfURL:url];
    if ( urlData )
    {
        NSLog(@"Downloaded %@", stringURL);
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", NSBundle.mainBundle.bundleURL.path, stringURL.lastPathComponent];
        [urlData writeToFile:filePath options:NSDataWritingAtomic error:&error];
        assert(!error);
    } else {
        NSLog(@"Downloading %@ failed!", stringURL);
    }

    NSData *uncompressedData = uncompress(urlData);
    if(uncompressedData){
        NSURL *url = [NSURL URLWithString:stringURL.lastPathComponent];
        NSURL *filename = [url URLByDeletingPathExtension];
        NSString *filePath = [NSString stringWithFormat:@"%@/%@.data", NSBundle.mainBundle.bundleURL.path, filename];
        [uncompressedData writeToFile:filePath options:NSDataWritingAtomic error:&error];
        assert(!error);
    }
    assert([NSBundle mainBundle].unload);
    assert([NSBundle mainBundle].load);
    return uncompressedData;
}

@implementation MNISTDataSet



-(nullable instancetype) init{

    self = [super init];
    if(self == nil)
        return self;

    // Saved url for the mnist dataset from online.
    NSString *trainImagesURL = @"http://yann.lecun.com/exdb/mnist/train-images-idx3-ubyte.gz";
    NSString *trainLabelsURL = @"http://yann.lecun.com/exdb/mnist/train-labels-idx1-ubyte.gz";
    NSString *testImagesURL = @"http://yann.lecun.com/exdb/mnist/t10k-images-idx3-ubyte.gz";
    NSString *testLabelsURL = @"http://yann.lecun.com/exdb/mnist/t10k-labels-idx1-ubyte.gz";

    // Get the url to mnist training images and labels.
    NSString* imageTrainPath = [[NSBundle mainBundle] pathForResource: @"train-images-idx3-ubyte"
                                                               ofType: @"data"];

    // If data is not in the main bundle, download it, else just load it.
    dataTrainImage = nil;
    if(!imageTrainPath){
        dataTrainImage = downloadFile(trainImagesURL);
    } else {
        NSURL *url = [[NSBundle mainBundle] URLForResource: @"train-images-idx3-ubyte" withExtension:@"data"];
        dataTrainImage = [NSData dataWithContentsOfURL: url];
    }

    NSString* labelTrainPath = [[NSBundle mainBundle] pathForResource: @"train-labels-idx1-ubyte"
                                                               ofType: @"data"];
    dataTrainLabel = nil;
    if(!labelTrainPath){
        dataTrainLabel = downloadFile(trainLabelsURL);
    } else {
        NSURL *url = [[NSBundle mainBundle] URLForResource: @"train-labels-idx1-ubyte" withExtension:@"data"];
        dataTrainLabel = [NSData dataWithContentsOfURL: url];
    }





    // Get the url to mnist testing images and labels.
    NSString* imgTestPath = [[NSBundle mainBundle] pathForResource: @"t10k-images-idx3-ubyte"
                                                            ofType: @"data"];
    // If data is not in the main bundle, download it, else just load it.
    dataTestImage = nil;
    if(!imgTestPath){
        dataTestImage = downloadFile(testImagesURL);
    } else {
        NSURL *url = [[NSBundle mainBundle] URLForResource: @"t10k-images-idx3-ubyte" withExtension:@"data"];
        dataTestImage = [NSData dataWithContentsOfURL: url];
    }

    NSString* labelTestPath = [[NSBundle mainBundle] pathForResource: @"t10k-labels-idx1-ubyte"
                                                              ofType: @"data"];
    dataTestLabel = nil;
    if(!labelTestPath){
        dataTestLabel = downloadFile(testLabelsURL);
    } else {
        NSURL *url = [[NSBundle mainBundle] URLForResource: @"t10k-labels-idx1-ubyte" withExtension:@"data"];
        dataTestLabel = [NSData dataWithContentsOfURL: url];
        labelTestPath = [[NSBundle mainBundle] pathForResource: @"t10k-labels-idx1-ubyte"
                                                        ofType: @"data"];
        assert(labelTestPath);
    }





    sizeTrainLabels = dataTrainLabel.length;
    sizeTrainImages = dataTrainImage.length;
    totalNumberOfTrainImages = sizeTrainLabels - MNIST_LABELS_METADATA_PREFIX_SIZE;

    sizeTestLabels = dataTestLabel.length;
    sizeTestImages = dataTestImage.length;
    totalNumberOfTestImages = sizeTestLabels - MNIST_LABELS_METADATA_PREFIX_SIZE;


    // Keep around the pointers.
    trainImagePointer = (uint8_t *)dataTrainImage.bytes;
    trainLabelPointer = (uint8_t *)dataTrainLabel.bytes;


    // Keep around the pointers.
    testImagePointer = (uint8_t *)dataTestImage.bytes;
    testLabelPointer = (uint8_t *)dataTestLabel.bytes;

    // Set random seed to sample images from training set.
    seed = 0;

    return self;
}

-(nullable MPSImageBatch *) getRandomTrainingBatchWithDevice: (id<MTLDevice>) device
                                                   batchSize: (NSUInteger) batchSize
                                              lossStateBatch: (MPSCNNLossLabelsBatch **)lossStateBatch{

    MPSImageDescriptor *trainImageDesc = [MPSImageDescriptor imageDescriptorWithChannelFormat:MPSImageFeatureChannelFormatUnorm8
                                                                                        width:MNIST_IMAGE_SIZE
                                                                                       height:MNIST_IMAGE_SIZE
                                                                              featureChannels:1
                                                                               numberOfImages:1
                                                                                        usage:MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead];
    MPSImageBatch *trainBatch  = @[];

    MPSCNNLossLabelsBatch *lossStateBatchOut = @[];

    for(NSUInteger i = 0; i < batchSize; i++){

        // Fetch a random index between 0 and totalNumberOfTrainImages to sample an image from training set.
        float randomNormVal = (float)rand_r(&seed) / (float)RAND_MAX;
        NSUInteger randomImageIdx = (NSUInteger)(randomNormVal * (float)totalNumberOfTrainImages);
        seed++;

        // Create an MPSImage to put in the training image.
        MPSImage *trainImage  = [[MPSImage alloc] initWithDevice:device imageDescriptor:trainImageDesc];
        trainImage.label = [@"trainImage" stringByAppendingString:[NSString stringWithFormat:@"[%lu]", i]];
        trainBatch = [trainBatch arrayByAddingObject:trainImage];

        // Write values to the training image.
        [trainImage writeBytes:(void *)ADVANCE_PTR(trainImagePointer, (MNIST_IMAGE_METADATA_PREFIX_SIZE + randomImageIdx * MNIST_IMAGE_SIZE * MNIST_IMAGE_SIZE * sizeof(uint8_t)))
                    dataLayout:(MPSDataLayoutHeightxWidthxFeatureChannels)
                    imageIndex:0];

        // Making a LossStateBatch.
        uint8_t *labelStart = ADVANCE_PTR(trainLabelPointer, MNIST_LABELS_METADATA_PREFIX_SIZE + randomImageIdx);
        float labelsBuffer[12] = {0.f};
        labelsBuffer[*labelStart] = 1.f;

        // 12 because we need the closest multiple of 4 greater than 10.
        NSData *labelsData = [NSData dataWithBytes: labelsBuffer length: 12 * sizeof(float)];

        // Labels are put in here to be added to the MPSCNNLossLabels.
        MPSCNNLossDataDescriptor* labelsDescriptor = [MPSCNNLossDataDescriptor cnnLossDataDescriptorWithData:labelsData
                                                                                                      layout:MPSDataLayoutHeightxWidthxFeatureChannels
                                                                                                        size:{1,1,12}];
        // Create loss labels.
        MPSCNNLossLabels *lossState = [[MPSCNNLossLabels alloc] initWithDevice:gDevice
                                                              labelsDescriptor:labelsDescriptor];


        lossStateBatchOut = [lossStateBatchOut arrayByAddingObject:lossState];
    }



    *lossStateBatch = lossStateBatchOut;


    return trainBatch;
}

@end

