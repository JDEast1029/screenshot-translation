import Carbon
import Foundation

final class HotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private var action: (() -> Void)?

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
        }
    }

    func register(shortcut: KeyboardShortcutSetting, action: @escaping () -> Void) throws {
        self.action = action
        try installEventHandlerIfNeeded()
        unregisterCurrentHotKey()

        let hotKeyID = EventHotKeyID(
            signature: HotKeyManager.signature,
            id: HotKeyManager.shortcutID
        )

        let hotKeyStatus = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard hotKeyStatus == noErr else {
            throw HotKeyError.registrationFailed(shortcut, hotKeyStatus)
        }
    }

    private func unregisterCurrentHotKey() {
        guard let hotKeyRef else {
            return
        }

        UnregisterEventHotKey(hotKeyRef)
        self.hotKeyRef = nil
    }

    private func installEventHandlerIfNeeded() throws {
        guard eventHandlerRef == nil else {
            return
        }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let userData else {
                    return noErr
                }

                let manager = Unmanaged<HotKeyManager>
                    .fromOpaque(userData)
                    .takeUnretainedValue()

                var hotKeyID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hotKeyID
                )

                if hotKeyID.id == HotKeyManager.shortcutID {
                    DispatchQueue.main.async {
                        manager.action?()
                    }
                }

                return noErr
            },
            1,
            &eventType,
            Unmanaged.passUnretained(self).toOpaque(),
            &eventHandlerRef
        )

        guard handlerStatus == noErr else {
            throw HotKeyError.handlerRegistrationFailed(handlerStatus)
        }
    }

    private static let shortcutID = UInt32(1)
    private static let signature = OSType(
        UInt32(Character("S").asciiValue!) << 24
            | UInt32(Character("T").asciiValue!) << 16
            | UInt32(Character("R").asciiValue!) << 8
            | UInt32(Character("N").asciiValue!)
    )
}

enum HotKeyError: LocalizedError {
    case handlerRegistrationFailed(OSStatus)
    case registrationFailed(KeyboardShortcutSetting, OSStatus)

    var errorDescription: String? {
        switch self {
        case .handlerRegistrationFailed(let status):
            return "全局快捷键监听注册失败：\(status)"
        case .registrationFailed(let shortcut, let status):
            return "全局快捷键 \(shortcut.displayName) 注册失败：\(status)"
        }
    }
}
