/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The new backyard form.
*/

import SwiftUI
import SwiftData
import BackyardBirdsData
import LayeredArtworkLibrary

public struct NewBackyardForm: View {
    @Query(sort: [.init(\.name, comparator: .localizedStandard)])
    private var birdFood: [BirdFood]
    
    @Query(sort: \.creationDate)
    private var plants: [Plant]
    
    @State private var name = ""
    @State private var selectedBirdFood: BirdFood?
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    public init() {
        
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                nameSection
                foodSection
                plantSection
            }
            .navigationTitle(Text("New Backyard", bundle: .module))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        guard let food = selectedBirdFood, name.isEmpty == false else {
                            return
                        }
                        let backyard = Backyard(name: name)
                        modelContext.insert(backyard)
                        backyard.birdFood = food
                        dismiss()
                    } label: {
                        Text("Create", bundle: .module)
                    }
                    .disabled(name.isEmpty || selectedBirdFood == nil)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel", bundle: .module)
                    }
                }
            }
        }
        .onAppear {
            selectedBirdFood = birdFood.first
        }
    }
    
    var nameSection: some View {
        Section {
            TextField(text: $name, prompt: Text("My Backyard", bundle: .module,
                                                comment: "Placeholder on the text field for the name of a new backyard")) {
                Text("Name", bundle: .module)
            }
        } header: {
            Text("Name", bundle: .module)
        }
    }
    
    var foodSection: some View {
        Section {
            HStack {
                if let food = selectedBirdFood {
                    food.image
                        .scaledToFit()
                        .padding(6)
                        .frame(width: 44, height: 44)
                        .background(.fill)
                        .clipShape(.circle)
                
                    Text(food.name)
                    Spacer()
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Food", bundle: .module)
        }
    }
    
    var plantSection: some View {
        Section {
            ForEach(plants.prefix(10)) { plant in
                HStack {
                    ComposedPlant(plant: plant)
                        .frame(width: 44, height: 44)
                        .background(.fill)
                        .clipShape(.circle)
                    
                    Text(plant.speciesName)
                    Spacer()
                    Toggle(isOn: .constant(false), label: { Text("Use Plant", bundle: .module) })
                        .labelsHidden()
                }
            }
        } header: {
            Text("Plants", bundle: .module)
        }
    }
}

#Preview {
    NewBackyardForm()
}
