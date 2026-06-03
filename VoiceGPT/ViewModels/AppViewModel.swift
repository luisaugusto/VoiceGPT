import AVFoundation
import SwiftData
import SwiftUI
import Observation

enum PTTState {
    case idle, listening, thinking
}

@Observable
final class AppViewModel: NSObject {
    var pttState: PTTState = .idle
    var activeConversation: Conversation?
    var isHistoryOpen = false
    var isSettingsOpen = false
    var errorMessage: String?

    let recorder = AudioRecorder()
    let openAI = OpenAIService()

    private var audioPlayer: AVAudioPlayer?
    private var playerDelegate: AudioPlayerDelegate?

    func handlePTTPress() {
        guard pttState == .idle else { return }
        errorMessage = nil
        pttState = .listening
        recorder.startRecording()
    }

    func handlePTTRelease(context: ModelContext, settings: AppSettings) {
        guard pttState == .listening else { return }
        guard let audioURL = recorder.stopRecording() else {
            pttState = .idle
            return
        }

        openAI.configure(apiKey: settings.apiKey)
        pttState = .thinking

        Task {
            do {
                let userText = try await openAI.transcribe(audioURL: audioURL)
                let conversation = ensureConversation(context: context)
                let userMsg = Message(role: "user", text: userText, conversation: conversation)
                context.insert(userMsg)
                conversation.messages.append(userMsg)

                let assistantText = try await openAI.chat(
                    history: conversation.sortedMessages,
                    personalContext: settings.personalContext
                )

                let assistantMsg = Message(role: "assistant", text: assistantText, conversation: conversation)
                context.insert(assistantMsg)
                conversation.messages.append(assistantMsg)

                updateTitleIfNeeded(
                    for: conversation,
                    firstUserMessage: userText,
                    firstAssistantResponse: assistantText
                )

                let audioData = try await openAI.speak(text: assistantText)
                await MainActor.run { playAudio(data: audioData) }

            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    pttState = .idle
                }
            }
        }
    }

    func newConversation(context: ModelContext) {
        let conv = Conversation()
        context.insert(conv)
        activeConversation = conv
        withAnimation { isHistoryOpen = false }
    }

    func deleteConversation(_ conversation: Conversation, context: ModelContext) {
        deleteConversation(
            conversation,
            delete: { context.delete(conversation) },
            save: { try context.save() },
            rollback: { context.rollback() }
        )
    }

    func deleteConversation(
        _ conversation: Conversation,
        delete: () -> Void,
        save: () throws -> Void,
        rollback: () -> Void
    ) {
        let previouslyActiveConversation = activeConversation

        if activeConversation?.id == conversation.id {
            activeConversation = nil
        }

        delete()

        do {
            try save()
        } catch {
            rollback()
            activeConversation = previouslyActiveConversation
            errorMessage = "Unable to delete conversation: \(error.localizedDescription)"
        }
    }

    private func ensureConversation(context: ModelContext) -> Conversation {
        if let existing = activeConversation { return existing }
        let conv = Conversation()
        context.insert(conv)
        activeConversation = conv
        return conv
    }

    private func updateTitleIfNeeded(
        for conversation: Conversation,
        firstUserMessage: String,
        firstAssistantResponse: String
    ) {
        guard conversation.title == "New conversation", conversation.messages.count == 2 else { return }

        Task {
            do {
                let title = try await openAI.generateConversationTitle(
                    firstUserMessage: firstUserMessage,
                    firstAssistantResponse: firstAssistantResponse
                )
                await MainActor.run {
                    if conversation.title == "New conversation" {
                        conversation.title = title
                    }
                }
            } catch {
                await MainActor.run {
                    if conversation.title == "New conversation" {
                        conversation.title = OpenAIService.cleanedTitle(firstUserMessage)
                    }
                }
            }
        }
    }

    private func playAudio(data: Data) {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("response.mp3")
        do {
            try data.write(to: url)
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            playerDelegate = AudioPlayerDelegate { [weak self] in
                self?.pttState = .idle
            }
            audioPlayer?.delegate = playerDelegate
            audioPlayer?.play()
        } catch {
            pttState = .idle
        }
    }
}

private final class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    private let onFinish: () -> Void
    init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish()
    }
}
