import CryptoKit
import Foundation

struct TranslationService {
    func translate(text: String, settings: TranslationSettings) async throws -> String {
        switch settings.provider {
        case .openAICompatible:
            return try await translateWithOpenAICompatibleAPI(text: text, settings: settings)
        case .baidu:
            return try await translateWithBaidu(text: text, settings: settings)
        }
    }

    private func translateWithOpenAICompatibleAPI(text: String, settings: TranslationSettings) async throws -> String {
        let trimmedAPIKey = settings.normalizedAPIKey
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

    private func translateWithBaidu(text: String, settings: TranslationSettings) async throws -> String {
        let appID = settings.normalizedBaiduAppID
        let secret = settings.normalizedBaiduSecret

        guard !appID.isEmpty, !secret.isEmpty else {
            throw AppError.missingBaiduCredentials
        }

        let salt = String(Int.random(in: 100_000...999_999))
        let signature = md5Hex(appID + text + salt + secret)
        let requestBody = formEncodedData([
            URLQueryItem(name: "q", value: text),
            URLQueryItem(name: "from", value: "auto"),
            URLQueryItem(name: "to", value: settings.baiduTargetLanguageCode),
            URLQueryItem(name: "appid", value: appID),
            URLQueryItem(name: "salt", value: salt),
            URLQueryItem(name: "sign", value: signature)
        ])

        guard let endpoint = URL(string: "https://fanyi-api.baidu.com/api/trans/vip/translate") else {
            throw AppError.invalidEndpoint
        }

        var request = URLRequest(url: endpoint, timeoutInterval: 60)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestBody

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response, data: data)

        let decodedResponse = try JSONDecoder().decode(BaiduTranslateResponse.self, from: data)
        if let errorCode = decodedResponse.errorCode {
            throw AppError.serverError(decodedResponse.displayErrorMessage(errorCode: errorCode))
        }

        let translatedText = decodedResponse.transResult?
            .map(\.dst)
            .joined(separator: "\n")
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
            throw AppError.serverError(errorMessage(statusCode: httpResponse.statusCode, data: data))
        }
    }

    private func errorMessage(statusCode: Int, data: Data) -> String {
        if let apiError = try? JSONDecoder().decode(ChatCompletionErrorResponse.self, from: data) {
            return apiError.displayMessage(statusCode: statusCode)
        }

        let responseText = String(data: data, encoding: .utf8) ?? "empty response"
        return "翻译接口返回 \(statusCode)\n\(responseText)"
    }

    private func formEncodedData(_ queryItems: [URLQueryItem]) -> Data {
        var components = URLComponents()
        components.queryItems = queryItems
        return Data((components.percentEncodedQuery ?? "").utf8)
    }

    private func md5Hex(_ value: String) -> String {
        Insecure.MD5.hash(data: Data(value.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
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

private struct ChatCompletionErrorResponse: Decodable {
    var error: ErrorDetail

    func displayMessage(statusCode: Int) -> String {
        var lines = ["翻译接口返回 \(statusCode)"]

        if let message = error.message, !message.isEmpty {
            lines.append("message: \(message)")
        }

        if let type = error.type, !type.isEmpty {
            lines.append("type: \(type)")
        }

        if let code = error.code, !code.isEmpty {
            lines.append("code: \(code)")
        }

        if let param = error.param, !param.isEmpty {
            lines.append("param: \(param)")
        }

        return lines.joined(separator: "\n")
    }

    struct ErrorDetail: Decodable {
        var message: String?
        var type: String?
        var code: String?
        var param: String?
    }
}

private struct BaiduTranslateResponse: Decodable {
    var from: String?
    var to: String?
    var transResult: [TranslationResult]?
    var errorCode: String?
    var errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case from
        case to
        case transResult = "trans_result"
        case errorCode = "error_code"
        case errorMessage = "error_msg"
    }

    func displayErrorMessage(errorCode: String) -> String {
        var lines = ["百度翻译接口返回错误"]
        lines.append("error_code: \(errorCode)")

        if let errorMessage, !errorMessage.isEmpty {
            lines.append("error_msg: \(errorMessage)")
        }

        return lines.joined(separator: "\n")
    }

    struct TranslationResult: Decodable {
        var src: String
        var dst: String
    }
}
