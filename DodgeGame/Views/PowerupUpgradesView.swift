import SwiftUI

struct PowerupUpgradesView: View {
    @ObservedObject var engine: GameEngine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            HStack {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.yellow)
                Text("Powerup Upgrades")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
            }
            .padding(.bottom, 4)
            
            // Available coins
            HStack {
                Image(systemName: "star.circle.fill")
                    .foregroundColor(.yellow)
                Text("Available Coins: \(engine.totalCoinsCollected)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.bottom, 8)
            
            // Upgrade options
            VStack(spacing: 8) {
                upgradeRow(
                    icon: "shield.fill",
                    color: .cyan,
                    name: "Shield Duration",
                    currentLevel: engine.powerupUpgrades.shieldDurationLevel,
                    maxLevel: PowerupUpgrade.maxLevel,
                    cost: PowerupUpgrade.upgradeCost,
                    benefit: "+1s duration",
                    type: "shield"
                )
                
                upgradeRow(
                    icon: "magnet",
                    color: .purple,
                    name: "Magnet Radius",
                    currentLevel: engine.powerupUpgrades.magnetRadiusLevel,
                    maxLevel: PowerupUpgrade.maxLevel,
                    cost: PowerupUpgrade.upgradeCost,
                    benefit: "+20 range",
                    type: "magnet"
                )
                
                upgradeRow(
                    icon: "clock.fill",
                    color: .orange,
                    name: "Slow-Mo Duration",
                    currentLevel: engine.powerupUpgrades.slowMoDurationLevel,
                    maxLevel: PowerupUpgrade.maxLevel,
                    cost: PowerupUpgrade.upgradeCost,
                    benefit: "+1s duration",
                    type: "slowMo"
                )
                
                upgradeRow(
                    icon: "snowflake",
                    color: .blue,
                    name: "Freeze Duration",
                    currentLevel: engine.powerupUpgrades.freezeDurationLevel,
                    maxLevel: PowerupUpgrade.maxLevel,
                    cost: PowerupUpgrade.upgradeCost,
                    benefit: "+1s duration",
                    type: "freeze"
                )
            }
        }
        .padding(16)
        .glassBackground()
    }
    
    @ViewBuilder
    private func upgradeRow(
        icon: String,
        color: Color,
        name: String,
        currentLevel: Int,
        maxLevel: Int,
        cost: Int,
        benefit: String,
        type: String
    ) -> some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.white)
                
                Text("\(benefit) • Level \(currentLevel)/\(maxLevel)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Upgrade button
            if currentLevel < maxLevel {
                Button {
                    if engine.upgradePowerup(type) {
                        // Success feedback
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "star.circle.fill")
                            .font(.caption)
                        Text("\(cost)")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(engine.canUpgradePowerup(type) ? .black : .white.opacity(0.5))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        engine.canUpgradePowerup(type) 
                            ? Color.yellow
                            : Color.gray.opacity(0.3)
                    )
                    .clipShape(Capsule())
                }
                .disabled(!engine.canUpgradePowerup(type))
            } else {
                // Max level indicator
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                    Text("MAX")
                        .font(.caption.weight(.semibold))
                }
                .foregroundColor(.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.2))
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
