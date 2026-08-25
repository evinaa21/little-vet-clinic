import SwiftUI

/// A patient arriving is checked in from the side; a patient leaving is torn off
/// the sheet. Keeping the two motions unrelated is the point — the board should
/// never leave you unsure whether something was finished or thrown away.
extension AnyTransition {

    /// Slides in from the right while fading up.
    static var checkIn: AnyTransition {
        .modifier(active: CheckInEffect(hidden: true), identity: CheckInEffect(hidden: false))
    }

    /// Tips, drops off the bottom edge and fades — a strip torn from the pad.
    static var tearOff: AnyTransition {
        .modifier(active: TearOffEffect(torn: true), identity: TearOffEffect(torn: false))
    }

    /// What a row uses: arrive from the side, leave through the bottom.
    static var patientRow: AnyTransition {
        .asymmetric(insertion: .checkIn, removal: .tearOff)
    }
}

private struct CheckInEffect: ViewModifier {
    let hidden: Bool

    func body(content: Content) -> some View {
        content
            .offset(x: hidden ? 40 : 0)
            .opacity(hidden ? 0 : 1)
    }
}

private struct TearOffEffect: ViewModifier {
    let torn: Bool

    func body(content: Content) -> some View {
        content
            // Anchored at the left so the row pivots away from the spine of the
            // sheet, the way paper gives when you pull a strip off it.
            .rotationEffect(.degrees(torn ? 3.5 : 0), anchor: .leading)
            .offset(y: torn ? 90 : 0)
            .opacity(torn ? 0 : 1)
    }
}
