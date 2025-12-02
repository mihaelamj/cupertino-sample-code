/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Custom NSScrubberItemView for displaying an image.
*/

#import "ThumbnailItemView.h"

@interface ThumbnailItemView ()

@property (strong) NSCache<NSString *, NSImage *> *thumbnailCache;
@property (strong) NSImageView *imageView;
@property (strong) NSProgressIndicator *spinner;

@end


#pragma mark -

@implementation ThumbnailItemView

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self != nil)
    {
        _thumbnail = [[NSImage alloc] initWithSize:frameRect.size];
        _thumbnailCache = [[NSCache alloc] init];
        _imageView = [NSImageView imageViewWithImage:_thumbnail];
        [self.imageView setAutoresizingMask:(NSAutoresizingMaskOptions)(NSViewWidthSizable | NSViewHeightSizable)];
        
        _spinner = [[NSProgressIndicator alloc] init];
        self.spinner.indeterminate = YES;
        self.spinner.style = NSProgressIndicatorStyleSpinning;
        [self.spinner sizeToFit];
        self.spinner.frame = CGRectInset(self.bounds, (self.bounds.size.width - self.spinner.frame.size.width)/2.0, (self.bounds.size.height - self.spinner.frame.size.height)/2.0);
        self.spinner.hidden = YES;
        self.spinner.controlSize = NSControlSizeSmall;
        self.spinner.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
        self.spinner.autoresizingMask = (NSAutoresizingMaskOptions)(NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin);
        
        [self addSubview:self.imageView];
        [self addSubview:self.spinner];
    }
    
    return self;
}

- (void)updateLayer
{
    [self.layer setBackgroundColor:[NSColor controlColor].CGColor];
}

- (void)layout
{
    [super layout];
    
    _imageView.frame = self.bounds;
    
    [_spinner sizeToFit];
    _spinner.frame = CGRectInset(self.bounds, (self.bounds.size.width - _spinner.frame.size.width)/2.0, (self.bounds.size.height - _spinner.frame.size.height)/2.0);
}

- (NSImage *)thumbnail
{
    return _imageView.image;
}

- (void)setThumbnail:(NSImage *)thumbnail
{
    _spinner.hidden = YES;
    [_spinner stopAnimation:nil];
    _imageView.hidden = NO;
    _imageView.image = thumbnail;
}

- (NSString *)imageName
{
    return _imageName;
}

- (void)setImageName:(NSString *)imageName
{
    if (_imageName != imageName)
    {
        NSImage *cachedThumbnail = [_thumbnailCache objectForKey:imageName];
        if (cachedThumbnail)
        {
            [self setThumbnail: cachedThumbnail];
            return;
        }
        _spinner.hidden = NO;
        [_spinner startAnimation:nil];
        _imageView.hidden = YES;
        
        NSString *currentName = imageName;
        
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{

            NSImage *fullImage = [NSImage imageNamed:currentName];
            if (fullImage == nil)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (currentName == self.imageName) {
                        [self setThumbnail:[[NSImage alloc] initWithSize:NSZeroSize]];
                    }
                });
                return;
            }
            
            NSSize imageSize = [fullImage size];
            CGFloat thumbnailHeight = 30;
            NSSize thumbnailSize = NSMakeSize(ceil(thumbnailHeight * imageSize.width / imageSize.height), thumbnailHeight);
            
            NSImage *thumbnail = [[NSImage alloc] initWithSize:thumbnailSize];
            
            [thumbnail lockFocus];
            [fullImage drawInRect:NSMakeRect(0, 0, thumbnailSize.width, thumbnailSize.height) fromRect:NSMakeRect(0, 0, imageSize.width, imageSize.height) operation:NSCompositingOperationSourceOver fraction:1.0];
            [thumbnail unlockFocus];
            
            [self.thumbnailCache setObject:thumbnail forKey:currentName];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setThumbnail:thumbnail];
            });
        });
    }
}

@end



