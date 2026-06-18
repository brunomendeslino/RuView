import SwiftUI

struct NoteDisplayView: View {
    let targetNote: MusicalNote
    let centsOff: Double
    let isDetecting: Bool
    var showSolfege: Bool = false

    @State private var pulseScale: Double = 1.0
    @State private var sparkleProgress: Double = 0.0
    @State private var showSparkle: Bool = false

    private var feedbackColor: Color {
        guard isDetecting else { return .primary }
        let a = abs(centsOff)
        if a < 10 { return .green }
        if a < 20 { return .yellow }
        if a < 30 { return .orange }
        return .red
    }

    private var noteFontSize: CGFloat {
        #if os(iOS)
        return 80
        #else
        return 120
        #endif
    }

    var body: some View {
        ZStack {
            if showSparkle {
                SparkleCanvas(progress: sparkleProgress)
            }

            VStack(spacing: CT.smallSpacing) {
                Text(showSolfege ? targetNote.name.solfege : targetNote.name.displayName)
                    .font(.system(size: noteFontSize, weight: .black, design: .default))
                    .foregroundStyle(feedbackColor)
                    .animation(.easeInOut(duration: 0.1), value: centsOff)
                    .scaleEffect(isDetecting ? 1.0 : pulseScale)

                HStack(spacing: 4) {
                    Text("Octave")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(targetNote.octave)")
                        .font(.caption).bold()
                        .padding(4)
                        .glassCard()
                }

                if isDetecting {
                    let cents = Int(centsOff)
                    Text(cents == 0 ? "±0¢" : (cents > 0 ? "+\(cents)¢" : "\(cents)¢"))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                } else {
                    Text("Sing this note")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(CT.largeSpacing)
        .glassSurface()
        .onAppear { startPulse() }
        .onChange(of: isDetecting) { _, detecting in
            if !detecting { startPulse() }
        }
        .onChange(of: centsOff) { _, newVal in
            if isDetecting && abs(newVal) < 10 { triggerSparkle() }
        }
    }

    private func startPulse() {
        guard !isDetecting else { return }
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.03
        }
    }

    private func triggerSparkle() {
        guard !showSparkle else { return }
        showSparkle = true
        sparkleProgress = 0
        withAnimation(.linear(duration: 0.6)) { sparkleProgress = 1.0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            showSparkle = false
            sparkleProgress = 0
        }
    }
}

private struct SparkleCanvas: View {
    let progress: Double

    var body: some View {
        Canvas { ctx, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let maxRadius = min(size.width, size.height) * 0.45
            for i in 0..<8 {
                let angle = Double(i) * .pi / 4
                let radius = maxRadius * progress
                let x = center.x + radius * cos(angle)
                let y = center.y + radius * sin(angle)
                let dotSize = CGFloat(8 * (1.0 - progress))
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x - dotSize/2, y: y - dotSize/2, width: dotSize, height: dotSize)),
                    with: .color(.yellow.opacity(1.0 - progress))
                )
            }
        }
    }
}
