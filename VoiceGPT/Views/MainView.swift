import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(AppViewModel.self) private var vm
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var context
    @Query private var settingsArray: [AppSettings]

    @State private var settings: AppSettings?
    @State private var scrollProxy: ScrollViewProxy?

    private var accent: Color {
        Color.accent(settings?.accentColor ?? AppSettings.defaultAccentColor)
    }

    var body: some View {
        @Bindable var vm = vm
        ZStack(alignment: .bottom) {
            // Wallpaper
            WallpaperView(
                vibe: AppSettings.defaultVibe,
                isDark: colorScheme == .dark
            )

            // Main content
            VStack(spacing: 0) {
                topBar
                transcript
                Spacer(minLength: 0)
            }

            // PTT dock pinned to bottom
            if let s = settings {
                PTTDock(
                    pttState: vm.pttState,
                    style: AppSettings.defaultPTTStyle,
                    accent: accent,
                    onPress: {
                        Task { await handlePTTPress(settings: s) }
                    },
                    onRelease: {
                        if let s = settings {
                            vm.handlePTTRelease(context: context, settings: s)
                        }
                    }
                )
                .padding(.bottom, 8)
            }

            // Error banner
            if let error = vm.errorMessage {
                VStack {
                    Spacer()
                    Text(error)
                        .font(.system(size: 13))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Color.red.opacity(0.85)))
                        .padding(.bottom, 160)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .onTapGesture { vm.errorMessage = nil }
                }
            }

            // History pane overlay
            if vm.isHistoryOpen {
                Color.black.opacity(0.40)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(DS.easeGlass) { vm.isHistoryOpen = false }
                    }
                    .transition(.opacity)
                    .zIndex(8)

                HistoryPane()
                    .transition(.move(edge: .leading))
                    .zIndex(9)
            }
        }
        .animation(.easeInOut(duration: DS.paneDuration), value: vm.isHistoryOpen)
        .animation(.easeInOut(duration: 0.3), value: vm.errorMessage)
        .sheet(isPresented: Binding(get: { vm.isSettingsOpen }, set: { vm.isSettingsOpen = $0 })) {
            if let s = settings {
                SettingsSheet(settings: s)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .task { await bootstrapSettings() }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button {
                withAnimation(DS.easeGlass) { vm.isHistoryOpen.toggle() }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.inkSecondary)
                    .glassCircle(size: 44)
            }

            Spacer()

            Text(vm.activeConversation?.title ?? "VoiceGPT")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.inkPrimary)
                .lineLimit(1)

            Spacer()

            // Mirror of menu button for balance
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .padding(.top, 4)
    }

    // MARK: - Transcript

    @ViewBuilder
    private var transcript: some View {
        let messages = vm.activeConversation?.sortedMessages ?? []
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 14) {
                    if messages.isEmpty {
                        emptyState
                            .padding(.top, 80)
                    } else {
                        ForEach(messages) { msg in
                            MessageBubbleView(message: msg, accent: accent)
                                .id(msg.id)
                        }
                        if vm.pttState == .thinking {
                            ThinkingIndicator(accent: accent)
                                .id("thinking")
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.04),
                        .init(color: .black, location: 0.96),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top, endPoint: .bottom
                )
            )
            .onChange(of: messages.count) {
                if let last = messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .onChange(of: vm.pttState) {
                if vm.pttState == .thinking {
                    withAnimation { proxy.scrollTo("thinking", anchor: .bottom) }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .overlay(Circle().strokeBorder(Color.glassBorder, lineWidth: 1))
                    .frame(width: 76, height: 76)
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 26))
                    .foregroundColor(accent)
            }
            Text("Hold to talk")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.inkPrimary)
            Text("Ask me anything. I'll listen and respond.")
                .font(.system(size: 15))
                .foregroundColor(.inkSecondary)
                .multilineTextAlignment(.center)

            if !(settings?.personalContext.isEmpty ?? true) {
                HStack(spacing: 6) {
                    Circle().fill(Color.green).frame(width: 7, height: 7)
                    Text("Personal context on")
                        .font(.system(size: 13))
                        .foregroundColor(.inkSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(Capsule().fill(Color.glassFill))
            }
        }
        .frame(maxWidth: 280)
    }

    // MARK: - Bootstrap

    private func bootstrapSettings() async {
        if let existing = settingsArray.first {
            existing.refreshAPIKeyStatus()
            applyFixedAppearance(to: existing)
            settings = existing
        } else {
            let s = AppSettings()
            applyFixedAppearance(to: s)
            context.insert(s)
            settings = s
        }
    }

    private func applyFixedAppearance(to settings: AppSettings) {
        settings.accentColor = AppSettings.defaultAccentColor
        settings.vibe = AppSettings.defaultVibe
        settings.pttStyle = AppSettings.defaultPTTStyle
    }

    private func handlePTTPress(settings: AppSettings) async {
        guard vm.pttState == .idle else { return }
        let granted = await vm.recorder.requestPermission()
        guard granted else {
            vm.errorMessage = "Microphone access denied. Enable it in Settings."
            return
        }
        vm.handlePTTPress()
    }
}
