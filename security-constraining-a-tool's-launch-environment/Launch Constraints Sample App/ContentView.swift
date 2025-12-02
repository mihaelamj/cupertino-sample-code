/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A content view that displays a single-function calculator.
*/
import SwiftUI

func integerTextBinding(binding: Binding<Int>) -> Binding<String> {
    return Binding(get: { String(binding.wrappedValue) },
                   set: { binding.wrappedValue = Int($0) ?? 0 })
}

struct ContentView: View {
    @State var firstNumber: Int = 0
    @State var secondNumber: Int = 0
    
    @State var result: Int = 0
    var body: some View {
        VStack {
            HStack {
                TextField("First number", text: integerTextBinding(binding: $firstNumber))
                .frame(width: 50)
                Text("+")
                TextField("Second number", text: integerTextBinding(binding: $secondNumber))
                .frame(width: 50)
                Text("=")
                TextField("Result", text: integerTextBinding(binding: $result))
                .frame(width: 50)
                .disabled(true)
            }
            Button("Calculate") {
                do {
                    result = try sum(firstNumber: firstNumber, secondNumber: secondNumber)
                } catch let error {
                    NSApp.presentError(error)
                }
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
