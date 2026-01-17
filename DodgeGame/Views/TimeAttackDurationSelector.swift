import SwiftUI

/// Time attack duration selector component
struct TimeAttackDurationSelector: View {
    @ObservedObject var engine: GameEngine
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Time Attack Duration")
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.8))
            
            HStack(spacing: 10) {
                ForEach(GameConstants.timeAttackDurations, id: \.self) { duration in
                    durationButton(for: duration)
                }
            }
        }
        .padding()
        .background(glassContainer)
    }
    
    private func durationButton(for duration: Int) -> some View {
        Button {
            engine.settings.timeAttackDuration = duration
        } label: {
            Text("\(duration)s")
                .font(.subheadline.bold())
                .foregroundStyle(isSelected(duration) ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(buttonBackground(isSelected: isSelected(duration)))
                .overlay(buttonBorder(isSelected: isSelected(duration)))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
    
    private func isSelected(_ duration: Int) -> Bool {
        engine.settings.timeAttackDuration == duration
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
