# 截图翻译

一个本地 macOS 截图翻译应用：

1. 在主窗口配置翻译服务和目标语言
2. 日常使用时按全局快捷键，或从菜单栏图标选择“截图翻译”
3. 使用系统截图工具框选区域
4. 应用通过 Apple Vision 做 OCR，并调用所选服务翻译
5. 翻译结果会浮在截图结束位置附近，同时写回主窗口

## 运行

```bash
swift run ScreenshotTranslator
```

首次截图时，macOS 可能会要求给终端或应用授予“屏幕录制”权限。

关闭主窗口不会退出应用，应用会继续留在菜单栏。需要重新打开配置时，从菜单栏图标选择“显示设置”。

## 打包成 .app

```bash
chmod +x scripts/build-app.sh
./scripts/build-app.sh
open dist/截图翻译.app
```

## 配置

应用内可配置：

- `服务`，可选 `OpenAI` 或 `百度翻译`
- `API Key`
- `接口`，默认 `https://api.openai.com/v1/chat/completions`
- `模型`，默认 `gpt-4o-mini`
- 百度翻译的 `APP ID` 和 `密钥`
- `目标语言`，默认 `中文`
- `快捷键`，默认 `Command + Shift + S`，可在主窗口里点击“录制”后重新设置

当前版本把配置保存在 `UserDefaults`，适合本地原型验证；如果要正式分发，建议把 API Key 改为 Keychain 存储。

百度翻译模式下，`目标语言` 可以填 `中文`、`英文`、`日文`、`韩文`、`法文`、`德文`、`西班牙文`、`俄文`，也可以直接填百度语言代码，例如 `zh`、`en`、`jp`。
