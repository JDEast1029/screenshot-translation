import AppKit
import SwiftUI

@MainActor
final class TranslationResultOverlayController {
    private var window: NSWindow?

    func showProgress(_ message: String) {
        show(state: .progress(message))
    }

    func showResult(recognizedText: String, translatedText: String) {
        show(state: .result(recognizedText: recognizedText, translatedText: translatedText))
    }

    func showError(_ message: String) {
        show(state: .error(message))
    }

    func close() {
        window?.orderOut(nil)
    }

    private func show(state: TranslationOverlayState) {
        let content = TranslationOverlayView(
            state: state,
            onCopy: { [weak self] in self?.copy(state.copyText) },
            onClose: { [weak self] in self?.close() }
        )

        let size = state.windowSize
        let overlayWindow = window ?? makeWindow(size: size)
        overlayWindow.contentView = NSHostingView(rootView: content)
        overlayWindow.setContentSize(size)
        position(overlayWindow)
        overlayWindow.orderFrontRegardless()
        window = overlayWindow
    }

    private func makeWindow(size: NSSize) -> NSWindow {
        let overlayWindow = OverlayWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        overlayWindow.backgroundColor = .clear
        overlayWindow.isOpaque = false
        overlayWindow.hasShadow = true
        overlayWindow.isReleasedWhenClosed = false
        overlayWindow.level = .floating
        overlayWindow.collectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary]
        return overlayWindow
    }

    private func position(_ overlayWindow: NSWindow) {
        let mouseLocation = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { screen in
            screen.frame.contains(mouseLocation)
        } ?? NSScreen.main

        guard let visibleFrame = screen?.visibleFrame else {
            overlayWindow.center()
            return
        }

        let margin: CGFloat = 14
        let size = overlayWindow.frame.size
        var x = mouseLocation.x + margin
        var y = mouseLocation.y - size.height - margin

        if x + size.width > visibleFrame.maxX {
            x = mouseLocation.x - size.width - margin
        }

        if y < visibleFrame.minY {
            y = mouseLocation.y + margin
        }

        x = min(max(x, visibleFrame.minX + margin), visibleFrame.maxX - size.width - margin)
        y = min(max(y, visibleFrame.minY + margin), visibleFrame.maxY - size.height - margin)

        overlayWindow.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func copy(_ text: String) {
        guard !text.isEmpty else {
            return
        }

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

private final class OverlayWindow: NSWindow {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }
}

private enum TranslationOverlayState {
    case progress(String)
    case result(recognizedText: String, translatedText: String)
    case error(String)

    var title: String {
        switch self {
        case .progress:
            return "截图翻译"
        case .result:
            return "翻译结果"
        case .error:
            return "翻译失败"
        }
    }

    var copyText: String {
        switch self {
        case .progress:
            return ""
        case .result(_, let translatedText):
            return translatedText
        case .error(let message):
            return message
        }
    }

    var windowSize: NSSize {
        switch self {
        case .progress:
            return NSSize(width: 360, height: 92)
        case .result:
            return NSSize(width: 440, height: 360)
        case .error:
            return NSSize(width: 420, height: 180)
        }
    }
}

private struct TranslationOverlayView: View {
    var state: TranslationOverlayState
    var onCopy: () -> Void
    var onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            switch state {
            case .progress(let message):
                progressBody(message)
            case .result(let recognizedText, let translatedText):
                resultBody(recognizedText: recognizedText, translatedText: translatedText)
            case .error(let message):
                errorBody(message)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(nsColor: .separatorColor).opacity(0.65))
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text(state.title)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 8)

            if !state.copyText.isEmpty {
                Button(action: onCopy) {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.borderless)
                .help("复制")
            }

            Button(action: onClose) {
                Image(systemName: "xmark")
            }
            .buttonStyle(.borderless)
            .help("关闭")
        }
    }

    private func progressBody(_ message: String) -> some View {
        HStack(spacing: 10) {
            ProgressView()
                .controlSize(.small)

            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func resultBody(recognizedText: String, translatedText: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView {
                Text(translatedText)
                    .font(.body)
                    .textSelection(.enabled)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(maxHeight: .infinity)

            Divider()

            Text(recognizedText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .lineLimit(4)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func errorBody(_ message: String) -> some View {
        ScrollView {
            Text(message)
                .font(.callout)
                .foregroundStyle(.red)
                .textSelection(.enabled)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }
}
