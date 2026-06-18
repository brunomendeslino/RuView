import Foundation

enum ExerciseLibrary {
    static let all: [ChantExercise] = beginnerExercises + noviceExercises
        + intermediateExercises + advancedExercises + masterExercises

    static func exercises(for difficulty: Difficulty) -> [ChantExercise] {
        all.filter { $0.difficulty == difficulty }
    }

    static func unlocked(xp: Int, completedIDs: Set<String>) -> [ChantExercise] {
        all.filter { $0.unlockXP <= xp }
    }

    static func next(after id: String) -> ChantExercise? {
        guard let idx = all.firstIndex(where: { $0.id == id }), idx + 1 < all.count else { return nil }
        return all[idx + 1]
    }

    private static let beginnerExercises: [ChantExercise] = [
        ChantExercise(id: "beg_001", title: "Hold A", subtitle: "Sustain A3 for 3 beats",
            difficulty: .beginner, mode: .sustainNote,
            targets: [NoteTarget(note: .A3, durationBeats: 3)], unlockXP: 0),
        ChantExercise(id: "beg_002", title: "Hold D", subtitle: "Sustain D4 for 3 beats",
            difficulty: .beginner, mode: .sustainNote,
            targets: [NoteTarget(note: .D4, durationBeats: 3)], unlockXP: 0),
        ChantExercise(id: "beg_003", title: "Hold G", subtitle: "Sustain G3 for 3 beats",
            difficulty: .beginner, mode: .sustainNote,
            targets: [NoteTarget(note: .G3, durationBeats: 3)], unlockXP: 10),
        ChantExercise(id: "beg_004", title: "Hold E", subtitle: "Sustain E4 for 3 beats",
            difficulty: .beginner, mode: .sustainNote,
            targets: [NoteTarget(note: .E4, durationBeats: 3)], unlockXP: 20),
        ChantExercise(id: "beg_005", title: "Listen: A", subtitle: "Hear and repeat A3",
            difficulty: .beginner, mode: .mimicNote,
            targets: [NoteTarget(note: .A3, durationBeats: 3)], unlockXP: 30),
        ChantExercise(id: "beg_006", title: "Listen: D", subtitle: "Hear and repeat D4",
            difficulty: .beginner, mode: .mimicNote,
            targets: [NoteTarget(note: .D4, durationBeats: 3)], unlockXP: 40),
    ]

    private static let noviceExercises: [ChantExercise] = [
        ChantExercise(id: "nov_001", title: "Do–Re", subtitle: "Sing C4 then D4",
            difficulty: .novice, mode: .sustainNote,
            targets: [NoteTarget(note: .C4, durationBeats: 2), NoteTarget(note: .D4, durationBeats: 2)], unlockXP: 60),
        ChantExercise(id: "nov_002", title: "Do–Re–Mi", subtitle: "Sing C4, D4, E4",
            difficulty: .novice, mode: .sustainNote,
            targets: [NoteTarget(note: .C4), NoteTarget(note: .D4), NoteTarget(note: .E4)], unlockXP: 80),
        ChantExercise(id: "nov_003", title: "Mi–Re–Do", subtitle: "Descending E4, D4, C4",
            difficulty: .novice, mode: .sustainNote,
            targets: [NoteTarget(note: .E4), NoteTarget(note: .D4), NoteTarget(note: .C4)], unlockXP: 100),
        ChantExercise(id: "nov_004", title: "C Major Chord", subtitle: "Listen to C Major, then sing each note",
            difficulty: .novice, mode: .mimicChord,
            targets: Chord(root: .C4, type: .major).notes.map { NoteTarget(note: $0) },
            chord: Chord(root: .C4, type: .major), unlockXP: 120),
        ChantExercise(id: "nov_005", title: "G Major Chord", subtitle: "Hear G Major and repeat each note",
            difficulty: .novice, mode: .mimicChord,
            targets: Chord(root: MusicalNote(name: .G, octave: 3), type: .major).notes.map { NoteTarget(note: $0) },
            chord: Chord(root: MusicalNote(name: .G, octave: 3), type: .major), unlockXP: 140),
        ChantExercise(id: "nov_006", title: "F Major Chord", subtitle: "Hear F Major and repeat each note",
            difficulty: .novice, mode: .mimicChord,
            targets: Chord(root: MusicalNote(name: .F, octave: 3), type: .major).notes.map { NoteTarget(note: $0) },
            chord: Chord(root: MusicalNote(name: .F, octave: 3), type: .major), unlockXP: 160),
    ]

    private static let intermediateExercises: [ChantExercise] = [
        ChantExercise(id: "int_001", title: "Do to Sol", subtitle: "C4 D4 E4 F4 G4 ascending",
            difficulty: .intermediate, mode: .sustainNote,
            targets: [.C4, .D4, .E4, .F4, .G4].map { NoteTarget(note: $0, durationBeats: 2) }, unlockXP: 200),
        ChantExercise(id: "int_002", title: "Recto Tono", subtitle: "Hold C4 for 8 beats — breath control",
            difficulty: .intermediate, mode: .sustainNote,
            targets: [NoteTarget(note: .C4, durationBeats: 8)], unlockXP: 230),
        ChantExercise(id: "int_003", title: "A Minor Chord", subtitle: "Listen then sing A Minor notes",
            difficulty: .intermediate, mode: .mimicChord,
            targets: Chord(root: .A3, type: .minor).notes.map { NoteTarget(note: $0) },
            chord: Chord(root: .A3, type: .minor), unlockXP: 260),
        ChantExercise(id: "int_004", title: "D Minor Chord", subtitle: "Listen then sing D Minor notes",
            difficulty: .intermediate, mode: .mimicChord,
            targets: Chord(root: .D4, type: .minor).notes.map { NoteTarget(note: $0) },
            chord: Chord(root: .D4, type: .minor), unlockXP: 290),
        ChantExercise(id: "int_005", title: "Antiphon Pattern", subtitle: "C4 D4 C4 D4 E4 D4 C4",
            difficulty: .intermediate, mode: .sustainNote,
            targets: [.C4, .D4, .C4, .D4, .E4, .D4, .C4].map { NoteTarget(note: $0, durationBeats: 1.5) }, unlockXP: 320),
        ChantExercise(id: "int_006", title: "E Minor Chord", subtitle: "Hear and mimic E Minor",
            difficulty: .intermediate, mode: .mimicChord,
            targets: Chord(root: .E4, type: .minor).notes.map { NoteTarget(note: $0) },
            chord: Chord(root: .E4, type: .minor), unlockXP: 360),
    ]

    private static let advancedExercises: [ChantExercise] = [
        ChantExercise(id: "adv_001", title: "Kyrie Incipit", subtitle: "D4 F4 E4 D4 C4 D4 F4 E4",
            difficulty: .advanced, mode: .sustainNote,
            targets: [
                MusicalNote(name: .D, octave: 4), MusicalNote(name: .F, octave: 4),
                MusicalNote(name: .E, octave: 4), MusicalNote(name: .D, octave: 4),
                MusicalNote(name: .C, octave: 4), MusicalNote(name: .D, octave: 4),
                MusicalNote(name: .F, octave: 4), MusicalNote(name: .E, octave: 4)
            ].map { NoteTarget(note: $0, durationBeats: 1.5) }, unlockXP: 420),
        ChantExercise(id: "adv_002", title: "B Diminished", subtitle: "Hear and mimic B Diminished chord",
            difficulty: .advanced, mode: .mimicChord,
            targets: Chord(root: .B3, type: .diminished).notes.map { NoteTarget(note: $0) },
            chord: Chord(root: .B3, type: .diminished), unlockXP: 460),
        ChantExercise(id: "adv_003", title: "G Dom 7", subtitle: "Hear G7 and sing each note",
            difficulty: .advanced, mode: .mimicChord,
            targets: Chord(root: .G3, type: .dominantSeventh).notes.map { NoteTarget(note: $0) },
            chord: Chord(root: .G3, type: .dominantSeventh), unlockXP: 500),
        ChantExercise(id: "adv_004", title: "Alleluia Phrase", subtitle: "G3 A3 B3 A3 G3 A3 C4 B3 A3 G3",
            difficulty: .advanced, mode: .sustainNote,
            targets: [
                .G3, .A3, .B3, .A3, .G3, .A3,
                MusicalNote(name: .C, octave: 4), MusicalNote(name: .B, octave: 3), .A3, .G3
            ].map { NoteTarget(note: $0, durationBeats: 1.5) }, unlockXP: 550),
        ChantExercise(id: "adv_005", title: "D Dom 7", subtitle: "Hear D7 and mimic each note",
            difficulty: .advanced, mode: .mimicChord,
            targets: Chord(root: .D4, type: .dominantSeventh).notes.map { NoteTarget(note: $0) },
            chord: Chord(root: .D4, type: .dominantSeventh), unlockXP: 600),
        ChantExercise(id: "adv_006", title: "Agnus Dei Phrase", subtitle: "C4 D4 E4 D4 C4 D4 E4 G4 E4 D4",
            difficulty: .advanced, mode: .sustainNote,
            targets: [
                .C4, .D4, .E4, .D4, .C4, .D4, .E4,
                MusicalNote(name: .G, octave: 4), .E4, .D4
            ].map { NoteTarget(note: $0, durationBeats: 1.5) }, unlockXP: 650),
    ]

    private static let masterExercises: [ChantExercise] = [
        ChantExercise(id: "mas_001", title: "C Maj 7", subtitle: "Hear and mimic C Major 7",
            difficulty: .master, mode: .mimicChord,
            targets: Chord(root: .C4, type: .majorSeventh).notes.map { NoteTarget(note: $0, durationBeats: 3) },
            chord: Chord(root: .C4, type: .majorSeventh), unlockXP: 750),
        ChantExercise(id: "mas_002", title: "A Min 7", subtitle: "Hear and mimic A Minor 7",
            difficulty: .master, mode: .mimicChord,
            targets: Chord(root: .A3, type: .minorSeventh).notes.map { NoteTarget(note: $0, durationBeats: 3) },
            chord: Chord(root: .A3, type: .minorSeventh), unlockXP: 800),
        ChantExercise(id: "mas_003", title: "Full Kyrie", subtitle: "18-note Kyrie eleison phrase",
            difficulty: .master, mode: .sustainNote,
            targets: [
                .D4, .E4, MusicalNote(name: .F, octave: 4), .E4, .D4,
                .C4, .D4, .E4, .D4, .C4,
                .D4, .E4, MusicalNote(name: .F, octave: 4), .E4, .D4,
                .C4, .D4, .C4
            ].map { NoteTarget(note: $0, durationBeats: 1.5, toleranceCents: 25) }, unlockXP: 850),
        ChantExercise(id: "mas_004", title: "E Maj 7", subtitle: "Hear and mimic E Major 7",
            difficulty: .master, mode: .mimicChord,
            targets: Chord(root: .E4, type: .majorSeventh).notes.map { NoteTarget(note: $0, durationBeats: 3) },
            chord: Chord(root: .E4, type: .majorSeventh), unlockXP: 900),
        ChantExercise(id: "mas_005", title: "D Min 7", subtitle: "Hear and mimic D Minor 7",
            difficulty: .master, mode: .mimicChord,
            targets: Chord(root: .D4, type: .minorSeventh).notes.map { NoteTarget(note: $0, durationBeats: 3) },
            chord: Chord(root: .D4, type: .minorSeventh), unlockXP: 950),
        ChantExercise(id: "mas_006", title: "Salve Regina", subtitle: "12-note phrase with held finals",
            difficulty: .master, mode: .sustainNote,
            targets: [
                MusicalNote(name: .G, octave: 3), MusicalNote(name: .A, octave: 3),
                MusicalNote(name: .G, octave: 3), MusicalNote(name: .F, octave: 3),
                MusicalNote(name: .G, octave: 3), MusicalNote(name: .A, octave: 3),
                MusicalNote(name: .B, octave: 3), .C4, .D4, .E4, .D4, .C4
            ].map { NoteTarget(note: $0, durationBeats: 2, toleranceCents: 25) }, unlockXP: 1100),
    ]
}
