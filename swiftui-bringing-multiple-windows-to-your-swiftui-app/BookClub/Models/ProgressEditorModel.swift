/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Reading progress editor model for managing state and presentation.
*/

import Foundation

struct ProgressEditorModel: Hashable {
    enum DismissAction {
        case save(in: CurrentlyReading)
        case cancel
    }

    var isPresented = false
    var note = ""
    var progress = 0.0

    mutating func present(initialProgress: Double) {
        progress = initialProgress
        note = ""
        isPresented = true
    }

    mutating func dismiss(_ action: DismissAction) {
        switch action {
        case .save(let currentlyReading):
            currentlyReading.markProgress(progress, note: note)
            fallthrough
        case .cancel:
            isPresented = false
            note = ""
        }
    }

    mutating func togglePresentation(for currentlyReading: CurrentlyReading) {
        if isPresented {
            dismiss(.cancel)
        } else {
            present(initialProgress: currentlyReading.currentProgress)
        }
    }
}

extension ProgressEditorModel {
    static var mocks: [ProgressEditorModel] {
        [
            .default,
            .presentedOnly,
            .presentedWithNote,
            .presentedWithNoteAndProgress,
            .noteOnly,
            .noteAndProgress
        ]
    }
    
    static var `default`: ProgressEditorModel {
        ProgressEditorModel()
    }
    
    static var presentedOnly: ProgressEditorModel {
        ProgressEditorModel(isPresented: true)
    }
    
    static var presentedWithNote: ProgressEditorModel {
        ProgressEditorModel(isPresented: true, note: note)
    }
    
    static var presentedWithNoteAndProgress: ProgressEditorModel {
        ProgressEditorModel(isPresented: true, note: note, progress: progress)
    }
    
    static var noteOnly: ProgressEditorModel {
        ProgressEditorModel(note: note)
    }
    
    static var noteAndProgress: ProgressEditorModel {
        ProgressEditorModel(note: note, progress: progress)
    }
    
    private static let note = "Hello World!"
    private static let progress = 0.75
}
