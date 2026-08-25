import Foundation
import Combine

/// Owns the day's patient list and the JSON file it lives in.
///
/// Persistence is a single `patients.json` in Application Support. No backend,
/// no account — the file is the whole clinic record.
final class PatientStore: ObservableObject {

    @Published private(set) var patients: [Patient] = []

    /// Guards against re-saving while we're loading.
    private var isLoading = false
    private var midnightTimer: Timer?

    // MARK: Derived counts

    /// The footer tally. Live, because the views read these directly.
    var seenCount: Int { patients.filter(\.isSeen).count }
    var waitingCount: Int { patients.filter { !$0.isSeen }.count }

    /// Nobody left in the waiting room — the clinic can close.
    var isClosed: Bool { waitingCount == 0 }

    // MARK: Lifecycle

    init() {
        load()
        repairLegacySeenTimestamps()
        sendYesterdayHome()
        scheduleMidnightRollover()
    }

    deinit { midnightTimer?.invalidate() }

    // MARK: Mutation

    /// Check in a new patient. Returns false for empty input so the field can
    /// keep the caret rather than clearing it.
    @discardableResult
    func checkIn(_ rawName: String) -> Bool {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return false }
        // Appended, not inserted: the board is a queue in order of arrival.
        patients.append(Patient(name: name))
        save()
        return true
    }

    /// Returns true when the patient went from waiting → seen, which is the
    /// moment that earns the stamp and the sound.
    @discardableResult
    func toggleSeen(_ id: UUID) -> Bool {
        guard let index = patients.firstIndex(where: { $0.id == id }) else { return false }
        let becameSeen = !patients[index].isSeen
        patients[index].isSeen = becameSeen
        patients[index].seenAt = becameSeen ? Date() : nil
        save()
        return becameSeen
    }

    func discharge(_ id: UUID) {
        patients.removeAll { $0.id == id }
        save()
    }

    // MARK: Overnight

    /// Back-fill `seenAt` for patients checked off before that field existed.
    private func repairLegacySeenTimestamps() {
        var changed = false
        for index in patients.indices where patients[index].isSeen && patients[index].seenAt == nil {
            patients[index].seenAt = patients[index].checkedInAt
            changed = true
        }
        if changed { save() }
    }

    /// Patients seen on an earlier day have gone home; the board starts each
    /// morning holding only whoever is still waiting.
    private func sendYesterdayHome() {
        let stale = patients.contains { $0.isSeen && !$0.wasSeenToday }
        guard stale else { return }
        patients.removeAll { $0.isSeen && !$0.wasSeenToday }
        save()
    }

    private func scheduleMidnightRollover() {
        midnightTimer?.invalidate()
        guard let nextMidnight = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0, second: 5),
            matchingPolicy: .nextTime
        ) else { return }

        let timer = Timer(fire: nextMidnight, interval: 0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.sendYesterdayHome()
                self.objectWillChange.send()   // redraw the date line too
                self.scheduleMidnightRollover()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        midnightTimer = timer
    }

    // MARK: Persistence

    private static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("LittleVetClinic", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("patients.json")
    }

    func save() {
        guard !isLoading else { return }
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            try encoder.encode(patients).write(to: Self.fileURL, options: .atomic)
        } catch {
            NSLog("Little Vet Clinic: could not save the patient list — \(error.localizedDescription)")
        }
    }

    private func load() {
        isLoading = true
        defer { isLoading = false }
        guard let data = try? Data(contentsOf: Self.fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        patients = (try? decoder.decode([Patient].self, from: data)) ?? []
    }
}
