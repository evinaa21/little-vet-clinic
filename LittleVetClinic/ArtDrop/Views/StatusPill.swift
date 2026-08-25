import SwiftUI

/// The status column. Fixed width so that flipping between the two states never
/// shifts the patient's name a pixel to the left or right.
struct StatusPill: View {
    let isSeen: Bool

    var body: some View {
        Text(isSeen ? "SEEN ♡" : "WAITING")
            .font(ClinicFont.printed(7.5, .bold))
            .kerning(0.5)
            .foregroundColor(isSeen ? Clinic.seenPillInk : Clinic.waitingPillInk)
            .frame(width: 54, height: 17)
            .background(Capsule().fill(isSeen ? Clinic.seenPill : Clinic.waitingPill))
            .animation(.easeInOut(duration: 0.2), value: isSeen)
    }
}
