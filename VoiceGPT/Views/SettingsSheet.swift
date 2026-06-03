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
                    voiceSection
                    Divider().background(Color.glassBorder)
                    appearanceSection
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
                    .fill(settings.apiKey.isEmpty ? Color.inkTertiary : Color.green)
                    .frame(width: 7, height: 7)
                Text(settings.apiKey.isEmpty ? "No key set" : "Key stored locally")
                    .font(.system(size: 13))
                    .foregroundColor(.inkSecondary)
            }

            Text("Your key is stored only on this device and never synced.")
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

            Text("Added as a system message at the start of each new conversation.")
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

    // MARK: - Appearance

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            label("Appearance")

            // Accent color
            VStack(alignment: .leading, spacing: 8) {
                Text("Accent")
                    .font(.system(size: 13))
                    .foregroundColor(.inkSecondary)
                HStack(spacing: 12) {
                    ForEach(["indigo", "blue", "cyan", "purple"], id: \.self) { name in
                        Circle()
                            .fill(Color.accent(name))
                            .frame(width: 30, height: 30)
                            .overlay(
                                Circle()
                                    .strokeBorder(.white, lineWidth: 2.5)
                                    .opacity(settings.accentColor == name ? 1 : 0)
                            )
                            .onTapGesture { settings.accentColor = name }
                    }
                }
            }

            // Vibe
            VStack(alignment: .leading, spacing: 8) {
                Text("Background")
                    .font(.system(size: 13))
                    .foregroundColor(.inkSecondary)
                HStack(spacing: 10) {
                    ForEach(["calm", "vibrant", "moody"], id: \.self) { v in
                        choiceChip(v, isSelected: settings.vibe == v) {
                            settings.vibe = v
                        }
                    }
                }
            }

            // PTT style
            VStack(alignment: .leading, spacing: 8) {
                Text("Button style")
                    .font(.system(size: 13))
                    .foregroundColor(.inkSecondary)
                HStack(spacing: 10) {
                    ForEach(["ring", "orb", "wave"], id: \.self) { s in
                        choiceChip(s, isSelected: settings.pttStyle == s) {
                            settings.pttStyle = s
                        }
                    }
                }
            }

            // Dark mode
            Toggle(isOn: $settings.isDarkMode) {
                Text("Dark mode")
                    .font(.system(size: 15))
                    .foregroundColor(.inkPrimary)
            }
            .tint(Color.accent(settings.accentColor))
        }
    }

    // MARK: - Helpers

    private func label(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .semibold))
            .tracking(0.6)
            .foregroundColor(.inkSecondary)
    }

    private func choiceChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Text(title.capitalized)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(isSelected ? .white : .inkSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accent(settings.accentColor) : Color.glassFill)
                    .overlay(Capsule().strokeBorder(Color.glassBorder, lineWidth: 1))
            )
            .onTapGesture { action() }
    }

    private var glassField: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.glassFill)
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.glassBorder, lineWidth: 1))
    }
}
