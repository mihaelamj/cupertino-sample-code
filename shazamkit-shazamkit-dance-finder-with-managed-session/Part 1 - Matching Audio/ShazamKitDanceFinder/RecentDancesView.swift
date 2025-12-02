/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that displays a list of previously danced songs and a button to start a match attempt.
*/

import SwiftUI
import ShazamKit

enum NavigationPath: Hashable {
    case nowPlayingView(videoURL: URL)
    case danceCompletionView
}

struct RecentDancesView: View {
  
    // MARK: View Constants
    private enum ViewConstants {
        static let emptyStateImageName: String = "EmptyStateIcon"
        static let emptyStateTextTitle: String = "No Dances Yet?"
        static let emptyStateTextSubtitle: String = "Find some music to start learning"
        static let deleteSwipeViewOpacity: Double = 0.5
        static let matchingStateTextTopPadding: CGFloat = 24
        static let matchingStateTextBottomPadding: CGFloat = 16
        static let progressViewScaleEffect: CGFloat = 1.1
        static let progressViewBottomPadding: CGFloat = 12.0
        static let learnDanceButtonWidth: CGFloat = 250
        static let curvedTopSideRectangleHeight: CGFloat = 200
        static let listRowBottomInset: CGFloat = 30.0
        static let matchingStateText: String = "Get Ready..."
        static let notMatchingStateText: String = "Hear Music?"
        static let noMatchText: String = "No dance video for audio"
        static let navigationTitleText: String = "Recent Dances"
        static let learnDanceButtonText: String = "Learn the Dance"
        static let retryButtonText: String = "Try Again"
        static let cancelButtonText: String = "Cancel"
    }
    
    // MARK: Properties
    private var isListEmpty: Bool {
        SHLibrary.default.items.isEmpty
    }
    
    @State private var matchingState: String = ViewConstants.notMatchingStateText
    @State private var matchButtonText: String = ViewConstants.learnDanceButtonText
    @State private var canRetryMatchAttempt = false
    @State private var navigationPath: [NavigationPath] = []
    
    // MARK: Environment
    @EnvironmentObject private var matcher: Matcher
    @Environment(\.openURL) var openURL
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack(alignment: .bottom) {
                List([SHMediaItem](), id: \.self) { mediaItem in
                    RecentDanceRowView(mediaItem: mediaItem)
                        .onTapGesture(perform: {
                            guard let appleMusicURL = mediaItem.appleMusicURL else {
                                return
                            }
                            openURL(appleMusicURL)
                        })
                }
                .listStyle(.plain)
                .overlay {
                    if isListEmpty {
                        ContentUnavailableView {
                            Label(ViewConstants.emptyStateTextTitle,
                                  image: ImageResource(name: ViewConstants.emptyStateImageName, bundle: Bundle.main))
                                .font(.title)
                                .foregroundStyle(Color.white)
                        } description: {
                            Text(ViewConstants.emptyStateTextSubtitle)
                                .foregroundStyle(Color.white)
                        }
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: ViewConstants.listRowBottomInset) {
                    ZStack(alignment: .top) {
                        CurvedTopSideRectangle()
                        VStack {
                            Text(matchingState)
                                .font(.body)
                                .foregroundStyle(.white)
                                .padding(.top, ViewConstants.matchingStateTextTopPadding)
                                .padding(.bottom, ViewConstants.matchingStateTextBottomPadding)
                            if matcher.isMatching {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.appPrimary)
                                    .scaleEffect(x: ViewConstants.progressViewScaleEffect, y: ViewConstants.progressViewScaleEffect)
                                    .padding(.bottom, ViewConstants.progressViewBottomPadding)
                                Button(ViewConstants.cancelButtonText) {
                                    canRetryMatchAttempt = false
                                    matcher.stopRecording()
                                    matcher.endSession()
                                }
                                .foregroundStyle(Color.appPrimary)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            } else {
                                Button {
                                    Task { await matcher.match() }
                                    matchingState = ViewConstants.matchingStateText
                                    canRetryMatchAttempt = true
                                } label: {
                                    Text(matchButtonText)
                                        .foregroundStyle(.black)
                                        .font(.title3)
                                        .fontWeight(.heavy)
                                        .frame(maxWidth: .infinity)
                                }
                                .frame(width: ViewConstants.learnDanceButtonWidth)
                                .padding()
                                .background(Color.appPrimary)
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .edgesIgnoringSafeArea(.bottom)
                    .frame(height: ViewConstants.curvedTopSideRectangleHeight)
                }
            }
            .background(Color.appSecondary)
            .navigationTitle(isListEmpty ? "" : ViewConstants.navigationTitleText)
            .preferredColorScheme(.dark)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.appSecondary, for: .navigationBar)
            .frame(maxHeight: .infinity)
            .onChange(of: matcher.currentMatchResult, { _, result in
                
                guard navigationPath.isEmpty else {
                    print("Dance video already displayed")
                    return
                }
                
                guard let match = result?.match,
                      let url = ResourcesProvider.videoURL(forFilename: match.mediaItems.first?.videoTitle ?? "") else {
                    
                    matchingState = canRetryMatchAttempt ? ViewConstants.noMatchText : ViewConstants.notMatchingStateText
                    matchButtonText = canRetryMatchAttempt ? ViewConstants.retryButtonText : ViewConstants.learnDanceButtonText
                    return
                }
                
                canRetryMatchAttempt = false
                
                // Add the video playing view to the navigation stack.
                navigationPath.append(.nowPlayingView(videoURL: url))
            })
            .navigationDestination(for: NavigationPath.self, destination: { newNavigationPath in
                switch newNavigationPath {
                case .nowPlayingView(let videoURL):
                    NowPlayingView(navigationPath: $navigationPath, nowPlayingViewModel: NowPlayingViewModel(player: AVPlayer(url: videoURL)))
                case .danceCompletionView:
                    DanceCompletionView(navigationPath: $navigationPath)
                }
            })
            .onAppear {
                matchingState = ViewConstants.notMatchingStateText
                matchButtonText = ViewConstants.learnDanceButtonText
            }
        }
    }
}

struct RecentDancesView_Previews: PreviewProvider {
    static var previews: some View {
        RecentDancesView()
            .environmentObject(Matcher())
    }
}
