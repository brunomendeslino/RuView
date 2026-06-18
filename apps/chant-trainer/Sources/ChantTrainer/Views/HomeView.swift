import SwiftUI

struct HomeView: View {
    var progress: GameProgress
    @State private var pitchDetector = AudioPitchDetector()

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var hSizeClass
    private var gridColumns: [GridItem] {
        hSizeClass == .compact
            ? [GridItem(.flexible()), GridItem(.flexible())]
            : [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    }
    #else
    private let gridColumns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
    #endif

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color(white: 0.05), Color(white: 0.12)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: CT.largeSpacing) {
                        streakBanner
                        xpBar
                        exerciseGrid
                    }
                    .padding(CT.largeSpacing)
                }
            }
            .navigationTitle("ChantTrainer")
        }
    }

    private var streakBanner: some View {
        HStack(spacing: CT.spacing) {
            TimelineView(.animation) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                Image(systemName: "flame.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.orange)
                    .scaleEffect(1.0 + 0.04 * abs(sin(t * 2)))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(progress.streakDays) Day Streak").font(.title2.bold())
                Text(progress.streakDays == 0 ? "Start practicing today!" :
                     progress.streakDays == 1 ? "Great start!" : "Keep it up!")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "star.fill").foregroundStyle(.yellow)
            Text("Lv \(progress.currentLevel)").font(.headline.bold())
        }
        .padding(CT.cardPadding)
        .glassSurface()
    }

    private var xpBar: some View {
        VStack(spacing: CT.smallSpacing) {
            HStack {
                Text(progress.levelTitle).font(.caption.bold()).foregroundStyle(.secondary)
                Spacer()
                Text("\(progress.xpToNextLevel) XP to Level \(progress.currentLevel + 1)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color.primary.opacity(0.1))
                    Rectangle()
                        .fill(LinearGradient(colors: [.accentColor, .purple], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * progress.levelProgress)
                        .animation(.spring(duration: 0.6), value: progress.levelProgress)
                }
            }
            .frame(height: 8)
            .clipShape(Rectangle())
            .overlay(Rectangle().stroke(Color.primary.opacity(0.15), lineWidth: 1))
        }
        .padding(CT.cardPadding)
        .glassSurface()
    }

    private var exerciseGrid: some View {
        VStack(alignment: .leading, spacing: CT.spacing) {
            ForEach(Difficulty.allCases, id: \.self) { difficulty in
                let exercises = ExerciseLibrary.exercises(for: difficulty)
                let unlocked = ExerciseLibrary.unlocked(xp: progress.totalXP, completedIDs: progress.completedExerciseIDs)

                VStack(alignment: .leading, spacing: CT.smallSpacing) {
                    HStack {
                        Circle().fill(difficulty.color).frame(width: 8, height: 8)
                        Text(difficulty.displayName).font(.subheadline.bold()).foregroundStyle(difficulty.color)
                    }
                    LazyVGrid(columns: gridColumns, spacing: CT.smallSpacing) {
                        ForEach(exercises) { exercise in
                            let isLocked = !unlocked.contains(where: { $0.id == exercise.id })
                            let stars = progress.starRatings[exercise.id]
                            NavigationLink {
                                ExerciseView(exercise: exercise, progress: progress, pitchDetector: pitchDetector)
                            } label: {
                                ExerciseCardView(exercise: exercise, stars: stars, isLocked: isLocked)
                            }
                            .disabled(isLocked)
                        }
                    }
                }
            }
        }
    }
}

struct ExerciseCardView: View {
    let exercise: ChantExercise
    let stars: Int?
    let isLocked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: CT.smallSpacing) {
            HStack {
                modeIcon.font(.caption).foregroundStyle(exercise.difficulty.color)
                Spacer()
                if let s = stars {
                    HStack(spacing: 2) {
                        ForEach(0..<3) { i in
                            Image(systemName: i < s ? "star.fill" : "star")
                                .font(.caption2)
                                .foregroundStyle(i < s ? .yellow : Color.primary.opacity(0.3))
                        }
                    }
                }
            }
            Text(exercise.title).font(.caption.bold()).foregroundStyle(.primary).lineLimit(1)
            Text(exercise.subtitle).font(.caption2).foregroundStyle(.secondary).lineLimit(2)
            HStack(spacing: 3) {
                ForEach(1...5, id: \.self) { i in
                    Circle()
                        .fill(i <= exercise.difficulty.rawValue ? exercise.difficulty.color : Color.primary.opacity(0.2))
                        .frame(width: 5, height: 5)
                }
            }
        }
        .padding(CT.smallSpacing)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassCard()
        .overlay(lockedOverlay)
    }

    @ViewBuilder
    private var lockedOverlay: some View {
        if isLocked {
            Rectangle().fill(Color.black.opacity(0.5))
                .overlay {
                    VStack(spacing: 4) {
                        Image(systemName: "lock.fill").foregroundStyle(.white)
                        Text("\(exercise.unlockXP) XP").font(.caption2).foregroundStyle(.white.opacity(0.8))
                    }
                }
        }
    }

    private var modeIcon: Image {
        switch exercise.mode {
        case .sustainNote: return Image(systemName: "music.note")
        case .mimicNote:   return Image(systemName: "ear")
        case .mimicChord:  return Image(systemName: "pianokeys")
        }
    }
}
