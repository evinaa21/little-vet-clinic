import SwiftUI
import Combine

/// Everything the app remembers that isn't a patient: one toggle and the panel's
/// position. Backed by UserDefaults so both survive a relaunch.
final class AppSettings: ObservableObject {

    @Published var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Keys.sound) }
    }

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let sound  = "clinic.soundEnabled"
        static let origin = "clinic.panelOrigin"
    }

    init() {
        soundEnabled = defaults.object(forKey: Keys.sound) as? Bool ?? true
    }

    /// Bottom-left origin of the floating panel, remembered between launches.
    var panelOrigin: CGPoint? {
        get {
            guard let dict = defaults.dictionary(forKey: Keys.origin),
                  let x = dict["x"] as? Double, let y = dict["y"] as? Double else { return nil }
            return CGPoint(x: x, y: y)
        }
        set {
            guard let newValue else { return }
            defaults.set(["x": newValue.x, "y": newValue.y], forKey: Keys.origin)
        }
    }
}
