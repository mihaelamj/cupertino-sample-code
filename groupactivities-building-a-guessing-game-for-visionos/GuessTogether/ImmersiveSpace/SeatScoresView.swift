/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The implementation for the seat scores view.
*/

import SwiftUI
import RealityKit
import Spatial

/// A reality view that positions a 3D representation of each participant's score
/// in front of their spatial template seat.
struct SeatScoresView: View {
    @Environment(AppModel.self) var appModel
    
    var body: some View {
        RealityView { _ in
            
        } update: { content in
            for player in players {
                guard let pose = player.seatPose else { continue }
                
                // Find each player's scoreboard.
                let resolvedEntity: Entity
                if let entity = content.entities.first(where: { $0.name == player.scoreEntityName }) {
                    resolvedEntity = entity
                } else {
                    guard let team = player.team else { continue }
                    
                    let color = player.isPlaying ? .green : team.color
                    resolvedEntity = scoreEntity(for: player.score, with: color)
                    resolvedEntity.name = player.scoreEntityName
                    content.add(resolvedEntity)
                }
                
                // Orient the scoreboard position for each player.
                resolvedEntity.position = SIMD3<Float>(pose.scorePosition)
                resolvedEntity.orientation = simd_quatf(pose.rotation)
            }

            content.entities.removeAll { entity in
                return !players.contains(where: { $0.scoreEntityName == entity.name && $0.seatPose != nil })
            }
        }
        .frame(depth: 0)
    }
    
    var players: any Sequence<PlayerModel> {
        return appModel.sessionController?.players.values.filter { $0.team != nil } ?? []
    }

    /// Generates the player's scoreboard entity.
    ///
    /// - Parameters:
    ///     - score: The current player score.
    ///     - color: A color for the player's score text, which typically is the same as their team's color.
    func scoreEntity(for score: Int, with color: Color) -> ModelEntity {
        let text = MeshResource.generateText(
            score.description,
            extrusionDepth: 0.02,
            font: .monospacedSystemFont(ofSize: 0.28, weight: .regular),
            containerFrame: CGRect(x: 0, y: 0, width: 1, height: 0.5),
            alignment: .center
        )

        return ModelEntity(
            mesh: text,
            materials: [SimpleMaterial(color: UIColor(color), isMetallic: false)]
        )
    }
}

private extension Pose3D {
    var scorePosition: Point3D {
        let transform = ProjectiveTransform3D(matrix)
        let forward = (transform * .forward).normalized * 0.65
        let right = (transform * .right).normalized * 0.5
        return position + forward - right
    }
}

private extension PlayerModel {
    var scoreEntityName: String {
        "\(id)-\(score)-\(isPlaying)"
    }
}
