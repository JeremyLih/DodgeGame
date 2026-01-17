import SwiftUI

/// Reusable glass morphism background style for panels
struct GlassBackgroundStyle: ViewModifier {
    var cornerRadius: CGFloat = 28
    var colors: [Color] = [
        Color.white.opacity(0.15),
        Color.white.opacity(0.05),
        Color.cyan.opacity(0.08),
        Color.purple.opacity(0.05)
    ]
    var borderColors: [Color] = [
        Color.white.opacity(0.6),
        Color.cyan.opacity(0.4),
        Color.white.opacity(0.2),
        Color.purple.opacity(0.3)
    ]
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Liquid glass effect with multiple layers
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    // Gradient overlay for depth
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: colors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Border gradient for liquid glass effect
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: borderColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            .shadow(color: .cyan.opacity(0.2), radius: 30, y: 15)
    }
}

extension View {
    func glassBackground(cornerRadius: CGFloat = 28, colors: [Color]? = nil, borderColors: [Color]? = nil) -> some View {
        modifier(GlassBackgroundStyle(
            cornerRadius: cornerRadius,
            colors: colors ?? [
                Color.white.opacity(0.15),
                Color.white.opacity(0.05),
                Color.cyan.opacity(0.08),
                Color.purple.opacity(0.05)
            ],
            borderColors: borderColors ?? [
                Color.white.opacity(0.6),
                Color.cyan.opacity(0.4),
                Color.white.opacity(0.2),
                Color.purple.opacity(0.3)
            ]
        ))
    }
}
