import SwiftUI
import Combine

/// Drives the signature moment: the sheet feeding out from under the clip.
///
/// The clip is fixed furniture — it never moves. What animates is a top-down mask
/// over the paper, so the sheet appears to extend downward out of the clip's grip,
/// revealing the header first, then each row as the edge passes it, then the
/// footer. The view keeps its full layout size throughout, which matters: the
/// window is sized from the hosting controller's preferred size, and animating the
/// real height would have the window itself resizing 60 times a second.
///
/// The app delegate owns one of these and calls `open()` / `close(then:)` around
/// ordering the panel in and out. Every method is main-thread only,
/// which is where both the delegate and SwiftUI already are.
final class PanelPresentation: ObservableObject {

    /// 0 = fully rolled up under the clip, 1 = fully fed out.
    @Published var reveal: CGFloat = 0
    /// Vertical squash on the clip, for the pinch as the paper lands.
    @Published var clipPinch: CGFloat = 1

    /// The feed itself. Quick off the mark like a motor engaging, then settling —
    /// a high damping fraction so the paper glides to a stop instead of bouncing.
    private static let feed = Animation.spring(response: 0.62, dampingFraction: 0.88)
    /// Retracting is the same motion played faster and without ceremony.
    private static let retract = Animation.spring(response: 0.28, dampingFraction: 1)

    /// How long to leave the panel on screen before ordering it out.
    static let closeDuration: TimeInterval = 0.26
    /// When the paper reaches the end of its travel — the clip pinches here, and
    /// the unroll sound places its settle-thud at the same moment.
    private static let settleAt: TimeInterval = 0.42

    /// Snap to the rolled-up state with no animation, before the window appears.
    func prepareForOpen() {
        var instant = Transaction()
        instant.disablesAnimations = true
        withTransaction(instant) {
            reveal = 0
            clipPinch = 1
        }
    }

    func open() {
        withAnimation(Self.feed) { reveal = 1 }

        // The clip clamps down the instant the paper stops moving.
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.settleAt) { [weak self] in
            guard let self, self.reveal > 0 else { return }   // closed again already
            withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) { self.clipPinch = 0.9 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { self.clipPinch = 1 }
            }
        }
    }

    /// Retract the paper, then hand back so the caller can order the window out.
    func close(then finish: @escaping () -> Void) {
        withAnimation(Self.retract) { reveal = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.closeDuration, execute: finish)
    }
}
