import SwiftUI
import Foundation
import UIKit
import Combine

// MARK: - Models

struct Player {
    var x: CGFloat
    let y: CGFloat
    let radius: CGFloat
}

struct Obstacle:  Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var radius:  CGFloat
    var speed: CGFloat
}

// MARK: - Powerup System

enum PowerupType: CaseIterable {
    case coin
    case shield
    case slowMo
    case magnet

    var color: Color {
        switch self {
        case .coin: return . yellow
        case .shield: return . cyan
        case .slowMo: return .orange
        case .magnet: return .purple
        }
    }

    var icon: String {
        switch self {
        case .coin: return "star. circle.fill"
        case .shield: return "shield.fill"
        case .slowMo: return "clock.fill"
        case .magnet: return "magnet"
        }
    }

    var duration: Double {
        switch self {
        case .coin: return 0
        case .shield: return 5.0
        case .slowMo: return 4.0
        case .magnet: return 6.0
        }
    }

    var spawnWeight: Int {
        switch self {
        case .coin: return 60
        case .shield: return 15
        case .slowMo: return 15
        case .magnet: return 10
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
    @Published var state:  GameState = .ready
    @Published var score: Int = 0
    @Published var bestScore: Int = 0
    @Published var coinsCollected:  Int = 0
    @Published var totalGamesPlayed: Int = 0
    @Published var totalCoinsCollected: Int = 0
    @Published var currentDifficultyLevel: Int = 0
    @Published var difficultyJustIncreased: Bool = false
    @Published var recentScoreIncrease: Int = 0
    @Published var showMilestone: Bool = false
    @Published var milestoneText: String = ""

    @Published var player: Player = Player(x: 0, y:  0, radius: 18)
    @Published var obstacles: [Obstacle] = []
    @Published var powerups: [Powerup] = []
    @Published var particles: [Particle] = []

    // Powerup states
    @Published var hasShield: Bool = false
    @Published var hasSlowMo: Bool = false
    @Published var hasMagnet: Bool = false
    @Published var shieldTimeRemaining:  Double = 0
    @Published var slowMoTimeRemaining: Double = 0
    @Published var magnetTimeRemaining: Double = 0

    // Combo system
    @Published var combo:  Int = 0
    private var comboTimer: Double = 0
    private let comboWindow: Double = 2.0

    // World sizing
    private(set) var worldWidth: CGFloat = 320
    private(set) var worldHeight: CGFloat = 600

    // Game loop
    private var timer: Timer?
    private let fps: Double = 60.0
    private var lastTick: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()

    // Spawning
    private var obstacleSpawnCooldown: Double = 0
    private var obstacleSpawnInterval: Double = 0.55
    private var powerupSpawnCooldown:  Double = 0
    private var powerupSpawnInterval: Double = 2.5

    // MARK: - Difficulty System (IMPROVED)
    private var gameTime: Double = 0  // Total time played this round
    private var lastDifficultyIncrease: Double = 0  // Track when we last increased difficulty
    private var difficultyLevel: Int = 0  // Current difficulty level
    
    // Base values
    private let baseObstacleSpeedMin: CGFloat = 220
    private let baseObstacleSpeedMax: CGFloat = 320
    private let baseSpawnInterval: Double = 0.55
    
    // How much to increase per difficulty level
    private let speedIncreasePerLevel: CGFloat = 25  // +25 speed per level
    private let spawnIntervalDecreasePerLevel: Double = 0.03  // Spawn 0.03s faster per level
    private let difficultyIncreaseInterval: Double = 5.0  // Increase difficulty every 5 seconds

    // Persistence
    private let bestScoreKey = "DodgeGame_BestScore"
    private let totalGamesKey = "DodgeGame_TotalGames"
    private let totalCoinsKey = "DodgeGame_TotalCoins"

    init() {
        loadBestScore()
        loadStatistics()
    }

    // MARK: - Setup

    func setWorldSize(width:  CGFloat, height: CGFloat) {
        worldWidth = max(1, width)
        worldHeight = max(1, height)

        player = Player(
            x: worldWidth / 2,
            y: worldHeight * 0.82,
            radius: 18
        )
    }

    // MARK: - Controls

    func setPlayerX(_ x: CGFloat) {
        guard state == .playing else { return }

        let minX = player.radius
        let maxX = worldWidth - player.radius
        player.x = min(max(x, minX), maxX)
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

        // Reset powerups
        hasShield = false
        hasSlowMo = false
        hasMagnet = false
        shieldTimeRemaining = 0
        slowMoTimeRemaining = 0
        magnetTimeRemaining = 0

        // Reset combo
        combo = 0
        comboTimer = 0

        // Reset difficulty
        gameTime = 0
        lastDifficultyIncrease = 0
        difficultyLevel = 0
        currentDifficultyLevel = 0
        difficultyJustIncreased = false
        obstacleSpawnInterval = baseSpawnInterval
        powerupSpawnInterval = 2.5
        obstacleSpawnCooldown = 0
        powerupSpawnCooldown = 1.0

        // Reset player position
        player = Player(
            x: worldWidth / 2,
            y: worldHeight * 0.82,
            radius: 18
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

    func endGame() {
        guard state == .playing else { return }
        state = .gameOver
        stopLoop()

        if score > bestScore {
            bestScore = score
            saveBestScore()
        }

        // Update statistics
        totalGamesPlayed += 1
        totalCoinsCollected += coinsCollected
        saveStatistics()

        spawnExplosion(at: player.x, y: player.y, color: .white, count: 20)
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
        combo = 0
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
        let speedMultiplier = hasSlowMo ? 0.4 : 1.0

        // 1) Update game time
        gameTime += dt

        // 2) Score increases with time
        let oldScore = score
        score += Int(dt * 10.0)
        
        // Check for score milestones
        if score != oldScore {
            checkScoreMilestone(currentScore: score)
        }

        // 3) Update combo timer
        if combo > 0 {
            comboTimer -= dt
            if comboTimer <= 0 {
                combo = 0
            }
        }

        // 4) DIFFICULTY SCALING - Check every 5 seconds of gameplay
        updateDifficulty()

        // 5) Update powerup timers
        updatePowerupTimers(dt: dt)

        // 6) Spawn obstacles
        obstacleSpawnCooldown -= dt
        if obstacleSpawnCooldown <= 0 {
            spawnObstacle()
            obstacleSpawnCooldown = obstacleSpawnInterval
        }

        // 7) Spawn powerups
        powerupSpawnCooldown -= dt
        if powerupSpawnCooldown <= 0 {
            spawnPowerup()
            powerupSpawnCooldown = powerupSpawnInterval * Double.random(in: 0.8...1.2)
        }

        // 8) Move obstacles (they use their own stored speed)
        for i in obstacles.indices {
            obstacles[i].y += obstacles[i].speed * CGFloat(dt * speedMultiplier)
        }

        // 9) Move powerups
        for i in powerups.indices {
            powerups[i].y += powerups[i].speed * CGFloat(dt * speedMultiplier)

            // Magnet effect
            if hasMagnet && powerups[i].type == .coin {
                let dx = player.x - powerups[i].x
                let dy = player.y - powerups[i].y
                let dist = sqrt(dx * dx + dy * dy)

                if dist < 150 && dist > 0 {
                    let attractSpeed:  CGFloat = 200
                    powerups[i].x += (dx / dist) * attractSpeed * CGFloat(dt)
                    powerups[i].y += (dy / dist) * attractSpeed * CGFloat(dt)
                }
            }
        }

        // 10) Update particles
        updateParticles(dt: dt)

        // 11) Remove off-screen obstacles
        let before = obstacles.count
        obstacles.removeAll { $0.y - $0.radius > worldHeight + 20 }
        let removed = before - obstacles.count
        if removed > 0 {
            score += removed * 2
        }

        // 12) Remove off-screen powerups
        powerups.removeAll { $0.y - $0.radius > worldHeight + 20 }

        // 13) Check powerup collection
        checkPowerupCollection()

        // 14) Check collision with obstacles
        if checkCollision() {
            if hasShield {
                hasShield = false
                shieldTimeRemaining = 0

                if let index = obstacles.firstIndex(where: { obs in
                    let dx = obs.x - player.x
                    let dy = obs.y - player.y
                    let dist2 = dx*dx + dy*dy
                    let r = obs.radius + player.radius
                    return dist2 <= r*r
                }) {
                    let obs = obstacles[index]
                    spawnExplosion(at: obs.x, y: obs.y, color: .cyan, count: 12)
                    obstacles.remove(at: index)
                }

                haptic(.medium)
                score += 15
                recentScoreIncrease = 15
            } else {
                endGame()
            }
        }
    }

    // MARK: - Difficulty Scaling (NEW IMPROVED SYSTEM)

    private func updateDifficulty() {
        // Increase difficulty every 5 seconds
        if gameTime - lastDifficultyIncrease >= difficultyIncreaseInterval {
            lastDifficultyIncrease = gameTime
            difficultyLevel += 1
            currentDifficultyLevel = difficultyLevel
            
            // Trigger visual feedback
            difficultyJustIncreased = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.difficultyJustIncreased = false
            }
            
            // Decrease spawn interval (more obstacles spawn)
            // Minimum spawn interval is 0.2 seconds
            obstacleSpawnInterval = max(0.2, baseSpawnInterval - (Double(difficultyLevel) * spawnIntervalDecreasePerLevel))
            
            // Also slightly decrease powerup spawn interval to help player
            powerupSpawnInterval = max(1.5, 2.5 - (Double(difficultyLevel) * 0.05))
            
            // Add haptic feedback for difficulty increase
            haptic(.medium)
            
            print("Difficulty increased to level \(difficultyLevel)!  Speed bonus: +\(CGFloat(difficultyLevel) * speedIncreasePerLevel), Spawn interval: \(obstacleSpawnInterval)")
        }
    }
    
    // Calculate current obstacle speed based on difficulty
    private func currentObstacleSpeedRange() -> (min: CGFloat, max: CGFloat) {
        let bonus = CGFloat(difficultyLevel) * speedIncreasePerLevel
        let minSpeed = baseObstacleSpeedMin + bonus
        let maxSpeed = baseObstacleSpeedMax + bonus
        
        // Cap maximum speed at 600 to keep game playable
        return (min: min(minSpeed, 500), max: min(maxSpeed, 600))
    }

    // MARK:  - Powerup Timers

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
    }

    // MARK: - Spawning

    private func spawnObstacle() {
        let radius = CGFloat.random(in: 14...26)
        let minX = radius
        let maxX = worldWidth - radius
        let x = CGFloat.random(in: minX...maxX)
        let y:  CGFloat = -30
        
        // Use difficulty-scaled speed range
        let speedRange = currentObstacleSpeedRange()
        let speed = CGFloat.random(in: speedRange.min...speedRange.max)

        let obs = Obstacle(x: x, y: y, radius: radius, speed: speed)
        obstacles.append(obs)
    }

    private func spawnPowerup() {
        let type = weightedRandomPowerup()
        let radius:  CGFloat = 16
        let minX = radius + 10
        let maxX = worldWidth - radius - 10
        let x = CGFloat.random(in: minX...maxX)
        let y: CGFloat = -30
        let speed = CGFloat.random(in: 100...160)

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
        return . coin
    }

    // MARK: - Collision Detection

    private func checkCollision() -> Bool {
        for obs in obstacles {
            let dx = obs.x - player.x
            let dy = obs.y - player.y
            let dist2 = dx*dx + dy*dy
            let r = obs.radius + player.radius
            if dist2 <= r*r {
                return true
            }
        }
        return false
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
        comboTimer = comboWindow

        let comboBonus = combo > 1 ? combo * 5 : 0

        switch type {
        case . coin:
            let points = 25 + comboBonus
            score += points
            recentScoreIncrease = points
            coinsCollected += 1
            haptic(.light)
            
            // Milestone achievements for coins
            checkMilestone(coins: coinsCollected)

        case .shield:
            hasShield = true
            shieldTimeRemaining = type.duration
            let points = 10 + comboBonus
            score += points
            recentScoreIncrease = points
            haptic(.medium)

        case .slowMo:
            hasSlowMo = true
            slowMoTimeRemaining = type.duration
            let points = 10 + comboBonus
            score += points
            recentScoreIncrease = points
            haptic(.medium)

        case .magnet:
            hasMagnet = true
            magnetTimeRemaining = type.duration
            let points = 10 + comboBonus
            score += points
            recentScoreIncrease = points
            haptic(.medium)
        }
    }
    
    // MARK: - Milestone System
    
    private func checkMilestone(coins: Int) {
        let milestones = [10, 25, 50, 100, 250, 500]
        if milestones.contains(coins) {
            showMilestoneNotification("🎯 \(coins) Coins Collected!")
        }
    }
    
    private func checkScoreMilestone(currentScore: Int) {
        let scoreMilestones = [100, 250, 500, 1000, 2500, 5000, 10000]
        for milestone in scoreMilestones {
            if currentScore >= milestone && (currentScore - Int(10 * 0.016)) < milestone {
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

    private func spawnExplosion(at x:  CGFloat, y: CGFloat, color: Color, count: Int) {
        // Limit total particles to prevent performance issues
        let maxParticles = 150
        if particles.count > maxParticles {
            particles.removeFirst(min(count, particles.count - maxParticles + count))
        }
        
        for _ in 0..<count {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 50...150)
            let particle = Particle(
                x: x,
                y: y,
                vx: cos(angle) * speed,
                vy: sin(angle) * speed,
                size: CGFloat.random(in: 4...10),
                color: color,
                opacity: 1.0,
                lifetime: Double.random(in: 0.3...0.6)
            )
            particles.append(particle)
        }
    }

    private func updateParticles(dt:  Double) {
        for i in particles.indices.reversed() {
            particles[i].x += particles[i].vx * CGFloat(dt)
            particles[i].y += particles[i].vy * CGFloat(dt)
            particles[i].age += dt
            particles[i].opacity = max(0, 1 - particles[i].age / particles[i].lifetime)
            particles[i].vy += 200 * CGFloat(dt)
        }

        particles.removeAll { $0.age >= $0.lifetime }
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
    }

    private func saveStatistics() {
        UserDefaults.standard.set(totalGamesPlayed, forKey: totalGamesKey)
        UserDefaults.standard.set(totalCoinsCollected, forKey: totalCoinsKey)
    }

    // MARK: - Haptics

    enum HapticStyle { case light, medium, heavy }

    private func haptic(_ style: HapticStyle) {
        let gen:  UIImpactFeedbackGenerator
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
