/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Progress details editor view for updating the user's reading progress entries.
*/

import SwiftUI

struct ProgressEditor: View {
    @ObservedObject var currentlyReading: CurrentlyReading
    @Binding var model: ProgressEditorModel
    @FocusState private var isTextEditorFocused: Bool

    init(
        book currentlyReading: CurrentlyReading,
        model: Binding<ProgressEditorModel>
    ) {
        self.currentlyReading = currentlyReading
        _model = model
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Slider(value: $model.progress, in: 0...1)
                Text(Int(model.progress * 100), format: .percent)
            }
            .padding(.bottom)

            TextField("Notes", text: $model.note, axis: .vertical)
                .lineLimit(5, reservesSpace: true)
                .focused($isTextEditorFocused)

            Spacer()
            buttons
        }
        .padding()
        #if os(iOS)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                buttons
            }
        }
        .onAppear {
            isTextEditorFocused = true
        }
        #endif
    }
    
    var buttons: some View {
        HStack {
            Button("Cancel", action: cancel)
            Spacer()
            Button("Save", action: save)
        }
    }

    func cancel() {
        isTextEditorFocused = false
        model.dismiss(.cancel)
    }

    func save() {
        isTextEditorFocused = false
        model.dismiss(.save(in: currentlyReading))
    }
}

extension View {
    func progressEditorModal(
        book: CurrentlyReading,
        model: Binding<ProgressEditorModel>
    ) -> some View {
        modifier(ProgressEditorModifier(book: book, model: model))
    }
}

private struct ProgressEditorModifier: ViewModifier {
    #if os(iOS)
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    #endif
    @ObservedObject var book: CurrentlyReading
    @Binding var model: ProgressEditorModel
    
    func body(content: Content) -> some View {
        if isCompactHorizonalSizeClass {
            content.sheet(isPresented: $model.isPresented) {
                ProgressEditor(book: book, model: $model)
                    .presentationDetents([.height(300)])
                    .presentationDragIndicator(.visible)
            }
        } else {
            content.popover(isPresented: $model.isPresented) {
                ProgressEditor(book: book, model: $model)
                    .frame(idealWidth: 300, minHeight: 200, maxHeight: 250)
            }
        }
    }
    
    var isCompactHorizonalSizeClass: Bool {
        #if os(iOS)
        return horizontalSizeClass == .compact
        #else
        return false
        #endif
    }
}

struct ProgressEditor_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(ProgressEditorModel.mocks, id: \.self) { model in
                ProgressEditor(book: .mock, model: .constant(model))
            }
        }
    }
}
