import Foundation
import OpenAI

@Observable
final class OpenAIService {
    static let chatModel: Model = "gpt-5.4"
    static let defaultSpeechVoice = AudioSpeechQuery.AudioSpeechVoice.alloy.rawValue
    static let supportedSpeechVoices = AudioSpeechQuery.AudioSpeechVoice.allCases.map(\.rawValue)

    private var client: OpenAI?

    var hasKey: Bool { client != nil }

    func configure(apiKey: String) {
        guard !apiKey.isEmpty else { client = nil; return }
        client = OpenAI(apiToken: apiKey)
    }

    func transcribe(audioURL: URL) async throws -> String {
        guard let client else { throw VoiceGPTError.noAPIKey }
        let data = try Data(contentsOf: audioURL)
        let query = AudioTranscriptionQuery(
            file: data,
            fileType: .m4a,
            model: .whisper_1
        )
        let result = try await client.audioTranscriptions(query: query)
        return result.text
    }

    func chat(history: [Message], personalContext: String) async throws -> String {
        guard let client else { throw VoiceGPTError.noAPIKey }

        var params: [ChatQuery.ChatCompletionMessageParam] = []

        if !personalContext.isEmpty {
            params.append(.system(.init(content: .textContent(personalContext))))
        }

        for message in history {
            switch message.role {
            case "assistant":
                params.append(.assistant(.init(content: .textContent(message.text))))
            default:
                params.append(.user(.init(content: .string(message.text))))
            }
        }

        let query = ChatQuery(messages: params, model: Self.chatModel)
        let result = try await client.chats(query: query)
        return result.choices.first?.message.content ?? ""
    }

    func speak(text: String, voice speechVoice: String) async throws -> Data {
        guard let client else { throw VoiceGPTError.noAPIKey }
        let query = AudioSpeechQuery(
            model: .tts_1,
            input: text,
            voice: Self.speechVoice(for: speechVoice),
            responseFormat: .mp3,
            speed: 1.0
        )
        let result = try await client.audioCreateSpeech(query: query)
        return result.audio
    }

    private static func speechVoice(for rawValue: String) -> AudioSpeechQuery.AudioSpeechVoice {
        AudioSpeechQuery.AudioSpeechVoice(rawValue: rawValue) ?? .alloy
    }
}

enum VoiceGPTError: LocalizedError {
    case noAPIKey
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .noAPIKey: return "No API key set. Add your OpenAI key in Settings."
        case .emptyResponse: return "Received an empty response from the model."
        }
    }
}
