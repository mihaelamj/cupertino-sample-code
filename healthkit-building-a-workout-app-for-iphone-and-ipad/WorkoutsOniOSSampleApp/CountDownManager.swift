/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The class that wraps the controls of the countdown view.
*/

import Combine
import Foundation

@Observable final class CountDownManager {
    var timeRemaining: TimeInterval = 3
    var duration: TimeInterval = 3
    
    private let timerFinishedSubject = PassthroughSubject<Void, Never>()
    var timerFinished: AnyPublisher<Void, Never> {
        timerFinishedSubject.eraseToAnyPublisher()
    }
    
    private var countDownConnector: Cancellable?
    
    private var endDate: Date?

    private func connectCountDown() {
        countDownConnector = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink(receiveValue: { [weak self] currentDate in
                guard let self, let endDate else { return }
                
                let remainingTime = endDate.timeIntervalSince(currentDate)
                
                if remainingTime > 0 {
                    timeRemaining = remainingTime
                } else {
                    endCountDown()
                    timerFinishedSubject.send()
                }
            })
    }
    
    func startCountDown() {
        self.duration = duration
        timeRemaining = duration
        endDate = Date().addingTimeInterval(duration)
        connectCountDown()
    }
    
    func endCountDown() {
        countDownConnector?.cancel()
        countDownConnector = nil
        
        timeRemaining = duration
        endDate = nil
    }
    
    var trimValue: Double {
        timeRemaining > 0 ? timeRemaining / duration : 0
    }
    
    var isSettingTrim: Bool {
        timeRemaining == duration
    }
}
