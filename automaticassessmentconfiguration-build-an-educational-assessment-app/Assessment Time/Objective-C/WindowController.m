/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The window controller.
*/
#import "WindowController.h"
#import <AutomaticAssessmentConfiguration/AutomaticAssessmentConfiguration.h>

@interface WindowController () <AEAssessmentSessionDelegate>
@property (weak) IBOutlet NSToolbarItem *lockUnlockItem;
@property (weak) IBOutlet NSSegmentedControl *calculatorOptions;
@property (weak) IBOutlet NSSegmentedControl *dictionaryOptions;
- (IBAction)lockSession:(id)sender;

@property AEAssessmentSession *session;

@end

NSString *calculatorBundleID = @"com.apple.calculator";
NSString *dictionaryBundleID = @"com.apple.Dictionary";

@implementation WindowController
- (void)windowDidLoad {
    [super windowDidLoad];

    // Arrange to remember the window location.
    [self.window setFrameAutosaveName:@"Assessment Time"];

    // Set up an assessment session and, optionally, additional participants.
    [self setupAssessmentSession];

    // Update the lock button to indicate whether the session is locked.
    // Initially, it won't be.
    [self updateLockButton];
}

// Prepare an assessment session and configure it.
- (void)setupAssessmentSession {
    AEAssessmentConfiguration *config = [self participantConfiguration];
    self.session = [[AEAssessmentSession alloc] initWithConfiguration:config];
    self.session.delegate = self;
}

// Create an appropriate configuration.
// When running a version of macOS earlier than 12, return a generic configuration that allows only this app.
// For macOS 12 or later, additionally allow (or disallow) Calculator and Dictionary as participant apps.
- (AEAssessmentConfiguration *) participantConfiguration {
    // Start with an assessment configuration.
    AEAssessmentConfiguration *config = [[AEAssessmentConfiguration alloc] init];
    
    [self log:@"Building new assessment configuration."];

    if (@available(macOS 12, *)) {

        // Create two different participant configurations, one that allows network access
        // and one that doesn't.

        // A configuration that allows network access.
        AEAssessmentParticipantConfiguration *networkAllowedConfig = [[AEAssessmentParticipantConfiguration alloc] init];
        networkAllowedConfig.allowsNetworkAccess = true;

        // A configuration that prevents network access.
        AEAssessmentParticipantConfiguration *noNetworkConfig = [[AEAssessmentParticipantConfiguration alloc] init];
        noNetworkConfig.allowsNetworkAccess = false;

        // For Calculator and Dictionary: Create an AEAssessmentApplication
        //   and add it to the configuration, using either the `networkAllowed`
        //   or `noNetwork` config, according to the selected option in the UI.

        AEAssessmentApplication *calculator = [[AEAssessmentApplication alloc] initWithBundleIdentifier:calculatorBundleID];

        switch ( [self.calculatorOptions selectedSegment] ) {
            case 0: // Not allowed.
                [self log:@"Calculator will not be allowed when locked"];
                break;
            case 1: // Allowed, no network.
                [self log:@"Calculator will be allowed when locked, with no network access."];
                [config setConfiguration:noNetworkConfig forApplication:calculator];
                break;
            case 2:  // Allowed, with network.
                [self log:@"Calculator will be allowed when locked, with network access."];
                [config setConfiguration:networkAllowedConfig forApplication:calculator];
                break;
            default:
                [self log:@"Unexpected segment; Calculator not allowed."];
                break;
        }

        AEAssessmentApplication *dictionary = [[AEAssessmentApplication alloc] initWithBundleIdentifier:dictionaryBundleID];

        switch ( [self.dictionaryOptions selectedSegment] ) {
            case 0: // Not allowed.
                [self log:@"Dictionary will not be allowed when locked."];
                break;
            case 1: // Allowed, no network.
                [self log:@"Dictionary will be allowed when locked, with no network access."];
                [config setConfiguration:noNetworkConfig forApplication:dictionary];
                break;
            case 2:  // Allowed, with network.
                [self log:@"Dictionary will be allowed when locked, with network access."];
                [config setConfiguration:networkAllowedConfig forApplication:dictionary];
                break;
            default:
                [self log:@"Unexpected segment; Dictionary not allowed."];
                break;
        }
    } else {
        // For any iOS earlier than iOS 12, you can't add participants,
        // so just return a generic config.
        [self log:@"AEAssessmentApplication is not available before macOS 12.0.  Creating a generic configuration which allows this app only."];
    }
    return config;
}

// Try opening an app with a particular bundle ID.
// It'll most likely succeed, but in macOS 12, it'll only appear in an assessment session
// if that app has been configured as a participant.
- (void) attemptToOpenAppWithBundleID:(NSString *) bundleID {
    NSURL *url = [[NSWorkspace sharedWorkspace] URLForApplicationWithBundleIdentifier:bundleID];
    [self log:@"Attempting to open bundle %@ from %@.", bundleID, url];
    if ( url != NULL ) {
        [[NSWorkspace sharedWorkspace] openApplicationAtURL:url
                                              configuration:[[NSWorkspaceOpenConfiguration alloc] init] completionHandler:^(NSRunningApplication * _Nullable app, NSError * _Nullable error) {
            if ( app != NULL ) {
                [self log:@"App successfully launched."];
            } else {
                [self log:@"App launch error: %@", [error localizedDescription]];
            }
        }];
    }
}

// The Calculator and Dictionary toolbar controls call this;
// reset the participant configuration, and attempt to reopen the apps.
- (IBAction) updateConfiguration:(id) sender {
    if (@available(macOS 12, *)) {
        [[self session] updateToConfiguration:[self participantConfiguration]];
    } else {
        [self log:@"Participant configuration options are macOS 12 only."];
    }
    [self attemptToOpenAppWithBundleID:calculatorBundleID];
    [self attemptToOpenAppWithBundleID:dictionaryBundleID];
}

// The Lock Session button begins and ends an assessment session.
- (IBAction)lockSession:(id)sender {
    if ( self.session != NULL && [self.session isActive]) {
        [self log:@"Requesting session end."];
        [self.session end];
    } else {
        [self log:@"Requesting session begin."];
        [self.session begin];
    }
}

// Change the lock button icon and text to match the current assessment state.
- (void) updateLockButton {
    if ( self.session != NULL && [self.session isActive ]) {
        self.lockUnlockItem.image = [NSImage imageWithSystemSymbolName:@"lock.fill" accessibilityDescription:@"Unlock Session"];
        self.lockUnlockItem.label = @"Unlock";
    } else {
        self.lockUnlockItem.image = [NSImage imageWithSystemSymbolName:@"lock.open.fill" accessibilityDescription:@"Lock Session"];
        self.lockUnlockItem.label = @"Lock";
    }
}


// Log a message by sending it to the Notification Center, in case anything
// (like the LogViewController) is listening.
- (void) log:(NSString *)format,... NS_FORMAT_FUNCTION(1,2) {
    va_list myArgs;
    va_start(myArgs, format);

    NSString *formattedMessage = [[NSString alloc]
                                  initWithFormat:format
                                  locale:[NSLocale currentLocale]
                                  arguments:myArgs];
    va_end(myArgs);

    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"LogThis" object:formattedMessage];
}
@end

@implementation WindowController (AEAssessmentSessionDelegate)

- (void)assessmentSessionDidBegin:(AEAssessmentSession *)session {
    [self log:@"assessmentSessionDidBegin"];
    [self updateLockButton];
}

-(void)assessmentSession:(AEAssessmentSession *)session failedToBeginWithError:(NSError *)error {
    [self log:@"Session failed to begin -: %@", [error localizedDescription]];
}

// During assessment, the sessionʼs delegate might receive an assessmentSession(_:was InterruptedWithError:) callback
// to indicate a failure. If this happens, immediately stop the assessment, hide all sensitive content, and end the session.
// Because it might take time for your app to finalize the assessment, the session relies on your app to call the sessionʼs end() method:
- (void)assessmentSession:(AEAssessmentSession *)session wasInterruptedWithError:(NSError *)error {
    [self log:@"Session interrupted - %@", [error localizedDescription]];
    [session end];
    [self updateLockButton];
}

- (void)assessmentSessionDidEnd:(AEAssessmentSession *)session {
    [self log:@"assessmentSessionDidEnd"];
    [self updateLockButton];
}

- (void)assessmentSession:(AEAssessmentSession *)session failedToUpdateToConfiguration:(AEAssessmentConfiguration *)configuration error:(NSError *)error {
    [self log:@"Session failed to update to configuration %@: %@",
     configuration,
     [error localizedDescription]
    ];
}
@end
