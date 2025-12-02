/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation of the cross-platform asset loader.
*/

#import "AssetLoader.h"
#import <MetalKit/MetalKit.h>

@implementation AssetLoader
{
    id<MTLDevice> _device;
    MTKTextureLoader *_textureLoader;
    NSDictionary *_textureLoaderOptions;
}

- (nonnull instancetype)initWithDevice:(nonnull id<MTLDevice>)device
{
    if (self = [super init])
    {
        _device = device;
        _textureLoader = [[MTKTextureLoader alloc] initWithDevice:_device];
        _textureLoaderOptions = @{
            MTKTextureLoaderOptionTextureUsage       : @(MTLTextureUsageShaderRead),
            MTKTextureLoaderOptionTextureStorageMode : @(MTLStorageModePrivate)
        };
    }
    
    return self;
}

- (nullable id<MTLTexture>)loadTextureWithName:(nonnull NSString *)resourceName
{
    NSError *error;
    id<MTLTexture> texture;
    
    // Check whether there's a URL that matches the resource name, or look in the main bundle.
    NSURL *url = [[NSBundle mainBundle] URLForResource:resourceName withExtension:nil];
    if (url)
    {
        texture = [_textureLoader newTextureWithContentsOfURL:url options:_textureLoaderOptions error:&error];
    }
    else
    {
        texture = [_textureLoader newTextureWithName:resourceName
                                         scaleFactor:1.0
                                              bundle:nil
                                             options:_textureLoaderOptions
                                               error:&error];
    }
    
    if (!texture)
    {
        NSLog(@"The app couldn't load the texture %@", resourceName);
        NSLog(@"Error info: %@", error);
        return nil;
    }
    
    return texture;
}

@end
