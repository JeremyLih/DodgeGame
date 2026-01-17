import SwiftUI

/// Game mode selector component with glass effect styling
struct GameModeSelector: View {
    @ObservedObject var engine: GameEngine
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Game Mode")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.8))
            
            HStack(spacing: 8) {
                ForEach(GameMode.allCases) { mode in
                    modeButton(for: mode)
                }
            }
            
            Text(engine.settings.selectedMode.description)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.7))
                .padding(.top, 2)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(glassContainer)
    }
    
    private func modeButton(for mode: GameMode) -> some View {
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
            .background(buttonBackground(isSelected: engine.settings.selectedMode == mode))
            .overlay(buttonBorder(isSelected: engine.settings.selectedMode == mode))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: engine.settings.selectedMode == mode ? .white.opacity(0.3) : .clear, radius: 8)
        }
    }
    
    private func buttonBackground(isSelected: Bool) -> some View {
        Group {
            if isSelected {
                Color.white
            } else {
                Color.white.opacity(0.15)
            }
        }
    }
    
    private func buttonBorder(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(Color.white.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
    }
    
    private var glassContainer: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.05))
            .overlay(containerBorder)
    }
    
    private var containerBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(
                LinearGradient(
                    colors: [.white.opacity(0.3), .white.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}
