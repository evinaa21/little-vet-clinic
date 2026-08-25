import Foundation

/// The three patients the clinic can admit. Each one ships with three
/// illustrated moods in the asset catalog.
enum Animal: String, Codable, CaseIterable {
    case dog
    case cat
    case bunny
}

/// Which illustration of an animal to show.
///
/// `waiting` and `seen` are the two per-row states; `celebrating` is reserved for
/// the closed-clinic screen so it stays a treat rather than a decoration.
enum Mood: String {
    case waiting
    case seen
    case celebrating
}

extension Animal {
    /// Matches the asset catalog names under `AnimalFaces` — `dog_waiting`, etc.
    func assetName(_ mood: Mood) -> String { "\(rawValue)_\(mood.rawValue)" }
}

/// One task, admitted as a patient.
///
/// The animal is decided once, when the patient is checked in, and never changes
/// again — including on check-off. A row should feel like a specific patient you
/// recognise, not an icon that gets reshuffled.
struct Patient: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var animal: Animal
    var isSeen: Bool = false
    var checkedInAt: Date = Date()
    var seenAt: Date?

    init(name: String, animal: Animal = Animal.allCases.randomElement() ?? .cat) {
        self.name = name
        self.animal = animal
    }

    /// The illustration this row should be showing right now.
    var mood: Mood { isSeen ? .seen : .waiting }

    /// Seen *today* — yesterday's finished patients go home overnight.
    var wasSeenToday: Bool {
        guard isSeen, let seenAt else { return false }
        return Calendar.current.isDateInToday(seenAt)
    }
}
