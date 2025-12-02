/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The header for the cross-platform asset loader.
*/

#import <Metal/Metal.h>

@interface AssetLoader : NSObject

- (nonnull instancetype)initWithDevice:(nonnull id<MTLDevice>)device;

- (nullable id<MTLTexture>)loadTextureWithName:(nonnull NSString *)resourceName;

@end
