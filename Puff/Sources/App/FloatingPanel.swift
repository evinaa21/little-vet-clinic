import AppKit
import SwiftUI

/// The desktop-widget window.
///
/// A borderless, non-activating `NSPanel` that floats over other apps, joins every
/// Space, and carries a SwiftUI view through an `NSHostingController`. It is
/// transparent: the visible rounded card (and its shadow) are drawn in SwiftUI, so
/// the window itself contributes no chrome at all.
final class FloatingPanel: NSPanel {

    /// Called whenever the user finishes dragging the panel somewhere new.
    var onMove: ((CGPoint) -> Void)?

    init<Content: View>(view: Content) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: Metrics.windowWidth, height: 420),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]

        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        isMovableByWindowBackground = false   // dragging is limited to the header handle
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = false

        backgroundColor = .clear
        isOpaque = false
        hasShadow = false                      // the soft shadow is drawn in SwiftUI
        animationBehavior = .utilityWindow

        let hosting = NSHostingController(rootView: view)
        hosting.sizingOptions = [.preferredContentSize]  // window grows/shrinks with the list
        contentViewController = hosting

        delegate = self
    }

    // A borderless panel must opt in to key status or the quick-add field can't type.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Restore a saved origin, clamped so the panel can't come back off-screen
    /// (a monitor that is no longer attached, for instance).
    func restore(origin: CGPoint?) {
        guard let origin else {
            center()
            return
        }
        let frame = NSRect(origin: origin, size: frame.size)
        let visible = NSScreen.screens.contains { $0.visibleFrame.intersects(frame) }
        if visible {
            setFrameOrigin(origin)
        } else {
            center()
        }
    }
}

extension FloatingPanel: NSWindowDelegate {
    func windowDidMove(_ notification: Notification) {
        onMove?(frame.origin)
    }
}