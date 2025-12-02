/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller responsible for showing NSPickerTouchBarItem in an NSTouchBar instance.
*/

#import "PickerViewController.h"

static NSTouchBarCustomizationIdentifier PickerItemCustomizationIdentifier = @"com.TouchBarCatalog.pickerItemController";
static NSTouchBarItemIdentifier PickerItemIdentifier = @"com.TouchBarCatalog.pickerItem";

@interface PickerViewController () <NSTouchBarDelegate>

@property (weak) IBOutlet NSButton *singleSelection;
@property (weak) IBOutlet NSButton *collapsedState;
@property (weak) IBOutlet NSButton *imagesState;

@end

#pragma mark -

@implementation PickerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (IBAction)singleSelectionAction:(id)sender {
    // Change each button to the right background color.
    for (NSTouchBarItemIdentifier itemIdentifier in self.touchBar.itemIdentifiers)
    {
        if (itemIdentifier == PickerItemIdentifier)
        {
            NSPickerTouchBarItem *pickerTouchBarItem = [self.touchBar itemForIdentifier:itemIdentifier];
        
            // First reset the selection.
            pickerTouchBarItem.selectedIndex = -1;
            
            pickerTouchBarItem.selectionMode =
                (self.singleSelection.state == NSControlStateValueOn) ?
            NSPickerTouchBarItemSelectionModeSelectOne : NSPickerTouchBarItemSelectionModeSelectAny;
        }
    }
}

- (IBAction)imagesAction:(id)sender {
    // This creates a call to makeTouchBar.
    self.touchBar = nil;
}

- (IBAction)collapsedAction:(id)sender {
    for (NSTouchBarItemIdentifier itemIdentifier in self.touchBar.itemIdentifiers)
    {
        if (itemIdentifier == PickerItemIdentifier)
        {
            NSPickerTouchBarItem *pickerTouchBarItem = [self.touchBar itemForIdentifier:itemIdentifier];
            pickerTouchBarItem.controlRepresentation = self.collapsedState.state ==
                NSControlStateValueOn ? NSPickerTouchBarItemControlRepresentationCollapsed : NSPickerTouchBarItemControlRepresentationAutomatic;
        }
    }
}

- (void)itemPicked:(id)sender {
    NSLog(@"Item Picked = %ld\n", ((NSPickerTouchBarItem *)sender).selectedIndex);
}

#pragma mark NSTouchBarProvider

- (NSTouchBar *)makeTouchBar
{
    NSTouchBar *bar = [[NSTouchBar alloc] init];
    bar.delegate = self;
    
    bar.customizationIdentifier = PickerItemCustomizationIdentifier;
    
    // Set the default ordering of items.
    bar.defaultItemIdentifiers =
        @[PickerItemIdentifier, NSTouchBarItemIdentifierOtherItemsProxy];
    
    bar.customizationAllowedItemIdentifiers = @[PickerItemIdentifier];
    
    return bar;
}

#pragma mark NSTouchBarDelegate

// The system calls this while constructing the NSTouchBar for each NSTouchBarItem you want to create.
- (nullable NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier
{
    if ([identifier isEqualToString:PickerItemIdentifier])
    {
        NSPickerTouchBarItem *pickerTouchBarItem = nil;
        
        NSPickerTouchBarItemSelectionMode selectionMode =
            (self.singleSelection.state == NSControlStateValueOn) ?
                NSPickerTouchBarItemSelectionModeSelectOne : NSPickerTouchBarItemSelectionModeSelectAny;
        // You can also use:
        // selectionMode = NSPickerTouchBarItemSelectionModeSelectMomentary
        
        if (self.imagesState.state == NSControlStateValueOn) {
            NSArray *images = @[ [NSImage imageWithSystemSymbolName:@"applewatch" accessibilityDescription:@"Apple Watch"],
                               [NSImage imageWithSystemSymbolName:@"desktopcomputer" accessibilityDescription:@"iMac"],
                                 [NSImage imageWithSystemSymbolName:@"iphone" accessibilityDescription:@"iPhone"],
                                 [NSImage imageWithSystemSymbolName:@"appletv" accessibilityDescription:@"Apple TV"]
            ];
            pickerTouchBarItem =
                [NSPickerTouchBarItem pickerTouchBarItemWithIdentifier:PickerItemIdentifier
                                                                images:images
                                                         selectionMode:selectionMode
                                                                target:self
                                                                action:@selector(itemPicked:)];
        }
        else
        {
            NSArray *labels = @[@"Item 1", @"Item 2", @"Item 3", @"Item 4"];
            pickerTouchBarItem =
                [NSPickerTouchBarItem pickerTouchBarItemWithIdentifier:PickerItemIdentifier
                                                                labels:labels
                                                         selectionMode:selectionMode
                                                                target:self
                                                                action:@selector(itemPicked:)];
        }
        
        pickerTouchBarItem.selectionColor = [NSColor systemTealColor];
        pickerTouchBarItem.collapsedRepresentationLabel = @"Choices";
        pickerTouchBarItem.controlRepresentation =
            self.collapsedState.state ==
                NSControlStateValueOn ? NSPickerTouchBarItemControlRepresentationCollapsed : NSPickerTouchBarItemControlRepresentationAutomatic;
        
        return pickerTouchBarItem;
    }
    
    return nil;
}

@end
