import AppKit
import Carbon
import SwiftUI

struct ContentView: View {
    @ObservedObject private var viewModel = TranslationViewModel.shared
    @StateObject private var shortcutRecorder = ShortcutRecorder()

    @AppStorage("provider") private var provider = TranslationProvider.openAICompatible.rawValue
    @AppStorage("apiKey") private var apiKey = ""
    @AppStorage("endpoint") private var endpoint = "https://api.openai.com/v1/chat/completions"
    @AppStorage("model") private var model = "gpt-4o-mini"
    @AppStorage("baiduAppID") private var baiduAppID = ""
    @AppStorage("baiduSecret") private var baiduSecret = ""
    @AppStorage("targetLanguage") private var targetLanguage = "中文"
    @AppStorage(KeyboardShortcutSetting.keyCodeDefaultsKey) private var shortcutKeyCode = KeyboardShortcutSetting.defaultKeyCode
    @AppStorage(KeyboardShortcutSetting.modifiersDefaultsKey) private var shortcutModifiers = KeyboardShortcutSetting.defaultModifiers

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            resultArea
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .background(SettingsWindowAccessor())
        .onDisappear {
            shortcutRecorder.stop()
        }
    }

    private var toolbar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Button {
                    viewModel.captureAndTranslate(settings: currentSettings)
                } label: {
                    Label("截图翻译", systemImage: "viewfinder")
                }
                .controlSize(.large)
                .disabled(viewModel.isTranslating)

                Button {
                    viewModel.clearResult()
                } label: {
                    Label("清空", systemImage: "trash")
                }
                .disabled(viewModel.isTranslating || resultIsEmpty)

                if viewModel.isTranslating {
                    ProgressView()
                        .controlSize(.small)
                }

                Text(statusSummary)
                    .font(.callout)
                    .foregroundStyle(statusColor)
                    .lineLimit(2)
                    .textSelection(.enabled)

                Spacer(minLength: 0)
            }

            settingsGrid
        }
        .padding(16)
    }

    private var settingsGrid: some View {
        Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 10) {
            GridRow {
                Text("服务")
                    .foregroundStyle(.secondary)
                Picker("服务", selection: providerBinding) {
                    ForEach(TranslationProvider.allCases) { provider in
                        Text(provider.title)
                            .tag(provider)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            if currentProvider == .openAICompatible {
                GridRow {
                    Text("API Key")
                        .foregroundStyle(.secondary)
                    SecureField("sk-...", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                }

                GridRow {
                    Text("接口")
                        .foregroundStyle(.secondary)
                    TextField("https://api.openai.com/v1/chat/completions", text: $endpoint)
                        .textFieldStyle(.roundedBorder)
                }

                GridRow {
                    Text("模型")
                        .foregroundStyle(.secondary)
                    TextField("gpt-4o-mini", text: $model)
                        .textFieldStyle(.roundedBorder)
                }
            } else {
                GridRow {
                    Text("APP ID")
                        .foregroundStyle(.secondary)
                    TextField("百度翻译 APP ID", text: $baiduAppID)
                        .textFieldStyle(.roundedBorder)
                }

                GridRow {
                    Text("密钥")
                        .foregroundStyle(.secondary)
                    SecureField("百度翻译密钥", text: $baiduSecret)
                        .textFieldStyle(.roundedBorder)
                }
            }

            GridRow {
                Text("目标语言")
                    .foregroundStyle(.secondary)
                TextField("中文", text: $targetLanguage)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 160)
            }

            GridRow {
                Text("快捷键")
                    .foregroundStyle(.secondary)
                shortcutSettingRow
            }
        }
        .font(.callout)
    }

    private var shortcutSettingRow: some View {
        HStack(spacing: 8) {
            Text(shortcutRecorder.isRecording ? "按下新的快捷键" : currentShortcut.displayName)
                .font(.system(.callout, design: .monospaced))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(minWidth: 180, maxWidth: 260, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color(nsColor: .separatorColor))
                }

            Button {
                toggleShortcutRecording()
            } label: {
                Label(shortcutRecorder.isRecording ? "取消" : "录制", systemImage: shortcutRecorder.isRecording ? "xmark.circle" : "keyboard")
            }

            Button {
                KeyboardShortcutSetting.saveDefault()
            } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .help("恢复默认")
            .disabled(shortcutRecorder.isRecording)
        }
    }

    private var resultArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let errorMessage = viewModel.errorMessage {
                    TextPane(title: "错误详情", text: errorMessage, placeholder: "")
                }

                TextPane(title: "OCR 识别结果", text: viewModel.recognizedText, placeholder: "截图后显示识别到的原文")
                TextPane(title: "翻译结果", text: viewModel.translatedText, placeholder: "翻译完成后显示目标语言文本")
            }
            .padding(16)
        }
    }

    private var currentSettings: TranslationSettings {
        TranslationSettings(
            provider: currentProvider,
            apiKey: apiKey,
            endpoint: endpoint,
            model: model,
            baiduAppID: baiduAppID,
            baiduSecret: baiduSecret,
            targetLanguage: targetLanguage
        )
    }

    private var providerBinding: Binding<TranslationProvider> {
        Binding {
            currentProvider
        } set: { newValue in
            provider = newValue.rawValue
        }
    }

    private var currentProvider: TranslationProvider {
        TranslationProvider(rawValue: provider) ?? .openAICompatible
    }

    private var currentShortcut: KeyboardShortcutSetting {
        KeyboardShortcutSetting(
            keyCode: UInt32(shortcutKeyCode),
            modifiers: UInt32(shortcutModifiers)
        )
    }

    private var resultIsEmpty: Bool {
        viewModel.recognizedText.isEmpty && viewModel.translatedText.isEmpty
    }

    private var statusSummary: String {
        viewModel.errorMessage == nil ? viewModel.statusText : "翻译失败，完整原因见错误详情"
    }

    private var statusColor: Color {
        viewModel.errorMessage == nil ? .secondary : .red
    }

    private func toggleShortcutRecording() {
        if shortcutRecorder.isRecording {
            shortcutRecorder.stop()
            return
        }

        shortcutRecorder.start {
            viewModel.setStatus(ShortcutRecordingError.invalidShortcut)
        }
    }
}

private final class ShortcutRecorder: ObservableObject {
    @Published private(set) var isRecording = false

    private var monitor: Any?

    func start(onInvalidShortcut: @escaping () -> Void) {
        stop()
        isRecording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.isRecording else {
                return event
            }

            if event.keyCode == UInt16(kVK_Escape) {
                self.stop()
                return nil
            }

            let shortcut = KeyboardShortcutSetting(
                keyCode: UInt32(event.keyCode),
                modifiers: carbonModifiers(from: event.modifierFlags)
            )

            if shortcut.isValid {
                KeyboardShortcutSetting.save(shortcut)
            } else {
                onInvalidShortcut()
            }

            self.stop()
            return nil
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }

        monitor = nil
        isRecording = false
    }

    deinit {
        stop()
    }
}

private enum ShortcutRecordingError: LocalizedError {
    case invalidShortcut

    var errorDescription: String? {
        switch self {
        case .invalidShortcut:
            return "快捷键需要包含 Command、Control、Option 或 Shift，并搭配一个非修饰键"
        }
    }
}

private struct SettingsWindowAccessor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else {
                return
            }

            window.delegate = SettingsWindowDelegate.shared
            TranslationViewModel.shared.attachSettingsWindow(window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}

private final class SettingsWindowDelegate: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowDelegate()

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }
}

private struct TextPane: View {
    var title: String
    var text: String
    var placeholder: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            Text(text.isEmpty ? placeholder : text)
                .frame(maxWidth: .infinity, minHeight: 150, alignment: .topLeading)
                .padding(12)
                .foregroundStyle(text.isEmpty ? .tertiary : .primary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color(nsColor: .separatorColor))
                }
        }
    }
}
