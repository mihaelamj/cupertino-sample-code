/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
---
*/

import Foundation

extension Landmark {
    @MainActor static let exampleData = [
        Landmark(
            id: 1001,
            name: String(localized: .LandmarkData.saharaDesertName),
            continent: "Africa",
            description: String(localized: .LandmarkData.saharaDesertDescription),
            latitude: 23.900_13,
            longitude: 10.335_69,
            span: 40.0,
            placeID: "IC6C65CA81B4B2772"
        ),
        
        Landmark(
            id: 1002,
            name: String(localized: .LandmarkData.serengetiName),
            continent: "Africa",
            description: String(localized: .LandmarkData.serengetiDescription),
            latitude: -2.454_69,
            longitude: 34.881_59,
            span: 10.0,
            placeID: "IB3A0184A4D301279"
        ),
        
        Landmark(
            id: 1003,
            name: String(localized: .LandmarkData.deadvleiName),
            continent: "Africa",
            description: String(localized: .LandmarkData.deadvleiDescription),
            latitude: -24.7629,
            longitude: 15.294_29,
            span: 10.0,
            placeID: "IBD2966F32E73D261"
        ),
        
        Landmark(
            id: 1004,
            name: String(localized: .LandmarkData.grandCanyonName),
            continent: "North America",
            description: String(localized: .LandmarkData.grandCanyonDescription),
            latitude: 36.219_04,
            longitude: -113.160_96,
            span: 10.0,
            placeID: "I55488B3D1D9B2D4B"
        ),
        
        Landmark(
            id: 1005,
            name: String(localized: .LandmarkData.niagaraFallsName),
            continent: "North America",
            description: String(localized: .LandmarkData.niagaraFallsDescription),
            latitude: 43.077_92,
            longitude: -79.074_01,
            span: 4.0,
            placeID: "I433E22BD30C61C40"
        ),
        
        Landmark(
            id: 1006,
            name: String(localized: .LandmarkData.joshuaTreeName),
            continent: "North America",
            description: String(localized: .LandmarkData.joshuaTreeDescription),
            latitude: 33.887_52,
            longitude: -115.808_26,
            span: 10.0,
            placeID: "I34674B3D3B032AA2"
        ),
        
        Landmark(
            id: 1007,
            name: String(localized: .LandmarkData.rockyMountainsName),
            continent: "North America",
            description: String(localized: .LandmarkData.rockyMountainsDescription),
            latitude: 47.625_96,
            longitude: -112.998_72,
            span: 16.0,
            placeID: "IBD757C9B53C92D9E"
        ),
        
        Landmark(
            id: 1008,
            name: String(localized: .LandmarkData.monumentValleyName),
            continent: "North America",
            description: String(localized: .LandmarkData.monumentValleyDescription),
            latitude: 36.874,
            longitude: -110.348,
            span: 10.0,
            placeID: "IAB1F0D2360FAAD29"
        ),
        
        Landmark(
            id: 1009,
            name: String(localized: .LandmarkData.muirWoodsName),
            continent: "North America",
            description: String(localized: .LandmarkData.muirWoodsDescription),
            latitude: 37.8922,
            longitude: -122.574_82,
            span: 2.0,
            placeID: "I907589547EB05261"
        ),
        
        Landmark(
            id: 1010,
            name: String(localized: .LandmarkData.amazonRainforestName),
            continent: "South America",
            description: String(localized: .LandmarkData.amazonRainforestDescription),
            latitude: -3.508_79,
            longitude: -62.808_02,
            span: 30.0,
            placeID: "I76A1045FB9294971"
        ),
        
        Landmark(
            id: 1011,
            name: String(localized: .LandmarkData.lençóisMaranhensesName),
            continent: "South America",
            description: String(localized: .LandmarkData.lençóisMaranhensesDescription),
            latitude: -2.578_12,
            longitude: -43.033_45,
            span: 10.0,
            placeID: "I292A37DAC754D6A0"
        ),
        
        Landmark(
            id: 1012,
            name: String(localized: .LandmarkData.uyuniSaltFlatName),
            continent: "South America",
            description: String(localized: .LandmarkData.uyuniSaltFlatDescription),
            latitude: -20.133_78,
            longitude: -67.489_14,
            span: 10.0,
            placeID: "ID903C9A78EB0CAAD"
        ),
        
        Landmark(
            id: 1014,
            name: String(localized: .LandmarkData.whiteCliffsOfDoverName),
            continent: "Europe",
            description: String(localized: .LandmarkData.whiteCliffsOfDoverDescription),
            latitude: 51.136_41,
            longitude: 1.363_51,
            span: 4.0,
            placeID: "I77B160572D5A2EB1"
        ),
        
        Landmark(
            id: 1015,
            name: String(localized: .LandmarkData.alpsName),
            continent: "Europe",
            description: String(localized: .LandmarkData.alpsDescription),
            latitude: 46.773_67,
            longitude: 10.547_73,
            span: 6.0,
            placeID: "IE380E71D265F97C0"
        ),
        
        Landmark(
            id: 1016,
            name: String(localized: .LandmarkData.mountFujiName),
            continent: "Asia",
            description: String(localized: .LandmarkData.mountFujiDescription),
            latitude: 35.360_72,
            longitude: 138.727_44,
            span: 10.0,
            placeID: "I2CC1DF519EDD7ACD"
        ),
        
        Landmark(
            id: 1017,
            name: String(localized: .LandmarkData.wulingyuanName),
            continent: "Asia",
            description: String(localized: .LandmarkData.wulingyuanDescription),
            latitude: 29.351_06,
            longitude: 110.452_42,
            span: 10.0,
            placeID: "I818C4BA5FE11BDD6"
        ),
        
        Landmark(
            id: 1018,
            name: String(localized: .LandmarkData.mountEverestName),
            continent: "Asia",
            description: String(localized: .LandmarkData.mountEverestDescription),
            latitude: 27.988_16,
            longitude: 86.9251,
            span: 10.0,
            placeID: "IE16B9C217B9B0DC1"
        ),
        
        Landmark(
            id: 1019,
            name: String(localized: .LandmarkData.greatBarrierReefName),
            continent: "Australia/Oceania",
            description: String(localized: .LandmarkData.greatBarrierReefDescription),
            latitude: -16.7599,
            longitude: 145.978_42,
            span: 16.0,
            placeID: "IF436B51611F3F9D1"
        ),
        
        Landmark(
            id: 1020,
            name: String(localized: .LandmarkData.yellowstoneNationalPark),
            continent: "North America",
            description: String(localized: .LandmarkData.yellowstoneNationalParkDescription),
            latitude: 44.6,
            longitude: -110.5,
            span: 4.0,
            placeID: "ICE88191F5D7094D0"
        ),
        
        Landmark(
            id: 1021,
            name: String(localized: .LandmarkData.southShetlandIslandsName),
            continent: "Antarctica",
            description: String(localized: .LandmarkData.southShetlandIslandsDescription),
            latitude: -61.794_36,
            longitude: -58.707_03,
            span: 20.0,
            placeID: "I1AAF5FE1DF954A59"
        ),
        
        Landmark(
            id: 1022,
            name: String(localized: .LandmarkData.kirkjufellMountain),
            continent: "Europe",
            description: String(localized: .LandmarkData.kirkjufellMountainDescription),
            latitude: 64.941,
            longitude: -23.305,
            span: 2.0,
            placeID: "I4E9DB8B46491DC5E"
        )
    ]
}
