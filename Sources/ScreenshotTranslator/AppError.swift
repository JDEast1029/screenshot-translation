import Foundation

enum AppError: LocalizedError {
    case captureCancelled
    case captureFailed(String)
    case imageLoadFailed
    case noRecognizedText
    case missingAPIKey
    case invalidEndpoint
    case emptyTranslation
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .captureCancelled:
            return "已取消截图"
        case .captureFailed(let message):
            return "截图失败：\(message)"
        case .imageLoadFailed:
            return "无法读取截图图片"
        case .noRecognizedText:
            return "截图区域没有识别到文字"
        case .missingAPIKey:
            return "请先填写 API Key"
        case .invalidEndpoint:
            return "翻译接口地址不正确"
        case .emptyTranslation:
            return "翻译接口没有返回内容"
        case .serverError(let message):
            return message
        }
    }
}
