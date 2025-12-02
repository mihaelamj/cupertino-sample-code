/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller responsible for showing NSStepperTouchBarItem in an NSTouchBar instance.
*/

#import "StepperViewController.h"

static NSTouchBarCustomizationIdentifier StepperItemCustomizationIdentifier = @"com.TouchBarCatalog.stepperItemController";
static NSTouchBarItemIdentifier StepperItemIdentifier = @"com.TouchBarCatalog.stepperItem";

@interface StepperViewController () <NSTouchBarDelegate>

@property (weak) IBOutlet NSButton *useCustomDraw;

@end

#pragma mark -

@implementation StepperViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

// The user chose Custom Button Color checkbox to change the button colors.
- (IBAction)customize:(id)sender
{
    // Set to nil so you can call makeTouchBar again to recreate the NSTouchBar instance.
    self.touchBar = nil;
}

#pragma mark NSTouchBarProvider

- (NSTouchBar *)makeTouchBar
{
    NSTouchBar *bar = [[NSTouchBar alloc] init];
    bar.delegate = self;
    
    bar.customizationIdentifier = StepperItemCustomizationIdentifier;
    
    // Set the default ordering of items.
    bar.defaultItemIdentifiers = @[StepperItemIdentifier, NSTouchBarItemIdentifierOtherItemsProxy];
    
    bar.customizationAllowedItemIdentifiers = @[StepperItemIdentifier];
    
    return bar;
}

#pragma mark NSTouchBarDelegate

// The system calls this while constructing the NSTouchBar for each NSTouchBarItem you want to create.
- (nullable NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier
{
    if ([identifier isEqualToString:StepperItemIdentifier])
    {
        NSStepperTouchBarItem *stepperItem = nil;
        
        if (self.useCustomDraw.state == NSControlStateValueOff) {
            NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
            numberFormatter.numberStyle = NSNumberFormatterPercentStyle;
            numberFormatter.maximumFractionDigits = 0;
            numberFormatter.multiplier = @1;
            
            stepperItem = [NSStepperTouchBarItem stepperTouchBarItemWithIdentifier:identifier formatter: numberFormatter];
        }
        else
        {
            stepperItem = [NSStepperTouchBarItem stepperTouchBarItemWithIdentifier:identifier drawingHandler:^void(NSRect rect, double value) {
                [NSGraphicsContext saveGraphicsState];

                // Draw the stepper value.
                NSString *valueStr = [NSString stringWithFormat:@"%.0f", value];
                NSFont *font = [NSFont systemFontOfSize:12.0];
                
                NSDictionary *attributes = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [NSColor whiteColor], NSForegroundColorAttributeName,
                                            font, NSFontAttributeName,
                                            nil];
                NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:valueStr attributes:attributes];

                NSSize valueSize = NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX);
                NSRect valueRect = [attrString boundingRectWithSize:valueSize options:NSStringDrawingUsesFontLeading | NSStringDrawingUsesLineFragmentOrigin];
                NSPoint pt = NSMakePoint((rect.size.width - valueRect.size.width) / 2, (rect.size.height - valueRect.size.height) / 2);
                [attrString drawAtPoint: pt];
         
                // Adorn the stepper value.
                NSBezierPath *path = [NSBezierPath bezierPathWithRect:rect];
                [[NSColor whiteColor] set];
                [path stroke];
                
                [NSGraphicsContext restoreGraphicsState];
            }];
        }
           
        stepperItem.maxValue = 100;
        stepperItem.minValue = 1;
        stepperItem.increment = 10;
        stepperItem.value = 50;
        
        return stepperItem;
    }
    
    return nil;
}

@end
