import AppKit

/// The clinic's two sounds.
///
/// `stamp` is a single sharp event on check-off. `unroll` is the quiet motor whirr
/// while the sheet feeds out, ending in its own settle-thud. They're deliberately
/// an octave apart and shaped differently so neither can be mistaken for the other.
final class SoundPlayer {

    static let shared = SoundPlayer()

    /// Three alternating voices for the stamp, so working down the board quickly
    /// doesn't cut each thud off halfway.
    private var stampVoices: [NSSound] = []
    private var nextStamp = 0
    private var unroll: NSSound?

    private init() {
        stampVoices = (0..<3).compactMap { _ in load("stamp", volume: 0.55) }
        unroll = load("unroll", volume: 0.34)
    }

    private func load(_ name: String, volume: Float) -> NSSound? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "wav") else {
            NSLog("Little Vet Clinic: \(name).wav missing from the bundle.")
            return nil
        }
        let sound = NSSound(contentsOf: url, byReference: false)
        sound?.volume = volume
        return sound
    }

    func playStamp() {
        guard !stampVoices.isEmpty else { return }
        let sound = stampVoices[nextStamp % stampVoices.count]
        nextStamp += 1
        if sound.isPlaying { sound.stop() }
        sound.play()
    }

    func playUnroll() {
        guard let unroll else { return }
        if unroll.isPlaying { unroll.stop() }
        unroll.play()
    }

    /// Closing the panel mid-feed shouldn't leave the motor running.
    func stopUnroll() {
        if unroll?.isPlaying == true { unroll?.stop() }
    }
}
