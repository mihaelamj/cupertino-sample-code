/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main entry to the MultiviewPlaybackSampleApp.
*/

import SwiftUI

@main
struct MultiviewPlaybackSampleAppApp: App {
    let mainViewModel = MainViewModel.createViewModelWithMenu
    
    var body: some Scene {
        WindowGroup {
            MainView(viewModel: mainViewModel)
        }
    }
}
