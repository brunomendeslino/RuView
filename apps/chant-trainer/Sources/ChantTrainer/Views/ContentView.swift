import SwiftUI

struct ContentView: View {
    @State private var progress = GameProgress()
    @State private var pitchDetector = AudioPitchDetector()

    var body: some View {
        TabView {
            HomeView(progress: progress)
                .tabItem { Label("Home", systemImage: "house.fill") }

            RandomChordView(progress: progress)
                .tabItem { Label("Random", systemImage: "shuffle") }

            ExerciseListView(progress: progress)
                .tabItem { Label("Practice", systemImage: "music.note.list") }

            AchievementsView(progress: progress)
                .tabItem { Label("Progress", systemImage: "chart.bar.fill") }
        }
        #if os(macOS)
        .frame(minWidth: 800, minHeight: 600)
        #endif
        .onAppear {
            progress = PersistenceManager.shared.load()
            Task { await pitchDetector.requestPermission() }
        }
        .onChange(of: progress.totalXP) {
            PersistenceManager.shared.save(progress)
        }
    }
}

struct ExerciseListView: View {
    var progress: GameProgress
    @State private var pitchDetector = AudioPitchDetector()

    private let allDifficulties = Difficulty.allCases

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
                        ForEach(allDifficulties, id: \.self) { difficulty in
                            difficultySection(difficulty)
                        }
                    }
                    .padding(CT.largeSpacing)
                }
            }
            .navigationTitle("Practice")
        }
    }

    private func difficultySection(_ difficulty: Difficulty) -> some View {
        let exercises = ExerciseLibrary.exercises(for: difficulty)
        let unlocked = ExerciseLibrary.unlocked(xp: progress.totalXP, completedIDs: progress.completedExerciseIDs)

        return VStack(alignment: .leading, spacing: CT.smallSpacing) {
            HStack {
                Circle().fill(difficulty.color).frame(width: 10, height: 10)
                Text(difficulty.displayName)
                    .font(.subheadline.bold())
                    .foregroundStyle(difficulty.color)
                Spacer()
                Text("\(exercises.filter { unlocked.contains(where: { u in u.id == $0.id }) }.count)/\(exercises.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
