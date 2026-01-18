import SwiftUI
import Foundation
import Combine

// MARK: - Theme Types

enum ObstacleTheme: String, CaseIterable, Identifiable {
    case classic = "Classic"
    case spaceMeteor = "Space Meteor"
    case pixelBlock = "Pixel Block"
    case neonOrb = "Neon Orb"
    
    var id: String { rawValue }
    
    var colors: [Color] {
        switch self {
        case .classic:
            return [.red, .red.opacity(0.7)]
        case .spaceMeteor:
            return [.brown, .orange.opacity(0.6)]
        case .pixelBlock:
            return [.purple, .pink]
        case .neonOrb:
            return [.cyan, .blue, .purple]
        }
    }
    
    var glowColor: Color {
        switch self {
        case .classic:
            return .red
        case .spaceMeteor:
            return .orange
        case .pixelBlock:
            return .purple
        case .neonOrb:
            return .cyan
        }
    }
    
    var unlockRequirement: UnlockRequirement {
        switch self {
        case .classic:
            return .none
        case .spaceMeteor:
            return .totalCoins(500)
        case .pixelBlock:
            return .totalCoins(1000)
        case .neonOrb:
            return .totalCoins(1500)
        }
    }
}

enum BackgroundTheme: String, CaseIterable, Identifiable {
    case classic = "Classic"
    case starrySpace = "Starry Space"
    case cyberpunk = "Cyberpunk"
    case underwater = "Underwater"
    
    var id: String { rawValue }
    
    var gradientColors: [Color] {
        switch self {
        case .classic:
            return [
                Color(red: 0.05, green: 0.05, blue: 0.15),
                Color.black,
                Color(red: 0.1, green: 0.05, blue: 0.15)
            ]
        case .starrySpace:
            return [
                Color(red: 0.05, green: 0.05, blue: 0.2),
                Color(red: 0.1, green: 0.05, blue: 0.25),
                Color.black
            ]
        case .cyberpunk:
            return [
                Color(red: 0.15, green: 0.05, blue: 0.2),
                Color(red: 0.2, green: 0, blue: 0.15),
                Color(red: 0.1, green: 0, blue: 0.2)
            ]
        case .underwater:
            return [
                Color(red: 0, green: 0.15, blue: 0.25),
                Color(red: 0, green: 0.1, blue: 0.2),
                Color(red: 0, green: 0.2, blue: 0.3)
            ]
        }
    }
    
    var starColor: Color {
        switch self {
        case .classic, .starrySpace:
            return .white
        case .cyberpunk:
            return .pink
        case .underwater:
            return .cyan
        }
    }
    
    var unlockRequirement: UnlockRequirement {
        switch self {
        case .classic:
            return .none
        case .starrySpace:
            return .totalCoins(300)
        case .cyberpunk:
            return .totalCoins(800)
        case .underwater:
            return .totalCoins(1200)
        }
    }
}

enum ParticleEffectPack: String, CaseIterable, Identifiable {
    case classic = "Classic"
    case fire = "Fire"
    case lightning = "Lightning"
    case cherryBlossom = "Cherry Blossom"
    
    var id: String { rawValue }
    
    func particleColor(baseColor: Color) -> Color {
        switch self {
        case .classic:
            return baseColor
        case .fire:
            return ParticleEffectPack.fireColors.randomElement() ?? .orange
        case .lightning:
            return ParticleEffectPack.lightningColors.randomElement() ?? .cyan
        case .cherryBlossom:
            return ParticleEffectPack.cherryBlossomColors.randomElement() ?? .pink
        }
    }
    
    // Static color arrays to avoid repeated allocation
    static let fireColors: [Color] = [.red, .orange, .yellow]
    static let lightningColors: [Color] = [.cyan, .blue, .white]
    static let cherryBlossomColors: [Color] = [.pink, .white, Color(red: 1.0, green: 0.8, blue: 0.9)]
    
    var unlockRequirement: UnlockRequirement {
        switch self {
        case .classic:
            return .none
        case .fire:
            return .totalCoins(600)
        case .lightning:
            return .totalCoins(900)
        case .cherryBlossom:
            return .totalCoins(1100)
        }
    }
}

// MARK: - Achievement Types

enum Achievement: String, CaseIterable, Identifiable {
    case dodger100 = "One in a Hundred"  // 百里挑一
    case wealthy = "Wealthy"  // 富甲一方
    case diamondHunter = "Diamond Hunter"  // 钻石猎手
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .dodger100:
            return "Dodge 100 obstacles in total"
        case .wealthy:
            return "Collect 1000 total coins"
        case .diamondHunter:
            return "Score 5000+ in a single game"
        }
    }
    
    var icon: String {
        switch self {
        case .dodger100:
            return "shield.checkered"
        case .wealthy:
            return "crown.fill"
        case .diamondHunter:
            return "diamond.fill"
        }
    }
    
    var reward: AchievementReward {
        switch self {
        case .dodger100:
            return .playerColor(7)  // Special color
        case .wealthy:
            return .playerColor(8)  // Golden skin
        case .diamondHunter:
            return .trailEffect(.diamond)
        }
    }
}

enum AchievementReward {
    case playerColor(Int)
    case trailEffect(TrailEffect)
}

enum TrailEffect: String, CaseIterable {
    case none = "None"
    case diamond = "Diamond"
    case rainbow = "Rainbow"
    case fire = "Fire"
}

enum UnlockRequirement {
    case none
    case totalCoins(Int)
    case achievement(Achievement)
}

// MARK: - Theme Manager

@MainActor
class ThemeManager: ObservableObject {
    // Current selections
    @Published var selectedObstacleTheme: ObstacleTheme = .classic
    @Published var selectedBackgroundTheme: BackgroundTheme = .classic
    @Published var selectedParticleEffectPack: ParticleEffectPack = .classic
    @Published var selectedTrailEffect: TrailEffect = .none
    
    // Unlocked items
    @Published var unlockedObstacleThemes: Set<ObstacleTheme> = [.classic]
    @Published var unlockedBackgroundThemes: Set<BackgroundTheme> = [.classic]
    @Published var unlockedParticleEffectPacks: Set<ParticleEffectPack> = [.classic]
    @Published var unlockedTrailEffects: Set<TrailEffect> = [.none]
    
    // Achievements
    @Published var unlockedAchievements: Set<Achievement> = []
    
    // Extended player colors for achievements
    static let extendedPlayerColors: [Color] = [
        .white, .cyan, .green, .pink, .orange, .purple,  // Original 6 (indices 0-5)
        .yellow,  // Index 6 - normal unlock
        Color(red: 0.5, green: 0.3, blue: 0.8),  // Index 7 - Special color for dodger100
        Color(red: 1.0, green: 0.84, blue: 0.0),  // Index 8 - Golden for wealthy
    ]
    
    static let extendedPlayerColorNames: [String] = [
        "White", "Cyan", "Green", "Pink", "Orange", "Purple",
        "Yellow",
        "Special Purple",  // Achievement: dodger100
        "Golden",  // Achievement: wealthy
    ]
    
    static let extendedPlayerColorCosts: [Int] = [
        0, 100, 200, 300, 500, 750,  // Original costs
        850,  // Yellow
        0,  // Special - unlocked via achievement
        0,  // Golden - unlocked via achievement
    ]
    
    // Persistence keys
    private let obstacleThemeKey = "DodgeGame_ObstacleTheme"
    private let backgroundThemeKey = "DodgeGame_BackgroundTheme"
    private let particleEffectPackKey = "DodgeGame_ParticleEffectPack"
    private let trailEffectKey = "DodgeGame_TrailEffect"
    private let unlockedObstacleThemesKey = "DodgeGame_UnlockedObstacleThemes"
    private let unlockedBackgroundThemesKey = "DodgeGame_UnlockedBackgroundThemes"
    private let unlockedParticleEffectPacksKey = "DodgeGame_UnlockedParticleEffectPacks"
    private let unlockedTrailEffectsKey = "DodgeGame_UnlockedTrailEffects"
    private let unlockedAchievementsKey = "DodgeGame_UnlockedAchievements"
    
    init() {
        loadSettings()
    }
    
    // MARK: - Unlocking
    
    func canUnlock(_ theme: ObstacleTheme, totalCoins: Int) -> Bool {
        if unlockedObstacleThemes.contains(theme) { return false }
        switch theme.unlockRequirement {
        case .none:
            return true
        case .totalCoins(let required):
            return totalCoins >= required
        case .achievement:
            return false
        }
    }
    
    func canUnlock(_ theme: BackgroundTheme, totalCoins: Int) -> Bool {
        if unlockedBackgroundThemes.contains(theme) { return false }
        switch theme.unlockRequirement {
        case .none:
            return true
        case .totalCoins(let required):
            return totalCoins >= required
        case .achievement:
            return false
        }
    }
    
    func canUnlock(_ pack: ParticleEffectPack, totalCoins: Int) -> Bool {
        if unlockedParticleEffectPacks.contains(pack) { return false }
        switch pack.unlockRequirement {
        case .none:
            return true
        case .totalCoins(let required):
            return totalCoins >= required
        case .achievement:
            return false
        }
    }
    
    func unlock(_ theme: ObstacleTheme, totalCoins: inout Int) -> Bool {
        guard canUnlock(theme, totalCoins: totalCoins) else { return false }
        switch theme.unlockRequirement {
        case .totalCoins(let cost):
            totalCoins -= cost
        default:
            break
        }
        unlockedObstacleThemes.insert(theme)
        saveSettings()
        return true
    }
    
    func unlock(_ theme: BackgroundTheme, totalCoins: inout Int) -> Bool {
        guard canUnlock(theme, totalCoins: totalCoins) else { return false }
        switch theme.unlockRequirement {
        case .totalCoins(let cost):
            totalCoins -= cost
        default:
            break
        }
        unlockedBackgroundThemes.insert(theme)
        saveSettings()
        return true
    }
    
    func unlock(_ pack: ParticleEffectPack, totalCoins: inout Int) -> Bool {
        guard canUnlock(pack, totalCoins: totalCoins) else { return false }
        switch pack.unlockRequirement {
        case .totalCoins(let cost):
            totalCoins -= cost
        default:
            break
        }
        unlockedParticleEffectPacks.insert(pack)
        saveSettings()
        return true
    }
    
    // MARK: - Achievements
    
    func checkAndUnlockAchievement(_ achievement: Achievement, totalObstaclesDodged: Int, totalCoins: Int, highestScore: Int) -> Bool {
        if unlockedAchievements.contains(achievement) { return false }
        
        let unlocked: Bool
        switch achievement {
        case .dodger100:
            unlocked = totalObstaclesDodged >= 100
        case .wealthy:
            unlocked = totalCoins >= 1000
        case .diamondHunter:
            unlocked = highestScore >= 5000
        }
        
        if unlocked {
            unlockedAchievements.insert(achievement)
            
            // Apply reward
            switch achievement.reward {
            case .playerColor:
                break  // Handled in color unlock check
            case .trailEffect(let effect):
                unlockedTrailEffects.insert(effect)
            }
            
            saveSettings()
            return true
        }
        
        return false
    }
    
    func isColorUnlockedByAchievement(_ colorIndex: Int) -> Bool {
        // Check if color is unlocked through achievement
        for achievement in unlockedAchievements {
            switch achievement.reward {
            case .playerColor(let index):
                if index == colorIndex {
                    return true
                }
            default:
                break
            }
        }
        return false
    }
    
    // MARK: - Selection
    
    func select(_ theme: ObstacleTheme) {
        guard unlockedObstacleThemes.contains(theme) else { return }
        selectedObstacleTheme = theme
        saveSettings()
    }
    
    func select(_ theme: BackgroundTheme) {
        guard unlockedBackgroundThemes.contains(theme) else { return }
        selectedBackgroundTheme = theme
        saveSettings()
    }
    
    func select(_ pack: ParticleEffectPack) {
        guard unlockedParticleEffectPacks.contains(pack) else { return }
        selectedParticleEffectPack = pack
        saveSettings()
    }
    
    func select(_ effect: TrailEffect) {
        guard unlockedTrailEffects.contains(effect) else { return }
        selectedTrailEffect = effect
        saveSettings()
    }
    
    // MARK: - Persistence
    
    private func loadSettings() {
        // Load selections
        if let obstacleThemeString = UserDefaults.standard.string(forKey: obstacleThemeKey),
           let theme = ObstacleTheme(rawValue: obstacleThemeString) {
            selectedObstacleTheme = theme
        }
        
        if let backgroundThemeString = UserDefaults.standard.string(forKey: backgroundThemeKey),
           let theme = BackgroundTheme(rawValue: backgroundThemeString) {
            selectedBackgroundTheme = theme
        }
        
        if let particleEffectPackString = UserDefaults.standard.string(forKey: particleEffectPackKey),
           let pack = ParticleEffectPack(rawValue: particleEffectPackString) {
            selectedParticleEffectPack = pack
        }
        
        if let trailEffectString = UserDefaults.standard.string(forKey: trailEffectKey),
           let effect = TrailEffect(rawValue: trailEffectString) {
            selectedTrailEffect = effect
        }
        
        // Load unlocked items
        if let obstacleThemeStrings = UserDefaults.standard.array(forKey: unlockedObstacleThemesKey) as? [String] {
            unlockedObstacleThemes = Set(obstacleThemeStrings.compactMap { ObstacleTheme(rawValue: $0) })
        }
        unlockedObstacleThemes.insert(.classic)
        
        if let backgroundThemeStrings = UserDefaults.standard.array(forKey: unlockedBackgroundThemesKey) as? [String] {
            unlockedBackgroundThemes = Set(backgroundThemeStrings.compactMap { BackgroundTheme(rawValue: $0) })
        }
        unlockedBackgroundThemes.insert(.classic)
        
        if let particleEffectPackStrings = UserDefaults.standard.array(forKey: unlockedParticleEffectPacksKey) as? [String] {
            unlockedParticleEffectPacks = Set(particleEffectPackStrings.compactMap { ParticleEffectPack(rawValue: $0) })
        }
        unlockedParticleEffectPacks.insert(.classic)
        
        if let trailEffectStrings = UserDefaults.standard.array(forKey: unlockedTrailEffectsKey) as? [String] {
            unlockedTrailEffects = Set(trailEffectStrings.compactMap { TrailEffect(rawValue: $0) })
        }
        unlockedTrailEffects.insert(.none)
        
        if let achievementStrings = UserDefaults.standard.array(forKey: unlockedAchievementsKey) as? [String] {
            unlockedAchievements = Set(achievementStrings.compactMap { Achievement(rawValue: $0) })
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(selectedObstacleTheme.rawValue, forKey: obstacleThemeKey)
        UserDefaults.standard.set(selectedBackgroundTheme.rawValue, forKey: backgroundThemeKey)
        UserDefaults.standard.set(selectedParticleEffectPack.rawValue, forKey: particleEffectPackKey)
        UserDefaults.standard.set(selectedTrailEffect.rawValue, forKey: trailEffectKey)
        
        UserDefaults.standard.set(unlockedObstacleThemes.map { $0.rawValue }, forKey: unlockedObstacleThemesKey)
        UserDefaults.standard.set(unlockedBackgroundThemes.map { $0.rawValue }, forKey: unlockedBackgroundThemesKey)
        UserDefaults.standard.set(unlockedParticleEffectPacks.map { $0.rawValue }, forKey: unlockedParticleEffectPacksKey)
        UserDefaults.standard.set(unlockedTrailEffects.map { $0.rawValue }, forKey: unlockedTrailEffectsKey)
        UserDefaults.standard.set(unlockedAchievements.map { $0.rawValue }, forKey: unlockedAchievementsKey)
    }
}
