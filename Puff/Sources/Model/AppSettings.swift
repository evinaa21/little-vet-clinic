import SwiftUI
import Combine
import Carbon.HIToolbox

enum Mascot: String, CaseIterable, Identifiable, Codable {
    case capybara
    case cat
    case blob

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .capybara: return "Capybara"
        case .cat:      return "Cat"
        case .blob:     return "Blob"
        }
    }
}

/// A global shortcut, stored as a Carbon key code plus Carbon modifier mask.
struct HotKeyCombo: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32

    /// ⌥ + Space
    static let `default` = HotKeyCombo(keyCode: UInt32(kVK_Space), modifiers: UInt32(optionKey))

    var displayString: String {
        var parts = ""
        if modifiers & UInt32(controlKey) != 0 { parts += "⌃" }
        if modifiers & UInt32(optionKey)  != 0 { parts += "⌥" }
        if modifiers & UInt32(shiftKey)   != 0 { parts += "⇧" }
        if modifiers & UInt32(cmdKey)     != 0 { parts += "⌘" }
        return parts + KeyCodeNames.name(for: keyCode)
    }
}

/// Everything the settings window can change. Backed by UserDefaults so it is
/// there again the next time the app launches.
final class AppSettings: ObservableObject {

    @Published var theme: Theme {
        didSet { defaults.set(theme.rawValue, forKey: Keys.theme) }
    }
    @Published var mascot: Mascot {
        didSet { defaults.set(mascot.rawValue, forKey: Keys.mascot) }
    }
    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Keys.sound) }
    }
    @Published var showStreak: Bool {
        didSet { defaults.set(showStreak, forKey: Keys.streak) }
    }
    @Published var hotKey: HotKeyCombo {
        didSet {
            if let data = try? JSONEncoder().encode(hotKey) {
                defaults.set(data, forKey: Keys.hotKey)
            }
            onHotKeyChange?(hotKey)
        }
    }

    /// Set by the app delegate so a remap re-registers the Carbon hot key immediately.
    var onHotKeyChange: ((HotKeyCombo) -> Void)?

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let theme  = "puff.theme"
        static let mascot = "puff.mascot"
        static let sound  = "puff.soundEnabled"
        static let streak = "puff.showStreak"
        static let hotKey = "puff.hotKey"
        static let origin = "puff.panelOrigin"
    }

    init() {
        theme = Theme(rawValue: defaults.string(forKey: Keys.theme) ?? "") ?? .lavender
        mascot = Mascot(rawValue: defaults.string(forKey: Keys.mascot) ?? "") ?? .capybara
        soundEnabled = defaults.object(forKey: Keys.sound) as? Bool ?? true
        showStreak = defaults.object(forKey: Keys.streak) as? Bool ?? true
        if let data = defaults.data(forKey: Keys.hotKey),
           let combo = try? JSONDecoder().decode(HotKeyCombo.self, from: data) {
            hotKey = combo
        } else {
            hotKey = .default
        }
    }

    // MARK: Panel position

    /// Bottom-left origin of the floating panel, remembered between launches.
    var panelOrigin: CGPoint? {
        get {
            guard let dict = defaults.dictionary(forKey: Keys.origin),
                  let x = dict["x"] as? Double, let y = dict["y"] as? Double else { return nil }
            return CGPoint(x: x, y: y)
        }
        set {
            guard let newValue else { return }
            defaults.set(["x": newValue.x, "y": newValue.y], forKey: Keys.origin)
        }
    }
}

// MARK: - Key code display names

enum KeyCodeNames {
    private static let table: [UInt32: String] = [
        UInt32(kVK_Space): "Space",
        UInt32(kVK_Return): "↩",
        UInt32(kVK_Tab): "⇥",
        UInt32(kVK_Escape): "⎋",
        UInt32(kVK_Delete): "⌫",
        UInt32(kVK_ANSI_A): "A", UInt32(kVK_ANSI_B): "B", UInt32(kVK_ANSI_C): "C",
        UInt32(kVK_ANSI_D): "D", UInt32(kVK_ANSI_E): "E", UInt32(kVK_ANSI_F): "F",
        UInt32(kVK_ANSI_G): "G", UInt32(kVK_ANSI_H): "H", UInt32(kVK_ANSI_I): "I",
        UInt32(kVK_ANSI_J): "J", UInt32(kVK_ANSI_K): "K", UInt32(kVK_ANSI_L): "L",
        UInt32(kVK_ANSI_M): "M", UInt32(kVK_ANSI_N): "N", UInt32(kVK_ANSI_O): "O",
        UInt32(kVK_ANSI_P): "P", UInt32(kVK_ANSI_Q): "Q", UInt32(kVK_ANSI_R): "R",
        UInt32(kVK_ANSI_S): "S", UInt32(kVK_ANSI_T): "T", UInt32(kVK_ANSI_U): "U",
        UInt32(kVK_ANSI_V): "V", UInt32(kVK_ANSI_W): "W", UInt32(kVK_ANSI_X): "X",
        UInt32(kVK_ANSI_Y): "Y", UInt32(kVK_ANSI_Z): "Z",
        UInt32(kVK_ANSI_0): "0", UInt32(kVK_ANSI_1): "1", UInt32(kVK_ANSI_2): "2",
        UInt32(kVK_ANSI_3): "3", UInt32(kVK_ANSI_4): "4", UInt32(kVK_ANSI_5): "5",
        UInt32(kVK_ANSI_6): "6", UInt32(kVK_ANSI_7): "7", UInt32(kVK_ANSI_8): "8",
        UInt32(kVK_ANSI_9): "9",
        UInt32(kVK_ANSI_Period): ".", UInt32(kVK_ANSI_Comma): ",",
        UInt32(kVK_ANSI_Slash): "/", UInt32(kVK_ANSI_Backslash): "\\",
        UInt32(kVK_ANSI_Semicolon): ";", UInt32(kVK_ANSI_Quote): "'",
        UInt32(kVK_ANSI_LeftBracket): "[", UInt32(kVK_ANSI_RightBracket): "]",
        UInt32(kVK_ANSI_Minus): "-", UInt32(kVK_ANSI_Equal): "=",
        UInt32(kVK_ANSI_Grave): "`",
        UInt32(kVK_F1): "F1", UInt32(kVK_F2): "F2", UInt32(kVK_F3): "F3",
        UInt32(kVK_F4): "F4", UInt32(kVK_F5): "F5", UInt32(kVK_F6): "F6",
        UInt32(kVK_F7): "F7", UInt32(kVK_F8): "F8", UInt32(kVK_F9): "F9",
        UInt32(kVK_F10): "F10", UInt32(kVK_F11): "F11", UInt32(kVK_F12): "F12",
        UInt32(kVK_LeftArrow): "←", UInt32(kVK_RightArrow): "→",
        UInt32(kVK_UpArrow): "↑", UInt32(kVK_DownArrow): "↓"
    ]

    static func name(for keyCode: UInt32) -> String {
        table[keyCode] ?? "Key \(keyCode)"
    }
}

// MARK: - NSEvent → Carbon modifier translation

extension NSEvent.ModifierFlags {
    var carbonFlags: UInt32 {
        var flags: UInt32 = 0
        if contains(.command) { flags |= UInt32(cmdKey) }
        if contains(.option)  { flags |= UInt32(optionKey) }
        if contains(.shift)   { flags |= UInt32(shiftKey) }
        if contains(.control) { flags |= UInt32(controlKey) }
        return flags
    }
}