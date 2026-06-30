import Foundation

@MainActor
final class TranslationViewModel: ObservableObject {
    @Published private(set) var isTranslating = false
    @Published private(set) var statusText = "选择截图区域后会自动识别并翻译"
    @Published private(set) var recognizedText = ""
    @Published private(set) var translatedText = ""
    @Published private(set) var errorMessage: String?

    private let screenshotCapturer: ScreenshotCapturer
    private let ocrService: OCRService
    private let translationService: TranslationService

    init(
        screenshotCapturer: ScreenshotCapturer = ScreenshotCapturer(),
        ocrService: OCRService = OCRService(),
        translationService: TranslationService = TranslationService()
    ) {
        self.screenshotCapturer = screenshotCapturer
        self.ocrService = ocrService
        self.translationService = translationService
    }

    func captureAndTranslate(settings: TranslationSettings) {
        guard !isTranslating else {
            return
        }

        isTranslating = true
        errorMessage = nil
        statusText = "正在截图..."

        Task {
            do {
                let imageURL = try await screenshotCapturer.captureSelection()
                statusText = "正在识别文字..."

                let text = try await ocrService.recognizeText(in: imageURL)
                recognizedText = text
                statusText = "正在翻译..."

                translatedText = try await translationService.translate(text: text, settings: settings)
                statusText = "翻译完成"
            } catch {
                handle(error)
            }

            isTranslating = false
        }
    }

    func clearResult() {
        recognizedText = ""
        translatedText = ""
        errorMessage = nil
        statusText = "选择截图区域后会自动识别并翻译"
    }

    private func handle(_ error: Error) {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        errorMessage = message
        statusText = message
    }
}
