import SwiftUI

/// A hand-drawn circular checkbox — deliberately not `Toggle`, so it can bounce.
///
/// On check: scale runs 0.8 → 1.1 → 1.0 on a spring while the fill blooms out from
/// the centre and a sparkle burst fires over the top.
struct CheckboxView: View {
    let isDone: Bool
    let theme: Theme
    let action: () -> Void

    @State private var scale: CGFloat = 1
    @State private var burstID: Int = 0
    @State private var showBurst = false

    private let diameter: CGFloat = 20

    var body: some View {
        ZStack {
            Circle()
                .strokeBorder(isDone ? theme.accent : theme.ink.opacity(0.35), lineWidth: 1.8)

            Circle()
                .fill(theme.accent)
                .padding(1.5)
                .scaleEffect(isDone ? 1 : 0.01)
                .opacity(isDone ? 1 : 0)

            Image(systemName: "checkmark")
                .font(.system(size: 9.5, weight: .black, design: .rounded))
                .foregroundColor(.white)
                .scaleEffect(isDone ? 1 : 0.3)
                .opacity(isDone ? 1 : 0)

            if showBurst {
                SparkleBurst(colors: theme.sparkles)
                    .id(burstID)
                    .allowsHitTesting(false)
            }
        }
        .frame(width: diameter, height: diameter)
        .scaleEffect(scale)
        .contentShape(Circle())
        .onTapGesture { tapped() }
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel(isDone ? "Mark as not done" : "Mark as done")
    }

    private func tapped() {
        let willComplete = !isDone

        // 0.8 → 1.1 → 1.0, timed so the fill lands on the overshoot.
        scale = 0.8
        withAnimation(.spring(response: 0.20, dampingFraction: 0.45)) { scale = 1.1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            withAnimation(.spring(response: 0.26, dampingFraction: 0.62)) { scale = 1.0 }
        }

        if willComplete {
            burstID &+= 1
            showBurst = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) { showBurst = false }
        }

        withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) { action() }
    }
}

/// Eight little four-point stars thrown outward from the checkbox, fading as they go.
struct SparkleBurst: View {
    let colors: [Color]
    var count: Int = 8

    @State private var progress: CGFloat = 0

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            for index in 0..<count {
                let angle = (Double(index) / Double(count)) * 2 * .pi + 0.35
                // Ease-out travel, so they leap and then drift.
                let eased = 1 - pow(1 - progress, 2.2)
                let distance = 6 + eased * 17
                let point = CGPoint(
                    x: center.x + cos(angle) * distance,
                    y: center.y + sin(angle) * distance
                )
                let sparkleSize = (index % 2 == 0 ? 5.0 : 3.4) * (1 - progress * 0.75)
                let opacity = Double(1 - progress) * 0.95

                var star = Path()
                star.move(to: CGPoint(x: point.x, y: point.y - sparkleSize))
                star.addQuadCurve(
                    to: CGPoint(x: point.x + sparkleSize, y: point.y),
                    control: point
                )
                star.addQuadCurve(
                    to: CGPoint(x: point.x, y: point.y + sparkleSize),
                    control: point
                )
                star.addQuadCurve(
                    to: CGPoint(x: point.x - sparkleSize, y: point.y),
                    control: point
                )
                star.addQuadCurve(
                    to: CGPoint(x: point.x, y: point.y - sparkleSize),
                    control: point
                )

                context.fill(
                    star,
                    with: .color(colors[index % colors.count].opacity(opacity))
                )
            }
        }
        .frame(width: 60, height: 60)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) { progress = 1 }
        }
    }
}