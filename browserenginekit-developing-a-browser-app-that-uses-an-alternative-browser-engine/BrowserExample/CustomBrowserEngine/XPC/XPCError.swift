/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A type that represents an error encountered while sending or receiving XPC messages.
*/

enum XPCError: Error {
  case failedToCreateReply
  case failedToSendReply
  case encodingFailed
  case invalidKey(String)
}
