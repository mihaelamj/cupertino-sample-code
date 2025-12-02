/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Implements the main view for `VideoProcessorApp`.
*/

import SwiftUI

struct VideoProcessorView: View {

    var body: some View {

        NavigationSplitView {

            SidebarView()

        } detail: {

            DetailView()
        }
        .preferredColorScheme(.dark)
    }
}

struct SidebarView: View {

    @Environment(VideoProcessorModel.self) private var model

    var body: some View {
        Group {

            if let videoEffect = model.selectedVideoEffect {

                VideoEffectSettingsView(effect: videoEffect)

            } else {

                VideoEffectSelectionView()
            }
        }
        .navigationSplitViewColumnWidth(320)
        .navigationBarBackButtonHidden()
    }
}

struct DetailView: View {

    var body: some View {

        VideoPreviewView()
            .background(.black)
    }
}

