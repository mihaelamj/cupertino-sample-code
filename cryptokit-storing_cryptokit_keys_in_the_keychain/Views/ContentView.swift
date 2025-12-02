/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The main view.
*/

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var tester: KeyTest
    
    var body: some View {
        let view = TabView(selection: $tester.category) {
            NISTView()
                .tabItem { Text(KeyTest.Category.nist.rawValue) }
                .tag(KeyTest.Category.nist)

            CurveView()
                .tabItem { Text(KeyTest.Category.curve.rawValue) }
                .tag(KeyTest.Category.curve)

            SymmetricView()
                .tabItem { Text(KeyTest.Category.symmetric.rawValue) }
                .tag(KeyTest.Category.symmetric)
        }
        
        #if os(macOS)
        return view.padding(EdgeInsets(top: 30, leading: 15, bottom: 15, trailing: 15))
        #else
        return view
        #endif
    }
}

#if DEBUG
struct ContentViewPreviews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(KeyTest())
    }
}
#endif
