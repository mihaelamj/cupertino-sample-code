/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The log view controller.
*/

#import "LogViewController.h"

@interface LogViewController ()
@property (weak) IBOutlet NSTextView *logTextView;
@property (strong) NSDateFormatter *formatter;
@end

@implementation LogViewController

id observer;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set up the formatter.
    self.formatter = [[NSDateFormatter alloc] init];
    [self.formatter setDateStyle:NSDateFormatterNoStyle];
    [self.formatter setTimeStyle:NSDateFormatterMediumStyle];
    
    // Set up the view.
    observer = [[NSNotificationCenter defaultCenter]
                addObserverForName:@"LogThis"
                object:nil
                queue:nil
                usingBlock:^(NSNotification * _Nonnull note) {
        NSString *message = [note object];
        if ( message ) {
            [self log:message];
        }
    }];
}

- (void)viewWillAppear {
    [super viewWillAppear];
    
    [[[self logTextView] window] setFrameAutosaveName:@"LogWindow"];
    [self log:@"Log view loaded."];
}

// Write the current date and a message to the log and to the console.
- (void) log:(NSString *)message {
    NSString *now = [self.formatter stringFromDate:[NSDate date]];
    NSString *messageWithDate = [NSString stringWithFormat:@"%@: %@\n",
                                 now, message];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.logTextView.textStorage appendAttributedString: [[NSAttributedString alloc] initWithString:messageWithDate]];
        [self.logTextView scrollToEndOfDocument:nil];
    });
    
    // Also log it to the console.
    NSLog(@"%@", message);
}
@end
