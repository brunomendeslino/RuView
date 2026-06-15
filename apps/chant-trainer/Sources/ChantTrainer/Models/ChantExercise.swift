import SwiftUI

enum ExerciseMode: String, Codable {
    case sustainNote
    case mimicNote
    case mimicChord
}

enum Difficulty: Int, Codable, CaseIterable, Comparable {
    case beginner     = 1
    case novice       = 2
    case intermediate = 3
    case advanced     = 4
    case master       = 5

    static func < (lhs: Difficulty, rhs: Difficulty) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var displayName: String {
        switch self {
        case .beginner:     return "Beginner"
        case .novice:       return "Novice"
        case .intermediate: return "Intermediate"
        case .advanced:     return "Advanced"
        case .master:       return "Master"
        }
    }

    var color: Color {
        switch self {
        case .beginner:     return .green
        case .novice:       return .blue
        case .intermediate: return .orange
        case .advanced:     return .red
        case .master:       return .purple
        }
    }
}

struct NoteTarget: Codable {
    let note: MusicalNote
    let durationBeats: Double
    let toleranceCents: Double

    init(note: MusicalNote, durationBeats: Double = 3.0, toleranceCents: Double = 30.0) {
        self.note = note
        self.durationBeats = durationBeats
        self.toleranceCents = toleranceCents
    }
}

struct ChantExercise: Identifiable, Codable {
    let id: String
    let title: String
    let subtitle: String
    let difficulty: Difficulty
    let mode: ExerciseMode
    let targets: [NoteTarget]
    let chord: Chord?
    let unlockXP: Int

    var totalDurationSeconds: Double {
        targets.reduce(0) { $0 + $1.durationBeats }
    }

    init(
        id: String,
        title: String,
        subtitle: String,
        difficulty: Difficulty,
        mode: ExerciseMode,
        targets: [NoteTarget],
        chord: Chord? = nil,
        unlockXP: Int = 0
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.difficulty = difficulty
        self.mode = mode
        self.targets = targets
        self.chord = chord
        self.unlockXP = unlockXP
    }
}
