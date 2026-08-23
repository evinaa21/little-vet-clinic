import SwiftUI

/// An empty list should never look like a bug. Big sleepy mascot, a line of copy,
/// and a small nudge toward the field above.
struct EmptyStateView: View {
    let mascot: Mascot
    let theme: Theme

    private static let lines = [
        "nothing to do… suspicious 👀",
        "the list is empty. sus.",
        "zero tasks. what are you hiding?",
        "all clear — genuinely, none left"
    ]

    /// Chosen once per appearance so the copy doesn't flicker on every redraw.
    @State private var line = EmptyStateView.lines[0]

    var body: some View {
        VStack(spacing: 8) {
            MascotView(mascot: mascot, state: .sleepy, theme: theme, size: 54)
                .padding(.top, 4)

            Text(line)
                .font(Font2.rounded(12, .semibold))
                .foregroundColor(theme.ink.opacity(0.6))
                .multilineTextAlignment(.center)

            Text("type up top and hit return")
                .font(Font2.rounded(10, .medium))
                .foregroundColor(theme.ink.opacity(0.35))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .onAppear { line = Self.lines.randomElement() ?? Self.lines[0] }
    }
}