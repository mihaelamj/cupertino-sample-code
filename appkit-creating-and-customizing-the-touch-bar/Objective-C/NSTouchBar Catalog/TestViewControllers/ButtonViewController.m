/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller responsible for showing NSStepperTouchBarItem in an NSTouchBar instance.
*/

#import "ButtonViewController.h"

static NSTouchBarCustomizationIdentifier ButtonItemCustomizationIdentifier = @"com.TouchBarCatalog.buttonItemController";
static NSTouchBarItemIdentifier ButtonItemIdentifier = @"com.TouchBarCatalog.buttonItem";

@interface ButtonViewController () <NSTouchBarDelegate>

@property (strong) NSButtonTouchBarItem *buttonTouchBarItem;

@property (weak) IBOutlet NSButton *useCustomColor;

@end


#pragma mark -

@implementation ButtonViewController

// Note: This particular view controller doesn't allow customizing its NSTouchBar instance.

- (void)viewDidLoad
{
    [super viewDidLoad];
}

// The user chose Custom Button Color checkbox to change the button colors.
- (IBAction)customize:(id)sender
{
    // Change each button to the right background color.
    for (NSTouchBarItemIdentifier itemIdentifier in self.touchBar.itemIdentifiers)
    {
        NSButtonTouchBarItem *touchBarItem = [self.touchBar itemForIdentifier:itemIdentifier];
        NSButton *button = (NSButton *)touchBarItem.view;
        button.bezelColor = (self.useCustomColor.state == NSControlStateValueOn) ? [NSColor systemYellowColor] : nil;
    }
}

- (void)buttonAction:(id)sender
//••- (IBAction)buttonAction:(id)sender
{
    NSLog(@"%@ was pressed", ((NSButtonTouchBarItem *)sender).title);
}

#pragma mark NSTouchBarProvider

- (NSTouchBar *)makeTouchBar
{
    NSTouchBar *bar = [[NSTouchBar alloc] init];
    bar.delegate = self;
    
    bar.customizationIdentifier = ButtonItemCustomizationIdentifier;
    
    // Set the default ordering of items.
    bar.defaultItemIdentifiers =
        @[ButtonItemIdentifier, NSTouchBarItemIdentifierOtherItemsProxy];
    
    bar.customizationAllowedItemIdentifiers = @[ButtonItemIdentifier];
    
    return bar;
}

#pragma mark NSTouchBarDelegate

// The system calls this while constructing the NSTouchBar for each NSTouchBarItem you want to create.
- (nullable NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier
{
    if ([identifier isEqualToString:ButtonItemIdentifier])
    {
        _buttonTouchBarItem = [[NSButtonTouchBarItem alloc] initWithIdentifier:ButtonItemIdentifier];
        
        self.buttonTouchBarItem.title = NSLocalizedString(@"Button", @"");
        self.buttonTouchBarItem.target = self;
        self.buttonTouchBarItem.action = @selector(buttonAction:);
        self.buttonTouchBarItem.image = [NSImage imageWithSystemSymbolName:@"tray" accessibilityDescription:@"tray"];
        
        return self.buttonTouchBarItem;
    }
    
    return nil;
}

@end
