import AppKit

/// Plays the bundled `pop.wav` on task completion.
///
/// Two alternating `NSSound` instances so rapid-fire checking doesn't cut the
/// previous pop off mid-bloop.
final class SoundPlayer {

    static let shared = SoundPlayer()

    private var voices: [NSSound] = []
    private var next = 0

    private init() {
        guard let url = Bundle.main.url(forResource: "pop", withExtension: "wav") else {
            NSLog("Puff: pop.wav missing from the bundle.")
            return
        }
        voices = (0..<3).compactMap { _ in
            let sound = NSSound(contentsOf: url, byReference: false)
            sound?.volume = 0.5
            return sound
        }
    }

    func playPop() {
        guard !voices.isEmpty else { return }
        let sound = voices[next % voices.count]
        next += 1
        if sound.isPlaying { sound.stop() }
        sound.play()
    }
}