import SwiftUI

enum MascotState: Equatable {
    /// The default: slow breathing plus an occasional blink.
    case idle
    /// A task just got checked — eyes squeeze into happy arcs, cheeks flush.
    case happy
    /// Nothing on the list, so the little guy dozes off.
    case sleepy
}

/// The header mascot. Everything is drawn with shapes and paths — no image assets,
/// so it stays crisp at any size and re-tints instantly with the theme.
struct MascotView: View {
    let mascot: Mascot
    let state: MascotState
    let theme: Theme
    var size: CGFloat = 36

    @State private var blinking = false
    @State private var breathing = false
    @State private var snoozeOffset = false

    private let blinkTimer = Timer.publish(every: 3.1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            switch mascot {
            case .capybara: capybara
            case .cat:      cat
            case .blob:     blob
            }

            if state == .sleepy {
                zzz
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(breathing ? 1.035 : 0.975, anchor: .bottom)
        .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: breathing)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: state)
        .onAppear { breathing = true; snoozeOffset = true }
        .onReceive(blinkTimer) { _ in blinkOnce() }
    }

    private func blinkOnce() {
        guard state == .idle else { return }
        withAnimation(.easeInOut(duration: 0.07)) { blinking = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) {
            withAnimation(.easeInOut(duration: 0.09)) { blinking = false }
        }
    }

    // MARK: - Capybara

    private var capybara: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let fur = Color(hex: 0xC1936B)
            let furDark = Color(hex: 0xA57A55)
            let muzzle = Color(hex: 0xDDBB96)

            ZStack {
                // ears
                Circle().fill(furDark)
                    .frame(width: w * 0.22, height: w * 0.22)
                    .offset(x: -w * 0.30, y: -h * 0.30)
                Circle().fill(furDark)
                    .frame(width: w * 0.22, height: w * 0.22)
                    .offset(x: w * 0.30, y: -h * 0.30)

                // head: capybaras are gloriously rectangular
                RoundedRectangle(cornerRadius: w * 0.30, style: .continuous)
                    .fill(fur)
                    .frame(width: w * 0.86, height: h * 0.74)
                    .offset(y: h * 0.02)

                // blunt muzzle
                RoundedRectangle(cornerRadius: w * 0.16, style: .continuous)
                    .fill(muzzle)
                    .frame(width: w * 0.44, height: h * 0.26)
                    .offset(y: h * 0.20)

                // nostrils
                HStack(spacing: w * 0.10) {
                    Capsule().fill(furDark.opacity(0.8)).frame(width: w * 0.05, height: h * 0.035)
                    Capsule().fill(furDark.opacity(0.8)).frame(width: w * 0.05, height: h * 0.035)
                }
                .offset(y: h * 0.15)

                eyes(width: w, height: h, spacing: w * 0.34, eyeWidth: w * 0.10, yOffset: -h * 0.06,
                     color: Color(hex: 0x4A3527))

                cheeks(width: w, height: h, spacing: w * 0.62, yOffset: h * 0.06)
            }
        }
    }

    // MARK: - Cat

    private var cat: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let fur = theme.wash
            let outline = theme.ink.opacity(0.75)

            ZStack {
                // ears
                Triangle()
                    .fill(fur)
                    .frame(width: w * 0.30, height: h * 0.30)
                    .offset(x: -w * 0.26, y: -h * 0.32)
                Triangle()
                    .fill(theme.accent.opacity(0.5))
                    .frame(width: w * 0.15, height: h * 0.16)
                    .offset(x: -w * 0.26, y: -h * 0.26)
                Triangle()
                    .fill(fur)
                    .frame(width: w * 0.30, height: h * 0.30)
                    .offset(x: w * 0.26, y: -h * 0.32)
                Triangle()
                    .fill(theme.accent.opacity(0.5))
                    .frame(width: w * 0.15, height: h * 0.16)
                    .offset(x: w * 0.26, y: -h * 0.26)

                // head
                Circle()
                    .fill(fur)
                    .frame(width: w * 0.82, height: w * 0.82)
                    .offset(y: h * 0.04)

                // whiskers
                ForEach(0..<2) { side in
                    let sign: CGFloat = side == 0 ? -1 : 1
                    ForEach(0..<2) { row in
                        Capsule()
                            .fill(outline.opacity(0.35))
                            .frame(width: w * 0.20, height: 1.2)
                            .rotationEffect(.degrees(Double(sign) * (row == 0 ? -8 : 8)))
                            .offset(x: sign * w * 0.40, y: h * (row == 0 ? 0.10 : 0.17))
                    }
                }

                // nose
                Triangle()
                    .fill(theme.accent)
                    .rotationEffect(.degrees(180))
                    .frame(width: w * 0.10, height: h * 0.07)
                    .offset(y: h * 0.13)

                eyes(width: w, height: h, spacing: w * 0.32, eyeWidth: w * 0.11, yOffset: -h * 0.01,
                     color: outline)

                cheeks(width: w, height: h, spacing: w * 0.58, yOffset: h * 0.12)
            }
        }
    }

    // MARK: - Blob

    private var blob: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                RoundedRectangle(cornerRadius: w * 0.42, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [theme.wash, theme.accent.opacity(0.75)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: w * 0.88, height: h * 0.80)
                    .rotationEffect(.degrees(breathing ? 3 : -3))
                    .animation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true), value: breathing)

                // glossy highlight, so it reads as squishy rather than flat
                Ellipse()
                    .fill(Color.white.opacity(0.55))
                    .frame(width: w * 0.22, height: h * 0.12)
                    .rotationEffect(.degrees(-20))
                    .offset(x: -w * 0.18, y: -h * 0.22)

                eyes(width: w, height: h, spacing: w * 0.30, eyeWidth: w * 0.11, yOffset: h * 0.02,
                     color: theme.ink)

                cheeks(width: w, height: h, spacing: w * 0.52, yOffset: h * 0.16)

                // a small mouth completes the face
                if state == .happy {
                    Arc(up: false)
                        .stroke(theme.ink.opacity(0.7), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                        .frame(width: w * 0.20, height: h * 0.09)
                        .offset(y: h * 0.20)
                }
            }
        }
    }

    // MARK: - Shared face parts

    @ViewBuilder
    private func eyes(width w: CGFloat, height h: CGFloat, spacing: CGFloat,
                      eyeWidth: CGFloat, yOffset: CGFloat, color: Color) -> some View {
        HStack(spacing: spacing - eyeWidth) {
            eye(eyeWidth: eyeWidth, height: h, color: color)
            eye(eyeWidth: eyeWidth, height: h, color: color)
        }
        .offset(y: yOffset)
    }

    @ViewBuilder
    private func eye(eyeWidth: CGFloat, height h: CGFloat, color: Color) -> some View {
        switch state {
        case .idle:
            Ellipse()
                .fill(color)
                .frame(width: eyeWidth, height: eyeWidth * 1.25)
                .scaleEffect(y: blinking ? 0.10 : 1, anchor: .center)
        case .happy:
            // ^ ^ — a squint of pure satisfaction
            Arc(up: true)
                .stroke(color, style: StrokeStyle(lineWidth: eyeWidth * 0.36, lineCap: .round))
                .frame(width: eyeWidth * 1.35, height: eyeWidth * 0.85)
        case .sleepy:
            // gently closed lids
            Arc(up: false)
                .stroke(color.opacity(0.8), style: StrokeStyle(lineWidth: eyeWidth * 0.32, lineCap: .round))
                .frame(width: eyeWidth * 1.3, height: eyeWidth * 0.6)
        }
    }

    @ViewBuilder
    private func cheeks(width w: CGFloat, height h: CGFloat, spacing: CGFloat, yOffset: CGFloat) -> some View {
        if state == .happy {
            HStack(spacing: spacing) {
                Ellipse().fill(Color(hex: 0xFF9EC4).opacity(0.55))
                    .frame(width: w * 0.13, height: h * 0.07)
                Ellipse().fill(Color(hex: 0xFF9EC4).opacity(0.55))
                    .frame(width: w * 0.13, height: h * 0.07)
            }
            .offset(y: yOffset)
            .transition(.scale.combined(with: .opacity))
        }
    }

    private var zzz: some View {
        VStack(spacing: 1) {
            Text("z")
                .font(Font2.rounded(size * 0.24, .bold))
                .opacity(snoozeOffset ? 0.15 : 0.75)
                .offset(y: snoozeOffset ? -4 : 0)
            Text("z")
                .font(Font2.rounded(size * 0.18, .bold))
                .opacity(snoozeOffset ? 0.4 : 0.9)
        }
        .foregroundColor(theme.ink.opacity(0.6))
        .offset(x: size * 0.46, y: -size * 0.34)
        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: snoozeOffset)
    }
}

// MARK: - Little shapes

/// An arc that bulges up (`^`) or down (`︶`), used for eyes and mouths.
struct Arc: Shape {
    var up: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if up {
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.maxY),
                control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.5)
            )
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.minY),
                control: CGPoint(x: rect.midX, y: rect.maxY + rect.height * 0.5)
            )
        }
        return path
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}