/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
View that controls the presentation of the playback UI controls, such as play/pause buttons,
 playback times, and a List that manages the items in the playlist.
*/

import SwiftUI
import AVKit
import MediaPlayer

struct ContentView: View {
    // The sample buffer player.
    @State private var sampleBufferPlayer = SampleBufferPlayer()
    
    // 'active' when the playlist is being edited.
    @State private var editMode = EditMode.inactive
    
    var body: some View {
        VStack {
            VStack {
                Text(sampleBufferPlayer.currentItem?.title ?? " ")
                    .font(.title)
                Text(sampleBufferPlayer.currentItem?.artist ?? " ")
                    .fontWeight(.thin)
            }
            .padding()
            VStack {
                Slider(value: $sampleBufferPlayer.offset, in: 0...(sampleBufferPlayer.currentItem?.duration.seconds ?? 0)) { editing in
                    sampleBufferPlayer.isDraggingOffset = editing
                }
                .frame(height: 48)
                .disabled(sampleBufferPlayer.currentItem == nil)
                HStack {
                    Text(sampleBufferPlayer.getOffsetText())
                    Spacer()
                    Text(sampleBufferPlayer.renderingMode.stringValue)
                        .opacity(sampleBufferPlayer.renderingMode == .notApplicable ? 0 : 1)
                    Spacer()
                    Text(sampleBufferPlayer.getDurationText())
                }
            }
            .padding()
            HStack {
                transportButton(action: sampleBufferPlayer.previousTrack, label: "backward.end.alt")
                transportButton(action: sampleBufferPlayer.togglePlayPause, label: sampleBufferPlayer.isPlaying ? "pause" : "play")
                transportButton(action: sampleBufferPlayer.nextTrack, label: "forward.end.alt")
            }
            .padding()
            VStack {
                HStack {
                    Text("Volume")
                    Spacer()
                    Representable<AVRoutePickerView>()
                        .frame(width: 48, height: 48)
                }
                Representable<MPVolumeView>()
                    .frame(height: 48)
            }
            .padding()
            HStack {
                if editMode == .inactive {
                    Button("Rearrange Playlist") {
                        editMode = .active
                    }
                    Spacer()
                    Button("Restore Playlist") {
                        sampleBufferPlayer.restorePlaylist()
                    }
                } else {
                    Button("Done") {
                        editMode = .inactive
                    }
                }
            }
            .padding()
            NavigationStack {
                List(selection: $sampleBufferPlayer.currentItem) {
                    ForEach(sampleBufferPlayer.items, id: \.self) { item in
                        VStack(alignment: .leading) {
                            Text(item.title)
                            // Mark items that fail to load with an error icon.
                            Text(item.error != nil ? NSLocalizedString("[Error]", comment: "") : item.artist)
                                .font(.footnote)
                                .fontWeight(.thin)
                        }
                        .swipeActions(edge: .leading) {
                            // Duplicate the item in the list, placing the duplicated item at the end of the playlist.
                            Button("Duplicate") {
                                sampleBufferPlayer.insertItem(item.copy(), at: sampleBufferPlayer.itemCount)
                            }
                            .tint(.accentColor)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            sampleBufferPlayer.removeItem(at: index)
                        }
                    }
                    .onMove {
                        sampleBufferPlayer.moveItems(fromOffsets: $0, toOffset: $1)
                    }
                }
                .environment(\.editMode, $editMode)
                .animation(.default, value: editMode)
            }
        }
        .padding()
        .task {
            await sampleBufferPlayer.loadPlaylist()
        }
    }
    
    @ViewBuilder func transportButton(action: @escaping () -> Void, label: String) -> some View {
        Button {
            action()
        } label: {
            Image(systemName: label)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
        }
    }
}

fileprivate extension AVAudioSession.RenderingMode {
    var stringValue: String {
        switch self {
        case .notApplicable: return ""
        case .monoStereo:    return "Stereo"
        case .surround:      return "Surround"
        case .spatialAudio:  return "Spatial"
        case .dolbyAudio:    return "Dolby Audio"
        case .dolbyAtmos:    return "Dolby Atmos"
        default:             return "Unknown \(self)"
        }
    }
}

// A generic representable view.
struct Representable<T: UIView>: UIViewRepresentable {
    func makeUIView(context: Context) -> T { return T() }
    func updateUIView(_ uiView: T, context: Context) {}
}
