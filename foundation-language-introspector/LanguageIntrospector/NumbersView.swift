/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view for numbers.
*/

import SwiftUI

struct NumbersView: View {
    @State private var model = NumbersModel()
    
    var body: some View {
        ScrollView {
            VStack {
                HeaderImage(name: "textformat.123")
                
                VStack {
                    Text(model.localizedNumber)
                        .font(.title2)
                        .padding(.top, 10)
                    
                    Picker("", selection: $model.numberStyle) {
                        Text("प्रतिशत", comment: "Percent").tag(NumberFormatter.Style.percent)
                        Text("क्रमसूचक", comment: "Ordinal").tag(NumberFormatter.Style.ordinal)
                        Text("सांख्यिक", comment: "Decimal").tag(NumberFormatter.Style.decimal)
                        Text("वैज्ञानिक", comment: "Scientific").tag(NumberFormatter.Style.scientific)
                        Text("शाब्दिक", comment: "Spell Out").tag(NumberFormatter.Style.spellOut)
                        Text("मुद्रा", comment: "Currency").tag(NumberFormatter.Style.currency)
                        Text("मुद्रा – शाब्दिक", comment: "Currency – Spell Out").tag(NumberFormatter.Style.currencyPlural)
                        Text("मुद्रा – हिसाब किताब", comment: "Currency – Accounting").tag(NumberFormatter.Style.currencyAccounting)
                        Text("मुद्रा – ISO कोड", comment: "Currency – ISO Code").tag(NumberFormatter.Style.currencyISOCode)
                    }
                    
                    HStack {
                        Text("पूर्ण व दशमलव अंक", comment: "Integer & Fractional Digits")
                            .subheadlineTextFormat()
                        Spacer()
                    }
                    Stepper(value: $model.minimumIntegerDigits) {
                        Text("कम से कम \(model.minimumIntegerDigits) पूर्ण अंक", comment: "At least N integer digits")
                    }
                    Stepper(value: $model.maximumIntegerDigits) {
                        Text("ज़्यादा से ज़्यादा \(model.maximumIntegerDigits) पूर्ण अंक", comment: "At most N integer digits")
                    }
                    Stepper(value: $model.minimumFractionDigits) {
                        Text("कम से कम \(model.minimumFractionDigits) दशमलव अंक", comment: "At least N fractional digits")
                    }
                    Stepper(value: $model.maximumFractionDigits) {
                        Text("ज़्यादा से ज़्यादा \(model.maximumFractionDigits) दशमलव अंक", comment: "At most N fractional digits")
                    }
                    
                    HStack {
                        Text("राउंडिंग मोड", comment: "Rounding Mode")
                            .subheadlineTextFormat()
                        Spacer()
                    }
                    
                    Picker("", selection: $model.roundingMode) {
                        Image(systemName: "equal.circle").tag(NumberFormatter.RoundingMode.halfEven)
                        Image(systemName: "circle.bottomhalf.fill").tag(NumberFormatter.RoundingMode.halfDown)
                        Image(systemName: "circle.tophalf.fill").tag(NumberFormatter.RoundingMode.halfUp)
                        Image(systemName: "arrow.up.to.line").tag(NumberFormatter.RoundingMode.ceiling)
                        Image(systemName: "arrow.down.to.line").tag(NumberFormatter.RoundingMode.floor)
                        Image(systemName: "arrow.up").tag(NumberFormatter.RoundingMode.up)
                        Image(systemName: "arrow.down").tag(NumberFormatter.RoundingMode.down)
                    }
                    .pickerStyle(.segmented)
                }
                .opaqueBackground()
                Spacer()
            }
        }
    }
}
