import SwiftUI

struct RandomChordView: View {
    var progress: GameProgress
    @State private var currentChord: Chord = ChordLibrary.random()
    @State private var filterType: ChordType? = nil
    @State private var synth = AudioSynthesizer()
    @State private var pitchDetector = AudioPitchDetector()
    @State private var navigateToExercise: ChantExercise? = nil
    @State private var isReady: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(white: 0.05), Color(white: 0.12)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: CT.largeSpacing) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: CT.smallSpacing) {
                                FilterChip(label: "Any", isSelected: filterType == nil) {
                                    filterType = nil; newChord()
                                }
                                ForEach(ChordType.allCases, id: \.self) { type in
                                    FilterChip(label: type.displayName, isSelected: filterType == type) {
                                        filterType = type; newChord()
                                    }
                                }
                            }
                            .padding(.horizontal, CT.largeSpacing)
                        }

                        VStack(spacing: CT.spacing) {
                            HStack {
                                Image(systemName: "shuffle").foregroundStyle(.secondary)
                                Text("Random Chord Challenge").font(.subheadline).foregroundStyle(.secondary)
                            }
                            Text(currentChord.displayName)
                                .font(.system(size: 56, weight: .black))
                                .foregroundStyle(.primary)
                            Text(currentChord.type.displayName)
                                .font(.subheadline.bold())
                                .padding(.horizontal, CT.smallSpacing).padding(.vertical, 4)
                                .glassCard()
                            HStack(spacing: CT.smallSpacing) {
                                ForEach(Array(currentChord.notes.enumerated()), id: \.offset) { index, note in
                                    VStack(spacing: 2) {
                                        Text(note.name.displayName).font(.headline.bold())
                                        Text("\(note.octave)").font(.caption2).foregroundStyle(.secondary)
                                    }
                                    .padding(CT.smallSpacing)
                                    .frame(minWidth: 50)
                                    .background(synth.playingNoteIndex == index ? Color.accentColor.opacity(0.3) : Color.clear)
                                    .glassCard()
                                    .animation(.easeInOut(duration: 0.15), value: synth.playingNoteIndex)
                                }
                            }
                        }
                        .padding(CT.largeSpacing)
                        .glassSurface()
                        .padding(.horizontal, CT.largeSpacing)

                        VStack(spacing: CT.smallSpacing) {
                            HStack(spacing: CT.smallSpacing) {
                                Button { Task { await synth.playChord(currentChord, duration: 2.0) } } label: {
                                    Label("Chord", systemImage: "play.circle.fill").frame(maxWidth: .infinity)
                                }
                                .buttonStyle(GlassButtonStyle()).disabled(synth.isPlaying)
                                Button { Task { await synth.arpeggiate(currentChord, noteDuration: 1.0) } } label: {
                                    Label("Notes", systemImage: "play.square.stack").frame(maxWidth: .infinity)
                                }
                                .buttonStyle(GlassButtonStyle()).disabled(synth.isPlaying)
                            }
                            Button { newChord() } label: {
                                Label("New Chord", systemImage: "shuffle").frame(maxWidth: .infinity)
                            }
                            .buttonStyle(GlassButtonStyle()).disabled(synth.isPlaying)
                        }
                        .padding(.horizontal, CT.largeSpacing)

                        Button { navigateToExercise = buildExercise() } label: {
                            Label("Start Challenge", systemImage: "mic.fill")
                                .font(.headline).foregroundStyle(.white)
                                .frame(maxWidth: .infinity).padding(.horizontal, CT.largeSpacing)
                        }
                        .buttonStyle(ProminentGlassButtonStyle())
                        .padding(.horizontal, CT.largeSpacing)
                    }
                    .padding(.vertical, CT.largeSpacing)
                }
            }
            .navigationTitle("Random Chord")
            .navigationDestination(item: $navigateToExercise) { exercise in
                ExerciseView(exercise: exercise, progress: progress, pitchDetector: pitchDetector)
            }
        }
    }

    private func newChord() {
        currentChord = filterType.map { ChordLibrary.random(type: $0) } ?? ChordLibrary.random()
        isReady = false
    }

    private func buildExercise() -> ChantExercise {
        ChantExercise(
            id: "random_\(currentChord.id)",
            title: "\(currentChord.displayName) Challenge",
            subtitle: "Hear and mimic \(currentChord.displayName)",
            difficulty: .intermediate, mode: .mimicChord,
            targets: currentChord.notes.map { NoteTarget(note: $0, durationBeats: 3.0) },
            chord: currentChord, unlockXP: 0
        )
    }
}

private struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label).font(.caption.bold())
                .padding(.horizontal, CT.smallSpacing).padding(.vertical, 4)
                .background(isSelected ? Color.accentColor : Color.clear)
                .clipShape(Rectangle())
                .overlay(Rectangle().stroke(isSelected ? Color.clear : Color.primary.opacity(0.2), lineWidth: 1))
        }
        .foregroundStyle(isSelected ? .white : .primary)
    }
}
