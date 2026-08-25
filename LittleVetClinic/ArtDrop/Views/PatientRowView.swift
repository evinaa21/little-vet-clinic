import SwiftUI

/// One line on the intake sheet: `[accent] [face] [name] [status]`.
///
/// Clicking anywhere on the row sees the patient. The check-off is the whole
/// reason the widget exists, so it gets the full two-beat stamp: the rubber head
/// drops and shrinks onto the paper, and on contact the ink blooms out from under
/// it while the head lifts away.
struct PatientRowView: View {
    let patient: Patient
    let badge: Color
    let onToggle: () -> Void
    let onDischarge: () -> Void

    @State private var isHovering = false
    @State private var deleteHovering = false

    @State private var headVisible = false
    @State private var headScale: CGFloat = 0.9
    @State private var headOpacity: Double = 0

    @State private var inkVisible = false
    @State private var inkScale: CGFloat = 0.5
    @State private var inkOpacity: Double = 0

    @State private var settle: CGFloat = 0

    var body: some View {
        HStack(spacing: 8) {
            // A thin bar of the row's own badge colour. Purely rhythm: five rows of
            // identical weight in a column read flat without it.
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(badge)
                .frame(width: Metrics.accentStripWidth)
                .opacity(patient.isSeen ? 0.45 : 1)

            AnimalAvatarView(animal: patient.animal, mood: patient.mood, badge: badge)

            Text(patient.name)
                .font(ClinicFont.printed(10.5, .medium))
                .foregroundColor(patient.isSeen ? Clinic.ink.opacity(0.4) : Clinic.ink)
                .strikethrough(patient.isSeen, color: Clinic.ink.opacity(0.3))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            StatusPill(isSeen: patient.isSeen)

            // A fixed gutter, so the discharge button fading in on hover never
            // reflows the name beside it.
            Button(action: onDischarge) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(deleteHovering ? Clinic.stamp : Clinic.inkMuted)
                    .scaleEffect(deleteHovering ? 1.15 : 1)
            }
            .buttonStyle(.plain)
            .frame(width: 12)
            .opacity(isHovering ? 1 : 0)
            .onHover { hovering in
                withAnimation(.spring(response: 0.28, dampingFraction: 0.6)) {
                    deleteHovering = hovering
                }
            }
            .help("Discharge — remove this patient")
        }
        .padding(.vertical, 5)
        .padding(.trailing, 2)
        .offset(y: settle)
        .background(rowWash)
        .overlay(stampLayer)
        .contentShape(Rectangle())
        .onTapGesture(perform: onToggle)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { isHovering = hovering }
        }
        .onChange(of: patient.isSeen) { isSeen in
            if isSeen { pressStamp() }
        }
    }

    /// Plain hover is a faint grey; hovering the ✕ warms it red, so a removal
    /// announces itself as the more deliberate of the two actions.
    private var rowWash: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .fill(deleteHovering
                  ? Clinic.tearWash.opacity(0.3)
                  : Clinic.ink.opacity(isHovering ? 0.035 : 0))
            .padding(.horizontal, -4)
    }

    @ViewBuilder
    private var stampLayer: some View {
        ZStack {
            if inkVisible {
                InkMarkView().scaleEffect(inkScale).opacity(inkOpacity)
            }
            if headVisible {
                StampHeadView().scaleEffect(headScale).opacity(headOpacity)
            }
        }
        .allowsHitTesting(false)
    }

    /// Beat one: the head drops. Beat two, on contact: the ink blooms out from
    /// under it, the head lifts away, and the row dips as the paper takes the
    /// pressure. Splitting it in two is the whole difference between a stamp
    /// landing and a badge appearing.
    private func pressStamp() {
        headScale = 0.9
        headOpacity = 1
        headVisible = true
        inkVisible = false

        // Beat one — down onto the paper.
        withAnimation(.easeIn(duration: 0.1)) { headScale = 0.5 }

        // Beat two — contact.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            inkScale = 0.5
            inkOpacity = 1
            inkVisible = true
            withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) { inkScale = 1 }
            withAnimation(.easeOut(duration: 0.12)) { headOpacity = 0 }
            withAnimation(.easeOut(duration: 0.07)) { settle = 2 }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) { headVisible = false }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { settle = 0 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.3)) { inkOpacity = 0 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) { inkVisible = false }
        }
    }
}
