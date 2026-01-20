import SwiftUI
import Foundation
import UIKit
import Combine

// MARK: - Constants

enum GameConstants {
    // Player
    static let playerRadius: CGFloat = 18
    static let playerYPosition: CGFloat = 0.82 // Percentage of screen height
    
    // Lives
    static let maxLives: Int = 3
    
    // Obstacles
    static let obstacleRadiusMin: CGFloat = 14
    static let obstacleRadiusMax: CGFloat = 26
    static let baseObstacleSpeedMin: CGFloat = 220
    static let baseObstacleSpeedMax: CGFloat = 320
    static let maxObstacleSpeed: CGFloat = 600
    static let obstacleSpawnY: CGFloat = -30
    
    // Powerups
    static let powerupRadius: CGFloat = 16
    static let powerupSpeedMin: CGFloat = 100
    static let powerupSpeedMax: CGFloat = 160
    static let magnetAttractRadius: CGFloat = 150
    static let magnetAttractSpeed: CGFloat = 200
    
    // Difficulty
    static let baseSpawnInterval: Double = 0.55
    static let minSpawnInterval: Double = 0.2
    static let speedIncreasePerLevel: CGFloat = 25
    static let spawnIntervalDecreasePerLevel: Double = 0.03
    static let difficultyIncreaseInterval: Double = 5.0
    
    // Particles
    static let maxParticles: Int = 150
    static let rainbowColors: [Color] = [.red, .orange, .yellow, .green, .cyan, .blue, .purple]
    
    // Scoring
    static let scorePerSecond: Int = 10
    static let scorePerDodge: Int = 2
    static let scorePerCoin: Int = 25
    static let scorePerPowerup: Int = 10
    static let scorePerShieldBlock: Int = 15
    static let scorePerBombDestroy: Int = 5
    static let comboBonus: Int = 5
    static let comboWindow: Double = 2.0
    
    // Game modes
    static let timeAttackDurations: [Int] = [60, 90, 120]
}

// MARK: - Game Mode

enum GameMode: String, CaseIterable, Identifiable {
    case endless = "Endless"
    case timeAttack = "Time Attack"
    case hardcore = "Hardcore"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .endless: return "Survive as long as possible"
        case .timeAttack: return "Survive for the set duration"
        case .hardcore: return "No shield, faster difficulty"
        }
    }
}

// MARK: - Settings

struct GameSettings {
    var hapticEnabled: Bool = true
    var selectedMode: GameMode = .endless
    var timeAttackDuration: Int = 60  // seconds
    var playerColorIndex: Int = 0  // Index for player color
    
    // Available player colors
    static let playerColors: [Color] = [.white, .cyan, .green, .pink, .orange, .purple]
    static let playerColorNames: [String] = ["White", "Cyan", "Green", "Pink", "Orange", "Purple"]
    static let playerColorCosts: [Int] = [0, 100, 200, 300, 500, 750]
}

// MARK: - Models

struct Player {
    var x: CGFloat
    let y: CGFloat
    let radius: CGFloat
}

struct Obstacle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var radius: CGFloat
    var speed: CGFloat
}

// MARK: - Powerup System

enum PowerupType: CaseIterable {
    case coin
    case shield
    case slowMo
    case magnet
    case speedBoost
    case freeze
    case bomb

    var color: Color {
        switch self {
        case .coin: return .yellow
        case .shield: return .cyan
        case .slowMo: return .orange
        case .magnet: return .purple
        case .speedBoost: return .green
        case .freeze: return .blue
        case .bomb: return .red
        }
    }

    var icon: String {
        switch self {
        case .coin: return "star.circle.fill"
        case .shield: return "shield.fill"
        case .slowMo: return "clock.fill"
        case .magnet: return "magnet"
        case .speedBoost: return "bolt.fill"
        case .freeze: return "snowflake"
        case .bomb: return "flame.fill"
        }
    }

    var duration: Double {
        switch self {
        case .coin: return 0
        case .shield: return 5.0
        case .slowMo: return 4.0
        case .magnet: return 6.0
        case .speedBoost: return 5.0
        case .freeze: return 3.0
        case .bomb: return 0  // Instant effect
        }
    }

    var spawnWeight: Int {
        switch self {
        case .coin: return 55
        case .shield: return 12
        case .slowMo: return 12
        case .magnet: return 8
        case .speedBoost: return 5
        case .freeze: return 4
        case .bomb: return 4
        }
    }
}

struct Powerup:  Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    let radius: CGFloat
    let type: PowerupType
    var speed: CGFloat
}

// MARK: - Particle System

enum ParticleType {
    case explosion
    case trail
    case powerupAura
}

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var size: CGFloat
    var color: Color
    var opacity: Double
    var lifetime: Double
    var age: Double = 0
    var type: ParticleType = .explosion
    var isPooled: Bool = false
}

// MARK: - Trail Particle

struct TrailParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var opacity: Double
    var size: CGFloat
    var color: Color
    var age: Double = 0
    var lifetime: Double = 0.5
}

// MARK: - Game Engine

@MainActor
final class GameEngine: ObservableObject {

    enum GameState {
        case ready
        case playing
        case paused
        case gameOver
    }

    // Published states for UI
    @Published var state: GameState = .ready
    @Published var score: Int = 0
    @Published var bestScore: Int = 0
    @Published var coinsCollected: Int = 0
    @Published var totalGamesPlayed: Int = 0
    @Published var totalCoinsCollected: Int = 0
    @Published var currentDifficultyLevel: Int = 0
    @Published var difficultyJustIncreased: Bool = false
    @Published var recentScoreIncrease: Int = 0
    @Published var showMilestone: Bool = false
    @Published var milestoneText: String = ""
    
    // Lives system
    @Published var lives: Int = GameConstants.maxLives
    @Published var showSettings: Bool = false
    
    // Developer Mode
    @Published var developerModeVisible: Bool = false
    @Published var developerModeUnlocked: Bool = false
    var titleTapCount: Int = 0
    private let developerModePassword = "670"
    
    // Settings
    @Published var settings: GameSettings = GameSettings()
    
    // Unlocked player colors (indices)
    @Published var unlockedColors: Set<Int> = [0]  // White is always unlocked
    
    // Time Attack mode
    @Published var timeRemaining: Double = 0
    @Published var timeAttackWon: Bool = false
    
    // Milestone tracking - track which milestones achieved this game
    private var lastScoreMilestone: Int = 0
    private var achievedCoinMilestones: Set<Int> = []

    @Published var player: Player = Player(x: 0, y: 0, radius: GameConstants.playerRadius)
    @Published var obstacles: [Obstacle] = []
    @Published var powerups: [Powerup] = []
    @Published var particles: [Particle] = []
    @Published var trailParticles: [TrailParticle] = []
    
    // Theme manager
    @Published var themeManager: ThemeManager = ThemeManager()
    
    // Achievement tracking
    @Published var totalObstaclesDodged: Int = 0
    @Published var newlyUnlockedAchievement: Achievement? = nil

    // Powerup states
    @Published var hasShield: Bool = false
    @Published var hasSlowMo: Bool = false
    @Published var hasMagnet: Bool = false
    @Published var hasSpeedBoost: Bool = false
    @Published var hasFreeze: Bool = false
    @Published var shieldTimeRemaining: Double = 0
    @Published var slowMoTimeRemaining: Double = 0
    @Published var magnetTimeRemaining: Double = 0
    @Published var speedBoostTimeRemaining: Double = 0
    @Published var freezeTimeRemaining: Double = 0

    // Combo system
    @Published var combo: Int = 0
    private var comboTimer: Double = 0
    
    // Particle pooling
    private var particlePool: [Particle] = []
    private let maxPoolSize: Int = 100
    
    // Trail spawning
    private var trailSpawnCooldown: Double = 0
    private let trailSpawnInterval: Double = 0.05

    // World sizing
    private(set) var worldWidth: CGFloat = 320
    private(set) var worldHeight: CGFloat = 600

    // Game loop
    private var timer: Timer?
    private let fps: Double = 60.0
    private var lastTick: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()

    // Spawning
    private var obstacleSpawnCooldown: Double = 0
    private var obstacleSpawnInterval: Double = GameConstants.baseSpawnInterval
    private var powerupSpawnCooldown: Double = 0
    private var powerupSpawnInterval: Double = 2.5

    // MARK: - Difficulty System
    private var gameTime: Double = 0  // Total time played this round
    private var lastDifficultyIncrease: Double = 0  // Track when we last increased difficulty
    private var difficultyLevel: Int = 0  // Current difficulty level

    // Persistence
    private let bestScoreKey = "DodgeGame_BestScore"
    private let totalGamesKey = "DodgeGame_TotalGames"
    private let totalCoinsKey = "DodgeGame_TotalCoins"
    private let totalObstaclesDodgedKey = "DodgeGame_TotalObstaclesDodged"
    private let unlockedColorsKey = "DodgeGame_UnlockedColors"
    private let settingsHapticKey = "DodgeGame_HapticEnabled"
    private let settingsColorKey = "DodgeGame_PlayerColor"

    init() {
        loadBestScore()
        loadStatistics()
        loadSettings()
        initializeParticlePool()
    }
    
    // MARK: - Particle Pool
    
    private func initializeParticlePool() {
        particlePool.removeAll()
        for _ in 0..<maxPoolSize {
            let particle = Particle(
                x: 0, y: 0, vx: 0, vy: 0,
                size: 6, color: .white,
                opacity: 0, lifetime: 0.5,
                isPooled: true
            )
            particlePool.append(particle)
        }
    }
    
    private func getParticleFromPool() -> Particle? {
        return particlePool.popLast()
    }
    
    private func returnParticleToPool(_ particle: Particle) {
        if particlePool.count < maxPoolSize {
            var pooledParticle = particle
            pooledParticle.isPooled = true
            pooledParticle.opacity = 0
            pooledParticle.age = 0
            particlePool.append(pooledParticle)
        }
    }

    // MARK: - Setup

    func setWorldSize(width: CGFloat, height: CGFloat) {
        worldWidth = max(1, width)
        worldHeight = max(1, height)

        player = Player(
            x: worldWidth / 2,
            y: worldHeight * GameConstants.playerYPosition,
            radius: GameConstants.playerRadius
        )
    }

    // MARK: - Controls

    func setPlayerX(_ x: CGFloat) {
        guard state == .playing else { return }
        
        // Speed boost increases movement responsiveness
        let speedMultiplier: CGFloat = hasSpeedBoost ? 1.5 : 1.0
        let targetX = x
        let currentX = player.x
        let newX = currentX + (targetX - currentX) * speedMultiplier

        let minX = player.radius
        let maxX = worldWidth - player.radius
        player.x = min(max(newX, minX), maxX)
    }

    // MARK: - Game Flow

    func startGame() {
        stopLoop()

        state = .playing
        score = 0
        coinsCollected = 0
        obstacles.removeAll()
        powerups.removeAll()
        particles.removeAll()
        trailParticles.removeAll()
        trailSpawnCooldown = 0
        
        // Reset lives based on game mode
        lives = settings.selectedMode == .hardcore ? 1 : GameConstants.maxLives
        timeAttackWon = false
        
        // Set up time attack mode
        if settings.selectedMode == .timeAttack {
            timeRemaining = Double(settings.timeAttackDuration)
        } else {
            timeRemaining = 0
        }

        // Reset powerups
        hasShield = false
        hasSlowMo = false
        hasMagnet = false
        hasSpeedBoost = false
        hasFreeze = false
        shieldTimeRemaining = 0
        slowMoTimeRemaining = 0
        magnetTimeRemaining = 0
        speedBoostTimeRemaining = 0
        freezeTimeRemaining = 0

        // Reset combo
        combo = 0
        comboTimer = 0

        // Reset difficulty (harder in hardcore mode)
        gameTime = 0
        lastDifficultyIncrease = 0
        difficultyLevel = settings.selectedMode == .hardcore ? 3 : 0  // Start at higher level for hardcore
        currentDifficultyLevel = difficultyLevel
        difficultyJustIncreased = false
        lastScoreMilestone = 0
        achievedCoinMilestones.removeAll()
        recentScoreIncrease = 0
        obstacleSpawnInterval = GameConstants.baseSpawnInterval
        powerupSpawnInterval = 2.5
        obstacleSpawnCooldown = 0
        powerupSpawnCooldown = 1.0

        // Reset player position
        player = Player(
            x: worldWidth / 2,
            y: worldHeight * GameConstants.playerYPosition,
            radius: GameConstants.playerRadius
        )

        lastTick = CFAbsoluteTimeGetCurrent()

        startLoop()
        haptic(.medium)
    }

    func pauseGame() {
        guard state == .playing else { return }
        state = .paused
        stopLoop()
        haptic(.light)
    }

    func resumeGame() {
        guard state == .paused else { return }
        state = .playing
        lastTick = CFAbsoluteTimeGetCurrent()
        startLoop()
        haptic(.light)
    }

    func endGame(won: Bool = false) {
        guard state == .playing else { return }
        state = .gameOver
        stopLoop()
        
        timeAttackWon = won

        if score > bestScore {
            bestScore = score
            saveBestScore()
        }

        // Update statistics
        totalGamesPlayed += 1
        totalCoinsCollected += coinsCollected
        saveStatistics()
        
        // Check achievements
        checkAchievements()

        spawnExplosion(at: player.x, y: player.y, color: won ? .green : .white, count: 20)
        haptic(.heavy)
    }

    func resetToReady() {
        stopLoop()
        state = .ready
        score = 0
        coinsCollected = 0
        obstacles.removeAll()
        powerups.removeAll()
        particles.removeAll()
        trailParticles.removeAll()
        combo = 0
        lives = GameConstants.maxLives
    }

    // MARK: - Loop

    private func startLoop() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / fps, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.tick()
            }
        }
    }

    private func stopLoop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard state == .playing else { return }

        let now = CFAbsoluteTimeGetCurrent()
        var dt = now - lastTick
        lastTick = now

        dt = min(dt, 0.1)
        update(dt: dt)
    }

    // MARK: - Update

    private func update(dt: Double) {
        // Freeze stops obstacles, slowMo slows them
        let speedMultiplier: Double = hasFreeze ? 0.0 : (hasSlowMo ? 0.4 : 1.0)

        // 1) Update game time
        gameTime += dt
        
        // 1.5) Update time attack timer
        if settings.selectedMode == .timeAttack {
            timeRemaining -= dt
            if timeRemaining <= 0 {
                timeRemaining = 0
                endGame(won: true)
                return
            }
        }

        // 2) Score increases with time
        score += Int(dt * Double(GameConstants.scorePerSecond))
        
        // Check for score milestones
        checkScoreMilestone(currentScore: score)

        // 3) Update combo timer
        if combo > 0 {
            comboTimer -= dt
            if comboTimer <= 0 {
                combo = 0
            }
        }

        // 4) DIFFICULTY SCALING - Check every 5 seconds of gameplay
        // Faster difficulty increase in hardcore mode
        let difficultyMultiplier = settings.selectedMode == .hardcore ? 0.7 : 1.0
        updateDifficulty(intervalMultiplier: difficultyMultiplier)

        // 5) Update powerup timers
        updatePowerupTimers(dt: dt)

        // 6) Spawn obstacles (not during freeze)
        if !hasFreeze {
            obstacleSpawnCooldown -= dt
            if obstacleSpawnCooldown <= 0 {
                spawnObstacle()
                obstacleSpawnCooldown = obstacleSpawnInterval
            }
        }

        // 7) Spawn powerups (skip shield in hardcore mode)
        powerupSpawnCooldown -= dt
        if powerupSpawnCooldown <= 0 {
            spawnPowerup()
            powerupSpawnCooldown = powerupSpawnInterval * Double.random(in: 0.8...1.2)
        }

        // 8) Move obstacles (they use their own stored speed)
        if !hasFreeze {
            for i in obstacles.indices {
                obstacles[i].y += obstacles[i].speed * CGFloat(dt * speedMultiplier)
            }
        }

        // 9) Move powerups
        for i in powerups.indices {
            powerups[i].y += powerups[i].speed * CGFloat(dt * (hasFreeze ? 0.3 : speedMultiplier))

            // Magnet effect
            if hasMagnet && powerups[i].type == .coin {
                let dx = player.x - powerups[i].x
                let dy = player.y - powerups[i].y
                let dist = sqrt(dx * dx + dy * dy)

                if dist < GameConstants.magnetAttractRadius && dist > 0 {
                    powerups[i].x += (dx / dist) * GameConstants.magnetAttractSpeed * CGFloat(dt)
                    powerups[i].y += (dy / dist) * GameConstants.magnetAttractSpeed * CGFloat(dt)
                }
            }
        }

        // 10) Update particles
        updateParticles(dt: dt)
        
        // 10.5) Spawn and update trail particles
        updateTrailParticles(dt: dt)
        spawnTrailParticles(dt: dt)
        
        // 10.6) Spawn powerup aura particles
        spawnPowerupAuraParticles(dt: dt)
        
        // 10.7) Spawn combo effects
        if combo >= 5 {
            spawnComboEffects(dt: dt)
        }

        // 11) Remove off-screen obstacles
        let before = obstacles.count
        obstacles.removeAll { $0.y - $0.radius > worldHeight + 20 }
        let removed = before - obstacles.count
        if removed > 0 {
            score += removed * GameConstants.scorePerDodge
            totalObstaclesDodged += removed
        }

        // 12) Remove off-screen powerups
        powerups.removeAll { $0.y - $0.radius > worldHeight + 20 }

        // 13) Check powerup collection
        checkPowerupCollection()

        // 14) Check collision with obstacles
        if let collidingIndex = findCollidingObstacleIndex() {
            let collidingObstacle = obstacles[collidingIndex]
            
            if hasShield {
                hasShield = false
                shieldTimeRemaining = 0
                spawnExplosion(at: collidingObstacle.x, y: collidingObstacle.y, color: .cyan, count: 12)
                obstacles.remove(at: collidingIndex)
                haptic(.medium)
                score += GameConstants.scorePerShieldBlock
                recentScoreIncrease = GameConstants.scorePerShieldBlock
            } else {
                // Lives system
                lives -= 1
                if lives <= 0 {
                    endGame()
                } else {
                    // Remove the colliding obstacle and show damage feedback
                    spawnExplosion(at: collidingObstacle.x, y: collidingObstacle.y, color: .white, count: 10)
                    obstacles.remove(at: collidingIndex)
                    haptic(.heavy)
                }
            }
        }
    }

    // MARK: - Difficulty Scaling

    private func updateDifficulty(intervalMultiplier: Double = 1.0) {
        let interval = GameConstants.difficultyIncreaseInterval * intervalMultiplier
        
        // Increase difficulty every X seconds
        if gameTime - lastDifficultyIncrease >= interval {
            lastDifficultyIncrease = gameTime
            difficultyLevel += 1
            currentDifficultyLevel = difficultyLevel
            
            // Trigger visual feedback
            difficultyJustIncreased = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.difficultyJustIncreased = false
            }
            
            // Decrease spawn interval (more obstacles spawn)
            obstacleSpawnInterval = max(GameConstants.minSpawnInterval, GameConstants.baseSpawnInterval - (Double(difficultyLevel) * GameConstants.spawnIntervalDecreasePerLevel))
            
            // Also slightly decrease powerup spawn interval to help player
            powerupSpawnInterval = max(1.5, 2.5 - (Double(difficultyLevel) * 0.05))
            
            // Add haptic feedback for difficulty increase
            haptic(.medium)
        }
    }
    
    // Calculate current obstacle speed based on difficulty
    private func currentObstacleSpeedRange() -> (min: CGFloat, max: CGFloat) {
        let bonus = CGFloat(difficultyLevel) * GameConstants.speedIncreasePerLevel
        let minSpeed = GameConstants.baseObstacleSpeedMin + bonus
        let maxSpeed = GameConstants.baseObstacleSpeedMax + bonus
        
        // Cap maximum speed to keep game playable
        return (min: min(minSpeed, 500), max: min(maxSpeed, GameConstants.maxObstacleSpeed))
    }

    // MARK: - Powerup Timers

    private func updatePowerupTimers(dt: Double) {
        if hasShield {
            shieldTimeRemaining -= dt
            if shieldTimeRemaining <= 0 {
                hasShield = false
                shieldTimeRemaining = 0
            }
        }

        if hasSlowMo {
            slowMoTimeRemaining -= dt
            if slowMoTimeRemaining <= 0 {
                hasSlowMo = false
                slowMoTimeRemaining = 0
            }
        }

        if hasMagnet {
            magnetTimeRemaining -= dt
            if magnetTimeRemaining <= 0 {
                hasMagnet = false
                magnetTimeRemaining = 0
            }
        }
        
        if hasSpeedBoost {
            speedBoostTimeRemaining -= dt
            if speedBoostTimeRemaining <= 0 {
                hasSpeedBoost = false
                speedBoostTimeRemaining = 0
            }
        }
        
        if hasFreeze {
            freezeTimeRemaining -= dt
            if freezeTimeRemaining <= 0 {
                hasFreeze = false
                freezeTimeRemaining = 0
            }
        }
    }

    // MARK: - Spawning

    private func spawnObstacle() {
        let radius = CGFloat.random(in: GameConstants.obstacleRadiusMin...GameConstants.obstacleRadiusMax)
        let minX = radius
        let maxX = worldWidth - radius
        let x = CGFloat.random(in: minX...maxX)
        let y: CGFloat = GameConstants.obstacleSpawnY
        
        // Use difficulty-scaled speed range
        let speedRange = currentObstacleSpeedRange()
        let speed = CGFloat.random(in: speedRange.min...speedRange.max)

        let obs = Obstacle(x: x, y: y, radius: radius, speed: speed)
        obstacles.append(obs)
    }

    private func spawnPowerup() {
        var type = weightedRandomPowerup()
        
        // In hardcore mode, skip shield powerup
        if settings.selectedMode == .hardcore && type == .shield {
            type = .coin
        }
        
        let radius: CGFloat = GameConstants.powerupRadius
        let minX = radius + 10
        let maxX = worldWidth - radius - 10
        let x = CGFloat.random(in: minX...maxX)
        let y: CGFloat = GameConstants.obstacleSpawnY
        let speed = CGFloat.random(in: GameConstants.powerupSpeedMin...GameConstants.powerupSpeedMax)

        let powerup = Powerup(x: x, y: y, radius: radius, type: type, speed: speed)
        powerups.append(powerup)
    }

    private func weightedRandomPowerup() -> PowerupType {
        let totalWeight = PowerupType.allCases.reduce(0) { $0 + $1.spawnWeight }
        var random = Int.random(in: 0..<totalWeight)

        for type in PowerupType.allCases {
            random -= type.spawnWeight
            if random < 0 {
                return type
            }
        }
        return .coin
    }

    // MARK: - Collision Detection

    private func findCollidingObstacleIndex() -> Int? {
        for (index, obs) in obstacles.enumerated() {
            let dx = obs.x - player.x
            let dy = obs.y - player.y
            let dist2 = dx*dx + dy*dy
            let r = obs.radius + player.radius
            if dist2 <= r*r {
                return index
            }
        }
        return nil
    }

    private func checkPowerupCollection() {
        var collected: [UUID] = []

        for powerup in powerups {
            let dx = powerup.x - player.x
            let dy = powerup.y - player.y
            let dist2 = dx*dx + dy*dy
            let r = powerup.radius + player.radius + 5

            if dist2 <= r*r {
                collected.append(powerup.id)
                applyPowerup(powerup.type)
                spawnExplosion(at: powerup.x, y: powerup.y, color: powerup.type.color, count: 8)
            }
        }

        powerups.removeAll { collected.contains($0.id) }
    }

    private func applyPowerup(_ type: PowerupType) {
        combo += 1
        comboTimer = GameConstants.comboWindow

        let comboBonus = combo > 1 ? combo * GameConstants.comboBonus : 0

        switch type {
        case .coin:
            let points = GameConstants.scorePerCoin + comboBonus
            score += points
            recentScoreIncrease = points
            coinsCollected += 1
            haptic(.light)
            
            // Milestone achievements for coins
            checkMilestone(coins: coinsCollected)

        case .shield:
            // In lives mode, shield can restore a life if not at max
            if lives < GameConstants.maxLives && settings.selectedMode != .hardcore {
                lives += 1
                showMilestoneNotification("❤️ Life Restored!")
            } else {
                hasShield = true
                shieldTimeRemaining = type.duration
            }
            let points = GameConstants.scorePerPowerup + comboBonus
            score += points
            recentScoreIncrease = points
            haptic(.medium)

        case .slowMo:
            hasSlowMo = true
            slowMoTimeRemaining = type.duration
            let points = GameConstants.scorePerPowerup + comboBonus
            score += points
            recentScoreIncrease = points
            haptic(.medium)

        case .magnet:
            hasMagnet = true
            magnetTimeRemaining = type.duration
            let points = GameConstants.scorePerPowerup + comboBonus
            score += points
            recentScoreIncrease = points
            haptic(.medium)
            
        case .speedBoost:
            hasSpeedBoost = true
            speedBoostTimeRemaining = type.duration
            let points = GameConstants.scorePerPowerup + comboBonus
            score += points
            recentScoreIncrease = points
            haptic(.medium)
            
        case .freeze:
            hasFreeze = true
            freezeTimeRemaining = type.duration
            let points = GameConstants.scorePerPowerup + comboBonus
            score += points
            recentScoreIncrease = points
            haptic(.medium)
            
        case .bomb:
            // Destroy all obstacles on screen
            let obstacleCount = obstacles.count
            for obs in obstacles {
                spawnExplosion(at: obs.x, y: obs.y, color: .red, count: 6)
            }
            obstacles.removeAll()
            let points = GameConstants.scorePerPowerup + (obstacleCount * GameConstants.scorePerBombDestroy) + comboBonus
            score += points
            recentScoreIncrease = points
            haptic(.heavy)
            showMilestoneNotification("💥 BOOM! \(obstacleCount) destroyed!")
        }
    }
    
    // MARK: - Milestone System
    
    // Define milestone thresholds as static constants
    private static let coinMilestones: Set<Int> = [10, 25, 50, 100, 250, 500]
    private static let scoreMilestones: [Int] = [100, 250, 500, 1000, 2500, 5000, 10000]
    
    private func checkMilestone(coins: Int) {
        // Check if we just hit a milestone and haven't achieved it yet this game
        if Self.coinMilestones.contains(coins) && !achievedCoinMilestones.contains(coins) {
            achievedCoinMilestones.insert(coins)
            showMilestoneNotification("🎯 \(coins) Coins Collected!")
        }
    }
    
    private func checkScoreMilestone(currentScore: Int) {
        for milestone in Self.scoreMilestones {
            if currentScore >= milestone && lastScoreMilestone < milestone {
                lastScoreMilestone = milestone
                showMilestoneNotification("⭐ Score: \(milestone)!")
                break
            }
        }
    }
    
    private func showMilestoneNotification(_ text: String) {
        milestoneText = text
        showMilestone = true
        haptic(.heavy)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.showMilestone = false
        }
    }

    // MARK: - Particles

    private func spawnExplosion(at x: CGFloat, y: CGFloat, color: Color, count: Int) {
        // Use object pooling when available
        var particlesAdded = 0
        
        for _ in 0..<count {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 50...150)
            
            // Apply particle effect pack theme
            let particleColor = themeManager.selectedParticleEffectPack.particleColor(baseColor: color)
            
            if let pooledParticle = getParticleFromPool() {
                var particle = pooledParticle
                particle.x = x
                particle.y = y
                particle.vx = cos(angle) * speed
                particle.vy = sin(angle) * speed
                particle.size = CGFloat.random(in: 4...10)
                particle.color = particleColor
                particle.opacity = 1.0
                particle.lifetime = Double.random(in: 0.3...0.6)
                particle.age = 0
                particle.type = .explosion
                particle.isPooled = false
                particles.append(particle)
                particlesAdded += 1
            } else if particles.count < GameConstants.maxParticles {
                // Create new particle if pool is empty
                let particle = Particle(
                    x: x,
                    y: y,
                    vx: cos(angle) * speed,
                    vy: sin(angle) * speed,
                    size: CGFloat.random(in: 4...10),
                    color: particleColor,
                    opacity: 1.0,
                    lifetime: Double.random(in: 0.3...0.6),
                    type: .explosion
                )
                particles.append(particle)
                particlesAdded += 1
            }
        }
        
        // If too many particles, remove oldest ones
        if particles.count > GameConstants.maxParticles {
            let toRemove = particles.count - GameConstants.maxParticles
            let removed = particles.prefix(toRemove)
            for particle in removed {
                returnParticleToPool(particle)
            }
            particles.removeFirst(toRemove)
        }
    }

    private func updateParticles(dt: Double) {
        for i in particles.indices.reversed() {
            particles[i].x += particles[i].vx * CGFloat(dt)
            particles[i].y += particles[i].vy * CGFloat(dt)
            particles[i].age += dt
            particles[i].opacity = max(0, 1 - particles[i].age / particles[i].lifetime)
            
            // Add gravity only to explosion particles
            if particles[i].type == .explosion {
                particles[i].vy += 200 * CGFloat(dt)
            }
        }

        // Return expired particles to pool and remove them
        for i in particles.indices.reversed() {
            if particles[i].age >= particles[i].lifetime {
                let particle = particles[i]
                returnParticleToPool(particle)
                particles.remove(at: i)
            }
        }
    }
    
    // MARK: - Trail Particles
    
    private func spawnTrailParticles(dt: Double) {
        // Trail particles are spawned when:
        // 1. A trail effect is selected (diamond, rainbow, fire) OR
        // 2. Speed boost is active (shows green trail for visual feedback)
        guard themeManager.selectedTrailEffect != .none || hasSpeedBoost else { return }
        
        trailSpawnCooldown -= dt
        if trailSpawnCooldown <= 0 {
            trailSpawnCooldown = hasSpeedBoost ? trailSpawnInterval * 0.5 : trailSpawnInterval
            
            // Determine trail color based on effect
            let trailColor: Color
            switch themeManager.selectedTrailEffect {
            case .none:
                trailColor = hasSpeedBoost ? .green : currentPlayerColor
            case .diamond:
                trailColor = .cyan
            case .rainbow:
                trailColor = GameConstants.rainbowColors.randomElement() ?? .white
            case .fire:
                trailColor = ParticleEffectPack.fireColors.randomElement() ?? .orange
            }
            
            let trail = TrailParticle(
                x: player.x,
                y: player.y,
                opacity: 0.6,
                size: player.radius * (hasSpeedBoost ? 1.2 : 0.8),
                color: trailColor,
                lifetime: hasSpeedBoost ? 0.4 : 0.5
            )
            trailParticles.append(trail)
            
            // Limit trail particles
            if trailParticles.count > 30 {
                trailParticles.removeFirst()
            }
        }
    }
    
    private func updateTrailParticles(dt: Double) {
        for i in trailParticles.indices.reversed() {
            trailParticles[i].age += dt
            let progress = trailParticles[i].age / trailParticles[i].lifetime
            trailParticles[i].opacity = max(0, 0.6 * (1 - progress))
        }
        
        trailParticles.removeAll { $0.age >= $0.lifetime }
    }
    
    // MARK: - Powerup Aura Particles
    
    private func spawnPowerupAuraParticles(dt: Double) {
        // Spawn pulsing aura particles around player when powerups are active
        let activePowerups: [(Bool, Color, Double)] = [
            (hasShield, .cyan, shieldTimeRemaining),
            (hasSlowMo, .orange, slowMoTimeRemaining),
            (hasMagnet, .purple, magnetTimeRemaining),
            (hasSpeedBoost, .green, speedBoostTimeRemaining),
            (hasFreeze, .blue, freezeTimeRemaining)
        ]
        
        for (isActive, color, _) in activePowerups where isActive {
            // Spawn aura particles occasionally
            if Double.random(in: 0...1) < dt * 8 {
                let angle = CGFloat.random(in: 0...(2 * .pi))
                let distance = player.radius + CGFloat.random(in: 15...25)
                let x = player.x + cos(angle) * distance
                let y = player.y + sin(angle) * distance
                
                if let pooledParticle = getParticleFromPool() {
                    var particle = pooledParticle
                    particle.x = x
                    particle.y = y
                    particle.vx = cos(angle) * 20
                    particle.vy = sin(angle) * 20
                    particle.size = CGFloat.random(in: 3...6)
                    particle.color = color
                    particle.opacity = 0.7
                    particle.lifetime = 0.6
                    particle.age = 0
                    particle.type = .powerupAura
                    particle.isPooled = false
                    particles.append(particle)
                } else if particles.count < GameConstants.maxParticles {
                    let particle = Particle(
                        x: x,
                        y: y,
                        vx: cos(angle) * 20,
                        vy: sin(angle) * 20,
                        size: CGFloat.random(in: 3...6),
                        color: color,
                        opacity: 0.7,
                        lifetime: 0.6,
                        type: .powerupAura
                    )
                    particles.append(particle)
                }
            }
        }
    }
    
    // MARK: - Combo Effects
    
    private func spawnComboEffects(dt: Double) {
        // Spawn rainbow particles at screen edges for high combos
        if Double.random(in: 0...1) < dt * Double(combo) {
            let isLeftSide = Bool.random()
            let x = isLeftSide ? CGFloat.random(in: 0...30) : worldWidth - CGFloat.random(in: 0...30)
            let y = CGFloat.random(in: 0...worldHeight)
            let rainbowColor: Color = GameConstants.rainbowColors.randomElement() ?? .white
            
            if let pooledParticle = getParticleFromPool() {
                var particle = pooledParticle
                particle.x = x
                particle.y = y
                particle.vx = 0
                particle.vy = CGFloat.random(in: -50...50)
                particle.size = CGFloat.random(in: 6...12)
                particle.color = rainbowColor
                particle.opacity = 0.8
                particle.lifetime = 0.8
                particle.age = 0
                particle.type = .explosion
                particle.isPooled = false
                particles.append(particle)
            }
        }
    }

    // MARK: - Persistence

    private func loadBestScore() {
        bestScore = UserDefaults.standard.integer(forKey: bestScoreKey)
    }

    private func saveBestScore() {
        UserDefaults.standard.set(bestScore, forKey: bestScoreKey)
    }

    private func loadStatistics() {
        totalGamesPlayed = UserDefaults.standard.integer(forKey: totalGamesKey)
        totalCoinsCollected = UserDefaults.standard.integer(forKey: totalCoinsKey)
        totalObstaclesDodged = UserDefaults.standard.integer(forKey: totalObstaclesDodgedKey)
    }

    func saveStatistics() {
        UserDefaults.standard.set(totalGamesPlayed, forKey: totalGamesKey)
        UserDefaults.standard.set(totalCoinsCollected, forKey: totalCoinsKey)
        UserDefaults.standard.set(totalObstaclesDodged, forKey: totalObstaclesDodgedKey)
    }
    
    private func loadSettings() {
        settings.hapticEnabled = UserDefaults.standard.object(forKey: settingsHapticKey) as? Bool ?? true
        settings.playerColorIndex = UserDefaults.standard.integer(forKey: settingsColorKey)
        
        // Load unlocked colors
        if let savedColors = UserDefaults.standard.array(forKey: unlockedColorsKey) as? [Int] {
            unlockedColors = Set(savedColors)
        }
        unlockedColors.insert(0) // Ensure default is always unlocked
    }
    
    func saveSettings() {
        UserDefaults.standard.set(settings.hapticEnabled, forKey: settingsHapticKey)
        UserDefaults.standard.set(settings.playerColorIndex, forKey: settingsColorKey)
        UserDefaults.standard.set(Array(unlockedColors), forKey: unlockedColorsKey)
    }
    
    // MARK: - Unlockables
    
    // MARK: - Achievements
    
    private func checkAchievements() {
        for achievement in Achievement.allCases {
            let wasUnlocked = themeManager.checkAndUnlockAchievement(
                achievement,
                totalObstaclesDodged: totalObstaclesDodged,
                totalCoins: totalCoinsCollected,
                highestScore: bestScore
            )
            
            if wasUnlocked {
                newlyUnlockedAchievement = achievement
                showMilestoneNotification("🏆 \(achievement.rawValue) Unlocked!")
                
                // Auto-unlock achievement colors
                switch achievement.reward {
                case .playerColor(let colorIndex):
                    unlockedColors.insert(colorIndex)
                    saveSettings()
                default:
                    break
                }
            }
        }
    }
    
    func canAffordColor(index: Int) -> Bool {
        // Check if it's within extended color range
        guard index < ThemeManager.extendedPlayerColors.count else { return false }
        
        // Check if already unlocked
        if unlockedColors.contains(index) { return true }
        
        // Check if unlocked by achievement
        if themeManager.isColorUnlockedByAchievement(index) { return true }
        
        // Check if can afford to unlock
        guard index < ThemeManager.extendedPlayerColorCosts.count else { return false }
        let cost = ThemeManager.extendedPlayerColorCosts[index]
        return cost == 0 || totalCoinsCollected >= cost
    }
    
    func unlockColor(index: Int) -> Bool {
        guard index < ThemeManager.extendedPlayerColors.count else { return false }
        guard !unlockedColors.contains(index) else { return false }
        
        // Check if unlocked by achievement (free)
        if themeManager.isColorUnlockedByAchievement(index) {
            unlockedColors.insert(index)
            saveSettings()
            haptic(.medium)
            return true
        }
        
        // Check if can afford
        guard index < ThemeManager.extendedPlayerColorCosts.count else { return false }
        let cost = ThemeManager.extendedPlayerColorCosts[index]
        guard totalCoinsCollected >= cost else { return false }
        
        totalCoinsCollected -= cost
        unlockedColors.insert(index)
        saveStatistics()
        saveSettings()
        haptic(.medium)
        return true
    }
    
    func selectColor(index: Int) {
        guard unlockedColors.contains(index) || themeManager.isColorUnlockedByAchievement(index) else { return }
        settings.playerColorIndex = index
        saveSettings()
    }
    
    var currentPlayerColor: Color {
        let index = settings.playerColorIndex
        guard index < ThemeManager.extendedPlayerColors.count else { return .white }
        return ThemeManager.extendedPlayerColors[index]
    }

    // MARK: - Developer Mode
    
    func handleTitleTap() {
        titleTapCount += 1
        
        // Enable developer mode after 6 or more taps
        if titleTapCount >= 6 && !developerModeVisible {
            developerModeVisible = true
            haptic(.medium)
        }
    }
    
    func validateDeveloperPassword(_ password: String) -> Bool {
        // Note: Password is intentionally stored as plain text for this developer/cheat feature
        // This is acceptable for a local game feature that doesn't protect sensitive data
        if password == developerModePassword {
            developerModeUnlocked = true
            unlockAllContent()
            haptic(.heavy)
            return true
        }
        return false
    }
    
    private func unlockAllContent() {
        // Unlock all player colors
        for i in 0..<ThemeManager.extendedPlayerColors.count {
            unlockedColors.insert(i)
        }
        
        // Unlock all themes
        themeManager.unlockedObstacleThemes = Set(ObstacleTheme.allCases)
        themeManager.unlockedBackgroundThemes = Set(BackgroundTheme.allCases)
        themeManager.unlockedParticleEffectPacks = Set(ParticleEffectPack.allCases)
        themeManager.unlockedTrailEffects = Set(TrailEffect.allCases)
        
        // Unlock all achievements
        themeManager.unlockedAchievements = Set(Achievement.allCases)
        
        // Save everything
        saveSettings()
        themeManager.saveSettings()
    }

    // MARK: - Haptics

    enum HapticStyle { case light, medium, heavy }

    private func haptic(_ style: HapticStyle) {
        guard settings.hapticEnabled else { return }
        
        let gen: UIImpactFeedbackGenerator
        switch style {
        case .light:
            gen = UIImpactFeedbackGenerator(style: .light)
        case .medium:
            gen = UIImpactFeedbackGenerator(style: .medium)
        case .heavy:
            gen = UIImpactFeedbackGenerator(style: .heavy)
        }
        gen.prepare()
        gen.impactOccurred()
    }
}
