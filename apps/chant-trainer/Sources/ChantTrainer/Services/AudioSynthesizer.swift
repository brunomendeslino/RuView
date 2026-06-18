import AVFoundation
import Observation

@Observable
@MainActor
final class AudioSynthesizer {
    var isPlaying: Bool = false
    var playingNoteIndex: Int? = nil

    private var engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?
    private var phase: Double = 0
    private var frequencies: [Double] = []
    private var envelope: Double = 0
    private var envelopePhase: EnvelopePhase = .off
    private var samplesRemaining: Int = 0
    private let sampleRate: Double = 44100.0
    private let fadeInSamples  = 441
    private let fadeOutSamples = 2205

    private enum EnvelopePhase { case off, attack, sustain, release }

    func play(note: MusicalNote, duration: TimeInterval) async {
        await playSynth(frequencies: [note.frequency], duration: duration)
    }

    func playChord(_ chord: Chord, duration: TimeInterval) async {
        let freqs = chord.notes.map { $0.frequency }
        await playSynth(frequencies: freqs, duration: duration)
    }

    func arpeggiate(_ chord: Chord, noteDuration: TimeInterval) async {
        for (index, note) in chord.notes.enumerated() {
            playingNoteIndex = index
            await playSynth(frequencies: [note.frequency], duration: noteDuration)
            try? await Task.sleep(nanoseconds: 150_000_000)
        }
        playingNoteIndex = nil
    }

    func stop() {
        isPlaying = false
        envelopePhase = .release
    }

    private func playSynth(frequencies freqs: [Double], duration: TimeInterval) async {
        isPlaying = true
        setupEngine(frequencies: freqs)
        let totalSamples = Int(sampleRate * duration)
        samplesRemaining = totalSamples
        envelopePhase = .attack
        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000) + 100_000_000)
        isPlaying = false
        teardownEngine()
    }

    private func setupEngine(frequencies freqs: [Double]) {
        teardownEngine()
        frequencies = freqs

        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker])
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let amplitudeScale = Float(1.0 / max(1, freqs.count)) * 0.5

        var phases = [Double](repeating: 0, count: freqs.count)
        var localEnvelope: Double = 0
        var localPhase: EnvelopePhase = .attack
        var localSamplesRemaining: Int = samplesRemaining
        let localFadeIn  = fadeInSamples
        let localFadeOut = fadeOutSamples
        let sr = sampleRate

        sourceNode = AVAudioSourceNode(format: format) { [freqs] _, _, frameCount, audioBufferList -> OSStatus in
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard let ptr = abl[0].mData?.assumingMemoryBound(to: Float.self) else { return noErr }

            let twoPI = 2.0 * Double.pi
            var samplesLeft = localSamplesRemaining

            for frame in 0..<Int(frameCount) {
                var sample: Double = 0
                for i in 0..<freqs.count {
                    sample += sin(phases[i])
                    phases[i] += twoPI * freqs[i] / sr
                    if phases[i] > twoPI { phases[i] -= twoPI }
                }
                sample *= Double(amplitudeScale)

                switch localPhase {
                case .attack:
                    localEnvelope = min(1.0, localEnvelope + 1.0 / Double(localFadeIn))
                    if localEnvelope >= 1.0 { localPhase = .sustain }
                case .sustain:
                    if samplesLeft <= localFadeOut { localPhase = .release }
                case .release:
                    localEnvelope = max(0.0, localEnvelope - 1.0 / Double(localFadeOut))
                    if localEnvelope <= 0 { localPhase = .off }
                case .off:
                    localEnvelope = 0
                }

                ptr[frame] = Float(sample * localEnvelope)
                if samplesLeft > 0 { samplesLeft -= 1 }
            }
            localSamplesRemaining = samplesLeft
            return noErr
        }

        engine = AVAudioEngine()
        engine.attach(sourceNode!)
        engine.connect(sourceNode!, to: engine.mainMixerNode, format: format)
        try? engine.start()
    }

    private func teardownEngine() {
        sourceNode = nil
        engine.stop()
    }
}
