import SwiftUI

/// Theme selection component for customizing game appearance
struct ThemeSelector: View {
    @ObservedObject var engine: GameEngine
    
    var body: some View {
        VStack(spacing: 14) {
            // Obstacle themes
            ThemeSection(
                title: "Obstacle Skins",
                items: ObstacleTheme.allCases,
                isSelected: { theme in
                    engine.themeManager.selectedObstacleTheme == theme
                },
                unlockedItems: engine.themeManager.unlockedObstacleThemes,
                totalCoins: engine.totalCoinsCollected,
                onSelect: { theme in
                    engine.themeManager.select(theme)
                },
                onUnlock: { theme in
                    _ = engine.themeManager.unlock(theme, totalCoins: &engine.totalCoinsCollected)
                    engine.saveStatistics()
                },
                canUnlock: { theme in
                    engine.themeManager.canUnlock(theme, totalCoins: engine.totalCoinsCollected)
                }
            )
            
            // Background themes
            ThemeSection(
                title: "Background Themes",
                items: BackgroundTheme.allCases,
                isSelected: { theme in
                    engine.themeManager.selectedBackgroundTheme == theme
                },
                unlockedItems: engine.themeManager.unlockedBackgroundThemes,
                totalCoins: engine.totalCoinsCollected,
                onSelect: { theme in
                    engine.themeManager.select(theme)
                },
                onUnlock: { theme in
                    _ = engine.themeManager.unlock(theme, totalCoins: &engine.totalCoinsCollected)
                    engine.saveStatistics()
                },
                canUnlock: { theme in
                    engine.themeManager.canUnlock(theme, totalCoins: engine.totalCoinsCollected)
                }
            )
            
            // Particle effect packs
            ThemeSection(
                title: "Particle Effects",
                items: ParticleEffectPack.allCases,
                isSelected: { pack in
                    engine.themeManager.selectedParticleEffectPack == pack
                },
                unlockedItems: engine.themeManager.unlockedParticleEffectPacks,
                totalCoins: engine.totalCoinsCollected,
                onSelect: { pack in
                    engine.themeManager.select(pack)
                },
                onUnlock: { pack in
                    _ = engine.themeManager.unlock(pack, totalCoins: &engine.totalCoinsCollected)
                    engine.saveStatistics()
                },
                canUnlock: { pack in
                    engine.themeManager.canUnlock(pack, totalCoins: engine.totalCoinsCollected)
                }
            )
            
            // Trail effects
            TrailEffectSection(engine: engine)
        }
    }
}

/// Generic theme section for displaying theme options
struct ThemeSection<T: RawRepresentable & Hashable & CaseIterable & Identifiable>: View where T.RawValue == String {
    let title: String
    let items: [T]
    let isSelected: (T) -> Bool
    let unlockedItems: Set<T>
    let totalCoins: Int
    let onSelect: (T) -> Void
    let onUnlock: (T) -> Void
    let canUnlock: (T) -> Bool
    
    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                ForEach(items) { item in
                    ThemeButton(
                        item: item,
                        isSelected: isSelected(item),
                        isUnlocked: unlockedItems.contains(item),
                        canUnlock: canUnlock(item),
                        totalCoins: totalCoins,
                        onSelect: { onSelect(item) },
                        onUnlock: { onUnlock(item) }
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

/// Button for individual theme option
struct ThemeButton<T: RawRepresentable & Hashable>: View where T.RawValue == String {
    let item: T
    let isSelected: Bool
    let isUnlocked: Bool
    let canUnlock: Bool
    let totalCoins: Int
    let onSelect: () -> Void
    let onUnlock: () -> Void
    
    private var cost: Int {
        if let obstacleTheme = item as? ObstacleTheme {
            switch obstacleTheme.unlockRequirement {
            case .totalCoins(let cost): return cost
            default: return 0
            }
        } else if let bgTheme = item as? BackgroundTheme {
            switch bgTheme.unlockRequirement {
            case .totalCoins(let cost): return cost
            default: return 0
            }
        } else if let particlePack = item as? ParticleEffectPack {
            switch particlePack.unlockRequirement {
            case .totalCoins(let cost): return cost
            default: return 0
            }
        }
        return 0
    }
    
    var body: some View {
        Button {
            if isUnlocked {
                onSelect()
            } else if canUnlock {
                onUnlock()
            }
        } label: {
            VStack(spacing: 4) {
                Text(item.rawValue)
                    .font(.caption)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                if !isUnlocked {
                    HStack(spacing: 2) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8))
                        Text("\(cost)")
                            .font(.caption2)
                    }
                    .foregroundStyle(canUnlock ? .yellow : .gray)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    
    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(isSelected ? Color.cyan.opacity(0.2) : Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.cyan.opacity(0.5) : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
    }
}

/// Trail effect selection section
struct TrailEffectSection: View {
    @ObservedObject var engine: GameEngine
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Trail Effects")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.8))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                ForEach(TrailEffect.allCases, id: \.self) { effect in
                    TrailEffectButton(
                        effect: effect,
                        isSelected: engine.themeManager.selectedTrailEffect == effect,
                        isUnlocked: engine.themeManager.unlockedTrailEffects.contains(effect),
                        onSelect: {
                            engine.themeManager.select(effect)
                        }
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

/// Button for trail effect option
struct TrailEffectButton: View {
    let effect: TrailEffect
    let isSelected: Bool
    let isUnlocked: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button {
            if isUnlocked {
                onSelect()
            }
        } label: {
            VStack(spacing: 4) {
                Text(effect.rawValue)
                    .font(.caption)
                    .foregroundStyle(.white)
                
                if !isUnlocked {
                    HStack(spacing: 2) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 8))
                        Text("Achievement")
                            .font(.caption2)
                    }
                    .foregroundStyle(.gray)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(buttonBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(!isUnlocked)
    }
    
    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(isSelected ? Color.purple.opacity(0.2) : Color.white.opacity(0.08))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.purple.opacity(0.5) : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
    }
}
