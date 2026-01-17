import SwiftUI

/// Achievements display showing unlocked and locked achievements
struct AchievementsView: View {
    @ObservedObject var engine: GameEngine
    
    var body: some View {
        VStack(spacing: 14) {
            Text("Achievements")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                ForEach(Achievement.allCases) { achievement in
                    AchievementRow(
                        achievement: achievement,
                        isUnlocked: engine.themeManager.unlockedAchievements.contains(achievement),
                        totalObstaclesDodged: engine.totalObstaclesDodged,
                        totalCoins: engine.totalCoinsCollected,
                        bestScore: engine.bestScore
                    )
                }
            }
        }
        .padding()
        .background(glassContainer)
    }
    
    private var glassContainer: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
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

/// Individual achievement row
struct AchievementRow: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let totalObstaclesDodged: Int
    let totalCoins: Int
    let bestScore: Int
    
    private var progress: String {
        switch achievement {
        case .dodger100:
            return "\(totalObstaclesDodged) / 100"
        case .wealthy:
            return "\(totalCoins) / 1000"
        case .diamondHunter:
            return "\(bestScore) / 5000"
        }
    }
    
    private var progressPercent: Double {
        switch achievement {
        case .dodger100:
            return min(1.0, Double(totalObstaclesDodged) / 100.0)
        case .wealthy:
            return min(1.0, Double(totalCoins) / 1000.0)
        case .diamondHunter:
            return min(1.0, Double(bestScore) / 5000.0)
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: achievement.icon)
                .font(.title2)
                .foregroundStyle(isUnlocked ? .yellow : .gray)
                .frame(width: 40)
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(achievement.rawValue)
                        .font(.subheadline.bold())
                        .foregroundStyle(isUnlocked ? .white : .gray)
                    
                    if isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption)
                    }
                }
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                
                if !isUnlocked {
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))
                            
                            // Progress
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.yellow.opacity(0.6))
                                .frame(width: geo.size.width * progressPercent)
                        }
                    }
                    .frame(height: 6)
                    
                    Text(progress)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
                
                // Reward description
                Text(rewardDescription)
                    .font(.caption2)
                    .foregroundStyle(.cyan.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isUnlocked ? Color.yellow.opacity(0.15) : Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isUnlocked ? Color.yellow.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    private var rewardDescription: String {
        switch achievement.reward {
        case .playerColor(let index):
            if index < ThemeManager.extendedPlayerColorNames.count {
                return "Reward: \(ThemeManager.extendedPlayerColorNames[index]) skin"
            }
            return "Reward: Special skin"
        case .trailEffect(let effect):
            return "Reward: \(effect.rawValue) trail"
        }
    }
}
