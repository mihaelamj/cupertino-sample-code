/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View controller for the view-based table view of images, using an NSScrubberImageItemView without subclassing.
*/

#import "BackgroundImagesViewController.h"
#import "BackgroundViewController.h"
#import "TitleBarAccessoryViewController.h"
#import "ScrubberViewController.h"
#import "PhotoManager.h"

static NSTouchBarCustomizationIdentifier ScrubberCustomizationIdentifier =
    @"com.TouchBarCatalog.backgroudWindowScrubber";
static NSTouchBarItemIdentifier ScrubberItemIdentifier =
    @"com.TouchBarCatalog.backgroudWindowScrubberItem";

@interface BackgroundImagesViewController () <  NSTouchBarDelegate,
                                                NSScrubberDelegate,
                                                NSScrubberDataSource,
                                                NSTableViewDataSource,
                                                NSTableViewDelegate,
                                                PhotoManagerDelegate>

@property (nonatomic, weak) IBOutlet NSScrollView *scrollView;
@property (nonatomic, weak) IBOutlet NSTableView *tableView;
@property (nonatomic, weak) IBOutlet NSProgressIndicator *progressIndicator;

@end


#pragma mark -

@implementation BackgroundImagesViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Listen for table view selection changes.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(selectionDidChange:)
                                                 name:NSTableViewSelectionDidChangeNotification
                                               object:self.tableView];
    
    self.scrollView.wantsLayer = TRUE;
    self.scrollView.layer.cornerRadius = 6;
    
    // Load the pictures for the scrubber content.
    [self fetchPictureResources];
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    
    [self.view.window makeFirstResponder:self.view];
}

- (void)displayPhotos {
    [self.tableView reloadData];
    
    self.touchBar = nil; // Force update the NSTouchBar.
    
    [self.progressIndicator stopAnimation:self];
    self.progressIndicator.hidden = YES;
    self.scrollView.hidden = NO;
}

// Loads all the desktop pictures on this system, to use for the image-based NSScrubber
// in the touch bar item, and for table view in the NSPopover.
- (void)fetchPictureResources
{
    if ([PhotoManager shared].loadComplete) {
        [self displayPhotos];
    } else {
        // The PhotoManager hasn't loaded all the photos. This could take a while so show the progress indicator.
        PhotoManager.shared.delegate = self;  // To receive a notification when the photos finish loading.
        self.progressIndicator.hidden = false;
        self.scrollView.hidden = true;
        [self.progressIndicator startAnimation:self];
    }
}


#pragma mark NSTouchBarProvider

- (NSTouchBar *)makeTouchBar
{
    NSTouchBar *bar = [[NSTouchBar alloc] init];
    bar.delegate = self;
    
    bar.customizationIdentifier = ScrubberCustomizationIdentifier;
    
    // Set the default ordering of items.
    bar.defaultItemIdentifiers = @[ScrubberItemIdentifier, NSTouchBarItemIdentifierOtherItemsProxy];
    
    bar.customizationAllowedItemIdentifiers = @[ScrubberItemIdentifier];
    
    bar.principalItemIdentifier = ScrubberItemIdentifier;
    
    return bar;
}


#pragma mark - NSScrubberDataSource

static NSString *imageScrubberItemIdentifier = @"thumbnailItem";

- (NSInteger)numberOfItemsForScrubber:(NSScrubber *)scrubber
{
    return PhotoManager.shared.photos.count;
}

// Scrubber is asking for a custom view representation for a particular item index.
- (NSScrubberItemView *)scrubber:(NSScrubber *)scrubber viewForItemAtIndex:(NSInteger)index
{
    NSScrubberImageItemView *itemView = [scrubber makeItemWithIdentifier:imageScrubberItemIdentifier owner:nil];
    if (index < PhotoManager.shared.photos.count)
    {
        NSDictionary *itemDict = PhotoManager.shared.photos[index];
        itemView.image = [itemDict valueForKey:kImageKey];
    }
    
    itemView.imageView.imageScaling = NSImageScaleProportionallyDown;
    itemView.imageAlignment = NSImageAlignCenter;
    
    return itemView;
}


#pragma mark - NSScrubberFlowLayoutDelegate

// Scrubber is asking for the size for a particular item.
- (NSSize)scrubber:(NSScrubber *)scrubber layout:(NSScrubberFlowLayout *)layout sizeForItemAtIndex:(NSInteger)itemIndex
{
    return NSMakeSize(50, 30);
}


#pragma mark - NSScrubberDelegate

// The user selected an image from the NSScrubber touch bar item.
- (void)scrubber:(NSScrubber *)scrubber didSelectItemAtIndex:(NSInteger)selectedIndex
{
    [self chooseImageWithIndex:selectedIndex];
}


#pragma mark NSTouchBarDelegate

// The system calls this while constructing the NSTouchBar for each NSTouchBarItem you want to create.
- (nullable NSTouchBarItem *)touchBar:(NSTouchBar *)touchBar makeItemForIdentifier:(NSTouchBarItemIdentifier)identifier
{
    if ([identifier isEqualToString:ScrubberItemIdentifier])
    {
        // Create the scrubber touch bar item that uses the Desktop Pictures.
        NSCustomTouchBarItem *scrubberItem = [[NSCustomTouchBarItem alloc] initWithIdentifier:ScrubberItemIdentifier];
        
        NSScrubber *scrubber = [[NSScrubber alloc] initWithFrame:NSMakeRect(0, 0, 320, 30)];
        scrubber.delegate = self;   // This is so you can respond to selection.
        scrubber.dataSource = self; // This is so you can determine the content.
        
        [scrubber registerClass:[NSScrubberImageItemView class] forItemIdentifier:imageScrubberItemIdentifier];
            
        // For the image scrubber, you want the control to draw a fade effect to indicate that there is additional unscrolled content.
        scrubber.showsAdditionalContentIndicators = YES;

        scrubber.selectedIndex = 0; // Always select the first item in the scrubber.
        
        scrubberItem.customizationLabel = NSLocalizedString(@"Choose Photo", @"");
        
        NSScrubberLayout *scrubberLayout = [[NSScrubberFlowLayout alloc] init];
        scrubber.scrubberLayout = scrubberLayout;

        scrubber.mode = NSScrubberModeFree;
        scrubber.selectionBackgroundStyle = nil;
        scrubber.selectionOverlayStyle = nil;
        
        // Set the layout constraints on this scrubber so that it's 400 pixels wide.
        NSDictionary *items = NSDictionaryOfVariableBindings(scrubber);
        NSArray *theConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[scrubber(400)]" options:0 metrics:nil views:items];
        [NSLayoutConstraint activateConstraints:theConstraints];
        
        scrubberItem.view = scrubber;
        
        return scrubberItem;
    }
    
    return nil;
}

- (void)chooseImageWithIndex:(NSInteger)imageIndex
{
    // Process the chosen image and dismiss as the popover.
    TitleBarAccessoryViewController *presentingViewController = (TitleBarAccessoryViewController *)self.presentingViewController;
    BackgroundViewController *backgroundViewController = (BackgroundViewController *)presentingViewController.view.window.contentViewController;
        
    NSDictionary *itemDict = PhotoManager.shared.photos[imageIndex];
    NSString *imageName = [itemDict valueForKey:kImageNameKey];
    // Load the full image (not the thumbnail).
    NSImage *fullImage = [NSImage imageNamed: imageName];
    backgroundViewController.imageView.image = fullImage;
    
    [self dismissViewController:self];
}

// MARK: - NSTableViewDataSource
   
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return PhotoManager.shared.photos.count;
}

// MARK: - NSTableViewDelegate

- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSTableCellView *view = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    NSDictionary *imageDict = PhotoManager.shared.photos[row];
    NSString *imageName = imageDict[kImageNameKey];
    view.imageView.image = [NSImage imageNamed:imageName];
    return view;
}


#pragma mark - Notifications

// Listens for changes in the table view row selection.
- (void)selectionDidChange:(NSNotification *)notification
{
    NSInteger selectedRow = [self.tableView selectedRow];
    if (selectedRow != -1)
    {
        [self chooseImageWithIndex:selectedRow];
    }
}

#pragma mark - PhotoManagerDelegate

- (void)didLoadPhotos:(NSArray *)photos {
    [self displayPhotos];
}

@end
