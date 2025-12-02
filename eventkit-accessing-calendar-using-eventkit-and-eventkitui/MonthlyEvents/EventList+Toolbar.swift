/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The toolbar for the Event list view.
*/

import SwiftUI

extension EventList {
    @ToolbarContentBuilder
    func toolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            EditButton(editMode: $editMode) {
                selection.removeAll()
                editMode = .inactive
            }
        }
        
        ToolbarItem(placement: .navigationBarLeading) {
            if editMode == .active {
                Button(action: {
                    removeEvents(Array(selection))
                }) {
                    Text("Delete")
                }
                .disabled(selection.isEmpty)
            }
        }
    }
}
