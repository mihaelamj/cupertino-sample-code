/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A function to retrieve the current process's identity token.
*/

#import <Foundation/Foundation.h>
#import <mach/mach.h>

@interface ProcessIdentity : NSObject

  /// Returns the identity of the current task
  + (task_id_token_t)getCurrentToken;
@end
