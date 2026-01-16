import SwiftUI
import Combine

struct ContentView:  View {
    @StateObject private var engine = GameEngine()
    @State private var showCombo = false
    @State private var comboScale: CGFloat = 1.0

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

    private func gameCanvas(size:  CGSize) -> some View {
        ZStack {
            // 障碍物
            ForEach(engine.obstacles) { obs in
                ObstacleView(obstacle: obs)
            }

            // Powerups
            ForEach(engine.powerups) { powerup in
                PowerupView(powerup: powerup)
            }

            // 玩家
            PlayerView(
                player: engine.player,
                hasShield: engine.hasShield,
                hasMagnet: engine.hasMagnet
            )
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    engine.setPlayerX(value.location.x)
                }
        )
        .overlay(alignment: .bottom) {
            Text("Drag anywhere to move")
                .font(. caption)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.bottom, 22)
                .opacity(engine.state == .playing ?  1 : 0)
        }
    }

    // MARK: - Player View

    struct PlayerView: View {
        let player: Player
        let hasShield: Bool
        let hasMagnet: Bool

        @State private var pulseShield = false
        @State private var rotateMagnet = false

        var body: some View {
            ZStack {
                // Magnet field indicator
                if hasMagnet {
                    Circle()
                        .stroke(Color.purple.opacity(0.3), lineWidth: 2)
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(rotateMagnet ? 360 : 0))
                        .onAppear {
                            withAnimation(.linear(duration: 2).repeatForever(autoreverses:  false)) {
                                rotateMagnet = true
                            }
                        }
                }

                // Shield effect
                if hasShield {
                    Circle()
                        . stroke(
                            LinearGradient(
                                colors: [. cyan, .blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        . frame(width: player.radius * 2 + 16, height: player.radius * 2 + 16)
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

                // Player ball with gradient
                Circle()
                    . fill(
                        RadialGradient(
                            colors: [.white, .white.opacity(0.8)],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: player.radius * 2
                        )
                    )
                    .frame(width: player.radius * 2, height: player.radius * 2)
                    .shadow(color: hasShield ? .cyan : .white.opacity(0.5), radius: hasShield ? 15 : 10, y: 6)
            }
            .position(x: player.x, y: player.y)
        }
    }

    // MARK: - Obstacle View

    struct ObstacleView: View {
        let obstacle: Obstacle

        var body: some View {
            ZStack {
                // Glow effect
                Circle()
                    .fill(Color.red.opacity(0.3))
                    .frame(width: obstacle.radius * 2.5, height: obstacle.radius * 2.5)
                    .blur(radius: 8)

                // Main obstacle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.red, .red.opacity(0.7)],
                            center: . topLeading,
                            startRadius: 0,
                            endRadius: obstacle.radius * 2
                        )
                    )
                    .frame(width: obstacle.radius * 2, height: obstacle.radius * 2)
                    .shadow(color: .red.opacity(0.5), radius: 6, y: 3)
            }
            .position(x: obstacle.x, y: obstacle.y)
        }
    }

    // MARK: - Powerup View

    struct PowerupView: View {
        let powerup: Powerup

        @State private var bounce = false
        @State private var glow = false

        var body:  some View {
            ZStack {
                // Glow
                Circle()
                    .fill(powerup.type.color.opacity(0.4))
                    .frame(width: powerup.radius * 3, height: powerup.radius * 3)
                    .blur(radius: 10)
                    .scaleEffect(glow ? 1.2 : 0.8)

                // Icon background
                Circle()
                    . fill(
                        LinearGradient(
                            colors: [powerup.type.color, powerup.type.color.opacity(0.7)],
                            startPoint:  .topLeading,
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
                withAnimation(. easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
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
                powerupTimer(icon: "shield. fill", color: .cyan, remaining: engine.shieldTimeRemaining)
            }
            if engine.hasSlowMo {
                powerupTimer(icon: "clock.fill", color: .yellow, remaining: engine.slowMoTimeRemaining)
            }
            if engine.hasMagnet {
                powerupTimer(icon: "magnet", color: .purple, remaining: engine.magnetTimeRemaining)
            }
        }
        .padding(.horizontal)
    }

    private func powerupTimer(icon: String, color: Color, remaining: Double) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption.bold())
            Text(String(format: "%. 1f", remaining))
                .font(.caption.monospacedDigit())
        }
        . foregroundColor(. white)
        .padding(. horizontal, 10)
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

    // MARK: - HUD

    private var hudOverlay: some View {
        HStack(spacing: 12) {
            hudPill(title: "Score", value: "\(engine.score)", highlight: false)
            hudPill(title: "Best", value: "\(engine.bestScore)", highlight: engine.score > 0 && engine.score >= engine.bestScore)

            Spacer()

            // Coins collected
            if engine.state == .playing {
                HStack(spacing: 4) {
                    Image(systemName:  "star.circle.fill")
                        .foregroundColor(.yellow)
                    Text("\(engine.coinsCollected)")
                        . font(.headline.weight(.bold))
                        .foregroundColor(.white)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(. yellow.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            if engine.state == .playing {
                Button {
                    engine.pauseGame()
                } label:  {
                    Image(systemName: "pause.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(. white.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(. horizontal, 14)
    }

    private func hudPill(title: String, value: String, highlight: Bool) -> some View {
        VStack(alignment:  .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(highlight ? .yellow : .white)
        }
        .padding(. vertical, 8)
        .padding(.horizontal, 12)
        .background(highlight ?  . yellow.opacity(0.2) : .white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Overlays

    @ViewBuilder
    private var overlayPanels: some View {
        switch engine.state {
        case . ready:
            readyPanel
        case .gameOver:
            gameOverPanel
        case .playing:
            EmptyView()
        case .paused:
            pausedPanel
        }
    }

    private var readyPanel: some View {
        VStack(spacing: 14) {
            Text("🎮 Dodge + Powerups")
                .font(.largeTitle.weight(.heavy))
                .foregroundStyle(.white)

            VStack(spacing: 8) {
                Text("Survive as long as possible!")
                    .foregroundStyle(.white.opacity(0.9))

                HStack(spacing: 16) {
                    powerupLegend(icon: "star.circle.fill", color: .yellow, text: "+Points")
                    powerupLegend(icon: "shield.fill", color: .cyan, text: "Shield")
                }
                HStack(spacing: 16) {
                    powerupLegend(icon: "clock.fill", color: .yellow, text: "Slow-Mo")
                    powerupLegend(icon: "magnet", color: .purple, text: "Magnet")
                }
            }
            .padding(.vertical, 8)

            Button {
                engine.startGame()
            } label: {
                Text("START")
                    .font(.headline.weight(.bold))
                    . foregroundStyle(.black)
                    .padding(. vertical, 14)
                    .frame(maxWidth: 220)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(26)
        .background(. ultraThinMaterial.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 18)
    }

    private func powerupLegend(icon:  String, color: Color, text:  String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(text)
                .font(. caption)
                .foregroundColor(.white.opacity(0.8))
        }
    }

    private var gameOverPanel: some View {
        VStack(spacing: 12) {
            Text("💥 GAME OVER")
                .font(.title.weight(.heavy))
                .foregroundStyle(. white)

            VStack(spacing: 4) {
                Text("Score: \(engine.score)")
                    .font(.title2.bold())
                    .foregroundStyle(engine.score >= engine.bestScore ? .yellow : .white)

                if engine.score >= engine.bestScore && engine.score > 0 {
                    Text("🎉 NEW BEST!")
                        .font(.headline)
                        .foregroundColor(.yellow)
                }

                Text("Coins: \(engine.coinsCollected)")
                    .foregroundStyle(.white.opacity(0.7))

                Text("Best: \(engine.bestScore)")
                    . foregroundStyle(.white.opacity(0.7))
            }

            HStack(spacing: 12) {
                Button {
                    engine.startGame()
                } label: {
                    Text("RETRY")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.black)
                        .padding(.vertical, 12)
                        .frame(maxWidth: 140)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Button {
                    engine.resetToReady()
                } label: {
                    Text("MENU")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 12)
                        . frame(maxWidth: 140)
                        .background(. white.opacity(0.18))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: . continuous))
                }
            }
        }
        .padding(22)
        .background(.ultraThinMaterial.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 24, style:  .continuous))
        .padding(.horizontal, 18)
    }

    private var pausedPanel:  some View {
        VStack(spacing: 16) {
            Text("⏸️ PAUSED")
                .font(.title.weight(.heavy))
                .foregroundStyle(.white)

            Text("Score: \(engine.score)")
                .foregroundStyle(.white.opacity(0.8))

            VStack(spacing: 10) {
                Button {
                    engine.resumeGame()
                } label:  {
                    Text("RESUME")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.black)
                        .padding(.vertical, 12)
                        .frame(maxWidth: 180)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Button {
                    engine.resetToReady()
                } label: {
                    Text("QUIT")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.vertical, 12)
                        .frame(maxWidth: 180)
                        .background(.white.opacity(0.18))
                        . clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .padding(26)
        .background(.ultraThinMaterial.opacity(0.95))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: . continuous))
        .padding(.horizontal, 18)
    }
}

#Preview {
    ContentView()
}
