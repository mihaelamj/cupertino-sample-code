/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that sets up the parameter tips examples.
*/

import SwiftUI

struct ParameterView: View {
    var body: some View {
        List {
            NavigationLink("Basic parameter tip") {
                ParameterRuleView()
            }

            NavigationLink("Parameter tip using custom data type") {
                FavoritePlantsView()
            }
        }
        .navigationTitle("Parameter rules")
    }
}

#Preview {
    ParameterView()
}
