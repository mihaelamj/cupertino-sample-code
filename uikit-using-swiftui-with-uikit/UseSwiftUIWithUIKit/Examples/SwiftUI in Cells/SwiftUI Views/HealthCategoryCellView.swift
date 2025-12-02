/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The SwiftUI view for the health category cell.
*/

import SwiftUI

struct HealthCategoryProperties {
    var name: String
    var systemImageName: String
    var color: Color
}

enum HealthCategory: CaseIterable {
    case activity
    case bodyMeasurement
    case hearing
    case heart
    
    var properties: HealthCategoryProperties {
        switch self {
        case .activity:
            return .init(name: "Activity", systemImageName: "flame.fill", color: .orange)
        case .bodyMeasurement:
            return .init(name: "Body Measurements", systemImageName: "figure.stand", color: .purple)
        case .hearing:
            return .init(name: "Hearing", systemImageName: "ear", color: .blue)
        case .heart:
            return .init(name: "Heart", systemImageName: "heart.fill", color: .pink)
        }
    }
}

struct HealthCategoryCellView: View {
    var healthCategory: HealthCategory
    private var properties: HealthCategoryProperties {
        healthCategory.properties
    }
    
    var body: some View {
        HStack {
            Label(properties.name, systemImage: properties.systemImageName)
                .foregroundStyle(properties.color)
                .font(.system(.headline, weight: .bold))
            Spacer()
        }
    }
}

struct HealthCategoryCellView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            HealthCategoryCellView(healthCategory: .activity)
            HealthCategoryCellView(healthCategory: .bodyMeasurement)
            HealthCategoryCellView(healthCategory: .hearing)
            HealthCategoryCellView(healthCategory: .heart)
        }
    }
}
