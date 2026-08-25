import AppKit
import SwiftUI

/// The clipboard window.
///
/// A borderless, non-activating `NSPanel` that floats over other apps, joins every
/// Space, and carries the SwiftUI view through an `NSHostingController`. The window
/// itself is fully transparent — the paper, the clip, and the drop shadow are all
/// drawn in SwiftUI, so the torn bottom edge reads as a real torn edge.
final class FloatingPanel: NSPanel {

    /// Called whenever the user finishes dragging the clipboard somewhere new.
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
        isMovableByWindowBackground = false   // dragging is limited to the clip bar
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = false

        backgroundColor = .clear
        isOpaque = false
        hasShadow = false                      // the paper's shadow is drawn in SwiftUI
        animationBehavior = .utilityWindow

        let hosting = NSHostingController(rootView: view)
        hosting.sizingOptions = [.preferredContentSize]  // the sheet grows with the list
        contentViewController = hosting

        delegate = self
    }

    // A borderless panel must opt in to key status or the check-in field can't type.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    /// Restore a saved origin, clamped so the clipboard can't come back off-screen
    /// (a monitor that is no longer attached, for instance).
    func restore(origin: CGPoint?) {
        guard let origin else {
            center()
            return
        }
        let candidate = NSRect(origin: origin, size: frame.size)
        if NSScreen.screens.contains(where: { $0.visibleFrame.intersects(candidate) }) {
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
