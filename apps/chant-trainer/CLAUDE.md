# CLAUDE.md — ChantTrainer (macOS + iOS)

> This file will be written to `apps/chant-trainer/CLAUDE.md` as the first implementation step, then Claude Code implements each phase in order.

---

## Project Overview

**ChantTrainer** is a native Swift app (macOS 14 + iOS 17) that teaches users to chant musical notes with:
- Real-time microphone pitch detection (YIN algorithm via vDSP)
- Chord deconstruction: play full chord → arpeggiate → user mimics each note by singing
- Gamification: stars per exercise, XP/levels, daily streaks, achievements, full score history
- Random chord mode: tap to get a surprise chord challenge across all 84 chord types
- Design: **zero border radius**, **glassmorphism** (Apple `.ultraThinMaterial`), **system colors only**

**Location**: `apps/chant-trainer/` (standalone Swift Package, no dependency on the Rust/Python codebase)
**Branch**: `claude/macos-voice-training-app-xhixvp`

---

## Tech Stack

| Concern | Technology |
|---------|-----------|
| UI | SwiftUI |
| Audio capture | AVFoundation (`AVAudioEngine`) |
| Pitch detection | Accelerate (`vDSP`) — YIN algorithm |
| Audio synthesis | `AVAudioSourceNode` (sine wave additive) |
| Performance charts | Swift Charts |
| State | `@Observable` (Swift 5.9) |
| Persistence | `UserDefaults` (JSON-encoded) |
| Platforms | macOS 14+, iOS 17+ |
| Dependencies | None (pure Apple frameworks) |

---

## File Structure

```
apps/chant-trainer/
├── CLAUDE.md                             ← this file
├── Package.swift
└── Sources/
    └── ChantTrainer/
        ├── ChantTrainerApp.swift
        ├── Resources/
        │   └── Info.plist
        ├── Models/
        │   ├── MusicalNote.swift
        │   ├── Chord.swift
        │   ├── ChordLibrary.swift
        │   ├── ChantExercise.swift
        │   ├── ExerciseLibrary.swift
        │   ├── PerformanceEntry.swift
        │   └── GameProgress.swift
        ├── Services/
        │   ├── AudioPitchDetector.swift
        │   ├── AudioSynthesizer.swift
        │   └── PersistenceManager.swift
        ├── Views/
        │   ├── ContentView.swift
        │   ├── HomeView.swift
        │   ├── RandomChordView.swift
        │   ├── ExerciseView.swift
        │   ├── ChordDeconstructionView.swift
        │   ├── PitchMeterView.swift
        │   ├── NoteDisplayView.swift
        │   ├── ResultsView.swift
        │   └── AchievementsView.swift
        └── Utilities/
            ├── FrequencyToNote.swift
            └── DesignSystem.swift
```

---

## Build & Run

```bash
# Open in Xcode — required for real microphone permission + simulator
open apps/chant-trainer/Package.swift
# macOS: scheme=ChantTrainer, destination=My Mac, Cmd+R
# iOS:   scheme=ChantTrainer, destination=iPhone 17 Pro, Cmd+R

# Quick compile check (no GUI)
cd apps/chant-trainer && swift build 2>&1 | head -50
```

**Always run** `swift build` after each phase to catch errors early.

---

## Implementation Phases

Implement phases in order. After each phase, run `swift build` and fix any errors before proceeding.

---

### Phase 1 — Package Scaffolding

**Goal**: Create the directory structure and `Package.swift`. All subsequent files go inside `Sources/ChantTrainer/`.

**Files to create:**

**`Package.swift`**
```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ChantTrainer",
    platforms: [.macOS(.v14), .iOS(.v17)],
    targets: [
        .executableTarget(
            name: "ChantTrainer",
            path: "Sources/ChantTrainer",
            resources: [.process("Resources")]
        )
    ]
)
```

**`Sources/ChantTrainer/Resources/Info.plist`**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSMicrophoneUsageDescription</key>
    <string>ChantTrainer listens to your voice to detect pitch and give you real-time feedback while you practice chanting.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
```

**Verify**: `swift build` compiles with no source files yet (just the manifest).

---

### Phase 2 — Utilities

**Goal**: Pure math helpers. No UI, no AVFoundation. Compile-check before proceeding.

**`Utilities/FrequencyToNote.swift`**
- `enum FrequencyToNote` — all static functions
- `convert(frequency hz: Double) -> (noteName: String, octave: Int, cents: Double)?`
  - `midiFloat = 69.0 + 12.0 * log2(hz / 440.0)`
  - `midiNearest = Int(midiFloat.rounded())`
  - `cents = (midiFloat - Double(midiNearest)) * 100.0`
  - `octave = midiNearest / 12 - 1`
  - `noteIndex = ((midiNearest % 12) + 12) % 12`
- `static let noteNames = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]`
- `midiToHz(_ midi: Int) -> Double` → `440.0 * pow(2.0, Double(midi - 69) / 12.0)`
- `accuracyLabel(for cents: Double) -> String` → "Perfect" / "Slightly Flat" / "Flat" / "Sharp" etc.

**`Utilities/DesignSystem.swift`**
- `extension View { func glassCard() -> some View }` — `.background(.ultraThinMaterial).clipShape(Rectangle()).overlay(Rectangle().stroke(Color.primary.opacity(0.12), lineWidth: 1))`
- `extension View { func glassSurface() -> some View }` — `.background(.thinMaterial).clipShape(Rectangle())`
- `struct GlassButtonStyle: ButtonStyle` — `.background(.thinMaterial)`, `Rectangle()` clip, primary stroke 0.12 opacity, `.opacity(0.7)` when pressed
- All tokens as `static let` on a `enum CT` namespace: `CT.cornerRadius = 0`, `CT.spacing: CGFloat = 16`, etc.
- **Zero radius rule**: never use `RoundedRectangle`. Only `Rectangle()` for clips.

---

### Phase 3 — Models

**Goal**: Pure Swift value types. No AVFoundation. Must be fully Codable for persistence.

**`Models/MusicalNote.swift`**
```swift
enum NoteName: String, CaseIterable, Codable {
    case C, Cs, D, Ds, E, F, Fs, G, Gs, A, As, B
    var displayName: String  // "C", "C#", "D", etc.
    var solfege: String      // "Do", "Re", "Mi", "Fa", "Sol", "La", "Si" for naturals
}

struct MusicalNote: Hashable, Codable, Identifiable {
    var id: String { "\(name.rawValue)\(octave)" }
    let name: NoteName
    let octave: Int           // 2–5
    var frequency: Double     // 440 * pow(2, (midiNumber - 69) / 12)
    var midiNumber: Int       // computed: NoteName index + (octave+1)*12
    var displayLabel: String  // "D4", "A3"
    
    static func fromMidi(_ midi: Int) -> MusicalNote
    static func fromFrequency(_ hz: Double) -> (note: MusicalNote, centsOff: Double)?
    
    // Common reference notes
    static let A3 = MusicalNote(name: .A, octave: 3)
    static let C4 = MusicalNote(name: .C, octave: 4)
    static let D4 = MusicalNote(name: .D, octave: 4)
    static let E4 = MusicalNote(name: .E, octave: 4)
    static let G3 = MusicalNote(name: .G, octave: 3)
}
```

**`Models/Chord.swift`**
```swift
enum ChordType: String, CaseIterable, Codable {
    case major, minor, diminished, augmented
    case dominantSeventh = "dom7"
    case majorSeventh    = "maj7"
    case minorSeventh    = "min7"
    
    var intervals: [Int]     // semitone offsets from root
    var displayName: String  // "Major", "Minor", "Dim°", "Aug+", "Dom 7", "Maj 7", "Min 7"
    var shortName: String    // "", "m", "°", "+", "7", "M7", "m7"
}
// intervals: major=[0,4,7], minor=[0,3,7], dim=[0,3,6], aug=[0,4,8],
//            dom7=[0,4,7,10], maj7=[0,4,7,11], min7=[0,3,7,10]

struct Chord: Identifiable, Codable {
    let id: String           // e.g. "C_major"
    let root: MusicalNote
    let type: ChordType
    var notes: [MusicalNote] // computed: root + each interval applied to root.midiNumber
    var displayName: String  // "C Major", "D Minor", "B°"
    
    init(root: MusicalNote, type: ChordType)  // compute notes from intervals
}
```

**`Models/ChordLibrary.swift`**
```swift
enum ChordLibrary {
    static let all: [Chord]   // 84 chords: all 12 roots (octave 3) × 7 types
    static func random() -> Chord
    static func random(type: ChordType) -> Chord
    static func chords(ofType: ChordType) -> [Chord]
    static func chords(rootedAt: NoteName) -> [Chord]
}
// Generate all 84 programmatically in a computed property — don't hardcode 84 entries
// Loop: for noteName in NoteName.allCases { for type in ChordType.allCases { ... } }
```

**`Models/PerformanceEntry.swift`**
```swift
struct PerformanceEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let exerciseID: String
    let accuracyPercent: Double   // 0.0–1.0
    let stars: Int                // 0–3
    let xpEarned: Int
    let chordName: String?        // nil for note-only; "C Major" for chord exercises
}
```

**`Models/ChantExercise.swift`**
```swift
enum ExerciseMode: String, Codable {
    case sustainNote   // user reads notation, sings without audio cue
    case mimicNote     // system plays note; user listens then mimics
    case mimicChord    // system plays chord then arpeggiates; user mimics each note
}

enum Difficulty: Int, Codable, CaseIterable, Comparable {
    case beginner=1, novice, intermediate, advanced, master
    var displayName: String
    var color: Color  // .green, .blue, .orange, .red, .purple
}

struct NoteTarget: Codable {
    let note: MusicalNote
    let durationBeats: Double   // 1 beat = 1 second at 60 BPM
    let toleranceCents: Double  // default 30
}

struct ChantExercise: Identifiable, Codable {
    let id: String
    let title: String
    let subtitle: String
    let difficulty: Difficulty
    let mode: ExerciseMode
    let targets: [NoteTarget]
    let chord: Chord?           // non-nil for mimicChord mode
    let unlockXP: Int           // 0 = always unlocked
    
    var totalDurationSeconds: Double  // sum of durationBeats
    var isLocked: Bool  // computed against GameProgress externally
}
```

**`Models/ExerciseLibrary.swift`**
```swift
enum ExerciseLibrary {
    static let all: [ChantExercise]
    static func exercises(for difficulty: Difficulty) -> [ChantExercise]
    static func unlocked(xp: Int, completedIDs: Set<String>) -> [ChantExercise]
    static func next(after id: String) -> ChantExercise?
}
```

Exercise catalog (30 total — define inline):
| ID prefix | Difficulty | Count | Modes |
|-----------|-----------|-------|-------|
| `beg_` | beginner | 6 | 4× sustainNote, 2× mimicNote |
| `nov_` | novice | 6 | 3× sustainNote, 3× mimicChord (C/G/F major) |
| `int_` | intermediate | 6 | 2× sustainNote, 4× mimicChord (major+minor) |
| `adv_` | advanced | 6 | 2× sustainNote chant phrases, 4× mimicChord (dim+dom7) |
| `mas_` | master | 6 | 2× sustainNote long chants, 4× mimicChord (maj7+min7 across roots) |

**`Models/GameProgress.swift`**
```swift
@Observable
final class GameProgress {
    var totalXP: Int = 0
    var currentLevel: Int = 1
    var streakDays: Int = 0
    var lastPracticeDate: Date? = nil
    var completedExerciseIDs: Set<String> = []
    var starRatings: [String: Int] = [:]             // best star per exerciseID
    var performanceHistory: [String: [PerformanceEntry]] = [:]  // all attempts, max 50/exercise
    var achievements: Set<String> = []
    
    static let levelThresholds = [0, 100, 250, 500, 1000, 2000]
    static let achievementDefs: [(id: String, title: String, icon: String, description: String)]
    
    var levelProgress: Double   // 0.0–1.0 toward next level
    var xpToNextLevel: Int
    var levelTitle: String      // "Beginner"/"Novice"/"Chanter"/"Cantor"/"Precentor"/"Choirmaster"
    
    func recordExerciseComplete(
        id: String, stars: Int, xpEarned: Int,
        accuracy: Double, chordName: String? = nil
    )
    func updateStreak()
    func recentAccuracy(for exerciseID: String, last n: Int = 5) -> Double?
    private func checkAchievements()
}
```

Achievements (9):
- `first_note`: Complete first exercise
- `perfect_beginner`: 3 stars on any beginner exercise  
- `beginner_graduate`: Complete all 6 beginner exercises
- `chord_explorer`: Complete first chord exercise
- `3_star_sweep`: 3 stars on 5 different exercises
- `week_streak`: 7-day streak
- `month_streak`: 30-day streak
- `level_5`: Reach level 5
- `chant_master`: Complete any master exercise

---

### Phase 4 — Services

**Goal**: AVFoundation audio services. Compile-check after each file.

**`Services/PersistenceManager.swift`**
- `final class PersistenceManager` with `static let shared`
- All keys prefixed `ct_`
- `func save(_ progress: GameProgress)` — encodes each field; `performanceHistory` via `JSONEncoder`
- `func load() -> GameProgress` — decode; returns fresh `GameProgress()` if no data
- `func reset()` — clears all `ct_*` keys

**`Services/AudioPitchDetector.swift`**

Key class signature:
```swift
@Observable @MainActor
final class AudioPitchDetector {
    var currentFrequency: Double? = nil
    var currentNote: MusicalNote? = nil
    var currentCentsOff: Double = 0.0
    var signalAmplitude: Float = 0.0
    var isRunning: Bool = false
    var permissionGranted: Bool = false
    
    func requestPermission() async
    func startCapture() throws
    func stopCapture()
}
```

Implementation steps:
1. **Platform-conditional permission request**:
   ```swift
   #if os(iOS)
   AVAudioSession.sharedInstance().requestRecordPermission { granted in ... }
   #else
   AVAudioApplication.requestRecordPermissionWithCompletionHandler { granted in ... }
   #endif
   ```
2. **iOS audio session setup** (in `startCapture`, iOS only):
   ```swift
   try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .measurement, options: .defaultToSpeaker)
   try AVAudioSession.sharedInstance().setActive(true)
   ```
3. **Tap installation**: `engine.inputNode.installTap(onBus:0, bufferSize:4096, format:nil) { buf, _ in self.process(buf) }`
4. **`process(_ buffer: AVAudioPCMBuffer)`** (called on audio thread — post to MainActor):
   - Get `channelData[0]`, `frameLength`
   - `vDSP_rmsqv` → amplitude; gate at 0.01
   - Apply Hann window: `vDSP_hann_window` + `vDSP_vmul`
   - Call `yinDetect(samples:sampleRate:)` → `Double?`
   - Validate range 60–1000 Hz
   - `Task { @MainActor in self.currentFrequency = f0; ... }`
5. **`yinDetect(samples: [Float], sampleRate: Double) -> Double?`**:
   ```
   W = samples.count / 2
   d[tau] = sum_{j=0}^{W-1} (x[j] - x[j+tau])^2    // difference function
   cmndf[tau] = tau>0 ? d[tau]*tau / sum(d[1..tau]) : 1  // normalized
   threshold = 0.10
   find first tau in [minTau, maxTau] where cmndf[tau] < threshold
   walk right to local minimum
   parabolic interpolation for sub-sample accuracy
   return sampleRate / betterTau
   ```
   - `minTau = Int(sampleRate / 1000)`, `maxTau = Int(sampleRate / 60)`

**`Services/AudioSynthesizer.swift`**

```swift
@Observable @MainActor
final class AudioSynthesizer {
    var isPlaying: Bool = false
    var playingNoteIndex: Int? = nil   // for arpeggio highlight in UI
    
    func play(note: MusicalNote, duration: TimeInterval) async
    func playChord(_ chord: Chord, duration: TimeInterval) async
    func arpeggiate(_ chord: Chord, noteDuration: TimeInterval) async
    func stop()
}
```

Synthesis:
- `AVAudioEngine` + `AVAudioSourceNode` callback renders `sin(2π * freq * t)`
- For chord: sum N sine waves, divide by N to normalize
- Envelope: linear ramp from 0→1 over first 441 samples (10 ms), 1→0 over last 2205 (50 ms)
- Shared engine with `AudioPitchDetector` via a singleton or injected reference so they don't conflict on iOS
- `async` methods use `try await Task.sleep(nanoseconds:)` for duration, then detach source node

---

### Phase 5 — Core Exercise Views

**Goal**: The active training UI. This is the heart of the app.

**`Views/PitchMeterView.swift`**
```swift
struct PitchMeterView: View {
    let centsOff: Double     // -50 to +50
    let isActive: Bool
}
```
- `GeometryReader` for width
- Background: `LinearGradient` stops: red(0) orange(0.25) yellow(0.375) green(0.5) yellow(0.625) orange(0.75) red(1.0)
- Clip to `Rectangle()` (zero radius)
- Center line: white 2pt `Rectangle`
- Needle: white 4pt `Capsule` (one place where capsule is OK — it's a fine detail) at `x = (centsOff+50)/100 * width - width/2`, animated `.interactiveSpring(response: 0.15)`
- Bottom labels: HStack "Flat" — "Perfect" — "Sharp" in `.caption` `.secondary`
- When `!isActive`: full opacity 0.3, needle hidden, "Sing to detect pitch" label

**`Views/NoteDisplayView.swift`**
```swift
struct NoteDisplayView: View {
    let targetNote: MusicalNote
    let centsOff: Double
    let isDetecting: Bool
    let showSolfege: Bool  // show "Sol" vs "G"
}
```
- Large note letter: `Text(targetNote.name.displayName)` at 80pt iPhone / 120pt iPad+macOS
- `octaveLabel`: small circle with octave number below
- `feedbackColor`: green<10¢, yellow<20¢, orange<30¢, red else — `.animation(.easeInOut(0.1))`
- Perfect sparkle: `TimelineView(.animation)` driving a `Canvas` drawing 8 circles radiating outward
- Not detecting: scale pulse `1.0→1.02→1.0` on 1.5 s loop

**`Views/ChordDeconstructionView.swift`**
```swift
struct ChordDeconstructionView: View {
    let chord: Chord
    @Binding var isReady: Bool   // set to true when user taps "Start Singing"
    @EnvironmentObject var synth: AudioSynthesizer
}
```
- Title: chord `displayName` in large bold, chord type badge (colored pill)
- Note pills row: `HStack` of note cards (each: note name + octave, play button `▶`)
  - Tap → `synth.play(note:, duration: 1.0)`, animates highlight
  - During arpeggio: `synth.playingNoteIndex` drives highlight
- "Play Full Chord" button → `synth.playChord(chord, duration: 2.0)`
- "Play Each Note" button → `synth.arpeggiate(chord, noteDuration: 1.0)`
- Auto-plays full chord then arpeggios on appear
- "I'm Ready — Start Singing" button → sets `isReady = true`
- All cards: `.glassCard()`, no rounded corners

**`Views/ExerciseView.swift`**

State machine:
```swift
enum Phase {
    case countdown(Int)         // 3-2-1
    case chordPlayback          // only for mimicChord
    case active(noteIndex: Int) // listening
    case noteResult(grade: NoteGrade, nextIndex: Int?)
    case finished
}
```

Layout (adaptive):
```swift
// compact width (iPhone portrait): VStack
// regular width (iPad/macOS): HStack
@Environment(\.horizontalSizeClass) var hSizeClass
```

Active phase content:
- Progress dots: `HStack` of circles, filled for completed notes
- `NoteDisplayView` (left/top) + `PitchMeterView` (right/bottom)
- Timing bar: `GeometryReader`-based fill, depletes over `durationBeats` seconds
- Live score tally in corner: "XP: 34" + star estimate

Timing loop:
- `Timer.publish(every: 0.05, on: .main, in: .common)` → sample `pitchDetector.currentCentsOff`
- Skip first 10% of window (attack), last 5% (release) using elapsed time ratio
- Accumulate grades → on window close → advance to next note or `.finished`

**`Views/ResultsView.swift`**
```swift
struct ResultsView: View {
    let exercise: ChantExercise
    let stars: Int
    let xpEarned: Int
    let accuracy: Double
    let newAchievements: [String]
    let onNext: () -> Void
    let onHome: () -> Void
}
```
- Stars animate in one at a time (delay 0.3s each): `.scale.combined(with: .opacity)`
- XP counter: `@State var displayXP = 0` increments via timer over 1.5 s
- Accuracy percentage label
- Performance trend (if ≥3 prior attempts): `import Charts` → `Chart` with `LineMark` for last 5 accuracies
- Achievement banner: slides from bottom with `.transition(.move(edge: .bottom))` if `!newAchievements.isEmpty`
- 3-star confetti: `TimelineView(.animation)` + `Canvas` — 50 particles with random angle/speed/color, gravity simulation, runs 3s
- All panels: `.glassCard()`

---

### Phase 6 — Navigation & Gamification Views

**`Views/HomeView.swift`**
- **Streak banner** (`flame.fill`, gold): pulse animation `.scaleEffect(1 + 0.03 * sin(time))` via `TimelineView`
- **XP progress bar**: `GeometryReader` fill rect, level number on left, "Level N+1" on right, `.glassSurface()`
- **"Random Chord Challenge" card**: prominent full-width card with shuffle icon → navigates to `RandomChordView`
- **Exercise grid**: `LazyVGrid(columns: adaptiveColumns)` where columns = 2 on iPhone, 3 on iPad/macOS
- `ExerciseCardView`: `.glassCard()`, title, difficulty pips (●●●○○), star rating if completed (gold), lock overlay if locked
- Each card navigates to `ExerciseView(exercise:)`

**`Views/RandomChordView.swift`**
```swift
@Observable class RandomChordState {
    var currentChord: Chord = ChordLibrary.random()
    var filterType: ChordType? = nil   // nil = any type
    var activeExercise: ChantExercise? = nil
    
    func newChord() { currentChord = filterType.map { ChordLibrary.random(type: $0) } ?? ChordLibrary.random() }
    func buildExercise() -> ChantExercise  // creates a dynamic mimicChord exercise
}
```
- Chord type filter picker: `Picker` with all 7 chord types + "Any"
- Big chord display: name + type badge + constituent note pills
- "Play Chord" + "Play Each Note" buttons
- "🎲 New Chord" button → regenerates
- "Start Challenge" → pushes `ExerciseView(exercise: state.buildExercise())`
- Score recorded under `exerciseID = "random_\(chord.id)"` in performanceHistory

**`Views/AchievementsView.swift`**
- Level panel at top: big level number, `levelTitle`, progress bar (`.glassSurface()`, zero radius)
- Streak section: flame + count + "day streak"
- Achievement grid: `LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))])` of `AchievementBadge`
  - Earned: gold gradient background, full opacity
  - Locked: `.thinMaterial` bg, `.opacity(0.4)`, lock icon overlay
- Statistics row: total exercises completed, total XP, best streak

**`Views/ContentView.swift`**
```swift
struct ContentView: View {
    @State private var progress = GameProgress()
    @State private var pitchDetector = AudioPitchDetector()
    @State private var synthesizer = AudioSynthesizer()
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            RandomChordView()
                .tabItem { Label("Random", systemImage: "shuffle") }
            ExerciseListView()
                .tabItem { Label("Practice", systemImage: "music.note.list") }
            AchievementsView()
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
        }
        .environmentObject(progress)
        .environmentObject(pitchDetector)
        .environmentObject(synthesizer)
        #if os(macOS)
        .frame(minWidth: 800, minHeight: 600)
        #endif
        .onAppear { progress = PersistenceManager.shared.load() }
        .onChange(of: progress.totalXP) { PersistenceManager.shared.save(progress) }
    }
}
```

**`ChantTrainerApp.swift`**
```swift
@main
struct ChantTrainerApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
        #if os(macOS)
            .defaultSize(width: 1100, height: 750)
        #endif
    }
}
```

---

### Phase 7 — Wire & Polish

**Goal**: End-to-end flow works. Run app in Xcode, test each path manually.

Checklist:
- [ ] Microphone permission dialog appears on first launch (macOS + iOS)
- [ ] Pitch meter needle moves when singing/speaking
- [ ] `sustainNote` exercise: countdown → active → results
- [ ] `mimicChord` exercise: countdown → chord playback (hear full chord + arpeggio) → active per note → results
- [ ] Random chord mode: tap "New Chord" cycles through 84 chords; "Start Challenge" works end-to-end
- [ ] Stars animate in ResultsView; confetti fires on 3-star
- [ ] XP increments, level advances, streak updates on practice
- [ ] Performance history accumulated (check via debug breakpoint in PersistenceManager)
- [ ] Trend chart in ResultsView shows after 3+ attempts on same exercise
- [ ] All corners are sharp (zero radius) — inspect every card in UI
- [ ] Dark mode: `.ultraThinMaterial` glass adapts, all colors look correct
- [ ] Light mode: same check
- [ ] iOS iPhone layout: VStack in ExerciseView, 2-column grid
- [ ] iPad layout: 3-column grid, HStack in ExerciseView

---

## Design Rules (NEVER violate)

1. **Zero corner radius**: Use `Rectangle()` clip everywhere. Never `RoundedRectangle`. Never `.cornerRadius()`.
2. **Glassmorphism**: Cards → `.glassCard()`. Surfaces → `.glassSurface()`. No flat opaque fills for panels.
3. **System colors only**: `Color.primary`, `Color.secondary`, `Color.accentColor`, `.green`, `.yellow`, `.orange`, `.red`. No hex colors. No hardcoded `Color(red:green:blue:)`.
4. **Dark/light mode**: Never test in only one mode. Both must work (system colors + materials handle this automatically).
5. **No comments** unless the WHY is non-obvious (e.g., the YIN algorithm math, the iOS audio session setup order).
6. **No external dependencies**: Every import must be an Apple framework (`SwiftUI`, `AVFoundation`, `Accelerate`, `Charts`).
