/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main view of the watch app, showing the complication family list.
*/

import SwiftUI
import ClockKit

struct ContentView: View {
    @EnvironmentObject var configuration: TemplateConfiguration
    @State var isConfiguratonDirty = false
        
    var body: some View {
        VStack {
            List {
                NavigationLink(destination: VariantListView(
                    variantList: GraphicRectangleVariant.allRawValues, selection: $configuration.graphicRectangle)) {
                        FamilyRowView(familyName: "Rectangle", variantName: configuration.graphicRectangle)
                }
                NavigationLink(destination: VariantListView(
                    variantList: GraphicCornerVariant.allRawValues, selection: $configuration.graphicCorner)) {
                        FamilyRowView(familyName: "Corner", variantName: configuration.graphicCorner)
                }
                NavigationLink(destination: VariantListView(
                    variantList: GraphicCircularVariant.allRawValues, selection: $configuration.graphicCircular)) {
                        FamilyRowView(familyName: "Circular", variantName: configuration.graphicCircular)
                }
            }
            Button(action: { self.refreshComplications() }) {
                Text("Apply").foregroundColor(isConfiguratonDirty ? .blue : .gray)
            }
            .padding(.bottom, 0)
            .disabled(!isConfiguratonDirty)
        }
        .navigationBarTitle(Text("Families"))
        .onAppear { self.isConfiguratonDirty = self.isConfigurationDirty() }
    }
}

extension ContentView {
    private func refreshComplications() {
        let delegate: ExtensionDelegate! = WKExtension.shared().delegate as? ExtensionDelegate
        delegate.templateConfiguration.save(to: delegate.templateConfigurationURL)

        let server = CLKComplicationServer.sharedInstance()
        if let complications = server.activeComplications {
            for complication in complications {
                server.reloadTimeline(for: complication)
            }
        }
        // Disable the button because the configuration is consistent with the persisted one now.
        isConfiguratonDirty = false
    }
    
    private func isConfigurationDirty() -> Bool {
        let delegate: ExtensionDelegate! = WKExtension.shared().delegate as? ExtensionDelegate
        
        if FileManager.default.fileExists(atPath: delegate.templateConfigurationURL.path),
            let persistedConfiguration = TemplateConfiguration(from: delegate.templateConfigurationURL) {
            return persistedConfiguration != configuration
        }
        return true
    }
}

private struct FamilyRowView: View {
    let familyName: String, variantName: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(familyName)
                .foregroundColor(.blue)
                .font(.headline)
            
            Text(variantName)
                .foregroundColor(.white)
                .font(.footnote)
        }.padding(4)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let delegate: ExtensionDelegate! = WKExtension.shared().delegate as? ExtensionDelegate
        return ContentView().environmentObject(delegate.templateConfiguration)
    }
}
