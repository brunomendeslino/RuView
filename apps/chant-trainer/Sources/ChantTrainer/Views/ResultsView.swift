import SwiftUI
import Charts

struct ResultsView: View {
    let exercise: ChantExercise
    let stars: Int
    let xpEarned: Int
    let accuracy: Double
    let newAchievements: [String]
    var progressModel: GameProgress
    let onHome: () -> Void

    @State private var visibleStars: Int = 0
    @State private var displayXP: Int = 0
    @State private var showAchievement: Bool = false
    @State private var showConfetti: Bool = false
    @State private var confettiTime: Double = 0
    @Environment(\.dismiss) private var dismiss

    private var trendData: [(index: Int, accuracy: Double)]? {
        guard let recent = progressModel.performanceHistory[exercise.id], recent.count >= 3 else { return nil }
        return Array(recent.suffix(5).enumerated()).map { ($0.offset, $0.element.accuracyPercent) }
    }

    var body: some View {
        NavigationStack {
        ZStack {
            LinearGradient(colors: [Color(white: 0.05), Color(white: 0.12)],
                startPoint: .topLeading, endPoint: .bottomTrailing).ignoresSafeArea()
            if showConfetti { ConfettiCanvas(time: confettiTime).ignoresSafeArea().allowsHitTesting(false) }
            ScrollView {
                VStack(spacing: CT.largeSpacing) {
                    Text(exercise.title).font(.title2.bold()).foregroundStyle(.primary)
                    HStack(spacing: CT.spacing) {
                        ForEach(0..<3) { i in
                            Image(systemName: i < visibleStars ? "star.fill" : "star").font(.largeTitle)
                                .foregroundStyle(i < visibleStars ? .yellow : Color.primary.opacity(0.3))
                                .scaleEffect(i < visibleStars ? 1.0 : 0.6).opacity(i < visibleStars ? 1.0 : 0.4)
                                .animation(.spring(response: 0.4, dampingFraction: 0.5).delay(Double(i) * 0.3), value: visibleStars)
                        }
                    }
                    VStack(spacing: 4) {
                        Text("+\(displayXP) XP").font(.system(size: 48, weight: .black, design: .rounded)).foregroundStyle(.yellow)
                        Text("\(Int(accuracy * 100))% Accuracy").font(.headline).foregroundStyle(.secondary)
                    }.padding(CT.largeSpacing).glassCard()
                    if let trend = trendData {
                        VStack(alignment: .leading, spacing: CT.smallSpacing) {
                            Text("Your Progress").font(.caption.bold()).foregroundStyle(.secondary)
                            Chart(trend, id: \.index) { point in
                                LineMark(x: .value("Attempt", point.index + 1), y: .value("Accuracy", point.accuracy * 100))
                                    .foregroundStyle(Color.accentColor)
                                PointMark(x: .value("Attempt", point.index + 1), y: .value("Accuracy", point.accuracy * 100))
                                    .foregroundStyle(Color.accentColor)
                            }
                            .chartYScale(domain: 0...100)
                            .chartYAxis { AxisMarks(values: [0, 50, 100]) { val in
                                AxisValueLabel { Text("\(val.as(Int.self) ?? 0)%").font(.caption2) }
                                AxisGridLine()
                            }}
                            .chartXAxis(.hidden).frame(height: 80)
                            let improving = (trend.last?.accuracy ?? 0) >= (trend.first?.accuracy ?? 0)
                            Text(improving ? "Improving!" : "Keep practicing!").font(.caption)
                                .foregroundStyle(improving ? .green : .orange)
                        }.padding(CT.cardPadding).glassCard()
                    }
                    if showAchievement, let firstNew = newAchievements.first,
                       let def = GameProgress.achievementDefs.first(where: { $0.id == firstNew }) {
                        HStack(spacing: CT.spacing) {
                            Image(systemName: def.icon).font(.title2).foregroundStyle(.yellow)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Achievement Unlocked!").font(.caption.bold()).foregroundStyle(.secondary)
                                Text(def.title).font(.headline)
                            }
                            Spacer()
                        }.padding(CT.cardPadding).glassCard()
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    VStack(spacing: CT.smallSpacing) {
                        if let next = ExerciseLibrary.next(after: exercise.id) {
                            NavigationLink {
                                ExerciseView(exercise: next, progress: progressModel, pitchDetector: AudioPitchDetector())
                            } label: {
                                Label("Next Exercise", systemImage: "arrow.right").font(.headline).foregroundStyle(.white).frame(maxWidth: .infinity)
                            }.buttonStyle(ProminentGlassButtonStyle())
                        }
                        Button { dismiss(); onHome() } label: {
                            Label("Back to Home", systemImage: "house").frame(maxWidth: .infinity)
                        }.buttonStyle(GlassButtonStyle())
                    }
                }.padding(CT.largeSpacing)
            }
        }
        .onAppear {
            animateStars(); animateXP()
            if stars == 3 { startConfetti() }
            if !newAchievements.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.spring()) { showAchievement = true }
                }
            }
        }
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        }
    }

    private func animateStars() {
        guard stars > 0 else { return }
        for i in 1...stars {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i - 1) * 0.35) { visibleStars = i }
        }
    }
    private func animateXP() {
        let steps = 30; let target = xpEarned
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * (1.5 / Double(steps))) {
                displayXP = Int(Double(target) * Double(i) / Double(steps))
                if i == steps { displayXP = target }
            }
        }
    }
    private func startConfetti() {
        showConfetti = true; let start = Date()
        Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { timer in
            confettiTime = Date().timeIntervalSince(start)
            if confettiTime > 3.0 { timer.invalidate(); showConfetti = false }
        }
    }
}

private struct ConfettiCanvas: View {
    let time: Double
    struct Particle {
        let x, angle, speed, size: Double; let color: Color
        static func generate(seed: Int) -> Particle {
            let colors: [Color] = [.red, .yellow, .green, .blue, .purple, .orange, .pink]
            return Particle(x: Double(seed * 37 % 100) / 100.0, angle: Double(seed * 13 % 360) * .pi / 180,
                speed: 0.15 + Double(seed * 7 % 30) / 100.0, size: 6 + Double(seed % 8), color: colors[seed % colors.count])
        }
    }
    private let particles = (0..<50).map { Particle.generate(seed: $0) }
    var body: some View {
        Canvas { ctx, size in
            for p in particles {
                let x = (p.x + cos(p.angle) * p.speed * time).truncatingRemainder(dividingBy: 1.0) * size.width
                let y = (p.speed * time * 0.5 + sin(p.angle * 2) * 0.05).truncatingRemainder(dividingBy: 1.2) * size.height
                let alpha = max(0, 1.0 - time / 3.0)
                ctx.fill(Path(CGRect(x: x, y: y, width: p.size, height: p.size * 0.6)), with: .color(p.color.opacity(alpha)))
            }
        }
    }
}
