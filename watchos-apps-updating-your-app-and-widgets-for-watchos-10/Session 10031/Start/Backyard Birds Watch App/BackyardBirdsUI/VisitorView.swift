/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view showing the list of visitors within a backyard.
*/

import SwiftUI

struct VisitorView: View {
    @EnvironmentObject private var backyard: Backyard

    var body: some View {
        ForEach(backyard.birds) { bird in
            BirdCell(bird: bird)
        }
    }
}

struct VisitorView_Previews: PreviewProvider {
    static var previews: some View {
        VisitorView()
            .environmentObject(BackyardsData().backyards.first!)
    }
}
