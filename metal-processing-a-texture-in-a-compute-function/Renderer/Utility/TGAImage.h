/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The interface of an image data type that parses a TGA file.
*/

#import <Foundation/Foundation.h>

@interface TGAImage : NSObject

/// Creates an image instacne by loading a TGA file.
/// 
/// The type supports a few basic TGA (targa) file formats.
/// For example, the initializer can't load files with compression, color palettes, or color maps.
///
/// - Parameter fileURL: A URL to a TGA file.
-(nullable instancetype) initWithTGAFileAtLocation:(nonnull NSURL *)fileURL;

/// The width of the image, in pixels.
@property (nonatomic, readonly) NSUInteger width;

/// The height of the image, in pixels.
@property (nonatomic, readonly) NSUInteger height;

/// The images underlying pixel data.
///
/// The data's format is equivalent to `MTLPixelFormatBGRA8Unorm`, which is:
/// - 32 bits-per-pixel (bpp)
/// - 8 bits per color component: blue, green, red, and alpha (BGRA)
@property (nonatomic, readonly, nonnull) NSData *data;

@end
