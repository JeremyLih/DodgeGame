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

struct Obstacle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var radius: CGFloat
    var speed: CGFloat
}

// MARK: - Game Engine

@MainActor
final class GameEngine: ObservableObject {

    enum GameState {
        case ready
        case playing
        case gameOver
    }

    // Published states for UI
    @Published var state: GameState = .ready
    @Published var score: Int = 0
    @Published var bestScore: Int = 0

    @Published var player: Player = Player(x: 0, y: 0, radius: 18)
    @Published var obstacles: [Obstacle] = []

    // World sizing
    private(set) var worldWidth: CGFloat = 320
    private(set) var worldHeight: CGFloat = 600

    // Game loop
    private var timer: Timer?
    private let fps: Double = 60.0
    private var lastTick: CFAbsoluteTime = CFAbsoluteTimeGetCurrent()

    // Spawning
    private var obstacleSpawnCooldown: Double = 0
    private var obstacleSpawnInterval: Double = 0.55  // 越小越难（后面我们会动态调整）

    // Difficulty
    private var difficultySpeedBonus: CGFloat = 0

    // MARK: - Setup

    func setWorldSize(width: CGFloat, height: CGFloat) {
        worldWidth = max(1, width)
        worldHeight = max(1, height)

        // 初始化玩家位置：底部偏上
        player = Player(
            x: worldWidth / 2,
            y: worldHeight * 0.82,
            radius: 18
        )
    }

    // MARK: - Controls

    /// 直接把玩家 x 位置设置到手指位置（带边界限制）
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
        obstacles.removeAll()

        difficultySpeedBonus = 0
        obstacleSpawnInterval = 0.55
        obstacleSpawnCooldown = 0

        lastTick = CFAbsoluteTimeGetCurrent()

        startLoop()
    }

    func endGame() {
        guard state == .playing else { return }
        state = .gameOver
        stopLoop()

        if score > bestScore {
            bestScore = score
        }

        haptic(.heavy)
    }

    func resetToReady() {
        stopLoop()
        state = .ready
        score = 0
        obstacles.removeAll()
    }

    // MARK: - Loop

    private func startLoop() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / fps, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.tick()
        }
    }

    private func stopLoop() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard state == .playing else { return }

        let now = CFAbsoluteTimeGetCurrent()
        let dt = now - lastTick
        lastTick = now

        update(dt: dt)
    }

    // MARK: - Update

    private func update(dt: Double) {
        // 1) 计分：按时间增长（每秒 +10分，爽一点）
        score += Int(dt * 10.0)

        // 2) 难度：分数越高，速度越快、刷怪越频繁（轻微）
        if score % 60 == 0 { // 大约每 6 秒触发一次（取决于 score 增长速度）
            difficultySpeedBonus += 4
            obstacleSpawnInterval = max(0.28, obstacleSpawnInterval - 0.02)
        }

        // 3) 刷怪
        obstacleSpawnCooldown -= dt
        if obstacleSpawnCooldown <= 0 {
            spawnObstacle()
            obstacleSpawnCooldown = obstacleSpawnInterval
        }

        // 4) 移动所有障碍
        for i in obstacles.indices {
            obstacles[i].y += (obstacles[i].speed + difficultySpeedBonus) * CGFloat(dt)
        }

        // 5) 清理飞出屏幕的障碍（并奖励一点点分）
        let before = obstacles.count
        obstacles.removeAll { $0.y - $0.radius > worldHeight + 20 }
        let removed = before - obstacles.count
        if removed > 0 {
            score += removed * 2
        }

        // 6) 碰撞检测
        if checkCollision() {
            endGame()
        }
    }

    private func spawnObstacle() {
        let radius = CGFloat.random(in: 14...26)

        let minX = radius
        let maxX = worldWidth - radius
        let x = CGFloat.random(in: minX...maxX)

        let y: CGFloat = -30

        // 基础速度
        let baseSpeed = CGFloat.random(in: 220...320)

        let obs = Obstacle(
            x: x,
            y: y,
            radius: radius,
            speed: baseSpeed
        )

        obstacles.append(obs)
    }

    private func checkCollision() -> Bool {
        // 圆与圆碰撞：两圆心距离 <= 半径之和
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

    // MARK: - Haptics

    enum HapticStyle { case light, medium, heavy }

    private func haptic(_ style: HapticStyle) {
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
