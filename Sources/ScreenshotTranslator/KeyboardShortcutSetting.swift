import AppKit
import Carbon
import Foundation

struct KeyboardShortcutSetting: Equatable {
    static let changedNotification = Notification.Name("KeyboardShortcutSettingChanged")
    static let keyCodeDefaultsKey = "shortcutKeyCode"
    static let modifiersDefaultsKey = "shortcutModifiers"

    static let defaultKeyCode = Int(kVK_ANSI_S)
    static let defaultModifiers = Int(cmdKey | shiftKey)

    var keyCode: UInt32
    var modifiers: UInt32

    var displayName: String {
        let modifierText = modifierDisplayName(modifiers)
        let keyText = keyDisplayName(keyCode)
        return modifierText.isEmpty ? keyText : "\(modifierText)\(keyText)"
    }

    var isValid: Bool {
        containsSupportedModifier && !isModifierOnlyKey
    }

    static func stored(in defaults: UserDefaults = .standard) -> KeyboardShortcutSetting {
        KeyboardShortcutSetting(
            keyCode: UInt32(defaults.integer(forKey: keyCodeDefaultsKey)),
            modifiers: UInt32(defaults.integer(forKey: modifiersDefaultsKey))
        ).normalized
    }

    static func save(_ shortcut: KeyboardShortcutSetting, in defaults: UserDefaults = .standard) {
        let normalizedShortcut = shortcut.normalized
        defaults.set(Int(normalizedShortcut.keyCode), forKey: keyCodeDefaultsKey)
        defaults.set(Int(normalizedShortcut.modifiers), forKey: modifiersDefaultsKey)
        NotificationCenter.default.post(name: changedNotification, object: nil)
    }

    static func saveDefault(in defaults: UserDefaults = .standard) {
        save(.defaultValue, in: defaults)
    }

    static var defaultValue: KeyboardShortcutSetting {
        KeyboardShortcutSetting(
            keyCode: UInt32(defaultKeyCode),
            modifiers: UInt32(defaultModifiers)
        )
    }

    private var normalized: KeyboardShortcutSetting {
        isValid ? self : .defaultValue
    }

    private var containsSupportedModifier: Bool {
        modifiers & UInt32(cmdKey) != 0
            || modifiers & UInt32(controlKey) != 0
            || modifiers & UInt32(optionKey) != 0
            || modifiers & UInt32(shiftKey) != 0
    }

    private var isModifierOnlyKey: Bool {
        let modifierKeyCodes = [
            kVK_Command,
            kVK_Shift,
            kVK_CapsLock,
            kVK_Option,
            kVK_Control,
            kVK_RightCommand,
            kVK_RightShift,
            kVK_RightOption,
            kVK_RightControl,
            kVK_Function
        ]

        return modifierKeyCodes.contains(Int(keyCode))
    }
}

func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
    var modifiers: UInt32 = 0

    if flags.contains(.command) {
        modifiers |= UInt32(cmdKey)
    }

    if flags.contains(.shift) {
        modifiers |= UInt32(shiftKey)
    }

    if flags.contains(.option) {
        modifiers |= UInt32(optionKey)
    }

    if flags.contains(.control) {
        modifiers |= UInt32(controlKey)
    }

    return modifiers
}

private func modifierDisplayName(_ modifiers: UInt32) -> String {
    var parts: [String] = []

    if modifiers & UInt32(controlKey) != 0 {
        parts.append("Control")
    }

    if modifiers & UInt32(optionKey) != 0 {
        parts.append("Option")
    }

    if modifiers & UInt32(shiftKey) != 0 {
        parts.append("Shift")
    }

    if modifiers & UInt32(cmdKey) != 0 {
        parts.append("Command")
    }

    return parts.isEmpty ? "" : parts.joined(separator: " + ") + " + "
}

private func keyDisplayName(_ keyCode: UInt32) -> String {
    switch Int(keyCode) {
    case kVK_ANSI_A: return "A"
    case kVK_ANSI_B: return "B"
    case kVK_ANSI_C: return "C"
    case kVK_ANSI_D: return "D"
    case kVK_ANSI_E: return "E"
    case kVK_ANSI_F: return "F"
    case kVK_ANSI_G: return "G"
    case kVK_ANSI_H: return "H"
    case kVK_ANSI_I: return "I"
    case kVK_ANSI_J: return "J"
    case kVK_ANSI_K: return "K"
    case kVK_ANSI_L: return "L"
    case kVK_ANSI_M: return "M"
    case kVK_ANSI_N: return "N"
    case kVK_ANSI_O: return "O"
    case kVK_ANSI_P: return "P"
    case kVK_ANSI_Q: return "Q"
    case kVK_ANSI_R: return "R"
    case kVK_ANSI_S: return "S"
    case kVK_ANSI_T: return "T"
    case kVK_ANSI_U: return "U"
    case kVK_ANSI_V: return "V"
    case kVK_ANSI_W: return "W"
    case kVK_ANSI_X: return "X"
    case kVK_ANSI_Y: return "Y"
    case kVK_ANSI_Z: return "Z"
    case kVK_ANSI_0: return "0"
    case kVK_ANSI_1: return "1"
    case kVK_ANSI_2: return "2"
    case kVK_ANSI_3: return "3"
    case kVK_ANSI_4: return "4"
    case kVK_ANSI_5: return "5"
    case kVK_ANSI_6: return "6"
    case kVK_ANSI_7: return "7"
    case kVK_ANSI_8: return "8"
    case kVK_ANSI_9: return "9"
    case kVK_Space: return "Space"
    case kVK_Escape: return "Esc"
    case kVK_Return: return "Return"
    case kVK_Tab: return "Tab"
    case kVK_F1: return "F1"
    case kVK_F2: return "F2"
    case kVK_F3: return "F3"
    case kVK_F4: return "F4"
    case kVK_F5: return "F5"
    case kVK_F6: return "F6"
    case kVK_F7: return "F7"
    case kVK_F8: return "F8"
    case kVK_F9: return "F9"
    case kVK_F10: return "F10"
    case kVK_F11: return "F11"
    case kVK_F12: return "F12"
    default: return "Key \(keyCode)"
    }
}
