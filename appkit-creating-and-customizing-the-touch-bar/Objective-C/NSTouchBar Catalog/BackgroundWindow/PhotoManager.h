/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Singlelton object for asynchronously loading all photos from the Desktop Pictures folder.
*/

extern NSString *kImageNameKey;
extern NSString *kImageKey;

@protocol PhotoManagerDelegate;

@interface PhotoManager: NSObject

@property (strong) NSMutableArray *photos;
@property (assign) BOOL loadComplete;

@property (nonatomic, weak, readwrite) id<PhotoManagerDelegate> delegate;

+ (PhotoManager *)shared;

@end

@protocol PhotoManagerDelegate <NSObject>

- (void)didLoadPhotos:(NSArray *)photos;

@end

