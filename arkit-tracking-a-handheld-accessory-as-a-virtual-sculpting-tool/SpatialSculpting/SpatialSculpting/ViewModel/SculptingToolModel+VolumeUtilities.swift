/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Handle loading and saving out to a document.
*/

@preconcurrency import Metal

extension SculptingToolModel {
    // Save a finished sculpture out as a VolumeDocument.
    @MainActor
    func save(onCompleted: @Sendable @escaping (VolumeDocument) -> Void) {
        guard var sculptingToolComponent = sculptingTool.components[SculptingToolComponent.self] else {
            return
        }

        let originalTexture = sculptingToolComponent.sculptor.marchingCubesMesh.voxelVolume.voxelTexture
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = originalTexture.textureType
        textureDescriptor.pixelFormat = originalTexture.pixelFormat
        textureDescriptor.width = originalTexture.width
        textureDescriptor.height = originalTexture.height
        textureDescriptor.depth = originalTexture.depth
        textureDescriptor.usage = []
        textureDescriptor.storageMode = .shared
        guard let destinationTexture = metalDevice?.makeTexture(descriptor: textureDescriptor) else {
            return
        }

        sculptingToolComponent.saveToTexture = (destinationTexture, {
            let document = try VolumeDocument(texture: destinationTexture)
            onCompleted(document)
        })
        sculptingTool.components.set(sculptingToolComponent)
    }

    // Load in a VolumeDocument in as an editable sculpture.
    func loadFromURL(_ url: URL) throws {
        guard var sculptingToolComponent = sculptingTool.components[SculptingToolComponent.self] else {
            return
        }

        let originalTexture = sculptingToolComponent.sculptor.marchingCubesMesh.voxelVolume.voxelTexture
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = originalTexture.textureType
        textureDescriptor.pixelFormat = originalTexture.pixelFormat
        textureDescriptor.width = originalTexture.width
        textureDescriptor.height = originalTexture.height
        textureDescriptor.depth = originalTexture.depth
        textureDescriptor.usage = []
        textureDescriptor.storageMode = .shared
        guard let sourceTexture = metalDevice?.makeTexture(descriptor: textureDescriptor) else {
            return
        }

        try VolumeDocument.loadFromURL(url, texture: sourceTexture)
        sculptingToolComponent.loadFromTexture = sourceTexture
        sculptingTool.components.set(sculptingToolComponent)
    }
}
