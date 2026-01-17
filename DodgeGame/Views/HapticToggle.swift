import SwiftUI

/// Haptic feedback toggle component
struct HapticToggle: View {
    @ObservedObject var engine: GameEngine
    
    var body: some View {
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
