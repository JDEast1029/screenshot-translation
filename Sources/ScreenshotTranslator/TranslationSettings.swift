import Foundation

struct TranslationSettings {
    var apiKey: String
    var endpoint: String
    var model: String
    var targetLanguage: String

    var normalizedEndpoint: URL? {
        URL(string: endpoint.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    var normalizedTargetLanguage: String {
        let trimmedValue = targetLanguage.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? "中文" : trimmedValue
    }

    var normalizedModel: String {
        let trimmedValue = model.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? "gpt-4o-mini" : trimmedValue
    }
}
