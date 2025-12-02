/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller responsible for showing grouped (NSGroupTouchBarItem) NSTouchBarItem instances with a more fancy layout.
*/

#import "FancyGroupViewController.h"

static NSTouchBarItemIdentifier FancyGroupItemIdentifier = @"com.TouchBarCatalog.fancyGroupItem";
static NSTouchBarCustomizationIdentifier FancyGroupCustomizationIdentifier = @"com.TouchBarCatalog.fancyGroupViewController";
static NSTouchBarItemIdentifier FancyGroupSliderItem = @"com.TouchBarCatalog.simpleSlider";

@interface FancyGroupViewController () <NSTouchBarDelegate>

@property (strong) NSGroupTouchBarItem *touchBarItem;
@property (weak) IBOutlet NSButton *principalCheckBox;

@end


#pragma mark -

@implementation FancyGroupViewController

- (IBAction)principalAction:(id)sender
{
    // You need to set the first responder status when the user selects this checkbox.
    [self.view.window makeFirstResponder:self.view];
    
    // Set to nil so you can call makeTouchBar again to recreate the NSTouchBar instance.
    self.touchBar = nil;
    
    // Note: If you ever want to show the NSTouchBar instance within this view controller, do this:
    // [self.view.window makeFirstResponder:self.view];
}

#pragma mark NSTouchBarProvider

- (NSTouchBar *)makeTouchBar
{
    NSTouchBar *bar = [[NSTouchBar alloc] init];
    bar.delegate = self;
    
    bar.customizationIdentifier = FancyGroupCustomizationIdentifier;
    
    // Set the default ordering of items.
    bar.defaultItemIdentifiers =
        @[FancyGroupItemIdentifier, NSTouchBarItemIdentifierOtherItemsProxy];
    
    bar.customizationAllowedItemIdentifiers = @[FancyGroupItemIdentifier];
    
    if (self.principalCheckBox.state == NSControlStateValueOn)
    {
        // Note: To make this grouping truly centered in the NSTouchBar, it must be a principle item.
        bar.principalItemIdentifier = FancyGroupItemIdentifier;
    }
    
    return bar;
}

- (void)buttonAction:(id)sender
{
    NSLog(@"button was pressed");
}

- (NSCustomTouchBarItem *)makeButtonWithIdentifier:(NSString *)theIdentifier title:(NSString *)title customizationLabel:(NSString *)customizationLabel
{
    NSButton *button = [NSButton buttonWithTitle:title target:self action:@selector(buttonAction:)];
    NSCustomTouchBarItem *touchBarItem = [[NSCustomTouchBarItem alloc] initWithIdentifier:theIdentifier];
    touchBarItem.view = button;
    touchBarItem.customizationLabel = customizationLabel;

    return touchBarItem;
}

- (NSArray *)makeFirstGroupButtons
{
    return @[
             [self makeButtonWithIdentifier:@"com.TouchbarCatalog.fancyGroupItem.button1"
                                      title:NSLocalizedString(@"Button 1", @"")
                         customizationLabel:NSLocalizedString(@"Button 1", @"")],
             [self makeButtonWithIdentifier:@"com.TouchbarCatalog.fancyGroupItem.button2"
                                      title:NSLocalizedString(@"Button 2", @"")
                         customizationLabel:NSLocalizedString(@"Button 2", @"")],
             ];
}

- (NSArray *)makeSecondGroupButtons
{
    return @[
             [self makeButtonWithIdentifier:@"com.TouchbarCatalog.fancyGroupItem.button3"
                                      title:NSLocalizedString(@"Button 3", @"")
                         customizationLabel:NSLocalizedString(@"Button 3", @"")],
             [self makeButtonWithIdentifier:@"com.TouchbarCatalog.fancyGroupItem.button4"
                                      title:NSLocalizedString(@"Button 4", @"")
                         customizationLabel:NSLocalizedString(@"Button 4", @"")],
             ];
}

#pragma mark NSTouchBarDelegate

// The system calls this while constructing the NSTouchBar for each NSTouchBarItem you want to create.
- (nullable NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier
{
    if ([identifier isEqualToString:FancyGroupItemIdentifier])
    {
        // The left side is a group of two buttons.
        NSArray *firstSegItems = [self makeFirstGroupButtons];
        
        // The center is a popover.
        NSPopoverTouchBarItem *popoverTouchBarItem =
            [[NSPopoverTouchBarItem alloc] initWithIdentifier:@"com.TouchBarCatalog.centerPopover"];
        popoverTouchBarItem.collapsedRepresentationLabel = NSLocalizedString(@"Open Popover", @"");
        
        // The popover item's content is just a slider item and its label.
        NSTouchBar *secondaryTouchBar = [[NSTouchBar alloc] init];
        secondaryTouchBar.delegate = self;
        secondaryTouchBar.defaultItemIdentifiers = @[FancyGroupSliderItem];
        popoverTouchBarItem.popoverTouchBar = secondaryTouchBar;

        // The right side is a group of two buttons.
        NSArray *secondSegItems = [self makeSecondGroupButtons];
        
        // Combine all the elements in a single group.
        NSMutableArray *allItems = [[NSArray arrayWithArray:firstSegItems] mutableCopy];
        [allItems addObject:popoverTouchBarItem];
        [allItems addObjectsFromArray:secondSegItems];
        _touchBarItem = [NSGroupTouchBarItem groupItemWithIdentifier:FancyGroupItemIdentifier items:allItems];

        self.touchBarItem.customizationLabel = NSLocalizedString(@"Fancy Group", @"");

        return self.touchBarItem;
    }
    else if ([identifier isEqualToString:FancyGroupSliderItem])
    {
        NSSliderTouchBarItem *slider =
            [[NSSliderTouchBarItem alloc] initWithIdentifier:FancyGroupSliderItem];
        slider.slider.minValue = 0.0f;
        slider.slider.maxValue = 10.0f;
        slider.slider.doubleValue = 2.0f;
        slider.target = self;
        slider.action = @selector(sliderChanged:);
        slider.label = NSLocalizedString(@"Slider", @"");
        slider.customizationLabel = NSLocalizedString(@"Slider", @"");
        
        return slider;
    }
    
    return nil;
}

- (void)sliderChanged:(NSSliderTouchBarItem *)sender
{
    NSLog(@"slider changed");
}

@end
