/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A custom control to select the sentiment about a recipe.
*/

import SwiftUI

/// The shape of the rating picker control.
private let shape: some Shape = Capsule()

struct RatingPicker<Label: View>: View {
    @Environment(\.layoutDirection) private var layoutDirection

    /// A view that describes the use of the rating picker.
    private var label: Label

    /// A binding of the rating represented by the control, if any.
    @Binding private var rating: Rating?

    /// The last selected rating; used to restore the rating when toggled
    /// with the Space key.
    @State private var lastRatingSelection: Rating?

    /// Creates an instance of a rating picker.
    ///
    /// - Parameters:
    ///     - rating: A `Binding` to the variable that holds the selected
    ///       `Rating` or `nil` if none is selected.
    ///     - label: A view that describes the use of the rating picker.,
    init(
        rating: Binding<Rating?>,
        @ViewBuilder label: () -> Label
    ) {
        _rating = rating
        self.label = label()
    }

    var body: some View {
        LabeledContent {
            content
        } label: {
            Text("Rating")
        }
    }

    private var content: some View {
        EmojiContainer {
            ratingOptions
        }
        .contentShape(shape)
        .focusable(interactions: .activate)
        #if os(macOS)
        .onMoveCommand { direction in
            selectRating(in: direction, layoutDirection: layoutDirection)
        }
        .onKeyPress(.space) {
            rating = rating == nil ? (lastRatingSelection ?? .yummy) : nil
            return .handled
        }
        #endif
    }

    /// A view that displays the rating picker's options.
    private var ratingOptions: some View {
        HStack(spacing: 2) {
            ForEach(Rating.allCases) { rating in
                EmojiView(
                    rating: rating,
                    isSelected: self.rating == rating
                ) {
                    self.rating = self.rating != rating ? rating : nil
                }
                .zIndex(self.rating == rating ? 0 : 1)
            }
        }
        .onChange(of: rating) { oldValue, newValue in
            if let rating = newValue {
                lastRatingSelection = rating
            }
        }
    }

    #if os(macOS)
    /// Selects the rating in the given direction, taking into account the
    /// layout direction for right-to-left language environments.
    private func selectRating(
        in direction: MoveCommandDirection, layoutDirection: LayoutDirection
    ) {
        let direction = direction.transform(from: layoutDirection)

        if let rating {
            switch direction {
            case .left:
                guard let previousRating = rating.previous else { return }
                self.rating = previousRating
            case .right:
                guard let nextRating = rating.next else { return }
                self.rating = nextRating
            default:
                break
            }
        } else {
            // If no rating is already selected, select one.
            switch direction {
            case .left:
                self.rating = lastRatingSelection ?? Rating.allCases.last
            case .right:
                self.rating = lastRatingSelection ?? Rating.allCases.first
            default:
                break
            }
        }
    }
    #endif
}

/// A container view that provides the base styling of the control.
private struct EmojiContainer<Content: View>: View {
    @Environment(\.isFocused) private var isFocused
    private var content: Content

    /// The control's border color.
    private var strokeColor: Color {
        #if os(watchOS)
        isFocused ? .green : .clear
        #else
        .clear
        #endif
    }

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(height: 32)
            .font(.system(size: 24))
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.quaternary)
            .clipShape(shape)
            #if os(watchOS)
            .overlay(
                RatingPicker.shape
                    .strokeBorder(strokeColor, lineWidth: 1.5)
            )
            #endif
    }
}

/// A view that displays an emoji representing a rating and performs the
/// given action when the emoji is tapped or clicked.
private struct EmojiView: View {
    /// The rating that the emoji represents.
    private var rating: Rating

    /// Whether this rating is selected.
    private var isSelected: Bool

    /// An action to perform when the emoji is tapped or clicked.
    private var action: () -> Void

    init(rating: Rating, isSelected: Bool, action: @escaping () -> Void) {
        self.rating = rating
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(isSelected ? Color.accentColor : Color.clear)
            Text(verbatim: rating.emoji)
                .onTapGesture { action() }
                .accessibilityLabel(rating.localizedName)
        }
    }
}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
#Preview {
    Group {
        RatingPicker(rating: .constant(.delicious)) {
            Text("Rating")
        }
        .labelsHidden()

        RatingPicker(rating: .constant(.delicious)) {
            Text("Rating")
        }
        .labelsHidden()
        .environment(\.layoutDirection, .rightToLeft)
    }
}
