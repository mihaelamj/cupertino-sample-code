/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view to display the main view.
*/

import SwiftUI
import os

struct MainView: View {
    @Bindable var viewModel: MainViewModel
    @State var layoutGridViewModel: LayoutGridViewModel?
    
    init(viewModel: MainViewModel) {
        self.viewModel = viewModel
    }
    
    // Show the menu item information.
    @ViewBuilder
    var menuItemInfoView: some View {
        Text("**\(viewModel.menuItem.title)**: \(viewModel.menuItem.description)")
            .padding()
    }
    
    // Show navigation buttons for grid and layout view options.
    @ViewBuilder
    var navigationButtonsView: some View {
        HStack {
            // Navigate to grid view on button press.
            Button {
                layoutGridViewModel = LayoutGridViewModel(selectedItem: viewModel.menuItem)
                viewModel.showGridView()
            } label: {
                Text("Show Grid View")
            }
            .buttonStyle(SelectionButtonStyle())
            
            // Navigate to layout view on button press.
            Button {
                layoutGridViewModel = LayoutGridViewModel(selectedItem: viewModel.menuItem)
                viewModel.showLayoutView()
            } label: {
                Text("Show Layout View")
            }
            .buttonStyle(SelectionButtonStyle())
        }
    }

    // Show menu items and navigation buttons.
    var body: some View {
        NavigationStack(path: $viewModel.navigation) {
            VStack {
                menuItemInfoView
                navigationButtonsView
            }
            .navigationTitle("Multiview Playback Sample App")
            .navigationDestination(for: MenuNavigationRoute.self) { route in
                // Navigate to the correct view with the selected item.
                switch route {
                case .gridViewRoute:
                    GridView(viewModel: layoutGridViewModel!)
                        .background(.black)
                case .layoutViewRoute:
                    LayoutView(viewModel: layoutGridViewModel!)
                }
            }
            .onAppear {
                viewModel.resetStates()
                layoutGridViewModel?.resetValues()
                layoutGridViewModel = nil
            }
        }
    }
}
