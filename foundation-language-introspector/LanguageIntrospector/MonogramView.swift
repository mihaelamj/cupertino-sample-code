/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The monogram view.
*/

import SwiftUI

struct MonogramView: View {
    let nameComponents: PersonNameComponents
    let color: Color
    let sideLength: CGFloat
    
    private var abbreviatedName: String {
        PersonNameComponentsFormatter.localizedString(from: nameComponents, style: .abbreviated)
    }
    
    var body: some View {
        Group {
            ZStack {
                Circle()
                    .stroke(color, lineWidth: sideLength * 0.1)
                Text(abbreviatedName)
                    .foregroundStyle(color)
                    .padding(.all, sideLength * 0.1)
                    .minimumScaleFactor(0.1)
                    .scaledToFit()
                    .font(.system(size: 200, weight: .bold, design: .rounded))
                    
            }
            .frame(width: sideLength, height: sideLength)
        }
    }
}

#Preview {
    let name = PersonNameComponents(familyName: "मिश्र", givenName: "करन")
    
    MonogramView(nameComponents: name, color: .orange, sideLength: 75)
            .padding(.bottom, 20)
        
    MonogramView(nameComponents: name, color: .blue, sideLength: 100)
            .padding(.bottom, 20)
    MonogramView(nameComponents: name, color: .pink, sideLength: 250)
}
