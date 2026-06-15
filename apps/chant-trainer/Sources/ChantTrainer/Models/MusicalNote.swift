import Foundation

enum NoteName: String, CaseIterable, Codable {
    case C, Cs, D, Ds, E, F, Fs, G, Gs, A, As, B

    var displayName: String {
        switch self {
        case .C:  return "C"
        case .Cs: return "C#"
        case .D:  return "D"
        case .Ds: return "D#"
        case .E:  return "E"
        case .F:  return "F"
        case .Fs: return "F#"
        case .G:  return "G"
        case .Gs: return "G#"
        case .A:  return "A"
        case .As: return "A#"
        case .B:  return "B"
        }
    }

    var chromaticIndex: Int {
        switch self {
        case .C:  return 0
        case .Cs: return 1
        case .D:  return 2
        case .Ds: return 3
        case .E:  return 4
        case .F:  return 5
        case .Fs: return 6
        case .G:  return 7
        case .Gs: return 8
        case .A:  return 9
        case .As: return 10
        case .B:  return 11
        }
    }

    var solfege: String {
        switch self {
        case .C:  return "Do"
        case .D:  return "Re"
        case .E:  return "Mi"
        case .F:  return "Fa"
        case .G:  return "Sol"
        case .A:  return "La"
        case .B:  return "Si"
        default:  return displayName
        }
    }

    static func fromIndex(_ index: Int) -> NoteName {
        let i = ((index % 12) + 12) % 12
        return allCases.first { $0.chromaticIndex == i } ?? .C
    }
}

struct MusicalNote: Hashable, Codable, Identifiable {
    let name: NoteName
    let octave: Int

    var id: String { "\(name.rawValue)\(octave)" }

    var midiNumber: Int {
        (octave + 1) * 12 + name.chromaticIndex
    }

    var frequency: Double {
        FrequencyToNote.midiToHz(midiNumber)
    }

    var displayLabel: String {
        "\(name.displayName)\(octave)"
    }

    static func fromMidi(_ midi: Int) -> MusicalNote {
        let octave = midi / 12 - 1
        let noteIndex = ((midi % 12) + 12) % 12
        return MusicalNote(name: NoteName.fromIndex(noteIndex), octave: octave)
    }

    static func fromFrequency(_ hz: Double) -> (note: MusicalNote, centsOff: Double)? {
        guard let result = FrequencyToNote.convert(frequency: hz) else { return nil }
        let nameIndex = FrequencyToNote.noteNames.firstIndex(of: result.noteName) ?? 0
        let note = MusicalNote(name: NoteName.fromIndex(nameIndex), octave: result.octave)
        return (note, result.cents)
    }

    // Common reference notes
    static let A2 = MusicalNote(name: .A, octave: 2)
    static let C3 = MusicalNote(name: .C, octave: 3)
    static let D3 = MusicalNote(name: .D, octave: 3)
    static let G3 = MusicalNote(name: .G, octave: 3)
    static let A3 = MusicalNote(name: .A, octave: 3)
    static let B3 = MusicalNote(name: .B, octave: 3)
    static let C4 = MusicalNote(name: .C, octave: 4)
    static let D4 = MusicalNote(name: .D, octave: 4)
    static let E4 = MusicalNote(name: .E, octave: 4)
    static let F4 = MusicalNote(name: .F, octave: 4)
    static let G4 = MusicalNote(name: .G, octave: 4)
    static let A4 = MusicalNote(name: .A, octave: 4)
    static let B4 = MusicalNote(name: .B, octave: 4)
    static let C5 = MusicalNote(name: .C, octave: 5)
}
