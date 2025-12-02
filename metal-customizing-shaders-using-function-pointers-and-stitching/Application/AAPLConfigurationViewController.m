/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implementation of the cross-platform configuration view controller.
*/

#import "AAPLConfigurationViewController.h"

@implementation AAPLConfigurationViewController
{
    BOOL useUserDylib;
    BOOL useSubtraction;
    int iterations;
}

- (void)viewDidLoad
{
    useUserDylib = NO;
    useSubtraction = NO;
    iterations = 16;
}

#if defined(TARGET_IOS)
- (IBAction)selectVisualizationType:(UISegmentedControl *)sender
{
    switch(sender.selectedSegmentIndex)
    {
        case 0:
            useUserDylib = NO;
            break;
        case 1:
            useUserDylib = YES;
            break;
    }
    [_renderViewController updateRendererWith:useUserDylib
                         subtractionOperation:useSubtraction
                                   iterations:iterations];
}

- (IBAction)selectOperation:(UISegmentedControl *)sender
{
    switch(sender.selectedSegmentIndex)
    {
        case 0:
            useSubtraction = NO;
            break;
        case 1:
            useSubtraction = YES;
            break;
    }
    [_renderViewController updateRendererWith:useUserDylib
                         subtractionOperation:useSubtraction
                                   iterations:iterations];
}

- (IBAction)selectIterations:(UISegmentedControl *)sender
{
    switch(sender.selectedSegmentIndex)
    {
        case 0:
            iterations = 4;
            break;
        case 1:
            iterations = 16;
            break;
        case 2:
            iterations = 64;
            break;
    }
    [_renderViewController updateRendererWith:useUserDylib
                         subtractionOperation:useSubtraction
                                   iterations:iterations];
}
#else
- (IBAction)selectVisualizationType:(NSSegmentedControl *)sender
{
    switch(sender.selectedSegment)
    {
        case 0:
            useUserDylib = NO;
            break;
        case 1:
            useUserDylib = YES;
            break;
    }
    [_renderViewController updateRendererWith:useUserDylib
                         subtractionOperation:useSubtraction
                                   iterations:iterations];
}

- (IBAction)selectOperation:(NSSegmentedControl *)sender
{
    switch(sender.selectedSegment)
    {
        case 0:
            useSubtraction = NO;
            break;
        case 1:
            useSubtraction = YES;
            break;
    }
    [_renderViewController updateRendererWith:useUserDylib
                         subtractionOperation:useSubtraction
                                   iterations:iterations];
}

- (IBAction)selectIterations:(NSSegmentedControl *)sender
{
    switch(sender.selectedSegment)
    {
        case 0:
            iterations = 4;
            break;
        case 1:
            iterations = 16;
            break;
        case 2:
            iterations = 64;
            break;
    }
    [_renderViewController updateRendererWith:useUserDylib
                         subtractionOperation:useSubtraction
                                   iterations:iterations];
}
#endif

@end
