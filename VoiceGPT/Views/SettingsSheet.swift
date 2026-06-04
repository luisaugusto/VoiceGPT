import SwiftUI
import SwiftData

struct SettingsSheet: View {
    @Bindable var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var isKeyVisible = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    apiKeySection
                    contextSection
                    personalitySection
                    voiceSection
                }
                .padding(20)
            }
            .background(.ultraThinMaterial)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.accent(settings.accentColor))
                }
            }
        }
    }

    // MARK: - API Key

    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            label("OpenAI API Key")

            ZStack(alignment: .trailing) {
                Group {
                    if isKeyVisible {
                        TextField("sk-...", text: $settings.apiKey)
                    } else {
                        SecureField("sk-...", text: $settings.apiKey)
                    }
                }
                .font(.system(.body, design: .monospaced))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .padding(.trailing, 44)
                .background(glassField)

                Button {
                    isKeyVisible.toggle()
                } label: {
                    Image(systemName: isKeyVisible ? "eye.slash" : "eye")
                        .foregroundColor(.inkSecondary)
                        .frame(width: 44, height: 44)
                }
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(settings.hasAPIKey ? Color.green : Color.inkTertiary)
                    .frame(width: 7, height: 7)
                Text(settings.hasAPIKey ? "Key stored in Keychain" : "No key set")
                    .font(.system(size: 13))
                    .foregroundColor(.inkSecondary)
            }

            Text("Your key is stored in the iOS Keychain and never synced.")
                .font(.system(size: 12))
                .foregroundColor(.inkTertiary)
        }
    }

    // MARK: - Personal Context

    private var contextSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            label("Personal Context")

            TextEditor(text: $settings.personalContext)
                .font(.body)
                .frame(minHeight: 90)
                .padding(12)
                .background(glassField)
                .scrollContentBackground(.hidden)

            Text("Used in every conversation. VoiceGPT can automatically add durable preferences and details you mention, like dietary restrictions.")
                .font(.system(size: 12))
                .foregroundColor(.inkTertiary)
        }
    }

    // MARK: - Chatbot Personality

    private var personalitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            label("Chatbot Personality")

            ZStack(alignment: .topLeading) {
                TextEditor(text: $settings.chatbotPersonality)
                    .font(.body)
                    .frame(minHeight: 110)
                    .padding(12)
                    .background(glassField)
                    .scrollContentBackground(.hidden)

                if settings.chatbotPersonality.isEmpty {
                    Text("You are a cheerful bot with a bright and positive personality.")
                        .font(.body)
                        .foregroundColor(.inkTertiary)
                        .padding(.horizontal, 17)
                        .padding(.vertical, 20)
                        .allowsHitTesting(false)
                }
            }

            Text("Describe the voice, tone, and response style you want your chatbot to use.")
                .font(.system(size: 12))
                .foregroundColor(.inkTertiary)
        }
    }


    // MARK: - Voice

    private var voiceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            label("Assistant Voice")

            Picker("Assistant Voice", selection: $settings.speechVoice) {
                ForEach(OpenAIService.supportedSpeechVoices, id: \.self) { voice in
                    Text(voice.capitalized).tag(voice)
                }
            }
            .pickerStyle(.menu)
            .tint(Color.accent(settings.accentColor))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(glassField)

            Text("Choose the OpenAI text-to-speech voice used for spoken chatbot responses.")
                .font(.system(size: 12))
                .foregroundColor(.inkTertiary)
        }
    }

    // MARK: - Helpers

    private func label(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .tracking(0.6)
            .foregroundColor(.inkSecondary)
    }

    private var glassField: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.glassFill)
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.glassBorder, lineWidth: 1))
    }
}
