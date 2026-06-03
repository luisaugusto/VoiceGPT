import SwiftUI

struct MessageBubbleView: View {
    let message: Message
    let accent: Color

    private var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }
            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                if !isUser {
                    Text("VOICEGPT")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(0.6)
                        .foregroundColor(accent.opacity(0.85))
                }
                Text(message.text)
                    .font(.body)
                    .foregroundColor(isUser ? .white : .inkPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(bubbleBackground)
                    .clipShape(bubbleShape)
            }
            if !isUser { Spacer(minLength: 60) }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .opacity
        ))
    }

    @ViewBuilder
    private var bubbleBackground: some View {
        if isUser {
            LinearGradient(
                colors: [accent, accent.opacity(0.80)],
                startPoint: .top, endPoint: .bottom
            )
            .shadow(color: accent.opacity(0.40), radius: 8, y: 4)
        } else {
            Color.ultraThinMaterialFill
                .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Color.glassBorder, lineWidth: 1))
        }
    }

    private var bubbleShape: some Shape {
        if isUser {
            return UnevenRoundedRectangle(
                topLeadingRadius: 22,
                bottomLeadingRadius: 22,
                bottomTrailingRadius: 7,
                topTrailingRadius: 22
            )
        } else {
            return UnevenRoundedRectangle(
                topLeadingRadius: 7,
                bottomLeadingRadius: 22,
                bottomTrailingRadius: 22,
                topTrailingRadius: 22
            )
        }
    }
}

struct ThinkingIndicator: View {
    @State private var animate = false
    let accent: Color

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(accent)
                    .frame(width: 7, height: 7)
                    .scaleEffect(animate ? 1 : 0.5)
                    .opacity(animate ? 1 : 0.4)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(i) * 0.2),
                        value: animate
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.glassFill)
        .clipShape(UnevenRoundedRectangle(
            topLeadingRadius: 7,
            bottomLeadingRadius: 22,
            bottomTrailingRadius: 22,
            topTrailingRadius: 22
        ))
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear { animate = true }
    }
}

// MARK: - Helpers

private extension Color {
    static let ultraThinMaterialFill = Color(white: 0.18, opacity: 0.55)
}
