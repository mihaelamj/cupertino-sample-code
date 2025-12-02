/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The currently selected variant of the complication families.
*/

import Combine
import SwiftUI

extension CaseIterable where Self: RawRepresentable {
    static var allRawValues: [Self.RawValue] {
        return allCases.map { $0.rawValue }
    }
}

enum GraphicCornerVariant: String, Codable, CaseIterable {
    case gaugeText = "Gauge Text", gaugeImage = "Gauge Image", textImage = "Text Image"
    case stackText = "Stack Text", circularImage = "Circular Image"
}

enum GraphicCircularVariant: String, Codable, CaseIterable {
    case image = "Image"
    case openGaugeRangeText = "Open Gauge Range Text"
    case openGaugeSimpleText = "Open Gauge Simple Text"
    case openGaugeImage = "Open Gauge Image"
    case closedGaugeText = "Close Gauge Text"
    case closedGaugeImage = "Close Gauge Image"
}

enum GraphicRectangleVariant: String, Codable, CaseIterable {
    case largeImage = "Large Image", standardBody = "Standard Body", textGauge = "Text Gauge"
}

final class TemplateConfiguration: Codable, ObservableObject, Equatable {
    @Published var graphicRectangle = GraphicRectangleVariant.largeImage.rawValue
    @Published var graphicCorner = GraphicCornerVariant.gaugeText.rawValue
    @Published var graphicCircular = GraphicCircularVariant.image.rawValue
    
    init() {}
    
    convenience init?(from fileURL: URL) {
        guard let data = try? Data(contentsOf: fileURL),
            let configuration = try? JSONDecoder().decode(TemplateConfiguration.self, from: data) else {
                return nil
        }
        self.init()
        graphicCorner = configuration.graphicCorner
        graphicCircular = configuration.graphicCircular
        graphicRectangle = configuration.graphicRectangle
    }

    // MARK: - Codable
    //
    enum CodingKeys: CodingKey {
        case graphicCorner, graphicCircular, graphicRectangle
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        graphicCorner = try container.decode(String.self, forKey: .graphicCorner)
        graphicCircular = try container.decode(String.self, forKey: .graphicCircular)
        graphicRectangle = try container.decode(String.self, forKey: .graphicRectangle)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(graphicCorner, forKey: .graphicCorner)
        try container.encode(graphicCircular, forKey: .graphicCircular)
        try container.encode(graphicRectangle, forKey: .graphicRectangle)
    }
        
    // MARK: - Save to fileURL
    // Persist timeline data to the specified fileURL.
    // Callers should make sure the intermediate directories exist.
    //
    func save(to fileURL: URL) {
        guard let data = try? JSONEncoder().encode(self) else { return }
        do {
            try data.write(to: fileURL)
        } catch let error {
            print("\(error)")
        }
    }
 
    // MARK: - Equatable
    //
    static func == (lhs: TemplateConfiguration, rhs: TemplateConfiguration) -> Bool {
        return lhs.graphicCorner == rhs.graphicCorner && lhs.graphicCircular == rhs.graphicCircular
            && lhs.graphicRectangle == rhs.graphicRectangle
    }
}
