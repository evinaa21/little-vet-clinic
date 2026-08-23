import AppKit
import Carbon.HIToolbox

/// Registers one system-wide hot key through Carbon's `RegisterEventHotKey`,
/// which is still the only sanctioned way to get a global shortcut without
/// asking for Accessibility permission.
final class HotKeyManager {

    static let shared = HotKeyManager()

    /// Fired on the main queue when the combo is pressed.
    var onFire: (() -> Void)?

    private static let signature: OSType = 0x50554646 // 'PUFF'
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    private init() { installHandler() }

    func register(_ combo: HotKeyCombo) {
        unregister()
        guard combo.keyCode != 0 || combo.modifiers != 0 else { return }

        let id = EventHotKeyID(signature: Self.signature, id: 1)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            combo.keyCode,
            combo.modifiers,
            id,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        if status == noErr {
            hotKeyRef = ref
        } else {
            NSLog("Puff: could not register hot key (status \(status)) — it may already be taken.")
        }
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }

    private func installHandler() {
        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ -> OSStatus in
                var pressedID = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &pressedID
                )
                guard pressedID.signature == HotKeyManager.signature else { return noErr }
                DispatchQueue.main.async { HotKeyManager.shared.onFire?() }
                return noErr
            },
            1,
            &spec,
            nil,
            &handlerRef
        )
    }
}