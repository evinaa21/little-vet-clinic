import AppKit
import Carbon.HIToolbox

/// The one global shortcut, fixed at ⌥ + Space.
///
/// Carbon's `RegisterEventHotKey` is still the only sanctioned way to take a
/// system-wide shortcut without asking for Accessibility permission.
final class HotKeyManager {

    static let shared = HotKeyManager()

    /// Fired on the main queue when ⌥Space is pressed.
    var onFire: (() -> Void)?

    /// What to print in the UI. Nothing remaps it, so this is a constant.
    static let displayString = "⌥Space"

    private static let signature: OSType = 0x56455453 // 'VETS'
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?

    private init() { installHandler() }

    func register() {
        unregister()
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(optionKey),
            EventHotKeyID(signature: Self.signature, id: 1),
            GetApplicationEventTarget(),
            0,
            &ref
        )
        if status == noErr {
            hotKeyRef = ref
        } else {
            NSLog("Little Vet Clinic: could not register ⌥Space (status \(status)) — something else may hold it.")
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
