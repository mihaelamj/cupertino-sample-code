/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view for showing the tutorial stack.
*/

import SwiftUI

/// Top-level view that contains a tabbed view of each of the help pages.
struct HelpPageView: View {
    @Binding var showHelpPageView: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(LocalizedString.captureHelp).foregroundColor(.secondary)
                Spacer()
                Button(action: {
                    withAnimation {
                        showHelpPageView = false
                    }},
                       label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(white: 0.7, opacity: 0.5))
                        .font(.title)
                })
            }

            TabView {
                CaptureTypesHelpPageView()
                HowToCaptureHelpPageView()
                SupportedObjectHelpPageView()
                EnvironmentHelpPageView()
            }
            .tabViewStyle(.page)
            .onAppear {
                UIPageControl.appearance().currentPageIndicatorTintColor = colorScheme == .light ? .black : .white
                UIPageControl.appearance().pageIndicatorTintColor = .lightGray
            }
        }
    }

    private struct LocalizedString {
        static let captureHelp = NSLocalizedString(
            "Capture Help (Help, Object Capture)",
            bundle: Bundle.main,
            value: "Capture Help",
            comment: "Title for the object Capture Help screen."
        )
    }
}

private struct CaptureTypesHelpPageView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TutorialPageView(pageName: LocalizedString.title,
                         imageName: colorScheme == .light ? "AreavObjectGraphic-light" : "AreavObjectGraphic",
                         imageCaption: LocalizedString.caption,
                         sections: [Section(title: LocalizedString.objectModeTitle,
                                            body: objectMode,
                                            symbol: nil, symbolColor: nil),
                                    Section(title: LocalizedString.areaModeTitle,
                                            body: areaMode,
                                            symbol: nil, symbolColor: nil)])
    }

    private var objectMode: [String] {
        var objectMode = LocalizedString.objectMode
        if UIDevice.current.userInterfaceIdiom == .pad {
            objectMode.append("")
        }
        return objectMode
    }

    private var areaMode: [String] {
        var areaMode = LocalizedString.areaMode
        if UIDevice.current.userInterfaceIdiom == .pad {
            areaMode.append("")
        }
        return areaMode
    }

    private struct LocalizedString {
        static let title = NSLocalizedString(
            "Capture Types (Help, Object Capture)",
            bundle: Bundle.main,
            value: "Capture Types",
            comment: "Title for the Capture Types page on the object Capture Help screen."
        )

        static let caption = NSLocalizedString(
            "Choose which capture type suits your object. (Help, Object Capture)",
            bundle: Bundle.main,
            value: "Choose which capture type suits your object.",
            comment: "Caption for the Capture Types page on the object Capture Help screen."
        )

        static let objectModeTitle = NSLocalizedString(
            "Object Mode (Help, Object Capture)",
            bundle: Bundle.main,
            value: "Object Mode",
            comment: "Title for the Object Mode on the Capture Types page in the object Capture Help screen."
        )

        static let objectMode = [
            NSLocalizedString(
                "Capture entire objects and separate them from their surroundings. (Help, Object Capture)",
                bundle: Bundle.main,
                value: "Capture entire objects and separate them from their surroundings.",
                comment: "Object mode tips for the Capture Types page in the object Capture Help screen."
            ),
            NSLocalizedString(
                "Works best in controlled indoor environments (Help, Object Capture)",
                bundle: Bundle.main,
                value: "Works best in controlled indoor environments.",
                comment: "Object mode tips for the Capture Types page in the object Capture Help screen."
            )
        ]

        static let areaModeTitle = NSLocalizedString(
            "Area Mode (Help, Object Capture)",
            bundle: Bundle.main,
            value: "Area Mode",
            comment: "Title for the Area Mode on the Capture Types page in the object Capture Help screen."
        )

        static let areaMode = [
            NSLocalizedString(
                "Capture objects and their surroundings. (Help, Object Capture)",
                bundle: Bundle.main,
                value: "Capture objects and their surroundings.",
                comment: "Area Mode tips for the Capture Types page in the object Capture Help screen."
            ),
            NSLocalizedString(
                "Works in indoor or outdoor environments (Help, Object Capture)",
                bundle: Bundle.main,
                value: "Works in indoor or outdoor environments.",
                comment: "Area Mode tips for the Capture Types page in the object Capture Help screen."
            )
        ]
    }

}

private struct HowToCaptureHelpPageView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TutorialPageView(pageName: LocalizedString.title,
                         imageName: colorScheme == .light ? "OrbitTutorial-light" : "OrbitTutorial",
                         imageCaption: LocalizedString.caption,
                         sections: [Section(title: LocalizedString.firstSetOfTipsTitle,
                                            body: LocalizedString.firstSetOfTips,
                                            symbol: "checkmark.circle", symbolColor: .green),
                                    Section(title: LocalizedString.secondSetOfTipsTitle,
                                            body: LocalizedString.secondSetOfTips,
                                            symbol: "xmark.circle", symbolColor: .red)])
    }

    private struct LocalizedString {
        static let title = NSLocalizedString(
            "How to Capture (Help, Object Capture)",
            bundle: Bundle.main,
            value: "How to Capture",
            comment: "Title of the How to Capture page on the object Capture Help screen.")

        static let caption = NSLocalizedString(
            "Move slowly around your object to capture all sides. (Help, Object Capture)",
            bundle: Bundle.main,
            value: "Move slowly around your object to capture all sides.",
            comment: "Caption of the How to Capture page in the object Capture Help screen."
        )

        static let firstSetOfTipsTitle = NSLocalizedString(
            "Capture Tips (Help, Object Capture)",
            bundle: Bundle.main,
            value: "Capture Tips",
            comment: "The title for the first set of Capture Tips for the How to Capture page in the object Capture Help screen.")

        static let firstSetOfTips = [
            NSLocalizedString(
                "Fill the camera feed with your object (Help, Object Capture)",
                bundle: Bundle.main,
                value: "Fill the camera feed with your object.",
                comment: "First set of Capture Tips for the How to Capture page in the object Capture Help screen."
            ),
            NSLocalizedString(
                "Pause for automatic, clear photographs (Help, Object Capture)",
                bundle: Bundle.main,
                value: "Pause for automatic, clear photographs.",
                comment: "First set of Capture Tips for the How to Capture page in the object Capture Help screen."
            ),
            NSLocalizedString(
                "Capture more of your object for higher quality (Help, Object Capture)",
                bundle: Bundle.main,
                value: "Capture more of your object for higher quality.",
                comment: "First set of Capture Tips for the How to Capture page in the object Capture Help screen."
            )
        ]

        static let secondSetOfTipsTitle = NSLocalizedString(
            "May Reduce Quality (Help, Object Capture)",
            bundle: Bundle.main,
            value: "May Reduce Quality",
            comment: "The second set of Capture Tips for the How to Capture page in the object Capture Help screen."
        )

        static let secondSetOfTips = [
            NSLocalizedString(
                "Moving too quickly (Help, Object Capture)",
                bundle: Bundle.main,
                value: "Moving too quickly",
                comment: "The second set of Capture Tips for the How to Capture page in the object Capture Help screen."
            ),
            NSLocalizedString(
                "Not capturing all surfaces (Help, Object Capture)",
                bundle: Bundle.main,
                value: "Not capturing all surfaces",
                comment: "The second set of Capture Tips for the How to Capture page in the object Capture Help screen."
            ),
            ""
        ]
    }
}

private struct SupportedObjectHelpPageView: View {
    var body: some View {
        TutorialPageView(pageName: LocalizedString.title,
                         imageName: "TextureDetail",
                         imageCaption: LocalizedString.caption,
                         sections: [Section(title: LocalizedString.firstSetOfTipsTitle,
                                            body: LocalizedString.firstSetOfTips,
                                            symbol: "checkmark.circle", symbolColor: .green),
                                    Section(title: LocalizedString.secondSetOfTipsTitle,
                                            body: LocalizedString.secondSetOfTips,
                                            symbol: "xmark.circle", symbolColor: .red)])
    }

    private struct LocalizedString {
        static let title = NSLocalizedString(
            "Supported Objects (Help, Object Capture)",
            bundle: Bundle.main,
            value: "Supported Objects",
            comment: "Title for the Supported Objects page on the object Capture Help screen."
        )

        static let caption = NSLocalizedString(
            "Opaque, matte objects with varied surface textures scan best. (Help, Object Capture)",
            bundle: Bundle.main,
            value: "Opaque, matte objects with varied surface textures scan best.",
            comment: "Caption for the Supported Objects page on the object Capture Help screen."
        )

        static let firstSetOfTipsTitle = NSLocalizedString(
            "Ideal Object Characteristics (Help, Object Capture)",
            bundle: Bundle.main,
            value: "Ideal Object Characteristics",
            comment: "Title for the first set of tips on the Supported Objects page in the object Capture Help screen."
        )

        static let firstSetOfTips = [
            NSLocalizedString(
                "Varied Surface Texture, rigid objects (Help, Object Capture)",
                bundle: Bundle.main,
                value: "Varied Surface Texture, rigid objects",
                comment: "First set of tips for the Supported Objects page in the object Capture Help screen."
            ),
            NSLocalizedString(
                "Nonreflective, matte surface (Help, Object Capture)",
                bundle: Bundle.main,
                value: "Nonreflective, matte surface",
                comment: "First set of tips for the Supported Objects page in the object Capture Help screen."
            ),
            NSLocalizedString(
                "Between 3 in and 6 ft in size (Help, Object Capture)",
                bundle: Bundle.main,
                value: "Between 3 in and 6 ft in size",
                comment: "First set of tips for the Supported Objects page in the object Capture Help screen."
            )
        ]

        static let secondSetOfTipsTitle = NSLocalizedString(
            "May Reduce Quality (Help, Object Capture)",
            bundle: Bundle.main,
            value: "May Reduce Quality",
            comment: "Title for the second set of tips on the Supported Objects page in the object Capture Help screen."
        )

        static let secondSetOfTips = [
            NSLocalizedString(
                "Shiny materials (Help, Object Capture)",
                bundle: Bundle.main,
                value: "Shiny materials",
                comment: "Second set of tips for the Supported Objects page in the object Capture Help screen."
            ),
            NSLocalizedString(
                "Transparent, translucent objects (Help, Object Capture)",
                bundle: Bundle.main,
                value: "Transparent, translucent objects",
                comment: "Second set of tips for the Supported Objects page in the object Capture Help screen."
            ),
            NSLocalizedString(
                "Thin structures (Help, Object Capture)",
                bundle: Bundle.main,
                value: "Thin structures",
                comment: "Second set of tips for the Supported Objects page in the object Capture Help screen."
            )
        ]
    }
}

private struct EnvironmentHelpPageView: View {
    var body: some View {
        TutorialPageView(pageName: LocalizedString.title,
                         imageName: "EnvironmentCharacteristics",
                         imageCaption: LocalizedString.caption,
                         sections: [Section(title: LocalizedString.firstSetOfTipsTitle,
                                            body: LocalizedString.firstSetOfTips,
                                            symbol: "checkmark.circle", symbolColor: .green),
                                    Section(title: LocalizedString.secondSetOfTipsTitle,
                                            body: LocalizedString.secondSetOfTips,
                                            symbol: "xmark.circle", symbolColor: .red)])
    }

    private struct LocalizedString {
        static let title = NSLocalizedString(
            "Environment (Help, Object Capture)",
            bundle: Bundle.main,
            value: "Environment",
            comment: "Title for the Environment page on the object Capture Help screen."
        )

        static let caption = NSLocalizedString(
            "Make sure you have even, bright lighting and a stable environment for scanning. (Help, Object Capture)",
            bundle: Bundle.main,
            value: "Make sure you have even, bright lighting and a stable environment for scanning.",
            comment: "Caption for the Environment page on the object Capture Help screen."
        )

        static let firstSetOfTipsTitle = NSLocalizedString(
            "Ideal Environment Characteristics (Help, Object Capture)",
            bundle: Bundle.main,
            value: "Ideal Environment Characteristics",
            comment: "Title for the first set of tips on Environment page in the object Capture Help screen."
        )

        static let firstSetOfTips = [
            NSLocalizedString(
                "Diffuse, consistent lighting (Help, Object Capture)",
                bundle: Bundle.main,
                value: "Diffuse, consistent lighting",
                comment: "First set of tips for the Environment page in the object Capture Help screen."
            ),
            NSLocalizedString(
                "Space around the intended object (Help, Object Capture)",
                bundle: Bundle.main,
                value: "Space around the intended object",
                comment: "First set of tips for the Environment page in the object Capture Help screen."
            ),
            ""
        ]

        static let secondSetOfTipsTitle = NSLocalizedString(
            "May Reduce Quality (Help, Object Capture)",
            bundle: Bundle.main,
            value: "May Reduce Quality",
            comment: "Title for the second set of tips on the Environment page in the object Capture Help screen."
        )

        static let secondSetOfTips = [
            NSLocalizedString(
                "Sunny, directional lighting (Help, Object Capture)",
                bundle: Bundle.main,
                value: "Sunny, directional lighting",
                comment: "Second set of tips for the Environment page in the object Capture Help screen."
            ),
            NSLocalizedString(
                "Inconsistent shadows (Help, Object Capture)",
                bundle: Bundle.main,
                value: "Inconsistent shadows",
                comment: "Second set of tips for the Environment page in the object Capture Help screen."
            ),
            ""
        ]
    }
}
