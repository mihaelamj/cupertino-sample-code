/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view for displaying the itinerary.
*/

import FoundationModels
import SwiftUI
import MapKit
import WeatherKit

struct LandmarkTripView: View {
    @State private var requestedItinerary: Bool = false
    @State private var planner: ItineraryPlanner?
    
    let landmark: Landmark

    var body: some View {
        if let error = planner?.error {
            MessageView(error: error, landmark: landmark)
        } else {
            ScrollView {
                if !requestedItinerary {
                    LandmarkDescriptionView(
                        landmark: landmark
                    )
                } else if let itinerary = planner?.itinerary {
                    ItineraryView(landmark: landmark, itinerary: itinerary).padding()
                } else if let planner {
                    ItineraryPlanningView(landmark: landmark, planner: planner)
                }
            }
            .scrollDisabled(!requestedItinerary)
            .safeAreaInset(edge: .bottom) {
                ItineraryButton {
                    try await requestItinerary()
                }
            }
            .task {
                planner = ItineraryPlanner(landmark: landmark)
                planner?.prewarm()
            }
            .headerStyle(landmark: landmark)
        }
    }
    
    func requestItinerary() async throws {
        requestedItinerary = true
        do {
            try await planner?.suggestItinerary(dayCount: 3)
        } catch {
            planner?.error = error
        }
    }
}

struct ItineraryButton: View {
    @State private var showButton: Bool = false
    let closure: () async throws -> Void

    var body: some View {
        VStack {
            Button {
                showButton = false
                Task { @MainActor in
                    try await closure()
                }
            }
            label: {
                Label("Generate Itinerary", systemImage: "sparkles")
                    .fontWeight(.bold)
                    .padding()
            }
            .buttonStyle(.bordered)
            .padding()
            .opacity(showButton ? 1 : 0)
            .animation(
                .easeInOut(duration: 0.5),
                value: showButton
            )
            .onAppear {
                showButton = true
            }
            .transition(.opacity)
        }
        .frame(maxWidth: .infinity, alignment: .bottom)
    }
}

struct ItineraryHeader: View {
    let destination: Landmark
    var body: some View {
        ZStack(alignment: .topLeading) {
            Image(destination.backgroundImageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
            Image("\(destination.backgroundImageName)-thumb")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipped()
                .blur(radius: 16, opaque: true)
                .saturation(1.3)
                .brightness(0.15)
                .mask {
                    Rectangle()
                        .fill(
                            Gradient(stops: [
                                .init(color: .clear, location: 0.5),
                                .init(color: .white, location: 0.6)
                            ])
                            .colorSpace(.perceptual)
                        )
                }
        }
        .frame(height: 420)
        .compositingGroup()
        .mask {
            Rectangle()
                .fill(
                    Gradient(stops: [
                        .init(color: .white, location: 0.3),
                        .init(color: .clear, location: 1.0)
                    ])
                    .colorSpace(.perceptual)
                )
        }
        .ignoresSafeArea()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        #if os(iOS)
        .background(Color(uiColor: .systemGray6))
        #endif
    }
}
