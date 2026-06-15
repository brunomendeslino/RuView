import Foundation

enum ChordType: String, CaseIterable, Codable {
    case major
    case minor
    case diminished
    case augmented
    case dominantSeventh = "dom7"
    case majorSeventh    = "maj7"
    case minorSeventh    = "min7"

    var intervals: [Int] {
        switch self {
        case .major:           return [0, 4, 7]
        case .minor:           return [0, 3, 7]
        case .diminished:      return [0, 3, 6]
        case .augmented:       return [0, 4, 8]
        case .dominantSeventh: return [0, 4, 7, 10]
        case .majorSeventh:    return [0, 4, 7, 11]
        case .minorSeventh:    return [0, 3, 7, 10]
        }
    }

    var displayName: String {
        switch self {
        case .major:           return "Major"
        case .minor:           return "Minor"
        case .diminished:      return "Diminished"
        case .augmented:       return "Augmented"
        case .dominantSeventh: return "Dom 7"
        case .majorSeventh:    return "Maj 7"
        case .minorSeventh:    return "Min 7"
        }
    }

    var shortName: String {
        switch self {
        case .major:           return ""
        case .minor:           return "m"
        case .diminished:      return "°"
        case .augmented:       return "+"
        case .dominantSeventh: return "7"
        case .majorSeventh:    return "M7"
        case .minorSeventh:    return "m7"
        }
    }
}

struct Chord: Identifiable, Codable, Hashable {
    let root: MusicalNote
    let type: ChordType

    var id: String { "\(root.name.rawValue)_\(type.rawValue)" }

    var notes: [MusicalNote] {
        type.intervals.map { semitones in
            MusicalNote.fromMidi(root.midiNumber + semitones)
        }
    }

    var displayName: String {
        let suffix = type.shortName.isEmpty ? type.displayName : type.shortName
        return "\(root.name.displayName) \(type.displayName)"
    }

    var shortDisplayName: String {
        "\(root.name.displayName)\(type.shortName)"
    }
}
