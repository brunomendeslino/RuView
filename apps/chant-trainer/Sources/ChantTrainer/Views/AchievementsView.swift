import SwiftUI

struct AchievementsView: View {
    var progress: GameProgress

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: CT.spacing)]

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: CT.largeSpacing) {
                        levelPanel
                        statsRow
                        achievementGrid
                    }
                    .padding(CT.largeSpacing)
                }
            }
            .navigationTitle("Progress")
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [Color(white: 0.05), Color(white: 0.12)],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    private var levelPanel: some View {
        VStack(spacing: CT.smallSpacing) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Level \(progress.currentLevel)")
                        .font(.largeTitle.bold())
                    Text(progress.levelTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "crown.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.yellow)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.primary.opacity(0.1))
                    Rectangle()
                        .fill(LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * progress.levelProgress)
                        .animation(.spring(duration: 0.8), value: progress.levelProgress)
                }
            }
            .frame(height: 8)
            .clipShape(Rectangle())
            .overlay(Rectangle().stroke(Color.primary.opacity(0.15), lineWidth: 1))

            HStack {
                Text("\(progress.totalXP) XP")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(progress.xpToNextLevel) XP to Level \(progress.currentLevel + 1)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(CT.cardPadding)
        .glassSurface()
    }

    private var statsRow: some View {
        HStack(spacing: CT.spacing) {
            StatCell(value: "\(progress.streakDays)", label: "Day Streak", icon: "flame.fill", color: .orange)
            StatCell(value: "\(progress.completedExerciseIDs.count)", label: "Completed", icon: "checkmark.circle.fill", color: .green)
            StatCell(value: "\(progress.achievements.count)", label: "Badges", icon: "star.fill", color: .yellow)
        }
    }

    private var achievementGrid: some View {
        LazyVGrid(columns: columns, spacing: CT.spacing) {
            ForEach(GameProgress.achievementDefs, id: \.id) { def in
                AchievementBadge(
                    id: def.id,
                    title: def.title,
                    description: def.description,
                    iconName: def.icon,
                    isEarned: progress.achievements.contains(def.id)
                )
            }
        }
    }
}

private struct StatCell: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.title2.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(CT.cardPadding)
        .glassCard()
    }
}

private struct AchievementBadge: View {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let isEarned: Bool

    var body: some View {
        VStack(spacing: CT.smallSpacing) {
            ZStack {
                Rectangle()
                    .fill(isEarned ?
                          AnyShapeStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)) :
                          AnyShapeStyle(Material.ultraThinMaterial))
                    .frame(width: 64, height: 64)
                    .overlay(Rectangle().stroke(Color.primary.opacity(0.15), lineWidth: 1))

                Image(systemName: iconName)
                    .font(.title)
                    .foregroundStyle(isEarned ? .white : Color.primary.opacity(0.3))

                if !isEarned {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .offset(x: 18, y: 18)
                }
            }

            Text(title)
                .font(.caption.bold())
                .multilineTextAlignment(.center)
            Text(description)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(CT.smallSpacing)
        .opacity(isEarned ? 1.0 : 0.5)
        .glassCard()
    }
}
