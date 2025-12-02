/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A model that represents the canvas to draw on.
*/

import Foundation
import Combine
import SwiftUI
import GroupActivities

struct CanvasImage: Identifiable {
    var id: UUID
    let location: CGPoint
    let imageData: Data
}

@MainActor
class Canvas: ObservableObject {
    @Published var strokes = [Stroke]()
    @Published var activeStroke: Stroke?
    @Published var images = [CanvasImage]()
    @Published var selectedImageData: Data?
    let strokeColor = Stroke.Color.random

    var subscriptions = Set<AnyCancellable>()
    var tasks = Set<Task<Void, Never>>()

    func addPointToActiveStroke(_ point: CGPoint) {
        let stroke: Stroke
        if let activeStroke = activeStroke {
            stroke = activeStroke
        } else {
            stroke = Stroke(color: strokeColor)
            activeStroke = stroke
        }

        stroke.points.append(point)

        if let messenger = messenger {
            Task {
                try? await messenger.send(UpsertStrokeMessage(id: stroke.id, color: stroke.color, point: point))
            }
        }
    }

    func finishStroke() {
        guard let activeStroke = activeStroke else {
            return
        }

        strokes.append(activeStroke)
        self.activeStroke = nil
    }

    func finishImagePlacement(location: CGPoint) {
        guard let selectedImageData = selectedImageData, let journal = journal else {
            return
        }

        Task(priority: .userInitiated) {
            try await journal.add(selectedImageData, metadata: ImageMetadataMessage(location: location))
        }

        self.selectedImageData = nil
    }

    func reset() {
        // Clear the local drawing canvas.
        strokes = []
        images = []

        // Tear down the existing groupSession.
        messenger = nil
        journal = nil
        tasks.forEach { $0.cancel() }
        tasks = []
        subscriptions = []
        if groupSession != nil {
            groupSession?.leave()
            groupSession = nil
            self.startSharing()
        }
    }

    var pointCount: Int {
        return strokes.reduce(0) { $0 + $1.points.count }
    }

    @Published var groupSession: GroupSession<DrawTogether>?
    var messenger: GroupSessionMessenger?
    var journal: GroupSessionJournal?

    func startSharing() {
        Task {
            do {
                _ = try await DrawTogether().activate()
            } catch {
                print("Failed to activate DrawTogether activity: \(error)")
            }
        }
    }

    func configureGroupSession(_ groupSession: GroupSession<DrawTogether>) {
        strokes = []

        self.groupSession = groupSession
        let messenger = GroupSessionMessenger(session: groupSession)
        self.messenger = messenger
        let journal = GroupSessionJournal(session: groupSession)
        self.journal = journal

        groupSession.$state
            .sink { state in
                if case .invalidated = state {
                    self.groupSession = nil
                    self.reset()
                }
            }
            .store(in: &subscriptions)

        groupSession.$activeParticipants
            .sink { activeParticipants in
                let newParticipants = activeParticipants.subtracting(groupSession.activeParticipants)

                Task {
                    try? await messenger.send(CanvasMessage(strokes: self.strokes, pointCount: self.pointCount), to: .only(newParticipants))
                }
            }
            .store(in: &subscriptions)

        var task = Task {
            for await (message, _) in messenger.messages(of: UpsertStrokeMessage.self) {
                handle(message)
            }
        }
        tasks.insert(task)

        task = Task {
            for await (message, _) in messenger.messages(of: CanvasMessage.self) {
                handle(message)
            }
        }
        tasks.insert(task)

        task = Task {
            for await images in journal.attachments {
                await handle(images)
            }
        }
        tasks.insert(task)

        groupSession.join()
    }

    func handle(_ message: UpsertStrokeMessage) {
        if let stroke = strokes.first(where: { $0.id == message.id }) {
            stroke.points.append(message.point)
        } else {
            let stroke = Stroke(id: message.id, color: message.color)
            stroke.points.append(message.point)
            strokes.append(stroke)
        }
    }

    func handle(_ message: CanvasMessage) {
        guard message.pointCount > self.pointCount else { return }
        self.strokes = message.strokes
    }

    func handle(_ attachments: GroupSessionJournal.Attachments.Element) async {
        // Ensure that the canvas always has all the images from this sequence.
        self.images = await withTaskGroup(of: CanvasImage?.self) { group in
            var images = [CanvasImage]()

            attachments.forEach { attachment in
                group.addTask {
                    do {
                        let metadata = try await attachment.loadMetadata(of: ImageMetadataMessage.self)
                        let imageData = try await attachment.load(Data.self)
                        return .init(id: attachment.id, location: metadata.location, imageData: imageData)
                    } catch { return nil }
                }
            }

            for await image in group {
                if let image {
                    images.append(image)
                }
            }

            return images
        }
    }
}
