/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows a character's dialog and a response box.
*/

import SwiftUI

struct DialogBoxView: View {
    @State var dialogEngine = DialogEngine()

    // If a character is currently talking to the player
    @State var isTalking: Bool = false

    // Text inputed by the player
    @State var userText: String = ""

    /* Rendering character dialog: text is the full next dialog. As each letter is added to renderedText it appears as a typing animation. */
    @State var text: String = ""
    @State var renderedText: String = ""

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                if !renderedText.isEmpty {
                    dialogView
                    // end conversation
                    exitButton
                        .opacity(isTalking ? 0 : 1)
                        .transition(.opacity)
                        .animation(.linear(duration: 0.2), value: isTalking)
                }
            }
            // player's reply
            responseField
                .opacity(dialogEngine.talkingTo != nil && !isTalking && !dialogEngine.isGenerating ? 1 : 0)
                .transition(.opacity)
                .animation(.linear(duration: 0.2), value: isTalking)
        }
        .onChange(of: dialogEngine.nextUtterance) {
            // For each new dialog, reset the typing animation.
            text = dialogEngine.nextUtterance ?? ""
            renderedText = ""
            userText = ""
            typingAnimation()
        }
    }

    @ViewBuilder
    var dialogView: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(dialogEngine.talkingTo?.displayName ?? "")
                .fontWeight(.bold)
            HStack {
                Text(LocalizedStringResource(stringLiteral: renderedText))
                    .onChange(of: renderedText, typingAnimation)
                Spacer()
            }
        }
        .frame(maxWidth: 350)
        .modifier(GameBoxStyle())
        .padding()
        .onAppear(perform: typingAnimation)
    }

    @ViewBuilder
    var exitButton: some View {
        Button {
            dialogEngine.endConversation()
        } label: {
            Image(systemName: "xmark")
                .fontWeight(.bold)
                .foregroundStyle(.darkBrown)
                .font(.title2)
        }
        .buttonStyle(.plain)
        .modifier(GameBoxStyle())
        .padding([.top, .bottom, .trailing])
    }

    @ViewBuilder
    var responseField: some View {
        HStack {
            TextField(
                "Reply",
                text: $userText
            )
            .textFieldStyle(.plain)
            .focused($isFocused)
            .disabled(isTalking)
            .onSubmit {
                userResponds()
            }
            Button {
                userResponds()
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(.darkBrown)
                    .font(.title2)
            }
            .buttonStyle(.plain)
            .disabled(isTalking)
        }
        .frame(height: 50)
        .modifier(GameBoxStyle())
        .padding(.horizontal)
        .padding(.bottom)
    }

    func typingAnimation() {
        if renderedText.count < text.count {
            isTalking = true
            Task {
                try? await Task.sleep(for: .seconds(0.025))
                // check again in case text updated during the wait
                if renderedText.count < text.count {
                    let next = text[renderedText.endIndex]
                    renderedText.append(next)
                } else {
                    isTalking = false
                }
            }
        } else {
            isTalking = false
        }
    }

    func userResponds() {
        isFocused = false
        dialogEngine.respond(userText)
    }
}

#Preview {
    let dialogEngine = DialogEngine()
    DialogBoxView(dialogEngine: dialogEngine)
        .task {
            dialogEngine.talkingTo = Barista()
            dialogEngine.nextUtterance = "Hello welcome to Dream Coffee"
        }
}
