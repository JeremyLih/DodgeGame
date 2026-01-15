import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var engine = GameEngine()

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 背景
                LinearGradient(
                    colors: [Color.black, Color.blue.opacity(0.25), Color.black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // 游戏画布区域
                gameCanvas(size: geo.size)
                    .onAppear {
                        engine.setWorldSize(width: geo.size.width, height: geo.size.height)
                    }
                    .onChange(of: geo.size) { _, newSize in
                        engine.setWorldSize(width: newSize.width, height: newSize.height)
                    }

                // HUD 顶部信息
                hudOverlay
                    .padding(.top, 14)
                    .frame(maxHeight: .infinity, alignment: .top)

                // Ready / GameOver 面板
                overlayPanels
            }
        }
    }

    // MARK: - Game Canvas

    private func gameCanvas(size: CGSize) -> some View {
        ZStack {
            // 障碍物
            ForEach(engine.obstacles) { obs in
                Circle()
                    .fill(Color.red.opacity(0.95))
                    .frame(width: obs.radius * 2, height: obs.radius * 2)
                    .position(x: obs.x, y: obs.y)
                    .shadow(radius: 6, y: 3)
            }

            // 玩家
            Circle()
                .fill(Color.white)
                .frame(width: engine.player.radius * 2, height: engine.player.radius * 2)
                .position(x: engine.player.x, y: engine.player.y)
                .shadow(radius: 10, y: 6)
        }
        .contentShape(Rectangle()) // 让整个区域可接收手势
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    engine.setPlayerX(value.location.x)
                }
        )
        .overlay(alignment: .bottom) {
            Text("Drag anywhere to move")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .padding(.bottom, 22)
                .opacity(engine.state == .playing ? 1 : 0)
        }
    }

    // MARK: - HUD

    private var hudOverlay: some View {
        HStack(spacing: 12) {
            hudPill(title: "Score", value: "\(engine.score)")
            hudPill(title: "Best", value: "\(engine.bestScore)")

            Spacer()

            if engine.state == .playing {
                Button {
                    engine.endGame()
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

    private func hudPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Overlays

    @ViewBuilder
    private var overlayPanels: some View {
        switch engine.state {
        case .ready:
            VStack(spacing: 14) {
                Text("Dodge + Powerups")
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(.white)

                Text("Survive as long as possible.\nAvoid the red obstacles.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.75))

                Button {
                    engine.startGame()
                } label: {
                    Text("START")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.black)
                        .padding(.vertical, 14)
                        .frame(maxWidth: 220)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
            .padding(26)
            .background(.thinMaterial.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 18)

        case .gameOver:
            VStack(spacing: 12) {
                Text("GAME OVER")
                    .font(.title.weight(.heavy))
                    .foregroundStyle(.white)

                Text("Score: \(engine.score)\nBest: \(engine.bestScore)")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.8))

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
                            .frame(maxWidth: 140)
                            .background(.white.opacity(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }
            .padding(22)
            .background(.thinMaterial.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .padding(.horizontal, 18)

        case .playing:
            EmptyView()
        }
    }
}

