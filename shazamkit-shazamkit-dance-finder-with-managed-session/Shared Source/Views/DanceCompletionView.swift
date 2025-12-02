/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view displayed after playback of a dance video ends.
*/

import SwiftUI

struct DanceCompletionView: View {
    
    // MARK: View Constants
    private enum ViewConstants {
        static let medalImageName: String = "medal"
        static let medalImageBottomPadding: CGFloat = 12.0
        static let titleTextBottomPadding: CGFloat = 2.0
        static let subtitleTextBottomPadding: CGFloat = 64.0
        static let titleText: String = "Nice Moves!"
        static let subtitleText: String = "You learned a new dance"
        static let continueButtonText: String = "Continue"
        static let continueButtonHorizontalPadding: CGFloat = 12.0
        static let continueButtonVerticalPadding: CGFloat = 8.0
        static let chevronForwardImageName: String = "chevron.forward"
        static let medalImageWidth: CGFloat = 90
        static let medalImageHeight: CGFloat = 95
    }
    
    @Binding var navigationPath: [NavigationPath]
    
    var body: some View {
        VStack {
            Image(systemName: ViewConstants.medalImageName)
                .resizable()
                .scaledToFit()
                .frame(width: ViewConstants.medalImageWidth, height: ViewConstants.medalImageHeight)
                .padding(.bottom, ViewConstants.medalImageBottomPadding)
                .fontWeight(.medium)
                .foregroundStyle(Color.black)
            Text(ViewConstants.titleText)
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, ViewConstants.titleTextBottomPadding)
                .foregroundStyle(Color.black)
            Text(ViewConstants.subtitleText)
                .padding(.bottom, ViewConstants.subtitleTextBottomPadding)
                .foregroundStyle(Color.black)
            Button {
                navigationPath.removeAll()
            } label: {
                Text(ViewConstants.continueButtonText)
                Image(systemName: ViewConstants.chevronForwardImageName)
            }
            .padding(.horizontal, ViewConstants.continueButtonHorizontalPadding)
            .padding(.vertical, ViewConstants.continueButtonVerticalPadding)
            .background(Color.appTertiary)
            .foregroundStyle(Color.appPrimary)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appPrimary)
        .edgesIgnoringSafeArea(.vertical)
        .navigationBarBackButtonHidden(true)
    }
}

struct DanceCompletionView_Previews: PreviewProvider {
    
    @State private static var path: [NavigationPath] = [.danceCompletionView]
    static var previews: some View {
        DanceCompletionView(navigationPath: $path)
    }
}
