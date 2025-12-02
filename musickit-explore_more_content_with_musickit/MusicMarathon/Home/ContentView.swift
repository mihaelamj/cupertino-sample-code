/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The app's main content view.
*/

import SwiftUI

struct ContentView: View {
    
    // MARK: - Properties
    
    @StateObject private var recentlyPlayedViewModel = RecentlyPlayedViewModel()
    
    // MARK: - View
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack {
                        historyView
                        PastWorkoutsGraph()
                            .frame(maxWidth: .infinity, minHeight: 300)
                            .padding(24)
                        
                        recentlyPlayedView
                            .onAppear(perform: recentlyPlayedViewModel.beginObservingMusicAuthorizationStatus)
                            
                            // Display the welcome view when appropriate.
                            .welcomeSheet()
                    }
                }
                .navigationTitle("Music Marathon")
                
                VStack {
                    Spacer()
                    NavigationLink(destination: WorkoutView()) {
                        startWorkoutView
                    }
                    .buttonStyle(.workout)
                    .shadow(color: .black.opacity(0.4), radius: 5)
                }
            }
        }
    }
    
    private var historyView: some View {
        HStack {
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                Text("Total Steps")
                    .font(.callout)
                Text("8,431")
                    .font(.system(size: 24, weight: .semibold))
            }
            .padding()
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                Text("Total Time Running")
                    .font(.callout)
                Text("13.2 hours")
                    .font(.system(size: 24, weight: .semibold))
            }
            .padding()
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(Color(UIColor.systemBackground))
                .standardShadow()
        }
        .padding([.leading, .trailing], 24)
    }
    
    private var startWorkoutView: some View {
        HStack {
            Image(systemName: "figure.walk")
            Text("Start a new workout")
                .fontWeight(.semibold)
        }.frame(minWidth: 180)
    }
    
    private var recentlyPlayedView: some View {
        VStack(alignment: .leading) {
            Text("Recently Played")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.leading, .trailing], 24)
            
            ForEach(recentlyPlayedViewModel.recentlyPlayedItems) { recentlyPlayedItem in
                RecentlyPlayedCell(recentlyPlayedItem)
                    .padding([.leading, .trailing], 24)
            }
            Spacer(minLength: 72)
        }
    }
}
