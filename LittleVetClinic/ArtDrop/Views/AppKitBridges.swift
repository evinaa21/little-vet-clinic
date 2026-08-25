import SwiftUI
import AppKit

/// Both bridges below are plain AppKit views that SwiftUI positions by setting
/// their frame directly. Left at the default, AppKit answers every one of those
/// frame changes by regenerating the view's autoresizing constraints, and a
/// SwiftUI tree that animates continuously drives that on every frame. The
/// constraint engine falls behind, its pending-removal queue grows, and it
/// eventually recurses deep enough inside `_flushPendingRemovals` to overflow the
/// stack and take the app with it.
///
/// Neither view uses Auto Layout for anything, so opting them out costs nothing
/// and removes that whole path.
private func detachFromAutoLayout(_ view: NSView) {
    view.translatesAutoresizingMaskIntoConstraints = false
}

// MARK: - Window dragging

/// The strip you pick the clipboard up by.
///
/// It moves the window itself rather than calling `performDrag(with:)`, which
/// won't let a window's top edge pass under the menu bar. Two other details
/// matter more than they look:
///
/// * `acceptsFirstMouse` — the panel is non-activating and usually *isn't* the
///   frontmost app, and by default AppKit swallows the click that brings a window
///   forward. Without this, the first grab on the clip does nothing and you have
///   to click twice to start dragging.
/// * It is attached as an overlay rather than a background, so it sits above the
///   drawn clip in the view hierarchy and actually receives the event.
struct WindowDragHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = DragHandleView()
        detachFromAutoLayout(view)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class DragHandleView: NSView {

        /// Where inside the window the grab started, so the clip stays under the
        /// pointer for the whole drag.
        private var grabOffset: CGSize?

        override func mouseDown(with event: NSEvent) {
            guard let window else { return }
            let mouse = NSEvent.mouseLocation
            let origin = window.frame.origin
            grabOffset = CGSize(width: mouse.x - origin.x, height: mouse.y - origin.y)
            NSCursor.closedHand.set()
        }

        override func mouseDragged(with event: NSEvent) {
            guard let window, let grab = grabOffset else { return }
            let mouse = NSEvent.mouseLocation
            let wanted = NSPoint(x: mouse.x - grab.width, y: mouse.y - grab.height)
            window.setFrameOrigin(Self.clamped(wanted, size: window.frame.size))
        }

        override func mouseUp(with event: NSEvent) {
            grabOffset = nil
            NSCursor.openHand.set()
        }

        /// Grab it while another app is focused and the drag starts immediately,
        /// rather than the click being eaten as an activation.
        override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

        /// The clipboard is meant to go anywhere on the desktop, including hard
        /// into a corner or up behind the menu bar. AppKit's own `performDrag`
        /// refuses that last one, which is why the window is moved by hand here.
        ///
        /// The only rule kept is that the clip has to stay reachable on some
        /// screen — a handle you can't get to is a widget you can't get back.
        private static func clamped(_ origin: NSPoint, size: NSSize) -> NSPoint {
            let screens = NSScreen.screens
            guard var union = screens.first?.frame else { return origin }
            for screen in screens.dropFirst() { union = union.union(screen.frame) }

            let keepVisible: CGFloat = 90     // of the card's width
            let handleDepth: CGFloat = 60     // of the card's top edge

            var point = origin
            point.x = min(max(point.x, union.minX - size.width + keepVisible), union.maxX - keepVisible)
            point.y = min(max(point.y, union.minY + handleDepth - size.height), union.maxY - size.height)
            return point
        }

        override func resetCursorRects() {
            addCursorRect(bounds, cursor: .openHand)
        }

        /// `resetCursorRects` only applies while the window is key, which this one
        /// often isn't. This covers the rest of the time.
        override func cursorUpdate(with event: NSEvent) {
            NSCursor.openHand.set()
        }
    }
}

// MARK: - Click-to-activate

/// The panel is non-activating, so a plain click doesn't bring the app forward and
/// keystrokes would go to whatever app *is* frontmost. This transparent shim sits
/// over the check-in field while it is unfocused: one click activates the clinic
/// and focuses the field, after which the shim gets out of the way.
struct ClickToActivate: NSViewRepresentable {
    var onClick: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = ActivatorView()
        view.onClick = onClick
        detachFromAutoLayout(view)
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
