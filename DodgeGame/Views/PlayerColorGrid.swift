import SwiftUI

/// Player color selection grid component
struct PlayerColorGrid: View {
    @ObservedObject var engine: GameEngine
    
    var body: some View {
        VStack(spacing: 14) {
            Text("Player Color")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.8))
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 10) {
                ForEach(0..<GameSettings.playerColors.count, id: \.self) { index in
                    ColorButton(
                        index: index,
                        engine: engine
                    )
                }
            }
            
            CoinsDisplay(totalCoins: engine.totalCoinsCollected)
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

/// Individual color button in the grid
struct ColorButton: View {
    let index: Int
    @ObservedObject var engine: GameEngine
    
    private var color: Color {
        GameSettings.playerColors[index]
    }
    
    private var name: String {
        GameSettings.playerColorNames[index]
    }
    
    private var cost: Int {
        GameSettings.playerColorCosts[index]
    }
    
    private var isUnlocked: Bool {
        engine.unlockedColors.contains(index)
    }
    
    private var isSelected: Bool {
        engine.settings.playerColorIndex == index
    }
    
    var body: some View {
        Button {
            handleTap()
        } label: {
            VStack(spacing: 4) {
                colorCircle
                
                Text(name)
                    .font(.caption2)
                    .foregroundStyle(.white)
                
                if !isUnlocked {
                    lockBadge
                }
            }
            .padding(10)
            .background(buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var colorCircle: some View {
        Circle()
            .fill(color)
            .frame(width: 32, height: 32)
            .overlay(
                Circle()
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
            )
            .shadow(color: isSelected ? color.opacity(0.6) : .clear, radius: 10)
    }
    
    private var lockBadge: some View {
        HStack(spacing: 2) {
            Image(systemName: "lock.fill")
                .font(.system(size: 8))
            Text("\(cost)")
                .font(.caption2)
        }
        .foregroundStyle(engine.canAffordColor(index: index) ? .yellow : .gray)
    }
    
    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(isSelected ? color.opacity(0.2) : Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 1)
            )
    }
    
    private func handleTap() {
        if isUnlocked {
            engine.selectColor(index: index)
        } else if engine.canAffordColor(index: index) {
            _ = engine.unlockColor(index: index)
        }
    }
}

/// Coins display badge
struct CoinsDisplay: View {
    let totalCoins: Int
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "star.circle.fill")
                .foregroundStyle(.yellow)
            Text("Your coins: \(totalCoins)")
                .font(.caption.bold())
                .foregroundStyle(.yellow)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(Color.yellow.opacity(0.15))
                .overlay(Capsule().stroke(Color.yellow.opacity(0.3), lineWidth: 1))
        )
    }
}
