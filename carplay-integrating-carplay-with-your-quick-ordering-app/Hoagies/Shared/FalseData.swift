/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Provides test data for use in the app.
*/

import MapKit
import Contacts

class TestHoagieData {
    
    static let testData = TestHoagieData()
    
    static let appGroupContainerID = "<Your App Group>"
    
    static let tenMinutes = 60.0 * 10.0
    
    static let hoagieDefaults: UserDefaults = UserDefaults(suiteName: TestHoagieData.appGroupContainerID)!
    
    struct Hoagie: Codable {
        var meats = [String]()
        var vegetables = [String]()
        var dressings = [String]()
        var bread = ""
        var cheese = ""
    }
    
    // MARK: Orders
    
    class HoagieOrder: Codable {
        var date: Double
        var order: [String]
        var type: String
        var pickupLocation: String
        init(orderDate: Double = Date.timeIntervalSinceReferenceDate, orderItems: [String], typeOfOrder: String, location: String) {
            date = orderDate
            order = orderItems
            type = typeOfOrder
            pickupLocation = location
        }
    }
    
    private static let orderKey = "lastOrder"
    
    // Save to shared defaults and `NSUbiquitousKeyValueStore` in case you need it on another platform.
    class func saveLastOrder(order: TestHoagieData.HoagieOrder) {
        order.type = "Last Order"
        TestHoagieData.hoagieDefaults.set(try? JSONEncoder().encode(order), forKey: orderKey)
    }
    
    class func houseFavoriteOrder() -> TestHoagieData.HoagieOrder {
        TestHoagieData.HoagieOrder(
            orderItems: [
                "🥖",
                "🧀🫕",
                "🥓🦃🐷🥩",
                "🥬🍅🧅",
                "🧂🌶️"],
            typeOfOrder: "House Favorite",
            location: TestHoagieData.testMapItems().randomElement()!.mapItem.name!)
    }
    
    class func lastOrder() -> TestHoagieData.HoagieOrder {
        guard
            let data = TestHoagieData.hoagieDefaults.data(forKey: orderKey),
            let decoded = try? JSONDecoder().decode(TestHoagieData.HoagieOrder.self, from: data) else {
            return TestHoagieData.HoagieOrder(
                orderItems: [
                    "🥖",
                    "🥓",
                    "🥬🍅",
                    "🧂"],
                typeOfOrder: "Last Order",
                location: TestHoagieData.testMapItems().randomElement()!.mapItem.name!)
        }
        return decoded
    }
    
    class HoagieShopMapItem: Identifiable {
        let id = UUID()
        let mapItem: MKMapItem
        init(_ mapItem: MKMapItem) {
            self.mapItem = mapItem
        }
    }
    
    // MARK: Map Items
    
    static func testMapItems() -> [HoagieShopMapItem] {
        let bridgeItem = MKMapItem(
            placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.807_977, longitude: -122.475_306),
                                   postalAddress: TheBridge()))
        bridgeItem.name = "Hoagie Shop I"
        let cityHallItem = MKMapItem(
            placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 37.778_858, longitude: -122.419_326),
                                   postalAddress: CityHall()))
        cityHallItem.name = "Hoagie Shop II"
        return [HoagieShopMapItem(bridgeItem), HoagieShopMapItem(cityHallItem)]
    }
    
    static let testRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 37.790, longitude: -122.450),
                              latitudinalMeters: 500_000, longitudinalMeters: 500_000)
    
    // MARK: Address Data

    fileprivate class BaseAddress: CNPostalAddress {
        
        override var country: String {
            return "US"
        }
        
        override var city: String {
            return "San Francisco"
        }
        
        override var state: String {
            return "CA"
        }
        
        override var postalCode: String {
            return "94102"
        }
        
    }

    fileprivate class CityHall: BaseAddress {
        
        override var street: String {
            return "1 Dr. Carlton B Goodlett Pl"
        }
    }

    fileprivate class TheBridge: BaseAddress {
        
        override var street: String {
            return "Golden Gate Bridge Plaza"
        }
        
        override var postalCode: String {
            return "94129"
        }
    }
    
}

