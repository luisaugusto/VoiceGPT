import SwiftUI

struct WallpaperView: View {
    var vibe: String
    var isDark: Bool

    var body: some View {
        ZStack {
            base
            gradients
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var base: some View {
        if isDark {
            Color.baseBackgroundDark
        } else {
            Color.baseBackgroundLight
        }
    }

    @ViewBuilder
    private var gradients: some View {
        switch vibe {
        case "vibrant": vibrant
        case "moody":   moody
        default:        calm
        }
    }

    // MARK: Calm
    @ViewBuilder private var calm: some View {
        if isDark {
            RadialGradient(colors: [Color(hex: "1a2060").opacity(0.45), .clear],
                           center: .topLeading, startRadius: 0, endRadius: 420)
            RadialGradient(colors: [Color(hex: "3b2d7a").opacity(0.28), .clear],
                           center: .bottomTrailing, startRadius: 0, endRadius: 380)
        } else {
            RadialGradient(colors: [Color(hex: "c7d2fe").opacity(0.70), .clear],
                           center: .topLeading, startRadius: 0, endRadius: 400)
            RadialGradient(colors: [Color(hex: "ddd6fe").opacity(0.50), .clear],
                           center: .bottomTrailing, startRadius: 0, endRadius: 360)
        }
    }

    // MARK: Vibrant
    @ViewBuilder private var vibrant: some View {
        if isDark {
            RadialGradient(colors: [Color(hex: "5b7cfa").opacity(0.30), .clear],
                           center: .top, startRadius: 0, endRadius: 320)
            RadialGradient(colors: [Color(hex: "8b5cf6").opacity(0.22), .clear],
                           center: .bottomLeading, startRadius: 0, endRadius: 360)
            RadialGradient(colors: [Color(hex: "19b6c9").opacity(0.18), .clear],
                           center: .bottomTrailing, startRadius: 0, endRadius: 280)
        } else {
            RadialGradient(colors: [Color(hex: "818cf8").opacity(0.35), .clear],
                           center: .top, startRadius: 0, endRadius: 300)
            RadialGradient(colors: [Color(hex: "a78bfa").opacity(0.25), .clear],
                           center: .bottomLeading, startRadius: 0, endRadius: 340)
            RadialGradient(colors: [Color(hex: "67e8f9").opacity(0.20), .clear],
                           center: .bottomTrailing, startRadius: 0, endRadius: 260)
        }
    }

    // MARK: Moody
    @ViewBuilder private var moody: some View {
        if isDark {
            RadialGradient(colors: [Color(hex: "4c1d95").opacity(0.38), .clear],
                           center: .topTrailing, startRadius: 0, endRadius: 420)
            RadialGradient(colors: [Color(hex: "1e1b4b").opacity(0.45), .clear],
                           center: .bottomLeading, startRadius: 0, endRadius: 380)
        } else {
            RadialGradient(colors: [Color(hex: "a78bfa").opacity(0.40), .clear],
                           center: .topTrailing, startRadius: 0, endRadius: 400)
            RadialGradient(colors: [Color(hex: "818cf8").opacity(0.30), .clear],
                           center: .bottomLeading, startRadius: 0, endRadius: 360)
        }
    }
}
