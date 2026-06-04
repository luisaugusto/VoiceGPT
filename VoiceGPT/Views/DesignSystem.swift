import SwiftUI
import UIKit

// MARK: - Hex color initializer

extension Color {
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        s = s.hasPrefix("#") ? String(s.dropFirst()) : s
        var rgb: UInt64 = 0
        Scanner(string: s).scanHexInt64(&rgb)
        self.init(
            red:   Double((rgb & 0xFF0000) >> 16) / 255,
            green: Double((rgb & 0x00FF00) >> 8)  / 255,
            blue:  Double(rgb & 0x0000FF)          / 255
        )
    }
}

// MARK: - Design tokens

extension Color {
    // Backgrounds
    static let baseBackgroundDark  = Color(hex: "06070e")
    static let baseBackgroundLight = Color(hex: "e8ecfb")

    // Glass
    static let glassFill       = Color(white: 0.53, opacity: 0.16)
    static let glassFillStrong = Color(red: 40/255, green: 44/255, blue: 66/255).opacity(0.55)
    static let glassBorder     = Color.white.opacity(0.16)

    // Ink
    static let inkPrimary = Color.adaptive(
        light: Color(hex: "111827").opacity(0.94),
        dark: Color.white.opacity(0.96)
    )
    static let inkSecondary = Color.adaptive(
        light: Color(hex: "374151").opacity(0.82),
        dark: Color(hex: "ebeeff").opacity(0.62)
    )
    static let inkTertiary = Color.adaptive(
        light: Color(hex: "4b5563").opacity(0.58),
        dark: Color(hex: "ebeeff").opacity(0.34)
    )

    static func adaptive(light: Color, dark: Color) -> Color {
        Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }

    // Accent palette
    static func accent(_ name: String) -> Color {
        switch name {
        case "blue":   return Color(hex: "3b82f6")
        case "cyan":   return Color(hex: "19b6c9")
        case "purple": return Color(hex: "8b5cf6")
        default:       return Color(hex: "5b7cfa")  // indigo
        }
    }
}

// MARK: - Animation constants

enum DS {
    static let breathingDuration: Double = 3.4
    static let paneDuration:      Double = 0.46
    static let bubbleDuration:    Double = 0.42
    static let sheetDuration:     Double = 0.50
    static let easeGlass = Animation.timingCurve(0.32, 0.72, 0, 1, duration: paneDuration)
}

// MARK: - Glass button shape helper

struct GlassCircleStyle: ViewModifier {
    var size: CGFloat = 44
    func body(content: Content) -> some View {
        content
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(Circle().strokeBorder(Color.glassBorder, lineWidth: 1))
            )
    }
}

extension View {
    func glassCircle(size: CGFloat = 44) -> some View {
        modifier(GlassCircleStyle(size: size))
    }
}
