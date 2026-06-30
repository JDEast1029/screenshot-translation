import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TranslationViewModel()

    @AppStorage("apiKey") private var apiKey = ""
    @AppStorage("endpoint") private var endpoint = "https://api.openai.com/v1/chat/completions"
    @AppStorage("model") private var model = "gpt-4o-mini"
    @AppStorage("targetLanguage") private var targetLanguage = "中文"

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            resultArea
        }
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var toolbar: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                Button {
                    viewModel.captureAndTranslate(settings: currentSettings)
                } label: {
                    Label("截图翻译", systemImage: "viewfinder")
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
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

                Text(viewModel.statusText)
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
                HStack(spacing: 10) {
                    TextField("gpt-4o-mini", text: $model)
                        .textFieldStyle(.roundedBorder)
                    Text("目标语言")
                        .foregroundStyle(.secondary)
                    TextField("中文", text: $targetLanguage)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                }
            }
        }
        .font(.callout)
    }

    private var resultArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                TextPane(title: "OCR 识别结果", text: viewModel.recognizedText, placeholder: "截图后显示识别到的原文")
                TextPane(title: "翻译结果", text: viewModel.translatedText, placeholder: "翻译完成后显示目标语言文本")
            }
            .padding(16)
        }
    }

    private var currentSettings: TranslationSettings {
        TranslationSettings(
            apiKey: apiKey,
            endpoint: endpoint,
            model: model,
            targetLanguage: targetLanguage
        )
    }

    private var resultIsEmpty: Bool {
        viewModel.recognizedText.isEmpty && viewModel.translatedText.isEmpty
    }

    private var statusColor: Color {
        viewModel.errorMessage == nil ? .secondary : .red
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
