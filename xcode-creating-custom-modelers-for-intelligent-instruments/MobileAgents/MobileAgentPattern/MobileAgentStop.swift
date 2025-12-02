/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A Mobile Agent Stop accepts Mobile Agents via the receiveMobileAgent function and invokes their hello() and goodbye()
     functions to begin execution.
*/
import Foundation

/*
   All MobileAgentStops need to implement this protocol.
 
   receiveMobileAgent is responsible for accepting an incoming agent and invoking
   hello() to start the execution, and goodbye() to send the MobileAgent off to
   the next stop.
 
   diagnosticsTypeCode is needed for the purposes of instrumentation and debugging.
*/
protocol MobileAgentStop {
    func receiveMobileAgent(agent: MobileAgent)
    func diagnosticsTypeCode() -> UInt32
}

