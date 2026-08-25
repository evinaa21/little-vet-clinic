import SwiftUI

/// A patient's face on its pastel disc.
///
/// The disc is a plain SwiftUI `Circle`, deliberately *not* part of the artwork.
/// Nine separately generated illustrations would never agree on a shade or a
/// margin; drawing the badge in code means every row matches exactly, and the
/// colour can cycle independently of which animal happens to be in it.
///
/// Three things move here, and they're layered so they can't fight each other:
/// a slow breath while the patient waits, a "z" that drifts off every few seconds,
/// and a hop at the moment the mood swaps.
struct AnimalAvatarView: View {
    let animal: Animal
    let mood: Mood
    let badge: Color
    var size: CGFloat = Metrics.avatarSize
    /// The closed-clinic screen runs its own entrance, so it opts out of the
    /// ambient waiting-room behaviour.
    var ambient: Bool = true

    @State private var breathing = false
    @State private var hop: CGFloat = 1
    /// How far through its drift the "z" is, 0 → 1.
    @State private var zDrift: CGFloat = 0
    /// Held separately from `zDrift` on purpose. A single value can't drive both,
    /// because opacity would have to start and end at zero — and SwiftUI
    /// interpolates between the endpoints, so the glyph would animate from
    /// invisible to invisible and never appear at all.
    @State private var zOpacity: Double = 0

    private var isWaiting: Bool { mood == .waiting }

    var body: some View {
        ZStack {
            Circle().fill(badge)

            Image(animal.assetName(mood))
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .padding(size * 0.07)
                .id(mood)                        // a mood change is a real swap…
                .transition(.opacity)            // …so cross-fade rather than pop
        }
        .frame(width: size, height: size)
        .overlay(Circle().strokeBorder(Color.white.opacity(0.65), lineWidth: 1))
        .animation(.easeInOut(duration: 0.22), value: mood)
        // Breath first, then hop: two independent scales that compose cleanly
        // instead of one value trying to carry both.
        .scaleEffect(breathing ? 1.02 : 1)
        .scaleEffect(hop)
        .overlay(alignment: .topTrailing) { sleepyZ }
        .onChange(of: mood) { newMood in
            reactToMoodChange(newMood)
        }
        .onAppear { if ambient && isWaiting { startBreathing() } }
        .task(id: taskKey) { await driftZs() }
        .accessibilityLabel("\(animal.rawValue), \(mood.rawValue)")
    }

    // MARK: The sleepy z

    /// Not new art — just a glyph, drifting up and out from behind the ear. It's
    /// what turns "waiting" from a status word into a patient dozing off.
    @ViewBuilder
    private var sleepyZ: some View {
        if ambient && isWaiting {
            Text("z")
                .font(ClinicFont.display(size * 0.34, .bold))
                .foregroundColor(Clinic.inkMuted)
                .opacity(zOpacity)
                .offset(
                    x: size * 0.12 + zDrift * (size * 0.34),
                    y: -size * 0.06 - zDrift * (size * 0.62)
                )
                .scaleEffect(0.75 + zDrift * 0.45)
                .allowsHitTesting(false)
        }
    }

    /// Restarts the drift loop when a patient stops waiting (or starts again).
    private var taskKey: String { "\(mood.rawValue)-\(ambient)" }

    private func driftZs() async {
        guard ambient, isWaiting else { return }

        // A random opening delay, so a board full of waiting patients doesn't
        // breathe out in unison like a chorus line.
        try? await Task.sleep(nanoseconds: UInt64.random(in: 1_500_000_000...6_500_000_000))

        var instant = Transaction()
        instant.disablesAnimations = true

        while !Task.isCancelled {
            // Back to the start, unseen, before anything moves.
            withTransaction(instant) { zDrift = 0; zOpacity = 0 }
            try? await Task.sleep(nanoseconds: 20_000_000)   // let that frame land
            guard !Task.isCancelled else { return }

            withAnimation(.spring(response: 1.35, dampingFraction: 1)) { zDrift = 1 }
            withAnimation(.easeOut(duration: 0.2)) { zOpacity = 0.85 }

            try? await Task.sleep(nanoseconds: 700_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.7)) { zOpacity = 0 }

            try? await Task.sleep(nanoseconds: 800_000_000)
            guard !Task.isCancelled else { return }
            try? await Task.sleep(nanoseconds: UInt64.random(in: 6_000_000_000...8_000_000_000))
        }
    }

    // MARK: Breath and hop

    private func startBreathing() {
        withAnimation(.spring(response: 1.9, dampingFraction: 0.95).repeatForever(autoreverses: true)) {
            breathing = true
        }
    }

    private func reactToMoodChange(_ newMood: Mood) {
        // A repeatForever animation keeps running until something replaces it, so
        // the breath is explicitly stood down rather than just left behind.
        withAnimation(.easeOut(duration: 0.2)) { breathing = false }
        if ambient && newMood == .waiting {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                if mood == .waiting { startBreathing() }
            }
        }

        guard ambient else { return }

        // Timed to land as the crossfade finishes, so the animal is seen reacting
        // rather than having quietly become a different picture.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) { hop = 1.15 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) { hop = 1 }
            }
        }
    }
}
