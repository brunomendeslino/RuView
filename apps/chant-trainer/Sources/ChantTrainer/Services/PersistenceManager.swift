import Foundation

final class PersistenceManager {
    static let shared = PersistenceManager()
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Keys {
        static let totalXP            = "ct_totalXP"
        static let currentLevel       = "ct_currentLevel"
        static let streakDays         = "ct_streakDays"
        static let lastPracticeDate   = "ct_lastPracticeDate"
        static let completedIDs       = "ct_completedIDs"
        static let starRatings        = "ct_starRatings"
        static let performanceHistory = "ct_performanceHistory"
        static let achievements       = "ct_achievements"
    }

    func save(_ progress: GameProgress) {
        defaults.set(progress.totalXP,      forKey: Keys.totalXP)
        defaults.set(progress.currentLevel, forKey: Keys.currentLevel)
        defaults.set(progress.streakDays,   forKey: Keys.streakDays)
        defaults.set(progress.lastPracticeDate, forKey: Keys.lastPracticeDate)

        if let data = try? encoder.encode(Array(progress.completedExerciseIDs)) {
            defaults.set(data, forKey: Keys.completedIDs)
        }
        if let data = try? encoder.encode(progress.starRatings) {
            defaults.set(data, forKey: Keys.starRatings)
        }
        if let data = try? encoder.encode(progress.performanceHistory) {
            defaults.set(data, forKey: Keys.performanceHistory)
        }
        if let data = try? encoder.encode(Array(progress.achievements)) {
            defaults.set(data, forKey: Keys.achievements)
        }
    }

    func load() -> GameProgress {
        let p = GameProgress()
        p.totalXP      = defaults.integer(forKey: Keys.totalXP)
        p.currentLevel = max(1, defaults.integer(forKey: Keys.currentLevel))
        p.streakDays   = defaults.integer(forKey: Keys.streakDays)
        p.lastPracticeDate = defaults.object(forKey: Keys.lastPracticeDate) as? Date

        if let data = defaults.data(forKey: Keys.completedIDs),
           let arr = try? decoder.decode([String].self, from: data) {
            p.completedExerciseIDs = Set(arr)
        }
        if let data = defaults.data(forKey: Keys.starRatings),
           let dict = try? decoder.decode([String: Int].self, from: data) {
            p.starRatings = dict
        }
        if let data = defaults.data(forKey: Keys.performanceHistory),
           let history = try? decoder.decode([String: [PerformanceEntry]].self, from: data) {
            p.performanceHistory = history
        }
        if let data = defaults.data(forKey: Keys.achievements),
           let arr = try? decoder.decode([String].self, from: data) {
            p.achievements = Set(arr)
        }
        return p
    }

    func reset() {
        [Keys.totalXP, Keys.currentLevel, Keys.streakDays, Keys.lastPracticeDate,
         Keys.completedIDs, Keys.starRatings, Keys.performanceHistory, Keys.achievements
        ].forEach { defaults.removeObject(forKey: $0) }
    }
}
