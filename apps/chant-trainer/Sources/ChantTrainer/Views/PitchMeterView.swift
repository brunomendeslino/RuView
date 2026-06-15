import SwiftUI

struct PitchMeterView: View {
    let centsOff: Double
    let isActive: Bool

    private var needleFraction: Double {
        (max(-50, min(50, centsOff)) + 50.0) / 100.0
    }

    var body: some View {
        VStack(spacing: CT.smallSpacing) {
            GeometryReader { geo in
                ZStack(alignment: .center) {
                    // Gradient track
                    LinearGradient(
                        stops: [
                            .init(color: .red,    location: 0.00),
                            .init(color: .orange, location: 0.25),
                            .init(color: .yellow, location: 0.375),
                            .init(color: .green,  location: 0.50),
                            .init(color: .yellow, location: 0.625),
                            .init(color: .orange, location: 0.75),
                            .init(color: .red,    location: 1.00),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .opacity(isActive ? 1.0 : 0.3)
                    .clipShape(Rectangle())

                    // Center line
                    Rectangle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: 2)

                    // Needle
                    if isActive {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 4)
                            .shadow(color: .black.opacity(0.5), radius: 2)
                            .offset(x: needleFraction * geo.size.width - geo.size.width / 2)
                            .animation(.interactiveSpring(response: 0.15, dampingFraction: 0.7), value: centsOff)
                    }
                }
            }
            .frame(height: 48)
            .glassCard()

            // Labels
            HStack {
                Text("Flat").font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Text("Perfect").font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Text("Sharp").font(.caption2).foregroundStyle(.secondary)
            }
            .opacity(isActive ? 1 : 0.4)

            if isActive {
                Text(FrequencyToNote.accuracyLabel(for: centsOff))
                    .font(.caption).bold()
                    .foregroundStyle(accuracyColor)
                    .animation(.easeInOut(duration: 0.1), value: centsOff)
            } else {
                Text("Sing to detect pitch")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(CT.cardPadding)
        .glassSurface()
    }

    private var accuracyColor: Color {
        let a = abs(centsOff)
        if a < 10 { return .green }
        if a < 20 { return .yellow }
        if a < 30 { return .orange }
        return .red
    }
}
