import SwiftUI

/// The rubber stamp itself, on its way down.
///
/// This is the object in the hand, not the mark it leaves: solid, lifted off the
/// paper by a shadow, and opaque. It exists only for the tenth of a second before
/// contact, and shrinking it over that beat is what reads as it travelling down to
/// meet the sheet.
struct StampHeadView: View {
    var body: some View {
        Text("SEEN")
            .font(ClinicFont.printed(14, .heavy))
            .kerning(2.5)
            .foregroundColor(Clinic.paper)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Clinic.stamp)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(Clinic.stamp.opacity(0.65), lineWidth: 2.5)
                    .padding(-3)
            )
            .rotationEffect(.degrees(-11))
            .shadow(color: Color.black.opacity(0.28), radius: 5, x: 0, y: 4)
            .allowsHitTesting(false)
    }
}

/// The mark left behind once the stamp makes contact.
///
/// Multiply blending lets the paper show through the ink, which is most of why it
/// reads as a stamp rather than a label.
struct InkMarkView: View {
    var body: some View {
        Text("SEEN")
            .font(ClinicFont.printed(14, .heavy))
            .kerning(2.5)
            .foregroundColor(Clinic.stamp)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(Clinic.stamp, lineWidth: 2.5)
            )
            .rotationEffect(.degrees(-11))
            .opacity(0.82)
            .blendMode(.multiply)
            .allowsHitTesting(false)
    }
}
