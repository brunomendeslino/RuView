import SwiftUI

enum NoteGrade: Int {
    case perfect = 10
    case good    = 6
    case okay    = 3
    case miss    = 0

    static func from(centsOff: Double) -> NoteGrade {
        let a = abs(centsOff)
        if a < 10 { return .perfect }
        if a < 20 { return .good }
        if a < 30 { return .okay }
        return .miss
    }

    var label: String {
        switch self {
        case .perfect: return "Perfect!"
        case .good:    return "Good"
        case .okay:    return "Almost"
        case .miss:    return "Missed"
        }
    }

    var color: Color {
        switch self {
        case .perfect: return .green
        case .good:    return .yellow
        case .okay:    return .orange
        case .miss:    return .red
        }
    }
}

private enum Phase: Equatable {
    case countdown(Int)
    case chordPlayback
    case waitingForReady
    case active(noteIndex: Int, elapsed: Double)
    case noteResult(grade: NoteGrade, nextIndex: Int?)
    case finished
}

struct ExerciseView: View {
    let exercise: ChantExercise
    var progress: GameProgress

    @State private var synth = AudioSynthesizer()
    var pitchDetector: AudioPitchDetector

    @State private var phase: Phase = .countdown(3)
    @State private var countdownTimer: Timer? = nil
    @State private var noteTimer: Timer? = nil
    @State private var noteElapsed: Double = 0
    @State private var noteDuration: Double = 3.0
    @State private var centsReadings: [Double] = []
    @State private var noteGrades: [NoteGrade] = []
    @State private var totalXPEarned: Int = 0
    @State private var chordReady: Bool = false
    @State private var newAchievements: [String] = []

    @Environment(\.dismiss) private var dismiss

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var hSizeClass
    private var isCompact: Bool { hSizeClass == .compact }
    #else
    private var isCompact: Bool { false }
    #endif

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(white: 0.05), Color(white: 0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: CT.largeSpacing) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(exercise.title).font(.headline).foregroundStyle(.primary)
                        Text(exercise.difficulty.displayName)
                            .font(.caption).foregroundStyle(exercise.difficulty.color)
                    }
                    Spacer()
                    Text("XP: \(totalXPEarned)")
                        .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .padding(CT.smallSpacing)
                            .glassCard()
                    }
                    .foregroundStyle(.primary)
                }
                .padding(.horizontal, CT.largeSpacing)

                // Progress dots
                if case .active(let idx, _) = phase {
                    progressDots(currentIndex: idx)
                } else if case .noteResult(_, let nextIdx) = phase {
                    progressDots(currentIndex: (nextIdx ?? exercise.targets.count) - 1)
                }

                // Main content
                Group {
                    switch phase {
                    case .countdown(let n):
                        countdownView(n)
                    case .chordPlayback, .waitingForReady:
                        if let chord = exercise.chord {
                            ChordDeconstructionView(chord: chord, isReady: $chordReady, synth: synth)
                                .onChange(of: chordReady) { _, ready in
                                    if ready { startNotePhase(index: 0) }
                                }
                        }
                    case .active(let idx, let elapsed):
                        activeView(noteIndex: idx, elapsed: elapsed)
                    case .noteResult(let grade, _):
                        noteResultView(grade: grade)
                    case .finished:
                        Color.clear
                    }
                }
                .padding(.horizontal, CT.largeSpacing)
            }
            .padding(.vertical, CT.largeSpacing)
        }
        .onAppear { startCountdown() }
        .onDisappear { cleanUp() }
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .fullScreenCover(isPresented: Binding(
            get: { if case .finished = phase { return true } else { return false } },
            set: { _ in dismiss() }
        )) {
            ResultsView(
                exercise: exercise,
                stars: computeStars(),
                xpEarned: totalXPEarned,
                accuracy: computeAccuracy(),
                newAchievements: newAchievements,
                progressModel: progress,
                onHome: { dismiss() }
            )
        }
    }

    // MARK: - Sub-views

    private func countdownView(_ n: Int) -> some View {
        VStack(spacing: CT.largeSpacing) {
            Spacer()
            Text("\(n)")
                .font(.system(size: 120, weight: .black))
                .foregroundStyle(.primary)
                .transition(.scale.combined(with: .opacity))
                .id("countdown_\(n)")
            Text("Get ready…")
                .font(.title3).foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func activeView(noteIndex: Int, elapsed: Double) -> some View {
        let target = exercise.targets[noteIndex]
        let fraction = min(1.0, elapsed / target.durationBeats)
        let isDetecting = pitchDetector.isRunning && pitchDetector.currentNote != nil

        return Group {
            if isCompact {
                VStack(spacing: CT.spacing) {
                    NoteDisplayView(
                        targetNote: target.note,
                        centsOff: pitchDetector.currentCentsOff,
                        isDetecting: isDetecting
                    )
                    timingBar(fraction: fraction)
                    PitchMeterView(
                        centsOff: pitchDetector.currentCentsOff,
                        isActive: isDetecting
                    )
                }
            } else {
                VStack(spacing: CT.spacing) {
                    HStack(spacing: CT.largeSpacing) {
                        NoteDisplayView(
                            targetNote: target.note,
                            centsOff: pitchDetector.currentCentsOff,
                            isDetecting: isDetecting
                        )
                        .frame(maxWidth: .infinity)
                        PitchMeterView(
                            centsOff: pitchDetector.currentCentsOff,
                            isActive: isDetecting
                        )
                        .frame(maxWidth: .infinity)
                    }
                    timingBar(fraction: fraction)
                }
            }
        }
    }

    private func timingBar(fraction: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.primary.opacity(0.1))
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: geo.size.width * fraction)
                    .animation(.linear(duration: 0.05), value: fraction)
            }
        }
        .frame(height: 6)
        .glassCard()
    }

    private func noteResultView(grade: NoteGrade) -> some View {
        VStack(spacing: CT.spacing) {
            Spacer()
            Image(systemName: grade == .miss ? "xmark.circle" : "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(grade.color)
            Text(grade.label)
                .font(.largeTitle.bold())
                .foregroundStyle(grade.color)
            Text("+\(grade.rawValue) XP")
                .font(.title3)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func progressDots(currentIndex: Int) -> some View {
        HStack(spacing: 8) {
            ForEach(0..<exercise.targets.count, id: \.self) { i in
                Circle()
                    .fill(i < currentIndex ? Color.green :
                          i == currentIndex ? Color.accentColor :
                          Color.primary.opacity(0.3))
                    .frame(width: 10, height: 10)
            }
        }
    }

    // MARK: - State machine

    private func startCountdown() {
        var n = 3
        phase = .countdown(n)
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            n -= 1
            if n > 0 {
                withAnimation { phase = .countdown(n) }
            } else {
                countdownTimer?.invalidate()
                countdownTimer = nil
                if exercise.mode == .mimicChord && exercise.chord != nil {
                    withAnimation { phase = .chordPlayback }
                } else if exercise.mode == .mimicNote {
                    // play the first note via synth then jump to active
                    Task {
                        if let firstNote = exercise.targets.first?.note {
                            await synth.play(note: firstNote, duration: 1.5)
                        }
                        startNotePhase(index: 0)
                    }
                } else {
                    startNotePhase(index: 0)
                }
            }
        }
    }

    private func startNotePhase(index: Int) {
        guard index < exercise.targets.count else {
            finishExercise()
            return
        }
        centsReadings = []
        let target = exercise.targets[index]
        noteDuration = target.durationBeats
        noteElapsed = 0

        withAnimation { phase = .active(noteIndex: index, elapsed: 0) }

        if !pitchDetector.isRunning {
            Task { try? pitchDetector.startCapture() }
        }

        let skipFraction = 0.10
        var sampleCount = 0

        noteTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            noteElapsed += 0.05
            let fraction = noteElapsed / target.durationBeats
            withAnimation { phase = .active(noteIndex: index, elapsed: noteElapsed) }

            if fraction > skipFraction && fraction < 0.95 {
                let c = pitchDetector.currentCentsOff
                if pitchDetector.currentFrequency != nil { centsReadings.append(c) }
                sampleCount += 1
            }

            if noteElapsed >= target.durationBeats {
                noteTimer?.invalidate()
                noteTimer = nil
                evaluateNote(index: index)
            }
        }
    }

    private func evaluateNote(index: Int) {
        let grade: NoteGrade
        if centsReadings.isEmpty {
            grade = .miss
        } else {
            let avgCents = centsReadings.reduce(0, +) / Double(centsReadings.count)
            grade = NoteGrade.from(centsOff: avgCents)
        }
        noteGrades.append(grade)
        totalXPEarned += grade.rawValue

        let next = index + 1 < exercise.targets.count ? index + 1 : nil
        withAnimation { phase = .noteResult(grade: grade, nextIndex: next) }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let nextIndex = next {
                startNotePhase(index: nextIndex)
            } else {
                finishExercise()
            }
        }
    }

    private func finishExercise() {
        pitchDetector.stopCapture()
        let acc = computeAccuracy()
        let stars = computeStars()
        let bonus = stars == 3 ? 20 : 0
        totalXPEarned += bonus

        let beforeAchievements = progress.achievements
        progress.recordExerciseComplete(
            id: exercise.id,
            stars: stars,
            xpEarned: totalXPEarned,
            accuracy: acc,
            chordName: exercise.chord?.displayName
        )
        newAchievements = Array(progress.achievements.subtracting(beforeAchievements))
        PersistenceManager.shared.save(progress)

        withAnimation { phase = .finished }
    }

    private func computeAccuracy() -> Double {
        guard !noteGrades.isEmpty else { return 0 }
        let accurate = noteGrades.filter { $0 != .miss }.count
        return Double(accurate) / Double(noteGrades.count)
    }

    private func computeStars() -> Int {
        let acc = computeAccuracy()
        if acc >= 0.9 { return 3 }
        if acc >= 0.7 { return 2 }
        if acc >= 0.5 { return 1 }
        return 0
    }

    private func cleanUp() {
        countdownTimer?.invalidate()
        noteTimer?.invalidate()
        pitchDetector.stopCapture()
        synth.stop()
    }
}
