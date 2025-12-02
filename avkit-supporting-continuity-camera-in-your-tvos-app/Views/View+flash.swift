/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Wraps another view and temporarily presents it with a flash
 and then hides it with fade effect after a time delay.
*/

import SwiftUI

/// Wraps another view and temporarily presents it with a flash effect,
/// and then hides it with fade effect after a time delay.
///
/// Apps can use this view for multiple components of a flash effect,
/// including the following:
/// - A quick transition to a full screen color, typically white, to simulate a
/// camera's flash, which then fades away.
/// - A slower transition that temporarily shows a still image, typically at the
/// moment the first transition started, before fading away.
struct FlashAndFade<SubView: View>: View {

    /// The amount of time, in seconds, the flash-and-fade view shows its
    /// content before starting a fade-out transition.
    var visibleDuration = 0.2

    /// The amount of time, in seconds, for each fade-out transition.
    var easeOutDuration = 1.0

    /// The underlying view the outer view presents with a flash and then fades out.
    var subView: () -> SubView

    /// A completion handler the wrapping view calls after the subview fades out.
    var completion: () -> Void

    /// Generates a view that reveals a subview for a period of time.
    ///
    /// The property creates a view that presents `subView` with the following
    /// sequence:
    /// 1. Reveals the subview with an opacity transition.
    /// 2. Displays the subview normally for `visibleDuration` seconds.
    /// 3. Fades out the subview for `easeOutDuration` seconds.
    /// 4. Calls the `completion` method, which typically removes the
    /// `FlashAndFade` instance from its parent view.
    var body: some View {
        subView()
            .transition(.opacity)
            .onAppear {
                Task {
                    try await Task.sleep(for: .seconds(visibleDuration))
                    withAnimation(.easeOut(duration: easeOutDuration)) {
                        completion()
                    }
                }
            }
    }
}
