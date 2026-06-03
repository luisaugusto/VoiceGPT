import Foundation
import OpenAI

struct OpenAIChatResponse: Equatable {
    let assistantText: String
    let memoryUpdate: String?
}

private struct ModelChatEnvelope: Codable {
    let assistantResponse: String
    let memoryUpdate: String?

    enum CodingKeys: String, CodingKey {
        case assistantResponse = "assistant_response"
        case memoryUpdate = "memory_update"
    }
}

@Observable
final class OpenAIService {
    static let chatModel: Model = "gpt-5.4"

    private static let memoryAwareSystemPrompt = """
    You are VoiceGPT, a warm, concise voice assistant.

    Respond to the user's latest message and decide whether the user revealed durable context that should be remembered across future chats.

    Return only valid compact JSON with this exact shape:
    {"assistant_response":"Your natural reply to the user.","memory_update":null}

    Memory rules:
    - Save only durable user context that would help in future conversations, such as preferences, dietary restrictions, accessibility needs, long-term goals, recurring constraints, important personal details, or explicit requests to remember something.
    - Do not save one-off requests, temporary plans, conversation-local facts, guesses, or facts already present in the known user context.
    - Be especially careful with sensitive details. Only save them when the user clearly wants or expects them to be remembered.
    - When there is something worth saving, set memory_update to one concise standalone sentence written in third person about the user, for example: "The user is gluten free."
    - Never mention the memory_update field or JSON format in assistant_response.
    """

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

    func chat(history: [Message], personalContext: String) async throws -> OpenAIChatResponse {
        guard let client else { throw VoiceGPTError.noAPIKey }

        var params: [ChatQuery.ChatCompletionMessageParam] = [
            .system(.init(content: .textContent(Self.memoryAwareSystemPrompt)))
        ]

        if !personalContext.isEmpty {
            params.append(.system(.init(content: .textContent("Known user context:\n\(personalContext)"))))
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
        let rawContent = result.choices.first?.message.content ?? ""
        guard !rawContent.isEmpty else { throw VoiceGPTError.emptyResponse }
        return Self.parseChatResponse(rawContent)
    }

    static func parseChatResponse(_ rawContent: String) -> OpenAIChatResponse {
        let trimmed = rawContent.trimmingCharacters(in: .whitespacesAndNewlines)
        let jsonString = extractJSONString(from: trimmed)

        if let data = jsonString.data(using: .utf8),
           let envelope = try? JSONDecoder().decode(ModelChatEnvelope.self, from: data) {
            let assistantText = envelope.assistantResponse.trimmingCharacters(in: .whitespacesAndNewlines)
            let memoryUpdate = envelope.memoryUpdate?.trimmingCharacters(in: .whitespacesAndNewlines)
            return OpenAIChatResponse(
                assistantText: assistantText.isEmpty ? trimmed : assistantText,
                memoryUpdate: memoryUpdate?.isEmpty == false ? memoryUpdate : nil
            )
        }

        return OpenAIChatResponse(assistantText: trimmed, memoryUpdate: nil)
    }

    private static func extractJSONString(from rawContent: String) -> String {
        var jsonString = rawContent

        if jsonString.hasPrefix("```") {
            jsonString = jsonString
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```JSON", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let start = jsonString.firstIndex(of: "{"),
              let end = jsonString.lastIndex(of: "}"),
              start <= end else {
            return jsonString
        }

        return String(jsonString[start...end])
    }

    func speak(text: String) async throws -> Data {
        guard let client else { throw VoiceGPTError.noAPIKey }
        let query = AudioSpeechQuery(
            model: .tts_1,
            input: text,
            voice: .alloy,
            responseFormat: .mp3,
            speed: 1.0
        )
        let result = try await client.audioCreateSpeech(query: query)
        return result.audio
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
