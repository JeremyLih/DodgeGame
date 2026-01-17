import SwiftUI

/// Powerups legend display component
struct PowerupsLegend: View {
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                PowerupLegendItem(icon: "star.circle.fill", color: .yellow, text: "Coins")
                PowerupLegendItem(icon: "shield.fill", color: .cyan, text: "Shield/Life")
                PowerupLegendItem(icon: "clock.fill", color: .orange, text: "Slow")
            }
            HStack(spacing: 10) {
                PowerupLegendItem(icon: "magnet", color: .purple, text: "Magnet")
                PowerupLegendItem(icon: "bolt.fill", color: .green, text: "Speed")
                PowerupLegendItem(icon: "snowflake", color: .blue, text: "Freeze")
            }
            HStack(spacing: 10) {
                PowerupLegendItem(icon: "flame.fill", color: .red, text: "Bomb")
                Spacer().frame(width: 60)
                Spacer().frame(width: 60)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(glassContainer)
    }
    
    private var glassContainer: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

/// Individual powerup legend item
struct PowerupLegendItem: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 14))
                .shadow(color: color.opacity(0.5), radius: 4)
            Text(text)
                .font(.caption2.weight(.medium))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
