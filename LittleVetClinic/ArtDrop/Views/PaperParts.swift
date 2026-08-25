import SwiftUI

// MARK: - The sheet itself

/// The printed sheet: gently rounded at the top where the clip holds it, and torn
/// off along a perforated line at the bottom. The teeth are part of the window's
/// silhouette, not a drawing on top of it, because the panel behind is transparent.
struct TornSheet: Shape {
    var topRadius: CGFloat = 3

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let depth = Metrics.tearDepth
        let baseline = rect.maxY - depth
        let radius = min(topRadius, rect.width / 2)

        path.move(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + radius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: baseline))

        // Walk the perforation right to left, alternating between the valley line
        // and the full height, so the edge ends up with even little teeth.
        var x = rect.maxX
        var atTooth = true
        while x > rect.minX {
            let nextX = max(rect.minX, x - Metrics.tearWidth / 2)
            path.addLine(to: CGPoint(x: nextX, y: atTooth ? rect.maxY : baseline))
            atTooth.toggle()
            x = nextX
        }

        path.addLine(to: CGPoint(x: rect.minX, y: baseline))
        path.closeSubpath()
        return path
    }
}

// MARK: - The feed

/// The window onto the sheet while it unrolls: a rectangle that grows downward
/// from the top edge as `reveal` runs 0 → 1.
///
/// This is a `Shape` with real `animatableData` rather than a scaled rectangle
/// because a mask driven by `scaleEffect` rasterises the whole sheet through a
/// transformed layer, and small text — the tally lines, the key cap — drops out of
/// the composite entirely. Animating the path keeps the mask a plain path and the
/// text draws normally.
struct UnrollMask: Shape {
    var reveal: CGFloat

    var animatableData: CGFloat {
        get { reveal }
        set { reveal = newValue }
    }

    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: rect.minX, y: rect.minY,
                    width: rect.width,
                    height: max(0, rect.height * reveal)))
    }
}

// MARK: - Rules

/// The dashed separator that runs between blocks of a printed form.
struct DashedRule: View {
    var body: some View {
        Rule()
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [2.5, 3]))
            .foregroundColor(Clinic.rule)
            .frame(height: 1)
    }

    private struct Rule: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return path
        }
    }
}

/// Two solid hairlines — the "everything above this is itemised" rule that sits
/// over a subtotal.
struct DoubleRule: View {
    var body: some View {
        VStack(spacing: 2) {
            Rectangle().fill(Clinic.rule).frame(height: 1)
            Rectangle().fill(Clinic.rule).frame(height: 1)
        }
    }
}

// MARK: - The clip

/// The sage clip pinching the top of the sheet.
///
/// Drawn as a physical object rather than a title bar: a gradient body with a
/// darker lip along its bottom edge where it grips the paper, a rivet near each
/// end, and a shadow cast down onto the sheet. `pinch` squashes it vertically for
/// the clamp it does the instant the paper finishes feeding out.
struct ClipGraphic: View {
    var pinch: CGFloat = 1

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Clinic.clipTop, Clinic.clipBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // The gripping lip, darker and only along the bottom third.
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.clear, .clear, Clinic.clipLip.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // A highlight along the top edge, so it reads as moulded.
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.55), Color.white.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )

            HStack {
                rivet
                Spacer()
                rivet
            }
            .padding(.horizontal, 9)
        }
        .frame(width: Metrics.clipWidth, height: Metrics.clipHeight)
        .scaleEffect(x: 1, y: pinch, anchor: .center)
        .shadow(color: Color.black.opacity(0.22), radius: 3, x: 0, y: 2)
    }

    private var rivet: some View {
        Circle()
            .fill(Clinic.clipRivet)
            .frame(width: 4.5, height: 4.5)
            .overlay(Circle().strokeBorder(Clinic.clipRivetEdge.opacity(0.6), lineWidth: 0.6))
    }
}

// MARK: - Key cap

/// The shortcut hint, dressed as a physical key rather than left as grey text —
/// the one thing on the sheet that otherwise read as UI instead of object.
struct KeyCapView: View {
    let label: String

    var body: some View {
        Text(label)
            .font(ClinicFont.printed(7.5, .semibold))
            .kerning(0.6)
            .foregroundColor(Clinic.inkMuted)
            .padding(.horizontal, 6)
            .padding(.vertical, 2.5)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Clinic.keyCapFace)
                    // A dark wash at the top and a light one at the bottom reads as
                    // a dish pressed into the cap.
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Clinic.keyCapEdge.opacity(0.55), .clear, Color.white.opacity(0.5)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .strokeBorder(Clinic.keyCapEdge, lineWidth: 0.8)
            )
    }
}
