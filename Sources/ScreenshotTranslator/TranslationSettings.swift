import Foundation

enum TranslationProvider: String, CaseIterable, Identifiable {
    case openAICompatible
    case baidu

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .openAICompatible:
            return "OpenAI"
        case .baidu:
            return "百度翻译"
        }
    }
}

struct TranslationSettings {
    var provider: TranslationProvider
    var apiKey: String
    var endpoint: String
    var model: String
    var baiduAppID: String
    var baiduSecret: String
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

    var normalizedAPIKey: String {
        apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedBaiduAppID: String {
        baiduAppID.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var normalizedBaiduSecret: String {
        baiduSecret.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var baiduTargetLanguageCode: String {
        switch normalizedTargetLanguage.lowercased() {
        case "中文", "汉语", "zh", "zh-cn":
            return "zh"
        case "繁体", "繁體", "cht", "zh-tw":
            return "cht"
        case "英文", "英语", "英語", "en":
            return "en"
        case "日文", "日语", "日語", "jp", "ja":
            return "jp"
        case "韩文", "韩语", "韓語", "kor", "ko":
            return "kor"
        case "法文", "法语", "法語", "fra", "fr":
            return "fra"
        case "德文", "德语", "德語", "de":
            return "de"
        case "西班牙文", "西班牙语", "西班牙語", "spa", "es":
            return "spa"
        case "俄文", "俄语", "俄語", "ru":
            return "ru"
        default:
            return normalizedTargetLanguage
        }
    }

    static func stored(in defaults: UserDefaults = .standard) -> TranslationSettings {
        TranslationSettings(
            provider: TranslationProvider(rawValue: defaults.string(forKey: "provider") ?? "") ?? .openAICompatible,
            apiKey: defaults.string(forKey: "apiKey") ?? "",
            endpoint: defaults.string(forKey: "endpoint") ?? "https://api.openai.com/v1/chat/completions",
            model: defaults.string(forKey: "model") ?? "gpt-4o-mini",
            baiduAppID: defaults.string(forKey: "baiduAppID") ?? "",
            baiduSecret: defaults.string(forKey: "baiduSecret") ?? "",
            targetLanguage: defaults.string(forKey: "targetLanguage") ?? "中文"
        )
    }
}
