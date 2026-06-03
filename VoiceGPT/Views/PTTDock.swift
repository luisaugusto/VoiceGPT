import SwiftUI

struct PTTDock: View {
    var pttState: PTTState
    var style: String
    var accent: Color
    var onPress: () -> Void
    var onRelease: () -> Void

    @State private var ringScale: CGFloat = 1.0
    @State private var haloScale: CGFloat = 0.86

    private var isListening: Bool { pttState == .listening }
    private var statusText: String {
        switch pttState {
        case .idle:      return "Hold to talk"
        case .listening: return "Listening…"
        case .thinking:  return "Thinking…"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Status line
            HStack(spacing: 6) {
                Circle()
                    .fill(isListening ? accent : Color.inkTertiary)
                    .frame(width: 6, height: 6)
                    .scaleEffect(isListening ? 1.2 : 1)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isListening)
                Text(statusText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.inkSecondary)
            }

            // Button
            ZStack {
                switch style {
                case "orb":  orbButton
                case "wave": waveButton
                default:     ringButton
                }
            }
            .frame(width: 96, height: 96)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
            .disabled(pttState == .thinking)
        }
        .padding(.bottom, 32)
        .onAppear { startBreathing() }
        .onChange(of: pttState) { startBreathing() }
    }

    // MARK: - Ring style

    private var ringButton: some View {
        ZStack {
            // Halo
            Circle()
                .fill(accent.opacity(0.08))
                .frame(width: 96, height: 96)
                .scaleEffect(haloScale)
                .animation(
                    .easeInOut(duration: isListening ? 1.8 : 4.0).repeatForever(autoreverses: true),
                    value: haloScale
                )

            // Breathing rings
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .strokeBorder(accent.opacity(0.28 - Double(i) * 0.07), lineWidth: 1.5)
                    .frame(width: 96, height: 96)
                    .scaleEffect(ringScale + CGFloat(i) * 0.28)
                    .animation(
                        .easeInOut(duration: isListening ? 1.6 : DS.breathingDuration)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.7),
                        value: ringScale
                    )
            }

            // Core button
            Circle()
                .fill(.ultraThinMaterial)
                .overlay(Circle().strokeBorder(Color.glassBorder, lineWidth: 1))
                .scaleEffect(isListening ? 1.08 : 1.0)
                .overlay(
                    micIcon
                        .foregroundColor(isListening ? .white : accent)
                )
                .animation(.easeInOut(duration: 0.2), value: isListening)
        }
    }

    // MARK: - Orb style

    private var orbButton: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [accent, accent.opacity(0.75)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .shadow(color: accent.opacity(0.45), radius: isListening ? 20 : 10, y: 4)
                .scaleEffect(haloScale)
                .animation(
                    .easeInOut(duration: isListening ? 1.8 : 4.0).repeatForever(autoreverses: true),
                    value: haloScale
                )

            micIcon.foregroundColor(.white)
        }
    }

    // MARK: - Wave style

    private var waveButton: some View {
        let heights: [CGFloat] = [14, 24, 34, 24, 14]
        return HStack(spacing: 6) {
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(isListening ? Color.white : accent)
                    .frame(width: 4, height: heights[i])
                    .scaleEffect(
                        y: isListening ? (ringScale > 1.3 ? 2.2 : 0.5) : 1.0,
                        anchor: .center
                    )
                    .animation(
                        .easeInOut(duration: isListening ? 0.5 : 1.0)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.1),
                        value: ringScale
                    )
            }
        }
    }

    private var micIcon: some View {
        Image(systemName: "mic.fill")
            .font(.system(size: 26, weight: .medium))
    }

    private func startBreathing() {
        withAnimation(
            .easeInOut(duration: isListening ? 1.6 : DS.breathingDuration)
                .repeatForever(autoreverses: true)
        ) {
            ringScale = 1.85
            haloScale = 1.08
        }
    }
}
