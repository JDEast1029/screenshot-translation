import SwiftUI

@main
struct ScreenshotTranslatorApp: App {
    var body: some Scene {
        WindowGroup("截图翻译") {
            ContentView()
                .frame(minWidth: 900, minHeight: 620)
        }
        .windowStyle(.titleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}
