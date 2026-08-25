import SwiftUI

/// Nobody left in the waiting room.
///
/// The celebrating illustrations only ever appear here — keeping them off the rows
/// is what stops them becoming wallpaper. The animal is drawn fresh each time the
/// clinic closes, so it's a small surprise rather than a fixture.
///
/// It arrives in three beats rather than all at once: the animal springs in, the
/// sparkles follow it out, and only then does the sign settle underneath. Cutting
/// straight to the finished state would throw away the one moment the whole widget
/// is building towards.
struct ClinicClosedView: View {

    @State private var animal: Animal = Animal.allCases.randomElement() ?? .cat
    @State private var badge: Color = Clinic.badges.randomElement() ?? Clinic.badges[0]

    @State private var avatarScale: CGFloat = 0
    @State private var burst: CGFloat = 0
    /// Separate from `burst` for the same reason the sleepy "z" splits its two
    /// values: an opacity derived from the travel would start and end at zero, and
    /// SwiftUI would dutifully interpolate invisible to invisible.
    @State private var sparkOpacity: Double = 0
    @State private var signIn = false

    private static let sparkleAngles: [Double] = [-104, -40, 20, 92, 160]

    var body: some View {
        VStack(spacing: 7) {
            ZStack {
                sparkles
                AnimalAvatarView(animal: animal, mood: .celebrating, badge: badge, size: 52, ambient: false)
                    .scaleEffect(avatarScale)
            }

            VStack(spacing: 7) {
                Text("CLINIC CLOSED FOR TODAY")
                    .font(ClinicFont.printed(9.5, .bold))
                    .kerning(1.1)
                    .foregroundColor(Clinic.ink.opacity(0.75))

                Text("all patients went home happy")
                    .font(ClinicFont.display(11, .medium))
                    .foregroundColor(Clinic.inkMuted)
            }
            .opacity(signIn ? 1 : 0)
            .offset(y: signIn ? 0 : 10)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .onAppear(perform: play)
    }

    /// Small marks thrown out from behind the animal. Drawn rather than imported,
    /// so they pick up the palette instead of fighting it.
    private var sparkles: some View {
        ForEach(Array(Self.sparkleAngles.enumerated()), id: \.offset) { index, angle in
            let radians = angle * .pi / 180
            // They start tucked behind the avatar and clear its edge almost at
            // once. Travelling out from dead centre instead would keep them hidden
            // until they had all but faded.
            let distance = 20 + burst * (index.isMultiple(of: 2) ? 36 : 30)
            SparkleShape()
                .fill(index.isMultiple(of: 2) ? Clinic.stamp.opacity(0.7) : Clinic.seenPillInk.opacity(0.65))
                .frame(width: 10, height: 10)
                .rotationEffect(.degrees(angle))
                .scaleEffect(burst == 0 ? 0.3 : 1)
                .offset(x: cos(radians) * distance, y: sin(radians) * distance)
                .opacity(sparkOpacity)
        }
    }

    private func play() {
        animal = Animal.allCases.randomElement() ?? .cat
        badge = Clinic.badges.randomElement() ?? Clinic.badges[0]
        avatarScale = 0
        burst = 0
        sparkOpacity = 0
        signIn = false

        // Beat one: the animal arrives, overshooting before it settles.
        withAnimation(.spring(response: 0.42, dampingFraction: 0.55)) { avatarScale = 1 }

        // Beat two: sparkles chase it outward, holding long enough to be read
        // before they go — about 0.6s from first light to gone.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.62, dampingFraction: 1)) { burst = 1 }
            withAnimation(.easeOut(duration: 0.1)) { sparkOpacity = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.easeOut(duration: 0.42)) { sparkOpacity = 0 }
            }
        }

        // Beat three: the sign slides up underneath.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.34) {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.8)) { signIn = true }
        }
    }
}

/// A four-pointed star with concave sides — the shape a sparkle is, where a plain
/// dot just reads as a stray bit of ink.
struct SparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let arm = min(rect.width, rect.height) / 2
        let waist = arm * 0.24        // how far in the sides pinch

        var path = Path()
        path.move(to: CGPoint(x: center.x, y: center.y - arm))
        path.addQuadCurve(to: CGPoint(x: center.x + arm, y: center.y),
                          control: CGPoint(x: center.x + waist, y: center.y - waist))
        path.addQuadCurve(to: CGPoint(x: center.x, y: center.y + arm),
                          control: CGPoint(x: center.x + waist, y: center.y + waist))
        path.addQuadCurve(to: CGPoint(x: center.x - arm, y: center.y),
                          control: CGPoint(x: center.x - waist, y: center.y + waist))
        path.addQuadCurve(to: CGPoint(x: center.x, y: center.y - arm),
                          control: CGPoint(x: center.x - waist, y: center.y - waist))
        path.closeSubpath()
        return path
    }
}
