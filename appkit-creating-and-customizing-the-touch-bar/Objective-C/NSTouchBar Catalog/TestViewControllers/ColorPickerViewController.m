/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller responsible for showing different color picker items.
*/

#import "ColorPickerViewController.h"
#import "SplitViewController.h"
#import "PrimaryViewController.h"

static NSTouchBarItemIdentifier ColorPickerItemIdentifier = @"com.TouchBarCatalog.colorPicker";
static NSTouchBarCustomizationIdentifier ColorPickerCustomizationIdentifier = @"com.TouchBarCatalog.colorPickerViewController";

typedef NS_ENUM(NSInteger, ColorPickerType) {
    ColorPickerTypeColor = 1002,
    ColorPickerTypeText = 1003,
    ColorPickerTypeStroke = 1004
};

@interface ColorPickerViewController () <NSTouchBarDelegate>

@property (strong) NSColorPickerTouchBarItem *colorPickerItem;
@property (strong) IBOutlet NSButton *customColors;

@property ColorPickerType pickerType;

@end


#pragma mark -

@implementation ColorPickerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _pickerType = ColorPickerTypeColor;
    
    // Note: If you ever want to show the NSTouchBar instance within this view controller, do this:
    // [self.view.window makeFirstResponder:self.view];
}

- (void)invalidateTouchBar
{
    // Set the first responder status when the user selects a radio button.
    [self.view.window makeFirstResponder:self.view];
    
    // Set to nil so you can call makeTouchBar again to recreate the NSTouchBar instance.
    self.touchBar = nil;
}

- (IBAction)customColorsAction:(id)sender
{
    [self invalidateTouchBar];
}

- (IBAction)choiceAction:(id)sender
{
    _pickerType = ((NSButton *)sender).tag;
    
    [self invalidateTouchBar];
}

#pragma mark NSTouchBarProvider

- (NSTouchBar *)makeTouchBar
{
    NSTouchBar *bar = [[NSTouchBar alloc] init];
    bar.delegate = self;
    
    bar.customizationIdentifier = ColorPickerCustomizationIdentifier;
    
    // Set the default ordering of items.
    bar.defaultItemIdentifiers = @[ColorPickerItemIdentifier, NSTouchBarItemIdentifierOtherItemsProxy];
    
    bar.customizationAllowedItemIdentifiers = @[ColorPickerItemIdentifier];
    
    bar.principalItemIdentifier = ColorPickerItemIdentifier;
    
    return bar;
}

#pragma mark NSTouchBarDelegate

// The system calls this while constructing the NSTouchBar for each NSTouchBarItem you want to create.
- (nullable NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier
{
    if ([identifier isEqualToString:ColorPickerItemIdentifier])
    {
        if (self.pickerType == ColorPickerTypeColor)
        {
            // Create a bar item containing a button with the standard color picker icon that invokes the color picker.
            _colorPickerItem = [NSColorPickerTouchBarItem colorPickerWithIdentifier:ColorPickerItemIdentifier];
            self.colorPickerItem.target = self;
            self.colorPickerItem.action = @selector(colorAction:);
        }
        else if (self.pickerType == ColorPickerTypeText)
        {
            // Create a bar item containing a button with the standard text color picker icon that invokes the color picker. Use this when picking text colors.
            _colorPickerItem = [NSColorPickerTouchBarItem textColorPickerWithIdentifier:ColorPickerItemIdentifier];
            self.colorPickerItem.target = self;
            self.colorPickerItem.action = @selector(colorAction:);
        }
        else if (self.pickerType == ColorPickerTypeStroke)
        {
            // Creates a bar item containing a button with the standard stroke color picker icon that invokes the color picker.
            // Use this when picking stroke colors.
            _colorPickerItem = [NSColorPickerTouchBarItem strokeColorPickerWithIdentifier:ColorPickerItemIdentifier];
            self.colorPickerItem.target = self;
            self.colorPickerItem.action = @selector(colorAction:);
        }
        
        if (self.customColors.state == NSControlStateValueOn)
        {
            // Use a custom color list for the picker.
            self.colorPickerItem.colorList = [[NSColorList alloc] init];
            [self.colorPickerItem.colorList setColor:[NSColor systemRedColor] forKey:@"Red"];
            [self.colorPickerItem.colorList setColor:[NSColor systemGreenColor] forKey:@"Green"];
            [self.colorPickerItem.colorList setColor:[NSColor systemBlueColor] forKey:@"Blue"];
        }
        
        self.colorPickerItem.customizationLabel = NSLocalizedString(@"Color Picker", @"");
        
        return self.colorPickerItem;
    }
    
    return nil;
}

- (void)colorAction:(id)sender
{
    NSLog(@"Color Chosen = %@\n", ((NSColorPickerTouchBarItem *)sender).color);
}

@end
