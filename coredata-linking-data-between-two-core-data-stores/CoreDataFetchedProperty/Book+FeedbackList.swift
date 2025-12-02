/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension of the Book entity declaring the fetch property of the Book entity.
*/

// Xcode doesn't generate the accessor for fetched properties,
// so provide it manually with an extension.
//
extension Book {
    var feedbackList: [Feedback]? { // The accessor of the feedbackList property.
        return value(forKey: "feedbackList") as? [Feedback]
    }
}
