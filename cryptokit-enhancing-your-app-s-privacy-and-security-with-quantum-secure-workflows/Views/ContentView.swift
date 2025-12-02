/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view.
*/

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var tester: KeyTest
    
    var body: some View {
        let view = TabView(selection: $tester.category) {
            MLKEMView()
                .tabItem { Text(KeyTest.Category.MLKEM.rawValue) }
                .tag(KeyTest.Category.MLKEM)
            MLDSAView()
                .tabItem { Text(KeyTest.Category.MLDSA.rawValue) }
                .tag(KeyTest.Category.MLDSA)
            PQHPKEView()
                .tabItem { Text(KeyTest.Category.PQHPKE.rawValue) }
                .tag(KeyTest.Category.PQHPKE)
            HybridSigView()
                .tabItem { Text(KeyTest.Category.hybridSig.rawValue) }
                .tag(KeyTest.Category.hybridSig)
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
