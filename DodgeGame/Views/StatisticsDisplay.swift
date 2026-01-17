import SwiftUI

/// Statistics display component showing games, coins, and best score
struct StatisticsDisplay: View {
    let totalGamesPlayed: Int
    let totalCoinsCollected: Int
    let bestScore: Int
    
    var body: some View {
        HStack(spacing: 16) {
            StatItem(value: "\(totalGamesPlayed)", label: "Games", color: .white)
            
            Divider()
                .background(Color.white.opacity(0.3))
                .frame(height: 30)
            
            StatItem(value: "\(totalCoinsCollected)", label: "Total Coins", color: .yellow)
            
            Divider()
                .background(Color.white.opacity(0.3))
                .frame(height: 30)
            
            StatItem(value: "\(bestScore)", label: "Best Score", color: .green)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(glassContainer)
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
    }
    
    private var glassContainer: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.4), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
    }
}

/// Individual statistic item
struct StatItem: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}
