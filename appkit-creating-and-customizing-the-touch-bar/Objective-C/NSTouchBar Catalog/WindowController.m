/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Main window controller for this sample.
*/

#import "WindowController.h"

static NSTouchBarItemIdentifier WindowControllerLabelIdentifier = @"com.TouchBarCatalog.windowController.label";
static NSString *backgroundWindowIdentifier = @"BackgroundWindow";

@interface WindowController () <NSTouchBarDelegate>

// Background Window for testing the TouchBar in the context of an NSPopover.
@property (nonatomic, strong) NSWindowController *backgroundWindowController;

@end


#pragma mark -

@implementation WindowController

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    self.window.frameAutosaveName = @"WindowAutosave";

    // Load the Background Window from its separate storyboard.
    NSStoryboard *storyboard = [NSStoryboard storyboardWithName:backgroundWindowIdentifier bundle: nil];
    _backgroundWindowController = [storyboard instantiateControllerWithIdentifier:backgroundWindowIdentifier];
    self.backgroundWindowController.window.frameAutosaveName = backgroundWindowIdentifier;
    [self.backgroundWindowController showWindow:nil];
}

#pragma mark NSTouchBarProvider

// This window controller has only one NSTouchBarItem instance, which is a simple label,
// to show that the view controller bar can reside alongside its window controller.
//
- (NSTouchBar *)makeTouchBar
{
    NSTouchBar *bar = [[NSTouchBar alloc] init];
    bar.delegate = self;
        
    // Set the default ordering of items.
    bar.defaultItemIdentifiers =
        @[WindowControllerLabelIdentifier, NSTouchBarItemIdentifierOtherItemsProxy];
    
    return bar;
}

#pragma mark NSTouchBarDelegate

// The system calls this while constructing the NSTouchBar for each NSTouchBarItem you want to create.
- (nullable NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier
{
    if ([identifier isEqualToString:WindowControllerLabelIdentifier])
    {
        NSTextField *theLabel = [NSTextField labelWithString:NSLocalizedString(@"Catalog", @"")];
        
        NSCustomTouchBarItem *customItemForLabel =
            [[NSCustomTouchBarItem alloc] initWithIdentifier:WindowControllerLabelIdentifier];
        customItemForLabel.view = theLabel;
        
        // You want this label to always be visible no matter how many items are in the NSTouchBar instance.
        customItemForLabel.visibilityPriority = NSTouchBarItemPriorityHigh;
        
        return customItemForLabel;
    }
    
    return nil;
}

@end
