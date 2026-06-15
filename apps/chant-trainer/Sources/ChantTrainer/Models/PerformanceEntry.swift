import Foundation

struct PerformanceEntry: Codable, Identifiable {
    let id: UUID
    let date: Date
    let exerciseID: String
    let accuracyPercent: Double
    let stars: Int
    let xpEarned: Int
    let chordName: String?

    init(
        exerciseID: String,
        accuracyPercent: Double,
        stars: Int,
        xpEarned: Int,
        chordName: String? = nil
    ) {
        self.id = UUID()
        self.date = Date()
        self.exerciseID = exerciseID
        self.accuracyPercent = accuracyPercent
        self.stars = stars
        self.xpEarned = xpEarned
        self.chordName = chordName
    }
}
