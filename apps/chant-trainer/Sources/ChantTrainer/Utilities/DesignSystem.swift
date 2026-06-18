import SwiftUI

enum CT {
    static let spacing: CGFloat = 16
    static let smallSpacing: CGFloat = 8
    static let largeSpacing: CGFloat = 24
    static let iconSize: CGFloat = 24
    static let cardPadding: CGFloat = 16
}

extension View {
    func glassCard() -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(Rectangle())
            .overlay(Rectangle().stroke(Color.primary.opacity(0.12), lineWidth: 1))
    }

    func glassSurface() -> some View {
        self
            .background(.thinMaterial)
            .clipShape(Rectangle())
            .overlay(Rectangle().stroke(Color.primary.opacity(0.08), lineWidth: 1))
    }

    func glassOverlay() -> some View {
        self
            .background(.regularMaterial)
            .clipShape(Rectangle())
    }
}

struct GlassButtonStyle: ButtonStyle {
    var prominent: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, CT.spacing)
            .padding(.vertical, CT.smallSpacing)
            .background(prominent ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(Material.thinMaterial))
            .clipShape(Rectangle())
            .overlay(Rectangle().stroke(Color.primary.opacity(0.15), lineWidth: 1))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ProminentGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, CT.largeSpacing)
            .padding(.vertical, CT.spacing)
            .background(Color.accentColor)
            .clipShape(Rectangle())
            .opacity(configuration.isPressed ? 0.75 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
