/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A SwiftUI view that shows a countdown timer.
*/

import SwiftUI

struct CountDownView: View {
    @State private var manager = CountDownManager()
        
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(.gray, style: .init(lineWidth: 20))
                
                Circle()
                    .trim(from: 0, to: manager.trimValue)
                    .stroke(.accent, style: .init(lineWidth: 20, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(manager.isSettingTrim ? nil : .linear(duration: 1), value: manager.timeRemaining)
                    .overlay {
                        Text("\(Int(manager.timeRemaining))")
                            .font(.system(size: 60))
                            .foregroundColor(.accent)
                            .fontWeight(.bold)
                            .contentTransition(.numericText(countsDown: true))
                            .animation(.easeInOut, value: manager.timeRemaining)
                    }
            }
            .frame(width: 250, height: 250)
            .onReceive(manager.timerFinished) { _ in
                WorkoutManager.shared.startWorkout()
            }
        }
        .onAppear() {
            manager.startCountDown()
        }
    }
}
