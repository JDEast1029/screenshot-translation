import AppKit
import Foundation
@preconcurrency import Vision

struct OCRService {
    func recognizeText(in imageURL: URL) async throws -> String {
        guard let image = NSImage(contentsOf: imageURL),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw AppError.imageLoadFailed
        }

        let observations = try await recognizeTextObservations(in: cgImage)
        let recognizedText = observations
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if recognizedText.isEmpty {
            throw AppError.noRecognizedText
        }

        return recognizedText
    }

    private func recognizeTextObservations(in image: CGImage) async throws -> [VNRecognizedTextObservation] {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                continuation.resume(returning: observations)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["zh-Hans", "zh-Hant", "en-US", "ja-JP", "ko-KR"]

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let requestHandler = VNImageRequestHandler(cgImage: image)
                    try requestHandler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
