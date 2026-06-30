# ScreenshotTranslator

一个最小可运行的 macOS 截图翻译应用：

1. 点击“截图翻译”或按 `Command + Shift + S`
2. 使用系统截图工具框选区域
3. 应用通过 Apple Vision 做 OCR
4. 将识别文本发送到 OpenAI 兼容的 Chat Completions 接口翻译

## 运行

```bash
swift run ScreenshotTranslator
```

首次截图时，macOS 可能会要求给终端或应用授予“屏幕录制”权限。

## 打包成 .app

```bash
chmod +x scripts/build-app.sh
./scripts/build-app.sh
open dist/ScreenshotTranslator.app
```

## 配置

应用内可配置：

- `服务`，可选 `OpenAI` 或 `百度翻译`
- `API Key`
- `接口`，默认 `https://api.openai.com/v1/chat/completions`
- `模型`，默认 `gpt-4o-mini`
- 百度翻译的 `APP ID` 和 `密钥`
- `目标语言`，默认 `中文`

当前版本把配置保存在 `UserDefaults`，适合本地原型验证；如果要正式分发，建议把 API Key 改为 Keychain 存储。

百度翻译模式下，`目标语言` 可以填 `中文`、`英文`、`日文`、`韩文`、`法文`、`德文`、`西班牙文`、`俄文`，也可以直接填百度语言代码，例如 `zh`、`en`、`jp`。
