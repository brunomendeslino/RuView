import SwiftUI

struct ChordDeconstructionView: View {
    let chord: Chord
    @Binding var isReady: Bool
    var synth: AudioSynthesizer
    @State private var hasAutoPlayed = false

    var body: some View {
        VStack(spacing: CT.largeSpacing) {
            // Header
            VStack(spacing: CT.smallSpacing) {
                Text(chord.displayName)
                    .font(.largeTitle).bold()
                    .foregroundStyle(.primary)

                Text(chord.type.displayName)
                    .font(.caption).bold()
                    .padding(.horizontal, CT.smallSpacing)
                    .padding(.vertical, 4)
                    .background(chord.type == .major ? Color.green.opacity(0.3) :
                                chord.type == .minor ? Color.blue.opacity(0.3) :
                                chord.type == .diminished ? Color.red.opacity(0.3) :
                                Color.purple.opacity(0.3))
                    .clipShape(Rectangle())
                    .overlay(Rectangle().stroke(Color.primary.opacity(0.2), lineWidth: 1))
            }

            // Individual note pills
            HStack(spacing: CT.spacing) {
                ForEach(Array(chord.notes.enumerated()), id: \.offset) { index, note in
                    NotePillView(
                        note: note,
                        isHighlighted: synth.playingNoteIndex == index,
                        onPlay: {
                            Task { await synth.play(note: note, duration: 1.2) }
                        }
                    )
                }
            }

            Divider().background(Color.primary.opacity(0.1))

            // Playback buttons
            VStack(spacing: CT.smallSpacing) {
                Button {
                    Task { await synth.playChord(chord, duration: 2.0) }
                } label: {
                    Label("Play Full Chord", systemImage: "play.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
                .disabled(synth.isPlaying)

                Button {
                    Task { await synth.arpeggiate(chord, noteDuration: 1.0) }
                } label: {
                    Label("Play Each Note", systemImage: "play.square.stack")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(GlassButtonStyle())
                .disabled(synth.isPlaying)
            }

            Text("Listen carefully, then sing each note when ready")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                isReady = true
            } label: {
                Label("I'm Ready — Start Singing", systemImage: "mic.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(ProminentGlassButtonStyle())
        }
        .padding(CT.largeSpacing)
        .glassSurface()
        .task {
            guard !hasAutoPlayed else { return }
            hasAutoPlayed = true
            try? await Task.sleep(nanoseconds: 500_000_000)
            await synth.playChord(chord, duration: 2.0)
            try? await Task.sleep(nanoseconds: 500_000_000)
            await synth.arpeggiate(chord, noteDuration: 1.0)
        }
    }
}

private struct NotePillView: View {
    let note: MusicalNote
    let isHighlighted: Bool
    let onPlay: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            Text(note.name.displayName)
                .font(.title2).bold()
            Text("\(note.octave)")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Button(action: onPlay) {
                Image(systemName: "play.fill")
                    .font(.caption)
            }
            .buttonStyle(GlassButtonStyle())
        }
        .padding(CT.smallSpacing)
        .frame(minWidth: 60)
        .background(isHighlighted ? Color.accentColor.opacity(0.3) : Color.clear)
        .glassCard()
        .animation(.easeInOut(duration: 0.15), value: isHighlighted)
    }
}
