import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController(viewModel: .shared)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

@MainActor
private final class StatusBarController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let hotKeyManager = HotKeyManager()
    private let viewModel: TranslationViewModel
    private let captureMenuItem = NSMenuItem(title: "截图翻译", action: #selector(captureAndTranslate), keyEquivalent: "")
    private var shortcutObserver: NSObjectProtocol?

    init(viewModel: TranslationViewModel) {
        self.viewModel = viewModel
        super.init()
        configureStatusItem()
        registerHotKey()
        observeShortcutChanges()
    }

    deinit {
        if let shortcutObserver {
            NotificationCenter.default.removeObserver(shortcutObserver)
        }
    }

    private func configureStatusItem() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "viewfinder", accessibilityDescription: "截图翻译")
            button.image?.isTemplate = true
        }

        let menu = NSMenu()
        menu.addItem(captureMenuItem)
        menu.addItem(NSMenuItem(title: "显示设置", action: #selector(showSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q"))

        for item in menu.items {
            item.target = self
        }

        statusItem.menu = menu
        updateCaptureMenuTitle()
    }

    private func registerHotKey() {
        let shortcut = KeyboardShortcutSetting.stored()
        do {
            try hotKeyManager.register(shortcut: shortcut) { [weak viewModel] in
                Task { @MainActor in
                    viewModel?.captureAndTranslate(settings: .stored(), showsOverlay: true)
                }
            }
        } catch {
            viewModel.setStatus(error)
        }
    }

    private func observeShortcutChanges() {
        shortcutObserver = NotificationCenter.default.addObserver(
            forName: KeyboardShortcutSetting.changedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.registerHotKey()
                self?.updateCaptureMenuTitle()
            }
        }
    }

    private func updateCaptureMenuTitle() {
        captureMenuItem.title = "截图翻译 (\(KeyboardShortcutSetting.stored().displayName))"
    }

    @objc private func captureAndTranslate() {
        viewModel.captureAndTranslate(settings: .stored(), showsOverlay: true)
    }

    @objc private func showSettings() {
        NSApp.activate(ignoringOtherApps: true)
        viewModel.showSettingsWindow()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
