/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller responsible for showing NSButtons in an NSTouchBar instance.
*/

#import "CustomItemViewController.h"

@interface CustomItemViewController ()

@property (strong) NSCustomTouchBarItem *touchBarItem;

// View Controller
@property (weak) IBOutlet NSButton *sizeConstraint;
@property (weak) IBOutlet NSButton *useCustomColor;

// NSTouchBar
@property (weak) IBOutlet NSLayoutConstraint *button3WidthConstraint;
@property (assign) CGFloat originalButton3Width;

@end


#pragma mark -

@implementation CustomItemViewController

// Note: This particular view controller doesn't allow customizing its NSTouchBar instance.

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Remember the original size width of button3.
    _originalButton3Width = self.button3WidthConstraint.constant;
}

// The user chose Custom Button Color checkbox to change the button colors.
- (IBAction)customize:(id)sender
{
    // Change each button to the right background color.
    for (NSTouchBarItemIdentifier itemIdentifier in self.touchBar.itemIdentifiers)
    {
        NSCustomTouchBarItem *touchBarItem = [self.touchBar itemForIdentifier:itemIdentifier];
        
        NSButton *button = touchBarItem.view;
        button.bezelColor = (self.useCustomColor.state == NSControlStateValueOn) ? [NSColor systemYellowColor] : nil;
        
        // Because you are setting the color to yellow, it makes sense to make the button titles black.
        NSColor *titleColor = (self.useCustomColor.state == NSControlStateValueOn) ? NSColor.blackColor : NSColor.whiteColor;
        
        NSDictionary *attributesDictionary =
            [NSDictionary dictionaryWithObjectsAndKeys:
                 titleColor, NSForegroundColorAttributeName,
                 button.font, NSFontAttributeName,
             nil];
        NSMutableAttributedString *attributedString =
            [[NSMutableAttributedString alloc] initWithString:button.title attributes:attributesDictionary];
        [attributedString setAlignment:NSTextAlignmentCenter
                                 range:NSMakeRange(0, attributedString.length)];
        button.attributedTitle = attributedString;
    }
    
    // The Size Constraint checkbox changes the third button's width constraint.
    if (self.sizeConstraint.state == NSControlStateValueOn)
    {
        /** If the size constraint checkbox is in a selected state, set the button's width, larger with the image hugging the title.
            Set the layout constraint on this button so that it's 200 pixels wide.
         */
        self.button3WidthConstraint.constant = 200;
    }
    else
    {
        self.button3WidthConstraint.constant = self.originalButton3Width;
    }
}

- (IBAction)buttonAction:(id)sender
{
    NSLog(@"%@ was pressed", ((NSButton *)sender).title);
}

@end
