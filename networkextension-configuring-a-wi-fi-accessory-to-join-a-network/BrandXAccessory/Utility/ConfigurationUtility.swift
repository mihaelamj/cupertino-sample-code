/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The utility class for generating a QR code and random strings, and for obtaining an IP address.
*/

import Foundation
import CoreImage

enum ConfigurationUtility {
    
    /// @function generateQRCode
    /// @discussion Embed the networkInfo string in a 144x144 CGImage.
    /// @return A CIImage to create a CGImage and then an NSImage for capture by iOS.
    static func generateQRCode(networkInfo: String, to width: CGFloat, and height: CGFloat) -> CIImage? {
        
        guard
            let embeddedData = networkInfo.data(using: .isoLatin1),
            let qrFilter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        
        // The data to encode as a QR code. An NSData object with a display name of Message.
        qrFilter.setValue(embeddedData, forKey: "inputMessage")
        
        guard let rawCIImage = qrFilter.outputImage else { return nil }
        let xval = width / rawCIImage.extent.width
        let yval = height / rawCIImage.extent.height
        
        let transform = CGAffineTransform(scaleX: xval, y: yval)
        
        return qrFilter.outputImage?.transformed(by: transform)
    }
    
    /// @function createRandomString
    /// @discussion Generate a (length) digit random string based on random().
    /// @return A random string to use in psk and pskIndentity.
    static func createRandomString(length: Int) -> String {
        var authenticationCode = ""
        let characterString = ["a", "A", "b", "B", "c", "C", "d", "D", "e", "E", "f",
                               "F", "g", "G", "h", "H", "i", "I", "j", "J", "k", "K",
                               "l", "L", "m", "M", "n", "N", "o", "O", "p", "P", "q",
                               "Q", "r", "R", "s", "S", "t", "T", "u", "U", "v", "V",
                               "w", "W", "x", "X", "y", "Y", "Z", "0", "1", "2", "3",
                               "4", "5", "6", "7", "8", "9"]
        for _ in 0..<length {
            let ranValue = Int.random(in: 0..<characterString.count)
            authenticationCode += characterString[Int(ranValue)]
        }
        return authenticationCode
    }
    
    /// @function getIPAddress
    /// @discussion If Internet Sharing is up and running when App-Mac starts, get the IP for iOS to use in the QR code in WebSocketConnection.
    /// Completion returns a string IP value.
    static func getIPAddress(completion: @escaping (String) -> Void ) {
        
        DispatchQueue.global(qos: .default).sync {
            var address = "N/A"
            var ifAddrsList: UnsafeMutablePointer<ifaddrs>?
            guard getifaddrs(&ifAddrsList) == 0,
                  let firstIFAddr = ifAddrsList else {
                completion(address)
                return
            }
            defer { freeifaddrs(ifAddrsList) }
            // Iterate through the linked list using pointee.ifa_next to assign to the next iteration.
            for ifaddrs in sequence(first: firstIFAddr, next: { $0.pointee.ifa_next }) {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if let addr = ifaddrs.pointee.ifa_addr,
                   ifaddrs.pointee.ifa_name != nil,
                   (Int32(ifaddrs.pointee.ifa_flags) & (IFF_UP | IFF_RUNNING | IFF_LOOPBACK)) == (IFF_UP | IFF_RUNNING),
                   ifaddrs.pointee.ifa_addr.pointee.sa_family == UInt8(AF_INET), // Remove this for v4 or v6.
                   getnameinfo(addr, socklen_t(addr.pointee.sa_len),
                               &hostname, socklen_t(hostname.count), nil,
                               socklen_t(0), NI_NUMERICHOST) == 0,
                   hostname[0] != 0 {
                    // To check for the corresponding interface name on the inet address,
                    // let interface_name = String(cString: ifaddrs.pointee.ifa_name).
                    // When using Internet Sharing, you may see something like vmnet* as the interface name.
                    // % ifconfig -v to match the interface and address.
                    address = String(cString: hostname)
                    completion(address)
                    break
                }
            }
            completion(address)
        }
    }
}
