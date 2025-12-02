/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view that displays the item list and productivity chart.
*/

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                ItemList()
            }
            NavigationStack {
                ProductivityChart()
            }
        }.tabViewStyle(.page)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ItemListModel.shortList)
    }
}
