import SwiftUI

/// One line of the footer subtotal: an icon, a label, and the count.
///
/// The number never just changes. Icon and figure pop together on the same spring,
/// so the pair registers the update as one event — the count doing it alone reads
/// like a value being written rather than something happening.
struct TallyLine: View {
    let icon: String
    let label: String
    let count: Int
    let ink: Color

    @State private var pop: CGFloat = 1

    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: icon)
                .font(.system(size: 8.5, weight: .semibold))
                .foregroundColor(Clinic.inkMuted)
                .frame(width: 13, alignment: .leading)
                .scaleEffect(pop)

            Text(label)
                .font(ClinicFont.printed(9.5, .semibold))
                .kerning(0.6)
                .foregroundColor(Clinic.ink.opacity(0.6))

            Spacer(minLength: 8)

            Text("\(count)")
                .font(ClinicFont.printed(11, .bold))
                .foregroundColor(ink)
                .scaleEffect(pop)
        }
        .onChange(of: count) { _ in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) { pop = 1.2 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) { pop = 1 }
            }
        }
    }
}
