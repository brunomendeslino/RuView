import Foundation

enum FrequencyToNote {
    static let noteNames = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]

    static func convert(frequency hz: Double) -> (noteName: String, octave: Int, cents: Double)? {
        guard hz > 0 else { return nil }
        let midiFloat = 69.0 + 12.0 * log2(hz / 440.0)
        let midiNearest = Int(midiFloat.rounded())
        guard midiNearest >= 0, midiNearest <= 127 else { return nil }
        let cents = (midiFloat - Double(midiNearest)) * 100.0
        let octave = midiNearest / 12 - 1
        let noteIndex = ((midiNearest % 12) + 12) % 12
        return (noteNames[noteIndex], octave, cents)
    }

    static func midiToHz(_ midi: Int) -> Double {
        440.0 * pow(2.0, Double(midi - 69) / 12.0)
    }

    static func noteToMidi(nameIndex: Int, octave: Int) -> Int {
        (octave + 1) * 12 + nameIndex
    }

    static func accuracyLabel(for cents: Double) -> String {
        let abs = Swift.abs(cents)
        if abs < 10 { return "Perfect" }
        if abs < 20 { return cents < 0 ? "Slightly Flat" : "Slightly Sharp" }
        if abs < 35 { return cents < 0 ? "Flat" : "Sharp" }
        return cents < 0 ? "Very Flat" : "Very Sharp"
    }
}
