import SwiftUI
import AppKit

// MARK: - Frosted glass

/// `NSVisualEffectView` as a SwiftUI background. `.behindWindow` blending is what
/// makes the panel pick up the desktop and windows underneath it.
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blending: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blending
        view.state = .active           // stay frosted even when the app is inactive
        view.isEmphasized = false
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
        view.blendingMode = blending
    }
}

// MARK: - Window dragging

/// An invisible strip that hands mouse-downs to `performDrag(with:)`, which is the
/// only reliable way to move a borderless window without fighting SwiftUI gestures.
struct WindowDragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView { DragHandleView() }
    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class DragHandleView: NSView {
        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
        override func resetCursorRects() {
            addCursorRect(bounds, cursor: .openHand)
        }
    }
}

// MARK: - Click-to-activate

/// The panel is non-activating, so a plain click doesn't bring the app forward and
/// keystrokes would go to whatever app *is* frontmost. This transparent shim sits
/// over the quick-add field while it is unfocused: one click activates Puff and
/// focuses the field, after which the shim gets out of the way.
struct ClickToActivate: NSViewRepresentable {
    var onClick: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = ActivatorView()
        view.onClick = onClick
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        (nsView as? ActivatorView)?.onClick = onClick
    }

    private final class ActivatorView: NSView {
        var onClick: (() -> Void)?

        override func mouseDown(with event: NSEvent) {
            NSApp.activate(ignoringOtherApps: true)
            window?.makeKeyAndOrderFront(nil)
            onClick?()
        }

        override func resetCursorRects() {
            addCursorRect(bounds, cursor: .iBeam)
        }
    }
}