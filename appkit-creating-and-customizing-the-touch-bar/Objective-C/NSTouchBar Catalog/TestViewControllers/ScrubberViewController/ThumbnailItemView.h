/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Custom NSScrubberItemView for displaying an image.
*/

#import <Cocoa/Cocoa.h>

@interface ThumbnailItemView : NSScrubberItemView
{
    NSImage *_thumbnail;
    NSString *_imageName;
}

@property NSImage *thumbnail;
@property NSString *imageName;

@end
