/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view model that indicates the state of driver communication.
*/

import Foundation

@_silgen_name("SwiftAsyncCallback")
func SwiftAsyncCallback(refcon: UnsafeMutableRawPointer, result: IOReturn, args: UnsafeMutableRawPointer, numArgs: UInt32) {
    let viewModel: DriverCommunicationViewModel = Unmanaged<DriverCommunicationViewModel>.fromOpaque(refcon).takeUnretainedValue()

    let argsPointer = args.bindMemory(to: UInt8.self, capacity: Int(numArgs * 8))
    let argsBuffer = UnsafeBufferPointer(start: argsPointer, count: Int(numArgs * 8))

    viewModel.LocalAsyncCallback(result: result, data: Array(argsBuffer))
}

@_silgen_name("SwiftDeviceAdded")
func SwiftDeviceAdded(refcon: UnsafeMutableRawPointer, connection: io_connect_t) {
    let viewModel: DriverCommunicationViewModel = Unmanaged<DriverCommunicationViewModel>.fromOpaque(refcon).takeUnretainedValue()
    viewModel.isConnected = true
    viewModel.connection = connection
}

@_silgen_name("SwiftDeviceRemoved")
func SwiftDeviceRemoved(refcon: UnsafeMutableRawPointer) {
    let viewModel: DriverCommunicationViewModel = Unmanaged<DriverCommunicationViewModel>.fromOpaque(refcon).takeUnretainedValue()
    viewModel.isConnected = false
}

class DriverCommunicationStateMachine {

    enum State {
        case unknown
        case waiting
        case success
        case noCallback
        case error
    }

    enum Event {
        case sentRequest
        case returned
        case failed
        case foundNoCallback
    }

    static func process(_ state: State, _ event: Event) -> State {
        switch event {
        case .sentRequest:
            return .waiting
        case .returned:
            return .success
        case .failed:
            return .error
        case .foundNoCallback:
            return .noCallback
        }
    }
}

class DriverCommunicationViewModel: NSObject, ObservableObject {

    @Published public var isConnected: Bool = false
    public var connection: io_connect_t = 0

    var opaqueSelf: UnsafeMutableRawPointer? = UnsafeMutableRawPointer(bitPattern: 0)

    @Published private var state: DriverCommunicationStateMachine.State = .unknown
    public var stateDescription: String {
        switch state {
        case .unknown:
            return "Waiting for action"
        case .waiting:
            return "Sent request, waiting for response"
        case .success:
            return "Request returned successfully"
        case .noCallback:
            return "Assign a callback before you send an async message"
        case .error:
            return "Request returned an error, check the logs for details"
        }
    }

    override init() {
        super.init()

        // Create a reference to this view model so the C code can call back to it.
        self.opaqueSelf = Unmanaged.passRetained(self).toOpaque()

        // Let the C code set up the IOKit calls.
        UserClientSetup(opaqueSelf)
    }

    convenience init(isConnected: Bool) {
        self.init()

        self.isConnected = isConnected
    }

    deinit {
        // Take the last reference of the pointer so it can be freed.
        _ = Unmanaged<DriverCommunicationViewModel>.fromOpaque(self.opaqueSelf!).takeRetainedValue()

        // Let the C code clean up after itself.
        UserClientTeardown()
    }

    func LocalAsyncCallback(result: IOReturn, data: [UInt8]) {
        state = DriverCommunicationStateMachine.process(state, .returned)
    }

    private func ProcessResult(_ didWork: Bool) {
        if didWork {
            state = DriverCommunicationStateMachine.process(state, .returned)
        } else {
            state = DriverCommunicationStateMachine.process(state, .failed)
        }
    }

    func SwiftUncheckedScalar() {
        state = DriverCommunicationStateMachine.process(state, .sentRequest)
        ProcessResult(UncheckedScalar(connection))
    }

    func SwiftUncheckedStruct() {
        state = DriverCommunicationStateMachine.process(state, .sentRequest)
        ProcessResult(UncheckedStruct(connection))
    }

    func SwiftUncheckedLargeStruct() {
        state = DriverCommunicationStateMachine.process(state, .sentRequest)
        ProcessResult(UncheckedLargeStruct(connection))
    }

    func SwiftCheckedScalar() {
        state = DriverCommunicationStateMachine.process(state, .sentRequest)
        ProcessResult(CheckedScalar(connection))
    }

    func SwiftCheckedStruct() {
        state = DriverCommunicationStateMachine.process(state, .sentRequest)
        ProcessResult(CheckedStruct(connection))
    }

    func SwiftAssignAsyncCallback() {
        state = DriverCommunicationStateMachine.process(state, .sentRequest)
        let didSubmit = AssignAsyncCallback(opaqueSelf, connection)
        if !didSubmit {
            state = DriverCommunicationStateMachine.process(state, .failed)
        }
    }

    func SwiftSubmitAsyncRequest() {
        state = DriverCommunicationStateMachine.process(state, .sentRequest)
        let didSubmit = SubmitAsyncRequest(connection)
        if !didSubmit {
            state = DriverCommunicationStateMachine.process(state, .failed)
        }
    }
}
