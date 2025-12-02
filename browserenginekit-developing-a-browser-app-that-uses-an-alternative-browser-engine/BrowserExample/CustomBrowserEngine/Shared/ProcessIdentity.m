/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A function to retrieve the current process's identity token.
*/

#import "ProcessIdentity.h"

@implementation ProcessIdentity

+ (task_id_token_t) getCurrentToken {
  task_id_token_t identityToken;
  mach_port_t port = mach_task_self();
  kern_return_t result = task_create_identity_token(port, &identityToken);
  if (result != KERN_SUCCESS) {
    NSLog(@"task_create_identity_token() for current port (%x) failed: %s (code %x)", port, mach_error_string(result), result);
  }
  return identityToken;
}

@end
