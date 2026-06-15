import Foundation
import Observation

@Observable
final class GameProgress {
    var totalXP: Int = 0
    var currentLevel: Int = 1
    var streakDays: Int = 0
    var lastPracticeDate: Date? = nil
    var completedExerciseIDs: Set<String> = []
    var starRatings: [String: Int] = [:]
    var performanceHistory: [String: [PerformanceEntry]] = [:]
    var achievements: Set<String> = []

    static let levelThresholds = [0, 100, 250, 500, 1000, 2000, Int.max]

    static let achievementDefs: [(id: String, title: String, icon: String, description: String)] = [
        ("first_note",         "First Note",        "music.note",       "Complete your first exercise"),
        ("perfect_beginner",   "Perfect Start",     "star.fill",        "Get 3 stars on a beginner exercise"),
        ("beginner_graduate",  "Graduate",          "graduationcap",    "Complete all beginner exercises"),
        ("chord_explorer",     "Chord Explorer",    "pianokeys",        "Complete your first chord exercise"),
        ("3_star_sweep",       "Star Collector",    "sparkles",         "Get 3 stars on 5 different exercises"),
        ("week_streak",        "Week Warrior",      "flame.fill",       "Practice 7 days in a row"),
        ("month_streak",       "Monthly Devotee",   "calendar",         "Practice 30 days in a row"),
        ("level_5",            "Level 5",           "trophy.fill",      "Reach level 5"),
        ("chant_master",       "Chant Master",      "crown.fill",       "Complete a master difficulty exercise"),
    ]

    var levelProgress: Double {
        let thresholds = Self.levelThresholds
        let idx = min(currentLevel - 1, thresholds.count - 2)
        let lo = thresholds[idx]
        let hi = thresholds[idx + 1]
        guard hi > lo else { return 1.0 }
        return Double(totalXP - lo) / Double(hi - lo)
    }

    var xpToNextLevel: Int {
        let thresholds = Self.levelThresholds
        let idx = min(currentLevel, thresholds.count - 1)
        return max(0, thresholds[idx] - totalXP)
    }

    var levelTitle: String {
        switch currentLevel {
        case 1: return "Beginner"
        case 2: return "Novice"
        case 3: return "Chanter"
        case 4: return "Cantor"
        case 5: return "Precentor"
        default: return "Choirmaster"
        }
    }

    func recordExerciseComplete(
        id: String,
        stars: Int,
        xpEarned: Int,
        accuracy: Double,
        chordName: String? = nil
    ) {
        totalXP += xpEarned
        completedExerciseIDs.insert(id)
        if (starRatings[id] ?? 0) < stars { starRatings[id] = stars }

        let entry = PerformanceEntry(
            exerciseID: id,
            accuracyPercent: accuracy,
            stars: stars,
            xpEarned: xpEarned,
            chordName: chordName
        )
        var history = performanceHistory[id] ?? []
        history.append(entry)
        if history.count > 50 { history.removeFirst(history.count - 50) }
        performanceHistory[id] = history

        updateLevel()
        updateStreak()
        checkAchievements(exerciseID: id, stars: stars)
    }

    func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if let last = lastPracticeDate {
            let lastDay = calendar.startOfDay(for: last)
            let diff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if diff == 1 { streakDays += 1 }
            else if diff > 1 { streakDays = 1 }
        } else {
            streakDays = 1
        }
        lastPracticeDate = Date()
    }

    func recentAccuracy(for exerciseID: String, last n: Int = 5) -> Double? {
        guard let history = performanceHistory[exerciseID], !history.isEmpty else { return nil }
        let recent = Array(history.suffix(n))
        return recent.map { $0.accuracyPercent }.reduce(0, +) / Double(recent.count)
    }

    private func updateLevel() {
        let thresholds = Self.levelThresholds
        for (i, threshold) in thresholds.enumerated() {
            if totalXP < threshold {
                currentLevel = i
                return
            }
        }
        currentLevel = thresholds.count - 1
    }

    private func checkAchievements(exerciseID: String, stars: Int) {
        if !completedExerciseIDs.isEmpty { achievements.insert("first_note") }

        if let ex = ExerciseLibrary.all.first(where: { $0.id == exerciseID }) {
            if ex.difficulty == .beginner && stars == 3 { achievements.insert("perfect_beginner") }
            if ex.difficulty == .master { achievements.insert("chant_master") }
            if ex.mode == .mimicChord { achievements.insert("chord_explorer") }
        }

        let beginnerIDs = Set(ExerciseLibrary.exercises(for: .beginner).map { $0.id })
        if beginnerIDs.isSubset(of: completedExerciseIDs) { achievements.insert("beginner_graduate") }

        let threeStarCount = starRatings.values.filter { $0 == 3 }.count
        if threeStarCount >= 5 { achievements.insert("3_star_sweep") }

        if streakDays >= 7  { achievements.insert("week_streak") }
        if streakDays >= 30 { achievements.insert("month_streak") }
        if currentLevel >= 5 { achievements.insert("level_5") }
    }
}
