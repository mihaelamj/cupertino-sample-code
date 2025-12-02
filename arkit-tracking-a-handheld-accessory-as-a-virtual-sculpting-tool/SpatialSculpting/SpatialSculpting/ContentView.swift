/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The volume for sculpting and UI for controls.
*/

import SwiftUI
import ARKit
import RealityKit
import GameController
import CoreHaptics

struct ContentView: View {
    var root: Entity = Entity(components: [ComputeSystemComponent(computeSystem: SculptingToolSystem())])
    
    @State var sculpting: SculptingToolModel = SculptingToolModel()
    @State var haptics: HapticsModel = HapticsModel()
    
    let marchingCubesMesh: MarchingCubesMesh!
    let sculptor: MarchingCubesMeshSculptor!

    @State var saveDocument: VolumeDocument? = nil
    @State var isOpening = false
    @State var isSaving = false

    init() {
        let dimensions = SIMD3<UInt32>(128, 128, 128)
        let voxelSize = SIMD3<Float>(0.8, 0.8, 0.8) / SIMD3<Float>(dimensions)
        let voxelStartPosition = -SIMD3<Float>(dimensions) * voxelSize / 2
        
        guard let voxelVolume = try? VoxelVolume(dimensions: dimensions, voxelSize: voxelSize, voxelStartPosition: voxelStartPosition) else {
            self.marchingCubesMesh = nil
            self.sculptor = nil
            print("Failed to create volume.")
            return
        }
        
        self.marchingCubesMesh = try? MarchingCubesMesh(voxelVolume: voxelVolume)
        self.sculptor = MarchingCubesMeshSculptor(marchingCubesMesh: marchingCubesMesh)
    }
    
    func createMeshChunkEntity(meshChunk: MarchingCubesMeshChunk) throws -> Entity {
        let mesh = try MeshResource(from: meshChunk.mesh)
        let meshChunkEntity = Entity()
        meshChunkEntity.components.set(ModelComponent(mesh: mesh, materials: [SimpleMaterial(color: #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1), roughness: 0.8, isMetallic: false)]))
        return meshChunkEntity
    }

    func sculptingVolume() -> some View {
        RealityView { content, attachments in
            // Create an entity to render each mesh chunk.
            if let meshChunks = marchingCubesMesh?.meshChunks {
                for meshChunk in meshChunks {
                    if let meshChunkEntity = try? createMeshChunkEntity(meshChunk: meshChunk) {
                        root.addChild(meshChunkEntity)
                    }
                }
            }
            
            sculpting.sculptingTool.components.set(SculptingToolComponent(sculptor: sculptor))
            
            root.addChild(sculpting.sculptingTool)
            
            content.add(root)
            sculpting.rootEntity = root
            
            // Update sculpting tool and check for tracking quality each frame.
            _ = content.subscribe(to: SceneEvents.Update.self) {
                _ in
                sculpting.updateSculptingTool()
            }
            
            if let additiveAttachment = attachments.entity(for: "Additive") {
                sculpting.addEntityAttachmentToRoot(entity: additiveAttachment, name: "AdditiveIcon")
                sculpting.additiveIcon = additiveAttachment
            }
            
            if let subtractiveAttachment = attachments.entity(for: "Subtractive") {
                sculpting.addEntityAttachmentToRoot(entity: subtractiveAttachment, name: "SubtractiveIcon")
                sculpting.subtractiveIcon = subtractiveAttachment
            }
            
            if let enlargeAttachment = attachments.entity(for: "Enlarge") {
                sculpting.addEntityAttachmentToRoot(entity: enlargeAttachment, name: "EnlargeIcon")
                sculpting.enlargeIcon = enlargeAttachment
            }
            
            if let reduceAttachment = attachments.entity(for: "Reduce") {
                sculpting.addEntityAttachmentToRoot(entity: reduceAttachment, name: "ReduceIcon")
                sculpting.reduceIcon = reduceAttachment
            }

            // Iterate over all the currently connected supported spatial accessories.
            // Also, handle notifications of incoming connections.
            await sculpting.handleGameControllerSetup(hapticsModel: haptics)
        } attachments: {
            Attachment(id: "Additive") {
                ToolbarElement(name: "Add")
            }
            
            Attachment(id: "Subtractive") {
                ToolbarElement(name: "Subtract")
            }
            
            Attachment(id: "Enlarge") {
                ToolbarElement(name: "Enlarge")
            }
            
            Attachment(id: "Reduce") {
                ToolbarElement(name: "Reduce")
            }
        }.task {
            // Get transforms of accessories in the app process.
            let configuration = SpatialTrackingSession.Configuration(tracking: [.accessory])
            let session = SpatialTrackingSession()
            await session.run(configuration)
        }
    }

    func saveButton() -> some View {
        Button {
            sculpting.save { document in
                Task { @MainActor in
                    self.saveDocument = document
                    self.isSaving = true
                }
            }
        } label: {
            Text("Save")
        }
        .fileExporter(isPresented: $isSaving,
                      document: saveDocument) { result in
            switch result {
            case .success(let url):
                print("Saved to \(url)")
            case .failure(let error):
                print("Error saving: \(error)")
            }
            isSaving = false
            saveDocument = nil
        } onCancellation: {
            isSaving = false
            saveDocument = nil
        }
    }

    func openButton() -> some View {
        Button {
            isOpening = true
        } label: {
            Text("Open")
        }
        .fileImporter(isPresented: $isOpening, allowedContentTypes: [VolumeDocument.utType], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let success):
                do {
                    let url = success[0].absoluteURL
                    try sculpting.loadFromURL(url)
                } catch {
                    print("Failed to open document: \(error)")
                }
            case .failure(let error):
                print("Error opening: \(error)")
            }
            isOpening = false
        } onCancellation: {
            isOpening = false
        }
    }

    func clearButton() -> some View {
        Button {
            sculpting.sculptingTool.components[SculptingToolComponent.self]?.clear = true
        } label: {
            Text("Clear")
        }
    }
    
    func resetButton() -> some View {
        Button {
            sculpting.sculptingTool.components[SculptingToolComponent.self]?.reset = true
        } label: {
            Text("Reset")
        }
    }

    var body: some View {
        ZStack {
            sculptingVolume()
                .ornament(attachmentAnchor: .scene(.bottomFront)) {
                    HStack {
                        saveButton()
                        openButton()
                        clearButton()
                        resetButton()
                    }.padding().glassBackgroundEffect()
                }
        }
    }
}
