/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Singlelton object for asynchronously loading all photos from the Desktop Pictures folder.
*/

@import Cocoa;
@import Foundation;

#import "PhotoManager.h"

NSString *kImageNameKey = @"name";
NSString *kImageKey = @"image";

@implementation PhotoManager: NSObject

+ (PhotoManager *)shared
{
    static PhotoManager *photoManager;  // The singleton PhotoManager controller.
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        photoManager = [[PhotoManager alloc] init];
    });
    return photoManager;
}

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
            self.photos = [NSMutableArray array];
            for (NSUInteger index = 1; index <= 14; index++)
            {
                NSString *imageName = [NSString stringWithFormat:@"image%ld", index];
                NSImage *fullImage = [NSImage imageNamed: imageName];
                NSSize imageSize = [fullImage size];
                if (imageSize.width > 0 && imageSize.height > 0)
                {
                    CGFloat thumbnailHeight = 30;
                    NSSize thumbnailSize = NSMakeSize(ceil(thumbnailHeight * imageSize.width / imageSize.height), thumbnailHeight);
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSImage *thumbnail = [[NSImage alloc] initWithSize:thumbnailSize];
                        
                        [thumbnail lockFocus];
                        [fullImage drawInRect:NSMakeRect(0, 0, thumbnailSize.width, thumbnailSize.height) fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height) operation:NSCompositingOperationSourceOver fraction:1.0];
                        [thumbnail unlockFocus];

                        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                     [imageName lastPathComponent], kImageNameKey,
                                                     thumbnail, kImageKey,
                                                     // You can add any additional pertinent information for this image object here.
                                                     nil];
                        [self.photos addObject:dict];
                    });
                }
                
            }

            self.loadComplete = YES;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate didLoadPhotos:self.photos];
            });
        });
    }
	return self;
}

@end


