import Foundation

struct TranslationService {
    func translate(text: String, settings: TranslationSettings) async throws -> String {
        let trimmedAPIKey = settings.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAPIKey.isEmpty else {
            throw AppError.missingAPIKey
        }

        guard let endpoint = settings.normalizedEndpoint else {
            throw AppError.invalidEndpoint
        }

        var request = URLRequest(url: endpoint, timeoutInterval: 60)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(trimmedAPIKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(
            ChatCompletionRequest(
                model: settings.normalizedModel,
                messages: [
                    .system(content: systemPrompt(targetLanguage: settings.normalizedTargetLanguage)),
                    .user(content: text)
                ],
                temperature: 0.1
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data)

        let decodedResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        let translatedText = decodedResponse.choices
            .first?
            .message
            .content?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let translatedText, !translatedText.isEmpty else {
            throw AppError.emptyTranslation
        }

        return translatedText
    }

    private func systemPrompt(targetLanguage: String) -> String {
        """
        You translate OCR text captured from screenshots into \(targetLanguage).
        Preserve line breaks when they help readability.
        Keep product names, code, URLs, numbers, and placeholders unchanged.
        Return only the translated text.
        """
    }

    private func validateHTTPResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            return
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let responseText = String(data: data, encoding: .utf8) ?? "empty response"
            throw AppError.serverError("翻译接口返回 \(httpResponse.statusCode)：\(responseText)")
        }
    }
}

private struct ChatCompletionRequest: Encodable {
    var model: String
    var messages: [ChatMessage]
    var temperature: Double
}

private struct ChatMessage: Encodable {
    var role: String
    var content: String

    static func system(content: String) -> ChatMessage {
        ChatMessage(role: "system", content: content)
    }

    static func user(content: String) -> ChatMessage {
        ChatMessage(role: "user", content: content)
    }
}

private struct ChatCompletionResponse: Decodable {
    var choices: [Choice]

    struct Choice: Decodable {
        var message: Message
    }

    struct Message: Decodable {
        var content: String?
    }
}
