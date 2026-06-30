import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TranslationViewModel()

    @AppStorage("provider") private var provider = TranslationProvider.openAICompatible.rawValue
    @AppStorage("apiKey") private var apiKey = ""
    @AppStorage("endpoint") private var endpoint = "https://api.openai.com/v1/chat/completions"
    @AppStorage("model") private var model = "gpt-4o-mini"
    @AppStorage("baiduAppID") private var baiduAppID = ""
    @AppStorage("baiduSecret") private var baiduSecret = ""
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
        }
        .font(.callout)
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

    private var resultIsEmpty: Bool {
        viewModel.recognizedText.isEmpty && viewModel.translatedText.isEmpty
    }

    private var statusSummary: String {
        viewModel.errorMessage == nil ? viewModel.statusText : "翻译失败，完整原因见错误详情"
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
