import AVFoundation
import Accelerate
import Observation

@Observable
@MainActor
final class AudioPitchDetector {
    var currentFrequency: Double? = nil
    var currentNote: MusicalNote? = nil
    var currentCentsOff: Double = 0.0
    var signalAmplitude: Float = 0.0
    var isRunning: Bool = false
    var permissionGranted: Bool = false

    private let engine = AVAudioEngine()
    private let bufferSize: AVAudioFrameCount = 4096
    private let sampleRate: Double = 44100.0
    private let processingQueue = DispatchQueue(label: "pitch.processing", qos: .userInteractive)

    func requestPermission() async {
        #if os(iOS)
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                Task { @MainActor in self?.permissionGranted = granted }
                continuation.resume()
            }
        }
        #else
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                Task { @MainActor in self?.permissionGranted = granted }
                continuation.resume()
            }
        }
        #endif
    }

    func startCapture() throws {
        guard !isRunning else { return }

        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .allowBluetooth])
        try session.setActive(true)
        #endif

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: format) { [weak self] buffer, _ in
            self?.processingQueue.async {
                self?.processBuffer(buffer)
            }
        }
        try engine.start()
        isRunning = true
    }

    func stopCapture() {
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false
        currentFrequency = nil
        currentNote = nil
        signalAmplitude = 0
    }

    private func processBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return }

        var rms: Float = 0
        vDSP_rmsqv(channelData, 1, &rms, vDSP_Length(frameCount))

        let amplitude = rms
        if amplitude < 0.005 {
            Task { @MainActor [weak self] in
                self?.signalAmplitude = amplitude
                self?.currentFrequency = nil
                self?.currentNote = nil
            }
            return
        }

        var windowed = [Float](repeating: 0, count: frameCount)
        var hannWindow = [Float](repeating: 0, count: frameCount)
        vDSP_hann_window(&hannWindow, vDSP_Length(frameCount), Int32(vDSP_HANN_NORM))
        vDSP_vmul(channelData, 1, hannWindow, 1, &windowed, 1, vDSP_Length(frameCount))

        let f0 = yinDetect(samples: windowed, sampleRate: sampleRate)

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.signalAmplitude = amplitude
            if let f0, f0 > 60.0, f0 < 1500.0 {
                self.currentFrequency = f0
                if let (note, cents) = MusicalNote.fromFrequency(f0) {
                    self.currentNote = note
                    self.currentCentsOff = cents
                }
            } else {
                self.currentFrequency = nil
            }
        }
    }

    private func yinDetect(samples: [Float], sampleRate: Double) -> Double? {
        let N = samples.count
        let W = N / 2
        guard W > 0 else { return nil }

        var d = [Double](repeating: 0, count: W)
        for tau in 1..<W {
            for j in 0..<W {
                let diff = Double(samples[j]) - Double(samples[j + tau])
                d[tau] += diff * diff
            }
        }

        var cmndf = [Double](repeating: 1.0, count: W)
        var runningSum = 0.0
        for tau in 1..<W {
            runningSum += d[tau]
            cmndf[tau] = runningSum > 0 ? d[tau] * Double(tau) / runningSum : 1.0
        }

        let threshold = 0.10
        let minTau = max(1, Int(sampleRate / 1500.0))
        let maxTau = min(W - 1, Int(sampleRate / 60.0))

        var tauEstimate = -1
        var tau = minTau
        while tau <= maxTau {
            if cmndf[tau] < threshold {
                while tau + 1 < W && cmndf[tau + 1] < cmndf[tau] {
                    tau += 1
                }
                tauEstimate = tau
                break
            }
            tau += 1
        }

        guard tauEstimate > 0 else { return nil }

        let x0 = tauEstimate > 0       ? cmndf[tauEstimate - 1] : cmndf[tauEstimate]
        let x1 = cmndf[tauEstimate]
        let x2 = tauEstimate < W - 1   ? cmndf[tauEstimate + 1] : cmndf[tauEstimate]

        let denom = 2.0 * x1 - x0 - x2
        let betterTau: Double
        if abs(denom) > 1e-10 {
            betterTau = Double(tauEstimate) + (x2 - x0) / (2.0 * denom)
        } else {
            betterTau = Double(tauEstimate)
        }

        return sampleRate / betterTau
    }
}
