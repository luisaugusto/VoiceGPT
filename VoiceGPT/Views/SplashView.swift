import SwiftUI

struct SplashView: View {
    var onFinish: () -> Void

    @State private var floatUp = false
    @State private var waveScale = false
    @State private var progress: CGFloat = 0

    private let barRatios: [CGFloat] = [0.42, 0.72, 1.0, 0.55, 0.85, 0.34]
    private let maxBarHeight: CGFloat = 46
    private let accent = Color.accent("indigo")

    var body: some View {
        ZStack {
            Color.baseBackgroundDark.ignoresSafeArea()

            VStack(spacing: 26) {
                // Glass circle + soundwave
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .overlay(Circle().strokeBorder(Color.glassBorder, lineWidth: 1))
                        .frame(width: 132, height: 132)

                    HStack(alignment: .center, spacing: 6) {
                        ForEach(0..<6, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [accent.opacity(0.95), accent.opacity(0.60)],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                                .frame(width: 8, height: barRatios[i] * maxBarHeight)
                                .scaleEffect(y: waveScale ? 1.4 : 0.6, anchor: .center)
                                .animation(
                                    .easeInOut(duration: 1.1)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(i) * 0.14),
                                    value: waveScale
                                )
                        }
                    }
                }
                .offset(y: floatUp ? -9 : 0)
                .animation(
                    .easeInOut(duration: DS.breathingDuration).repeatForever(autoreverses: true),
                    value: floatUp
                )

                // Title
                (Text("Voice").font(.title2).fontWeight(.regular) +
                 Text("GPT").font(.title2).fontWeight(.bold).foregroundColor(accent))
                    .foregroundColor(.inkPrimary)

                // Loading bar
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 120, height: 4)
                    Capsule()
                        .fill(accent)
                        .frame(width: 120 * progress, height: 4)
                }
            }
        }
        .onAppear {
            floatUp = true
            waveScale = true
            withAnimation(.linear(duration: 1.3)) { progress = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { onFinish() }
        }
    }
}
