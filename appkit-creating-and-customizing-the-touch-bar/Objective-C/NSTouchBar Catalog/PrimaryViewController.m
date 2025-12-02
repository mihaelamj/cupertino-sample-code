/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The primary view controller that gives access to all test cases in this sample.
*/

#import "PrimaryViewController.h"

@interface PrimaryViewController ()

@property (weak) IBOutlet NSTableView *tableView;
@property (weak) IBOutlet NSArrayController *contentArray;

@end


#pragma mark -

// Key to the main dictionary containing all the test dictionaries.
static NSString *TestsKey = @"tests";

// Keys to the NSDictionary for each test item.
static NSString *TestNameKey = @"testName"; // The test's title for the table view.
static NSString *TestKindKey = @"testKind"; // The test's storyboard name to load.


@implementation PrimaryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Load the tests only if the NSTouchBar class exists.
    if (NSClassFromString(@"NSTouchBar"))
    {
        // Load the tests from the plist database, add them to the array controller.
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"Tests" withExtension:@"plist"];
        NSDictionary *testDatabase = [[NSDictionary alloc] initWithContentsOfURL:url];
        NSArray *tests = testDatabase[TestsKey];
        for (NSDictionary *test in tests)
        {
            [self.contentArray addObject:test];
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(selectionDidChange:)
                                                 name:NSTableViewSelectionDidChangeNotification
                                               object:self.tableView];
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    
    // Start by showing the first button example.
    self.contentArray.selectionIndex = 0;
}

// Use to swap in a new detail view controller when a table selection changes.
- (void)selectionDidChange:(NSNotification *)notification
{
    NSTableView *tableView = [notification object];
    NSInteger selectedItem = tableView.selectedRow;
    
    NSViewController *newDetailViewController = nil;
    NSSplitViewItem *newDetailSplitViewItem = nil;
    
    NSSplitViewController *splitViewController = (NSSplitViewController *)self.view.window.contentViewController;
    NSSplitViewItem *splitViewItem = splitViewController.splitViewItems[1];
    [splitViewController removeSplitViewItem:splitViewItem];
    
    // Remove as the observer to the associated detail view controller's NSTouchBar instance.
    @try {
        NSViewController *vcToRemove = splitViewItem.viewController;
        [vcToRemove removeObserver:self forKeyPath:@"touchBar" context:@"touchBar"];
    } @catch(id anException) {
        // Do nothing, obviously it wasn't attached because an exception was thrown.
    }
    
    if (selectedItem == -1)
    {
        // You don't have a valid selection, so use the generic detail view controller.
        NSStoryboard *storyboard = [NSStoryboard storyboardWithName:@"Main" bundle: nil];
        newDetailViewController = [storyboard instantiateControllerWithIdentifier:@"DetailViewController"];
        self.view.window.subtitle = @"";
    }
    else
    {
        // You have a valid selection, so load the corresponding storyboard.
        NSDictionary *selectedTest = [self.contentArray.arrangedObjects objectAtIndex:selectedItem];
        NSString *whichViewControllerIdentifierID = selectedTest[TestKindKey];
        
        NSStoryboard *storyboard =
            [NSStoryboard storyboardWithName:whichViewControllerIdentifierID bundle:[NSBundle mainBundle]];
        newDetailViewController = [storyboard instantiateInitialController];
        
        self.view.window.subtitle = selectedTest[TestNameKey];
    }
    
    newDetailSplitViewItem =
        [NSSplitViewItem splitViewItemWithViewController:newDetailViewController];
    [splitViewController insertSplitViewItem:newDetailSplitViewItem atIndex:1];
    
    // Bind or sync the NSTouchBar instance with the detail view controller.
    [self unbind:@"touchBar"];
    [self bind:@"touchBar" toObject:newDetailViewController withKeyPath:@"touchBar" options:nil];
}

@end
