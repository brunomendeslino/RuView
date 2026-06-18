import Foundation

enum ChordLibrary {
    static let all: [Chord] = {
        var chords: [Chord] = []
        for noteName in NoteName.allCases {
            let root = MusicalNote(name: noteName, octave: 3)
            for type in ChordType.allCases {
                chords.append(Chord(root: root, type: type))
            }
        }
        return chords
    }()

    static func random() -> Chord {
        all.randomElement() ?? Chord(root: .C4, type: .major)
    }

    static func random(type: ChordType) -> Chord {
        chords(ofType: type).randomElement() ?? Chord(root: .C4, type: type)
    }

    static func chords(ofType type: ChordType) -> [Chord] {
        all.filter { $0.type == type }
    }

    static func chords(rootedAt noteName: NoteName) -> [Chord] {
        all.filter { $0.root.name == noteName }
    }
}
