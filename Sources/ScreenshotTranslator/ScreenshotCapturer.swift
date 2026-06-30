import Foundation

struct ScreenshotCapturer {
    func captureSelection() async throws -> URL {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("screenshot-translator-\(UUID().uuidString).png")

        let exitCode = try await runScreenshotTool(outputURL: outputURL)
        let screenshotExists = FileManager.default.fileExists(atPath: outputURL.path)

        if exitCode == 0, screenshotExists {
            return outputURL
        }

        if !screenshotExists {
            throw AppError.captureCancelled
        }

        throw AppError.captureFailed("screencapture exited with code \(exitCode)")
    }

    private func runScreenshotTool(outputURL: URL) async throws -> Int32 {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            process.arguments = ["-i", "-x", outputURL.path]

            process.terminationHandler = { finishedProcess in
                continuation.resume(returning: finishedProcess.terminationStatus)
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: AppError.captureFailed(error.localizedDescription))
            }
        }
    }
}
