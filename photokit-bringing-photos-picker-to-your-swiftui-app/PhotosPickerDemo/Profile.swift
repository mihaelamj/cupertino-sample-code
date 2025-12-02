/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main content view of the app.
*/

import SwiftUI
import PhotosUI

struct Profile: View {
    var body: some View {
        #if os(macOS)
        ProfileForm()
            .labelsHidden()
            .frame(width: 400)
            .padding()
        #else
        NavigationView {
            ProfileForm()
        }
        #endif
    }
}

struct ProfileForm: View {
    @StateObject var viewModel = ProfileModel()
    
    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    EditableCircularProfileImage(viewModel: viewModel)
                    Spacer()
                }
            }
            .listRowBackground(Color.clear)
            #if !os(macOS)
            .padding([.top], 10)
            #endif
            Section {
                TextField("First Name",
						  text: $viewModel.firstName,
						  prompt: Text("First Name"))
                TextField("Last Name",
						  text: $viewModel.lastName,
						  prompt: Text("Last Name"))
            }
            Section {
                TextField("About Me",
						  text: $viewModel.aboutMe,
						  prompt: Text("About Me"))
            }
        }
        .navigationTitle("Account Profile")
    }
}
