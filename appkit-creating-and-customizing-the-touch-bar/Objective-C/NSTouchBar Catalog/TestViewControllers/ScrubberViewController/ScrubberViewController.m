/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller responsible for showing NSCustomTouchBarItem with an NSScrubber, using a custom subclass of NSScrubberImageItemView.
*/

#import "ScrubberViewController.h"
#import "IconTextScrubberBarItem.h"
#import "ThumbnailItemView.h"
#import "ScrubberBackgroundView.h"
#import "PhotoManager.h"

// Selection appearance override:

// Selection background:
#import "CustomBackgroundScrubberSelectionStyle.h"
#import "SelectionBackgroundView.h"

// Selection overlay:
#import "CustomOverlayScrubberSelectionStyle.h"
#import "SelectionOverlayView.h"


#pragma mark Scrubber control variants

typedef NS_ENUM(NSInteger, ScrubberType)
{
    ScrubberTypeImage = 2000,
    ScrubberTypeText = 2001,
    ScrubberTypeBoth = 2014
};

typedef NS_ENUM(NSInteger, ScrubberMode)
{
    ScrubberModeFree = 2002,
    ScrubberModeFixed = 2003
};

typedef NS_ENUM(NSInteger, SelectionBackgroundStyle)
{
    ScrubberSelectionBackgroundNone = 2004,
    ScrubberSelectionBackgroundBoldOutline = 2005,
    ScrubberSelectionBackgroundSolidBackground = 2006,
    ScrubberSelectionBackgroundCustom = 2007
};

typedef NS_ENUM(NSInteger, SelectionOverlayStyle)
{
    ScrubberSelectionOverlayNone = 2008,
    ScrubberSelectionOverlayBoldOutline = 2009,
    ScrubberSelectionOverlaySolidBackground = 2010,
    ScrubberSelectionOverlayCustom = 2011
};

typedef NS_ENUM(NSInteger, FlowType)
{
    ScrubberFlow = 2012,
    ScrubberProportional = 2013
};


#pragma mark - View Controller

static NSTouchBarCustomizationIdentifier ScrubberCustomizationIdentifier = @"com.TouchBarCatalog.scrubberViewController";
static NSTouchBarItemIdentifier ScrubbedItemIdentifier = @"com.TouchBarCatalog.scrubber";

@interface ScrubberViewController () <  NSTouchBarDelegate,
                                        NSScrubberDelegate,
                                        NSScrubberDataSource,
                                        NSScrubberFlowLayoutDelegate,
                                        PhotoManagerDelegate> // A notification for when photos finish loading.

@property NSInteger scrubberType;
@property NSInteger scrubberMode;
@property NSInteger scrubberSelectionBackgroundStyle;
@property NSInteger scrubberSelectionOverlayStyle;
@property NSInteger scrubberLayout;

@property (weak) IBOutlet NSSlider *spacingSlider;
@property (weak) IBOutlet NSButton *showsArrows;
@property (weak) IBOutlet NSButton *useBackgroundColor;
@property (weak) IBOutlet NSButton *useBackgroundView;
@property (weak) IBOutlet NSColorWell *backgroundColorWell;

@end


#pragma mark -

@implementation ScrubberViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    PhotoManager.shared.delegate = self; // To receive a notitification when photos finish loading.
    
    _scrubberType = ScrubberTypeImage;
    _scrubberMode = ScrubberModeFree;
    _scrubberSelectionBackgroundStyle = ScrubberSelectionBackgroundNone;
    _scrubberSelectionOverlayStyle = ScrubberSelectionOverlayNone;
    _scrubberLayout = ScrubberFlow;
}

#pragma mark - Actions

// The system calls this when the user selects any checkbox in the UI.
- (IBAction)customizeAction:(id)sender
{
    [self invalidateTouchBar];
}

- (IBAction)useBackgroundColorAction:(id)sender
{
    NSButton *useBackgroundColorCheckbox = (NSButton *)sender;
    self.backgroundColorWell.enabled = (useBackgroundColorCheckbox.state == NSControlStateValueOn);
    [self invalidateTouchBar];
}

- (IBAction)kindAction:(id)sender
{
    _scrubberType = ((NSButton *)sender).tag;
    [self invalidateTouchBar];
}

- (IBAction)modeAction:(id)sender
{
    _scrubberMode = ((NSButton *)sender).tag;
    [self invalidateTouchBar];
}

- (IBAction)selectionAction:(id)sender
{
    _scrubberSelectionBackgroundStyle = ((NSButton *)sender).tag;
    [self invalidateTouchBar];
}

- (IBAction)overlayAction:(id)sender
{
    _scrubberSelectionOverlayStyle = ((NSButton *)sender).tag;
    [self invalidateTouchBar];
}

- (IBAction)flowAction:(id)sender
{
    _scrubberLayout = ((NSButton *)sender).tag;
    [self invalidateTouchBar];
}

- (IBAction)spacingSliderAction:(id)sender
{
    [self invalidateTouchBar];
}

#pragma mark - NSTouchBar

// For invalidating the current NSTouchBar.
- (void)invalidateTouchBar
{
    // Set the first responder status when the user selects one of the radio buttons.
    [self.view.window makeFirstResponder:self.view];
    
    // Set to nil so you can call makeTouchBar again to recreate the NSTouchBar instance.
    self.touchBar = nil;
}

#pragma mark NSTouchBarProvider

- (NSTouchBar *)makeTouchBar
{
    NSTouchBar *bar = [[NSTouchBar alloc] init];
    bar.delegate = self;
    
    bar.customizationIdentifier = ScrubberCustomizationIdentifier;
    
    // Set the default ordering of items.
    bar.defaultItemIdentifiers =
    @[ScrubbedItemIdentifier, NSTouchBarItemIdentifierOtherItemsProxy];
    
    bar.customizationAllowedItemIdentifiers = @[ScrubbedItemIdentifier];
    
    bar.principalItemIdentifier = ScrubbedItemIdentifier;
    
    return bar;
}

#pragma mark - NSScrubberDataSource

NSString *thumbnailScrubberItemIdentifier = @"thumbnailItem";
NSString *textScrubberItemIdentifier = @"textItem";

- (NSInteger)numberOfItemsForScrubber:(NSScrubber *)scrubber
{
    if (self.scrubberType == ScrubberTypeImage)
    {
        return PhotoManager.shared.photos.count;
    }
    else
    {
        return 10; // For text scrubber items, you only use an aribtary 10.
    }
}

// Scrubber is asking for a custom view representation for a particular item index.
- (NSScrubberItemView *)scrubber:(NSScrubber *)scrubber viewForItemAtIndex:(NSInteger)index
{
    if (self.scrubberType == ScrubberTypeImage)
    {
        // Use an image for this scrubber item.
        ThumbnailItemView *itemView = [scrubber makeItemWithIdentifier:thumbnailScrubberItemIdentifier owner:nil];
        if (index < PhotoManager.shared.photos.count)
        {
            NSDictionary *imageDict = PhotoManager.shared.photos[index];
            itemView.imageName = imageDict[kImageNameKey];
        }
        return itemView;
    }
    else
    {
        // Use text for this scrubber item.
        NSScrubberTextItemView *itemView = [scrubber makeItemWithIdentifier:textScrubberItemIdentifier owner:nil];
        if (index < 10)
        {
            itemView.textField.stringValue = [@(index) stringValue];
        }
        return itemView;
    }
}

#pragma mark - NSScrubberFlowLayoutDelegate

// Scrubber is asking for the size for a particular item.
- (NSSize)scrubber:(NSScrubber *)scrubber layout:(NSScrubberFlowLayout *)layout sizeForItemAtIndex:(NSInteger)itemIndex
{
    NSInteger val = self.spacingSlider.integerValue;
    
    return NSMakeSize(val, 30);
}

#pragma mark - NSScrubberDelegate

// The user chose an item inside the scrubber.
- (void)scrubber:(NSScrubber *)scrubber didSelectItemAtIndex:(NSInteger)selectedIndex
{
    NSLog(@"selectedIndex = %ld", selectedIndex);
}

- (void)didBeginInteractingWithScrubber:(NSScrubber *)scrubber
{
    // The user performed the initial touch on the scrubber.
}

- (void)didFinishInteractingWithScrubber:(NSScrubber *)scrubber
{
    // The user released their touch on the scrubber.
}

- (void)didCancelInteractingWithScrubber:(NSScrubber *)scrubber
{
    // The user canceled the interaction on the scrubber.
}

#pragma mark - NSTouchBarDelegate

// The system calls this while constructing the NSTouchBar for each NSTouchBarItem you want to create.
- (nullable NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier
{
    if ([identifier isEqualToString:ScrubbedItemIdentifier])
    {
        NSCustomTouchBarItem *scrubberItem;
        NSScrubber *scrubber;
        
        if (self.scrubberType == ScrubberTypeBoth)
        {
            // Create a scrubber with icon and text items.
            scrubberItem = [[IconTextScrubberBarItem alloc] initWithIdentifier:ScrubbedItemIdentifier];
            scrubber = scrubberItem.view;
        }
        else
        {
            // Create a scrubber that uses images.
            scrubberItem = [[NSCustomTouchBarItem alloc] initWithIdentifier:ScrubbedItemIdentifier];
            
            scrubber = [[NSScrubber alloc] initWithFrame:NSMakeRect(0, 0, 310, 30)];
            scrubber.delegate = self;   // This is so you can respond to selection.
            scrubber.dataSource = self; // This is so you can determine the content.
                        
            // Determine the scrubber content.
            if (self.scrubberType == ScrubberTypeImage)
            {
                // Scrubber will use just images.
                [scrubber registerClass:[ThumbnailItemView class] forItemIdentifier:thumbnailScrubberItemIdentifier];
                
                // For the image scrubber, you want the control to draw a fade effect to indicate that there is additional unscrolled content.
                scrubber.showsAdditionalContentIndicators = YES;
            }
            else
            {
                // Scrubber will use just text.
                [scrubber registerClass:[NSScrubberTextItemView class] forItemIdentifier:textScrubberItemIdentifier];
            }
            
            scrubber.selectedIndex = 0; // Always select the first item in the scrubber.
        }
        
        scrubberItem.customizationLabel = NSLocalizedString(@"Scrubber", @"");
        
        NSScrubberLayout *scrubberLayout;
        if (self.scrubberLayout == ScrubberFlow)
        {
            // This layout arranges items end-to-end in a linear strip.
            // It supports a fixed inter-item spacing and both fixed- and variable-sized items.
            scrubberLayout = [[NSScrubberFlowLayout alloc] init];
        }
        else if (self.scrubberLayout == ScrubberProportional)
        {
            // This layout sizes each item to some fraction of the scrubber's visible size.
            scrubberLayout = [[NSScrubberProportionalLayout alloc] init];
        }
        scrubber.scrubberLayout = scrubberLayout;
        
        // Note: You can make the text-based scrubber's background transparent by using:
        // scrubber.backgroundColor = [NSColor clearColor];
        
        switch (self.scrubberMode)
        {
            case ScrubberModeFree:
            {
                scrubber.mode = NSScrubberModeFree;
                break;
            }
                
            case ScrubberModeFixed:
            {
                scrubber.mode = NSScrubberModeFixed;
                break;
            }
        }
        
        // Provides leading and trailing arrow buttons.
        // Tapping an arrow button moves the selection index by one element; pressing and holding repeatedly moves the selection.
        //
		scrubber.showsArrowButtons = self.showsArrows.state;
        
        // Specify the style of decoration to place behind selected and highlighted items.
        switch (self.scrubberSelectionBackgroundStyle)
        {
            case ScrubberSelectionBackgroundNone:
            {
                scrubber.selectionBackgroundStyle = nil;
                break;
            }
                
            case ScrubberSelectionBackgroundBoldOutline:
            {
                NSScrubberSelectionStyle *outlineStyle = [NSScrubberSelectionStyle outlineOverlayStyle];
                scrubber.selectionBackgroundStyle = outlineStyle;
                break;
            }
                
            case ScrubberSelectionBackgroundSolidBackground:
            {
                NSScrubberSelectionStyle *solidBackgroundStyle = [NSScrubberSelectionStyle roundedBackgroundStyle];
                scrubber.selectionBackgroundStyle = solidBackgroundStyle;
                break;
            }
                
            case ScrubberSelectionBackgroundCustom:
            {
                CustomBackgroundScrubberSelectionStyle *customBackgroundStyle = [[CustomBackgroundScrubberSelectionStyle alloc] init];
                scrubber.selectionBackgroundStyle = customBackgroundStyle;
            }
        }
        
        // Specify the style of decoration to place above selected and highlighted items.
        switch (self.scrubberSelectionOverlayStyle)
        {
            case ScrubberSelectionOverlayNone:
            {
                scrubber.selectionOverlayStyle = nil;
                break;
            }
                
            case ScrubberSelectionOverlayBoldOutline:
            {
                NSScrubberSelectionStyle *outlineStyle = [NSScrubberSelectionStyle outlineOverlayStyle];
                scrubber.selectionOverlayStyle = outlineStyle;
                break;
            }
                
            case ScrubberSelectionOverlaySolidBackground:
            {
                NSScrubberSelectionStyle *solidBackgroundStyle = [NSScrubberSelectionStyle roundedBackgroundStyle];
                scrubber.selectionOverlayStyle = solidBackgroundStyle;
                break;
            }
                
            case ScrubberSelectionOverlayCustom:
            {
                CustomOverlayScrubberSelectionStyle *customOverlayStyle = [[CustomOverlayScrubberSelectionStyle alloc] init];
                scrubber.selectionOverlayStyle = customOverlayStyle;
                break;
            }
        }
        
        // BackgroundColor displays behind the scrubber content.
        // The background color supresses if the scrubber has a non-nil backgroundView.
        //
        // Note: This is only visible when using the text scrubber
        //
        if (self.useBackgroundColor.state == NSControlStateValueOn)
        {
            scrubber.backgroundColor = self.backgroundColorWell.color;
        }
        
        // BackgroundView displays below the scrubber content.
        // NSScrubber manages the view's layout to match the content area.
        // If this property is non-nil, the backgroundColor property has no effect.
        //
        // Note: This is only visible when using the text scrubber.
        if (self.useBackgroundView.state == NSControlStateValueOn)
        {
            scrubber.backgroundView = [[ScrubberBackgroundView alloc] initWithFrame:NSZeroRect];    // Use a custom view that draws a purple background.
        }
        
        // Set the layout constraints on this scrubber so that it's 400 pixels wide.
        NSDictionary *items = NSDictionaryOfVariableBindings(scrubber);
        NSArray *theConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[scrubber(400)]" options:0 metrics:nil views:items];
        [NSLayoutConstraint activateConstraints:theConstraints];
        // Or you can do this:
        //[scrubber.widthAnchor constraintLessThanOrEqualToConstant:400].active = YES;
        
        scrubberItem.view = scrubber;
        
        return scrubberItem;
    }
    
    return nil;
}

#pragma mark - PhotoManagerDelegate

- (void)didLoadPhotos:(NSArray *)photos {
    [self invalidateTouchBar];
}

@end

