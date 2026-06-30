import AppKit
import Foundation

@MainActor
final class TranslationViewModel: ObservableObject {
    static let shared = TranslationViewModel()

    @Published private(set) var isTranslating = false
    @Published private(set) var statusText = "选择截图区域后会自动识别并翻译"
    @Published private(set) var recognizedText = ""
    @Published private(set) var translatedText = ""
    @Published private(set) var errorMessage: String?

    private let screenshotCapturer: ScreenshotCapturer
    private let ocrService: OCRService
    private let translationService: TranslationService
    private let overlayController: TranslationResultOverlayController
    private weak var settingsWindow: NSWindow?

    init(
        screenshotCapturer: ScreenshotCapturer = ScreenshotCapturer(),
        ocrService: OCRService = OCRService(),
        translationService: TranslationService = TranslationService()
    ) {
        self.screenshotCapturer = screenshotCapturer
        self.ocrService = ocrService
        self.translationService = translationService
        self.overlayController = TranslationResultOverlayController()
    }

    func captureAndTranslate(settings: TranslationSettings, showsOverlay: Bool = true) {
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
                if showsOverlay {
                    overlayController.showProgress(statusText)
                }

                let text = try await ocrService.recognizeText(in: imageURL)
                recognizedText = text
                statusText = "正在翻译..."
                if showsOverlay {
                    overlayController.showProgress(statusText)
                }

                translatedText = try await translationService.translate(text: text, settings: settings)
                statusText = "翻译完成"
                if showsOverlay {
                    overlayController.showResult(recognizedText: text, translatedText: translatedText)
                }
            } catch {
                handle(error)
                if showsOverlay {
                    overlayController.showError(errorMessage ?? statusText)
                }
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

    func setStatus(_ error: Error) {
        handle(error)
    }

    func attachSettingsWindow(_ window: NSWindow) {
        settingsWindow = window
    }

    func showSettingsWindow() {
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    private func handle(_ error: Error) {
        let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        errorMessage = message
        statusText = message
    }
}
