/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A web view.
*/
#import "ViewController.h"
#import <WebKit/WebKit.h>

@interface ViewController() <WKNavigationDelegate>
@property (weak) IBOutlet NSTextField *urlField;
@property (weak) IBOutlet WKWebView *webView;

@end
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.webView.navigationDelegate = self;
    self.urlField.stringValue = @"https://www.apple.com";
    [self loadWebPage:self.urlField];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view if already loaded.
}
- (IBAction)loadWebPage:(id)sender {
    // Make sure the url specifies the https scheme.
    if ([self.urlField.stringValue hasPrefix:@"http://"]) {
        self.urlField.stringValue = [self.urlField.stringValue stringByReplacingCharactersInRange:NSMakeRange(0, 4) withString:@"https"];
    } else if (![self.urlField.stringValue hasPrefix:@"https://"]) {
        self.urlField.stringValue = [@"https://" stringByAppendingString:self.urlField.stringValue];
    }
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.urlField.stringValue]];
    if ( request != NULL ) {
        [self.webView loadRequest:request];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if ( [webView URL] ) {
        self.urlField.stringValue = [[webView URL] absoluteString];
    }
}

@end
