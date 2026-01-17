import SwiftUI
import Combine

struct ContentView:  View {
    @StateObject private var engine = GameEngine()
    @State private var showCombo = false
    @State private var comboScale: CGFloat = 1.0
    @State private var scorePopupOffset: CGFloat = 0
    @State private var scorePopupOpacity: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 背景 with animated gradient
                AnimatedBackground()
                    .ignoresSafeArea()

                // 游戏画布区域
                gameCanvas(size: geo.size)
                    .onAppear {
                        engine.setWorldSize(width: geo.size.width, height: geo.size.height)
                    }
                    .onChange(of: geo.size) { _, newSize in
                        engine.setWorldSize(width: newSize.width, height: newSize.height)
                    }

                // Particles layer
                particlesLayer

                // Active powerup indicators
                if engine.state == .playing {
                    activePowerupsBar
                        .padding(.top, 70)
                        .frame(maxHeight: .infinity, alignment: .top)
                }

                // Combo indicator
                if showCombo && engine.combo > 1 {
                    comboIndicator
                }
                
                // Milestone achievement notification
                if engine.showMilestone {
                    milestoneNotification
                }
                
                // Score popup animation
                if engine.recentScoreIncrease > 0 && scorePopupOpacity > 0 {
                    scorePopup
                }

                // HUD 顶部信息
                hudOverlay
                    .padding(.top, 14)
                    .frame(maxHeight: .infinity, alignment: . top)

                // Ready / GameOver 面板
                overlayPanels
            }
        }
        .onChange(of: engine.combo) { oldValue, newValue in
            if newValue > 1 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    showCombo = true
                    comboScale = 1.3
                }
                withAnimation(.easeOut(duration: 0.2).delay(0.1)) {
                    comboScale = 1.0
                }
                // Hide combo after delay
                DispatchQueue.main.asyncAfter(deadline: . now() + 1.5) {
                    if engine.combo == newValue {
                        withAnimation { showCombo = false }
                    }
                }
            }
        }
        .onChange(of: engine.recentScoreIncrease) { oldValue, newValue in
            if newValue > 0 {
                // Animate score popup
                scorePopupOffset = 0
                scorePopupOpacity = 1.0
                withAnimation(.easeOut(duration: 1.0)) {
                    scorePopupOffset = -40
                    scorePopupOpacity = 0
                }
                // Reset after animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak engine] in
                    engine?.recentScoreIncrease = 0
                }
            }
        }
    }

    // MARK: - Animated Background

    struct AnimatedBackground: View {
        var body: some View {
            ZStack {
                // 静态深色背景
                LinearGradient(
                    colors:  [
                        Color(red: 0.05, green: 0.05, blue: 0.15),
                        Color.black,
                        Color(red: 0.1, green: 0.05, blue: 0.15)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // 添加一些静态"星星"
                ForEach(0..<30, id: \.self) { _ in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.3...0.6)))
                        .frame(width: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                            y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                        )
                }
            }
        }
    }

    // MARK: - Game Canvas

    private func gameCanvas(size: CGSize) -> some View {
        ZStack {
            // Obstacles
            ForEach(engine.obstacles) { obs in
                ObstacleView(obstacle: obs, isFrozen: engine.hasFreeze)
            }

            // Powerups
            ForEach(engine.powerups) { powerup in
                PowerupView(powerup: powerup)
            }

            // Player
            PlayerView(
                player: engine.player,
                hasShield: engine.hasShield,
                hasMagnet: engine.hasMagnet,
                hasSpeedBoost: engine.hasSpeedBoost,
                hasFreeze: engine.hasFreeze,
                playerColor: engine.currentPlayerColor
            )
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 5)
                .onChanged { value in
                    engine.setPlayerX(value.location.x)
                }
        )
        .overlay(alignment: .bottom) {
            Text("Drag to move")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.bottom, 22)
                .opacity(engine.state == .playing ? 1 : 0)
        }
    }

    // MARK: - Player View

    struct PlayerView: View {
        let player: Player
        let hasShield: Bool
        let hasMagnet: Bool
        let hasSpeedBoost: Bool
        let hasFreeze: Bool
        let playerColor: Color

        @State private var pulseShield = false
        @State private var rotateMagnet = false
        @State private var speedTrail = false

        var body: some View {
            ZStack {
                // Speed boost trail effect
                if hasSpeedBoost {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.green.opacity(0.2 - Double(i) * 0.05))
                            .frame(width: player.radius * 2, height: player.radius * 2)
                            .offset(y: CGFloat(i + 1) * 8)
                    }
                }
                
                // Magnet field indicator
                if hasMagnet {
                    Circle()
                        .stroke(Color.purple.opacity(0.3), lineWidth: 2)
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(rotateMagnet ? 360 : 0))
                        .onAppear {
                            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                                rotateMagnet = true
                            }
                        }
                }

                // Shield effect
                if hasShield {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.cyan, .blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .frame(width: player.radius * 2 + 16, height: player.radius * 2 + 16)
                        .scaleEffect(pulseShield ? 1.1 : 1.0)
                        .opacity(pulseShield ? 0.7 : 1.0)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                                pulseShield = true
                            }
                        }

                    Circle()
                        .fill(Color.cyan.opacity(0.2))
                        .frame(width: player.radius * 2 + 12, height: player.radius * 2 + 12)
                }
                
                // Freeze indicator ring
                if hasFreeze {
                    Circle()
                        .stroke(Color.blue.opacity(0.5), lineWidth: 3)
                        .frame(width: player.radius * 2 + 20, height: player.radius * 2 + 20)
                }

                // Player ball with gradient
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [playerColor, playerColor.opacity(0.8)],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: player.radius * 2
                        )
                    )
                    .frame(width: player.radius * 2, height: player.radius * 2)
                    .shadow(color: hasShield ? .cyan : (hasSpeedBoost ? .green : playerColor.opacity(0.5)), radius: hasShield ? 15 : 10, y: 6)
            }
            .position(x: player.x, y: player.y)
        }
    }

    // MARK: - Obstacle View

    struct ObstacleView: View {
        let obstacle: Obstacle
        let isFrozen: Bool

        var body: some View {
            ZStack {
                // Glow effect
                Circle()
                    .fill((isFrozen ? Color.blue : Color.red).opacity(0.3))
                    .frame(width: obstacle.radius * 2.5, height: obstacle.radius * 2.5)
                    .blur(radius: 8)

                // Main obstacle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: isFrozen ? [.blue, .blue.opacity(0.7)] : [.red, .red.opacity(0.7)],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: obstacle.radius * 2
                        )
                    )
                    .frame(width: obstacle.radius * 2, height: obstacle.radius * 2)
                    .shadow(color: (isFrozen ? Color.blue : Color.red).opacity(0.5), radius: 6, y: 3)
            }
            .position(x: obstacle.x, y: obstacle.y)
        }
    }

    // MARK: - Powerup View

    struct PowerupView: View {
        let powerup: Powerup

        @State private var bounce = false
        @State private var glow = false

        var body: some View {
            ZStack {
                // Glow
                Circle()
                    .fill(powerup.type.color.opacity(0.4))
                    .frame(width: powerup.radius * 3, height: powerup.radius * 3)
                    .blur(radius: 10)
                    .scaleEffect(glow ? 1.2 : 0.8)

                // Icon background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [powerup.type.color, powerup.type.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: powerup.radius * 2, height: powerup.radius * 2)
                    .shadow(color: powerup.type.color.opacity(0.6), radius: 8)

                // Icon
                Image(systemName: powerup.type.icon)
                    .font(.system(size: powerup.radius * 0.9, weight: .bold))
                    .foregroundColor(.white)
            }
            .scaleEffect(bounce ? 1.1 : 1.0)
            .position(x: powerup.x, y: powerup.y)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    bounce = true
                    glow = true
                }
            }
        }
    }

    // MARK: - Particles Layer

    private var particlesLayer: some View {
        ForEach(engine.particles) { particle in
            Circle()
                .fill(particle.color)
                .frame(width: particle.size, height: particle.size)
                .position(x: particle.x, y: particle.y)
                .opacity(particle.opacity)
        }
    }

    // MARK: - Active Powerups Bar

    private var activePowerupsBar: some View {
        HStack(spacing: 8) {
            if engine.hasShield {
                powerupTimer(icon: "shield.fill", color: .cyan, remaining: engine.shieldTimeRemaining)
            }
            if engine.hasSlowMo {
                powerupTimer(icon: "clock.fill", color: .orange, remaining: engine.slowMoTimeRemaining)
            }
            if engine.hasMagnet {
                powerupTimer(icon: "magnet", color: .purple, remaining: engine.magnetTimeRemaining)
            }
            if engine.hasSpeedBoost {
                powerupTimer(icon: "bolt.fill", color: .green, remaining: engine.speedBoostTimeRemaining)
            }
            if engine.hasFreeze {
                powerupTimer(icon: "snowflake", color: .blue, remaining: engine.freezeTimeRemaining)
            }
        }
        .padding(.horizontal)
    }

    private func powerupTimer(icon: String, color: Color, remaining: Double) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption.bold())
            Text(String(format: "%.1f", remaining))
                .font(.caption.monospacedDigit())
        }
        .foregroundColor(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.7))
        .clipShape(Capsule())
    }

    // MARK: - Combo Indicator

    private var comboIndicator: some View {
        VStack(spacing: 4) {
            Text("COMBO")
                .font(.caption.bold())
                .foregroundColor(.orange)
            Text("x\(engine.combo)")
                .font(.title.bold())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.orange.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .scaleEffect(comboScale)
        .position(x: UIScreen.main.bounds.width / 2, y: 150)
    }
    
    // MARK: - Milestone Notification
    
    private var milestoneNotification: some View {
        Text(engine.milestoneText)
            .font(.title2.bold())
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .opacity(0.9)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .purple.opacity(0.5), radius: 20)
            .position(x: UIScreen.main.bounds.width / 2, y: 200)
            .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Score Popup
    
    private var scorePopup: some View {
        Text("+\(engine.recentScoreIncrease)")
            .font(.title3.bold())
            .foregroundStyle(.yellow)
            .shadow(color: .black.opacity(0.5), radius: 2)
            .offset(x: engine.player.x, y: engine.player.y + scorePopupOffset - 40)
            .opacity(scorePopupOpacity)
    }
    
    // MARK: - Lives Indicator
    
    private var livesIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<GameConstants.maxLives, id: \.self) { i in
                Image(systemName: i < engine.lives ? "heart.fill" : "heart")
                    .foregroundColor(i < engine.lives ? .red : .gray.opacity(0.5))
                    .font(.system(size: 14))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.red.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - Time Attack Timer
    
    private var timeAttackTimer: some View {
        HStack(spacing: 4) {
            Image(systemName: "timer")
                .foregroundColor(.white)
            Text(String(format: "%.1f", engine.timeRemaining))
                .font(.headline.monospacedDigit().bold())
                .foregroundColor(engine.timeRemaining < 10 ? .red : .white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(engine.timeRemaining < 10 ? Color.red.opacity(0.3) : Color.blue.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - HUD

    private var hudOverlay: some View {
        HStack(spacing: 8) {
            hudPill(title: "Score", value: "\(engine.score)", highlight: false)
            
            // Lives indicator during gameplay
            if engine.state == .playing {
                livesIndicator
            }

            Spacer()
            
            // Time Attack timer
            if engine.state == .playing && engine.settings.selectedMode == .timeAttack {
                timeAttackTimer
            }

            // Difficulty level indicator (only during gameplay)
            if engine.state == .playing {
                VStack(spacing: 2) {
                    Text("Level")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\(engine.currentDifficultyLevel)")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(engine.difficultyJustIncreased ? .red : .orange)
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(engine.difficultyJustIncreased ? .red.opacity(0.3) : .orange.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .scaleEffect(engine.difficultyJustIncreased ? 1.15 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: engine.difficultyJustIncreased)
            }

            // Coins collected
            if engine.state == .playing {
                HStack(spacing: 4) {
                    Image(systemName: "star.circle.fill")
                        .foregroundColor(.yellow)
                    Text("\(engine.coinsCollected)")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(.yellow.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            if engine.state == .playing {
                Button {
                    engine.pauseGame()
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.white.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(.horizontal, 14)
    }

    private func hudPill(title: String, value: String, highlight: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(highlight ? .yellow : .white)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(highlight ? .yellow.opacity(0.2) : .white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Overlays

    @ViewBuilder
    private var overlayPanels: some View {
        switch engine.state {
        case .ready:
            if engine.showSettings {
                settingsPanel
            } else {
                readyPanel
            }
        case .gameOver:
            gameOverPanel
        case .playing:
            EmptyView()
        case .paused:
            pausedPanel
        }
    }

    private var readyPanel: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Title with glow effect
                Text("🎮 Dodge Game")
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .cyan.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .cyan.opacity(0.5), radius: 10)
                    .padding(.top, 4)

                // Game Mode Selector with glass effect
                VStack(spacing: 10) {
                    Text("Game Mode")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.8))
                    
                    HStack(spacing: 8) {
                        ForEach(GameMode.allCases) { mode in
                            Button {
                                engine.settings.selectedMode = mode
                            } label: {
                                VStack(spacing: 4) {
                                    Text(mode.rawValue)
                                        .font(.caption.bold())
                                    if mode == .timeAttack {
                                        Text("\(engine.settings.timeAttackDuration)s")
                                            .font(.caption2)
                                    }
                                }
                                .foregroundStyle(engine.settings.selectedMode == mode ? .black : .white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Group {
                                        if engine.settings.selectedMode == mode {
                                            Color.white
                                        } else {
                                            Color.white.opacity(0.15)
                                        }
                                    }
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(engine.settings.selectedMode == mode ? 0 : 0.3), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .shadow(color: engine.settings.selectedMode == mode ? .white.opacity(0.3) : .clear, radius: 8)
                            }
                        }
                    }
                    
                    Text(engine.settings.selectedMode.description)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                        .padding(.top, 2)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(
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
                )

                // Powerups Legend with glass containers
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        powerupLegend(icon: "star.circle.fill", color: .yellow, text: "Coins")
                        powerupLegend(icon: "shield.fill", color: .cyan, text: "Shield/Life")
                        powerupLegend(icon: "clock.fill", color: .orange, text: "Slow")
                    }
                    HStack(spacing: 10) {
                        powerupLegend(icon: "magnet", color: .purple, text: "Magnet")
                        powerupLegend(icon: "bolt.fill", color: .green, text: "Speed")
                        powerupLegend(icon: "snowflake", color: .blue, text: "Freeze")
                    }
                    HStack(spacing: 10) {
                        powerupLegend(icon: "flame.fill", color: .red, text: "Bomb")
                        Spacer().frame(width: 60)
                        Spacer().frame(width: 60)
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(
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
                )

                // Statistics display with enhanced glass effect
                if engine.totalGamesPlayed > 0 {
                    HStack(spacing: 16) {
                        VStack(spacing: 3) {
                            Text("\(engine.totalGamesPlayed)")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                            Text("Games")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                            .frame(height: 30)
                        
                        VStack(spacing: 3) {
                            Text("\(engine.totalCoinsCollected)")
                                .font(.title3.bold())
                                .foregroundStyle(.yellow)
                            Text("Total Coins")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                            .frame(height: 30)
                        
                        VStack(spacing: 3) {
                            Text("\(engine.bestScore)")
                                .font(.title3.bold())
                                .foregroundStyle(.green)
                            Text("Best Score")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
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
                    )
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                }

                // Buttons with enhanced styling
                VStack(spacing: 12) {
                    Button {
                        engine.startGame()
                    } label: {
                        Text("START")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.black)
                            .padding(.vertical, 16)
                            .frame(maxWidth: 240)
                            .background(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .shadow(color: .white.opacity(0.5), radius: 15, y: 5)
                    }
                    
                    Button {
                        engine.showSettings = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "gearshape.fill")
                            Text("Settings")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 12)
                        .frame(maxWidth: 200)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .background(
            ZStack {
                // Liquid glass effect with multiple layers
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                // Gradient overlay for depth
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05),
                                Color.cyan.opacity(0.08),
                                Color.purple.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Border gradient for liquid glass effect
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.cyan.opacity(0.4),
                                Color.white.opacity(0.2),
                                Color.purple.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        .shadow(color: .cyan.opacity(0.2), radius: 30, y: 15)
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
    }
    
    // MARK: - Settings Panel
    
    private var settingsPanel: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                // Title with gradient
                Text("⚙️ Settings")
                    .font(.title.weight(.heavy))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .cyan.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .cyan.opacity(0.5), radius: 10)
                    .padding(.top, 4)
                
                // Haptic Toggle with glass effect
                VStack(spacing: 8) {
                    Toggle(isOn: $engine.settings.hapticEnabled) {
                        HStack(spacing: 8) {
                            Image(systemName: "iphone.radiowaves.left.and.right")
                            Text("Haptic Feedback")
                        }
                        .foregroundStyle(.white)
                    }
                    .tint(.green)
                }
                .padding()
                .background(
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
                )
                
                // Time Attack Duration with glass effect
                if engine.settings.selectedMode == .timeAttack {
                    VStack(spacing: 10) {
                        Text("Time Attack Duration")
                            .font(.caption.bold())
                            .foregroundStyle(.white.opacity(0.8))
                        
                        HStack(spacing: 10) {
                            ForEach(GameConstants.timeAttackDurations, id: \.self) { duration in
                                Button {
                                    engine.settings.timeAttackDuration = duration
                                } label: {
                                    Text("\(duration)s")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(engine.settings.timeAttackDuration == duration ? .black : .white)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            Group {
                                                if engine.settings.timeAttackDuration == duration {
                                                    Color.white
                                                } else {
                                                    Color.white.opacity(0.15)
                                                }
                                            }
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.white.opacity(engine.settings.timeAttackDuration == duration ? 0 : 0.3), lineWidth: 1)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
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
                    )
                }
                
                // Player Color Selection with glass effect
                VStack(spacing: 14) {
                    Text("Player Color")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.8))
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 10) {
                        ForEach(0..<GameSettings.playerColors.count, id: \.self) { index in
                            let color = GameSettings.playerColors[index]
                            let name = GameSettings.playerColorNames[index]
                            let cost = GameSettings.playerColorCosts[index]
                            let isUnlocked = engine.unlockedColors.contains(index)
                            let isSelected = engine.settings.playerColorIndex == index
                            
                            Button {
                                if isUnlocked {
                                    engine.selectColor(index: index)
                                } else if engine.canAffordColor(index: index) {
                                    _ = engine.unlockColor(index: index)
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Circle()
                                                .stroke(isSelected ? Color.white : Color.clear, lineWidth: 3)
                                        )
                                        .shadow(color: isSelected ? color.opacity(0.6) : .clear, radius: 10)
                                    
                                    Text(name)
                                        .font(.caption2)
                                        .foregroundStyle(.white)
                                    
                                    if !isUnlocked {
                                        HStack(spacing: 2) {
                                            Image(systemName: "lock.fill")
                                                .font(.system(size: 8))
                                            Text("\(cost)")
                                                .font(.caption2)
                                        }
                                        .foregroundStyle(engine.canAffordColor(index: index) ? .yellow : .gray)
                                    }
                                }
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isSelected ? color.opacity(0.2) : Color.white.opacity(0.08))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(isSelected ? color.opacity(0.5) : Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    
                    HStack(spacing: 6) {
                        Image(systemName: "star.circle.fill")
                            .foregroundStyle(.yellow)
                        Text("Your coins: \(engine.totalCoinsCollected)")
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
                .padding()
                .background(
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
                )
                
                Button {
                    engine.saveSettings()
                    engine.showSettings = false
                } label: {
                    Text("Done")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.black)
                        .padding(.vertical, 14)
                        .frame(maxWidth: 200)
                        .background(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: .white.opacity(0.5), radius: 15, y: 5)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .background(
            ZStack {
                // Liquid glass effect
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                // Gradient overlay
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05),
                                Color.cyan.opacity(0.08),
                                Color.purple.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Border gradient
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.cyan.opacity(0.4),
                                Color.white.opacity(0.2),
                                Color.purple.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        .shadow(color: .cyan.opacity(0.2), radius: 30, y: 15)
        .padding(.horizontal, 20)
        .padding(.vertical, 30)
    }

    private func powerupLegend(icon: String, color: Color, text: String) -> some View {
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

    private var gameOverPanel: some View {
        VStack(spacing: 14) {
            if engine.timeAttackWon {
                Text("🏆 YOU WON!")
                    .font(.title.weight(.heavy))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .green.opacity(0.5), radius: 10)
            } else {
                Text("💥 GAME OVER")
                    .font(.title.weight(.heavy))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .white.opacity(0.3), radius: 10)
            }

            VStack(spacing: 6) {
                Text("Score: \(engine.score)")
                    .font(.title2.bold())
                    .foregroundStyle(engine.score >= engine.bestScore ? .yellow : .white)

                if engine.score >= engine.bestScore && engine.score > 0 {
                    Text("🎉 NEW BEST!")
                        .font(.headline)
                        .foregroundColor(.yellow)
                        .shadow(color: .yellow.opacity(0.5), radius: 8)
                }

                HStack(spacing: 20) {
                    VStack(spacing: 2) {
                        Text("Coins: \(engine.coinsCollected)")
                            .foregroundStyle(.yellow)
                        Text("Level Reached: \(engine.currentDifficultyLevel)")
                            .foregroundStyle(.orange)
                    }
                    .font(.subheadline)
                }
                .padding(.top, 4)

                Text("Best: \(engine.bestScore)")
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 2)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )

            HStack(spacing: 12) {
                Button {
                    engine.startGame()
                } label: {
                    Text("RETRY")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.black)
                        .padding(.vertical, 13)
                        .frame(maxWidth: 140)
                        .background(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .white.opacity(0.4), radius: 10)
                }

                Button {
                    engine.resetToReady()
                } label: {
                    Text("MENU")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 13)
                        .frame(maxWidth: 140)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 22)
        .background(
            ZStack {
                // Liquid glass effect
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                // Gradient overlay
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05),
                                Color.red.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Border gradient
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        .padding(.horizontal, 20)
    }

    private var pausedPanel: some View {
        VStack(spacing: 16) {
            Text("⏸️ PAUSED")
                .font(.title.weight(.heavy))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .cyan.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .cyan.opacity(0.5), radius: 10)

            VStack(spacing: 6) {
                Text("Score: \(engine.score)")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                
                // Show lives remaining
                HStack(spacing: 4) {
                    Text("Lives:")
                        .foregroundStyle(.white.opacity(0.7))
                    ForEach(0..<engine.lives, id: \.self) { _ in
                        Image(systemName: "heart.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 12))
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )

            VStack(spacing: 10) {
                Button {
                    engine.resumeGame()
                } label: {
                    Text("RESUME")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.black)
                        .padding(.vertical, 13)
                        .frame(maxWidth: 180)
                        .background(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .white.opacity(0.4), radius: 10)
                }

                Button {
                    engine.resetToReady()
                } label: {
                    Text("QUIT")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 13)
                        .frame(maxWidth: 180)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 26)
        .background(
            ZStack {
                // Liquid glass effect
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(.ultraThinMaterial)
                
                // Gradient overlay
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05),
                                Color.cyan.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Border gradient
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.cyan.opacity(0.4),
                                Color.white.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        .shadow(color: .cyan.opacity(0.2), radius: 30, y: 15)
        .padding(.horizontal, 20)
    }
}

#Preview {
    ContentView()
}
