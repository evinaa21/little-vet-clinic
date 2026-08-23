import SwiftUI
import AppKit
import Carbon.HIToolbox

/// Click it, press a combo, done. Escape cancels, ⌫ restores the default.
///
/// Recording happens in a real `NSView` because SwiftUI has no way to see a raw
/// key-down before the system turns it into text.
struct KeyRecorderView: NSViewRepresentable {
    @Binding var combo: HotKeyCombo
    @Binding var isRecording: Bool

    func makeNSView(context: Context) -> RecorderView {
        let view = RecorderView()
        view.onCapture = { keyCode, modifiers in
            combo = HotKeyCombo(keyCode: keyCode, modifiers: modifiers)
            isRecording = false
        }
        view.onCancel = { isRecording = false }
        view.onReset = {
            combo = .default
            isRecording = false
        }
        view.onBeginRecording = { isRecording = true }
        return view
    }

    func updateNSView(_ view: RecorderView, context: Context) {
        view.isRecording = isRecording
        if isRecording, view.window?.firstResponder !== view {
            view.window?.makeFirstResponder(view)
        }
    }

    final class RecorderView: NSView {
        var onCapture: ((UInt32, UInt32) -> Void)?
        var onCancel: (() -> Void)?
        var onReset: (() -> Void)?
        var onBeginRecording: (() -> Void)?
        var isRecording = false

        override var acceptsFirstResponder: Bool { true }

        override func mouseDown(with event: NSEvent) {
            window?.makeFirstResponder(self)
            onBeginRecording?()
        }

        override func keyDown(with event: NSEvent) {
            guard isRecording else {
                super.keyDown(with: event)
                return
            }

            switch Int(event.keyCode) {
            case kVK_Escape:
                onCancel?()
                return
            case kVK_Delete, kVK_ForwardDelete:
                onReset?()
                return
            default:
                break
            }

            let modifiers = event.modifierFlags.carbonFlags
            // A bare letter would swallow that key system-wide, so require a modifier.
            guard modifiers != 0 else { NSSound.beep(); return }

            onCapture?(UInt32(event.keyCode), modifiers)
        }

        override func resignFirstResponder() -> Bool {
            if isRecording { onCancel?() }
            return true
        }

        override func resetCursorRects() {
            addCursorRect(bounds, cursor: .pointingHand)
        }
    }
}

/// The visible chrome around the recorder.
struct HotKeyField: View {
    @Binding var combo: HotKeyCombo
    @State private var isRecording = false
    let theme: Theme

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(isRecording ? theme.accent : Color.primary.opacity(0.12),
                                      lineWidth: isRecording ? 1.8 : 1)
                )

            Text(isRecording ? "press a combo…" : combo.displayString)
                .font(Font2.rounded(12, .semibold))
                .foregroundColor(isRecording ? theme.accent : .primary)

            KeyRecorderView(combo: $combo, isRecording: $isRecording)
        }
        .frame(width: 120, height: 26)
        .help("Click, then press the shortcut. ⌫ restores ⌥Space, ⎋ cancels.")
    }
}