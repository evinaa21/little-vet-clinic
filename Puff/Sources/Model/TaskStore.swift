import Foundation
import Combine

/// Owns the list, the streak, and the JSON file they live in.
///
/// Persistence is a single `tasks.json` inside Application Support. No backend,
/// no login, nothing to sign in to — the file is the whole database.
final class TaskStore: ObservableObject {

    @Published private(set) var items: [TodoItem] = []
    @Published private(set) var streak: Int = 0

    /// The last day on which every task was checked off. Drives streak continuity.
    private var lastStreakDay: Date?
    /// Guards against re-saving while we're loading.
    private var isLoading = false
    private var midnightTimer: Timer?

    // MARK: Derived slices

    /// Still to do, in user-defined order.
    var openItems: [TodoItem] { items.filter { !$0.isDone } }

    /// Checked off today — collapsed under "done today", never deleted.
    var doneTodayItems: [TodoItem] {
        items.filter(\.isDoneToday)
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    /// True when there is at least one task and all of them are checked.
    var allClear: Bool { !items.isEmpty && items.allSatisfy(\.isDone) }

    var isEmpty: Bool { items.isEmpty }

    // MARK: Lifecycle

    init() {
        load()
        rollOverIfNeeded()
        scheduleMidnightRollover()
    }

    deinit { midnightTimer?.invalidate() }

    // MARK: Mutation

    @discardableResult
    func add(_ rawTitle: String) -> Bool {
        let title = rawTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return false }
        // New tasks land at the top of the open list, which is where the eye is.
        items.insert(TodoItem(title: title), at: 0)
        save()
        return true
    }

    /// Returns true when the task went from open → done (the moment worth celebrating).
    @discardableResult
    func toggle(_ id: UUID) -> Bool {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return false }
        let becameDone = !items[index].isDone
        items[index].isDone = becameDone
        items[index].completedAt = becameDone ? Date() : nil
        evaluateStreak()
        save()
        return becameDone
    }

    func delete(_ id: UUID) {
        items.removeAll { $0.id == id }
        evaluateStreak()
        save()
    }

    func rename(_ id: UUID, to newTitle: String) {
        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].title = title
        save()
    }

    /// Move within the *open* list; done items keep their own ordering.
    func move(id: UUID, before targetID: UUID) {
        guard id != targetID,
              let from = items.firstIndex(where: { $0.id == id }),
              let to = items.firstIndex(where: { $0.id == targetID }) else { return }
        let moved = items.remove(at: from)
        items.insert(moved, at: to)
    }

    func clearDoneToday() {
        items.removeAll(where: \.isDoneToday)
        save()
    }

    // MARK: Streak

    private func evaluateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        guard allClear else { return }
        guard lastStreakDay != today else { return }

        if let last = lastStreakDay,
           let gap = Calendar.current.dateComponents([.day], from: last, to: today).day,
           gap == 1 {
            streak += 1
        } else {
            streak = 1
        }
        lastStreakDay = today
    }

    /// At midnight: yesterday's finished tasks retire out of the list, and a day
    /// that ended without a clean sweep breaks the streak.
    private func rollOverIfNeeded() {
        let today = Calendar.current.startOfDay(for: Date())

        let stale = items.filter { $0.isDone && !$0.isDoneToday }
        if !stale.isEmpty {
            items.removeAll { $0.isDone && !$0.isDoneToday }
        }

        if let last = lastStreakDay,
           let gap = Calendar.current.dateComponents([.day], from: last, to: today).day,
           gap > 1 {
            streak = 0
        }

        if !stale.isEmpty { save() }
    }

    private func scheduleMidnightRollover() {
        midnightTimer?.invalidate()
        let calendar = Calendar.current
        guard let nextMidnight = calendar.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 0, second: 5),
            matchingPolicy: .nextTime
        ) else { return }

        let timer = Timer(fire: nextMidnight, interval: 0, repeats: false) { [weak self] _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.rollOverIfNeeded()
                self.objectWillChange.send()
                self.scheduleMidnightRollover()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        midnightTimer = timer
    }

    // MARK: Persistence

    private struct Payload: Codable {
        var items: [TodoItem]
        var streak: Int
        var lastStreakDay: Date?
    }

    private static var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let folder = base.appendingPathComponent("Puff", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("tasks.json")
    }

    func save() {
        guard !isLoading else { return }
        let payload = Payload(items: items, streak: streak, lastStreakDay: lastStreakDay)
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(payload)
            try data.write(to: Self.fileURL, options: .atomic)
        } catch {
            NSLog("Puff: could not save tasks — \(error.localizedDescription)")
        }
    }

    private func load() {
        isLoading = true
        defer { isLoading = false }
        guard let data = try? Data(contentsOf: Self.fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let payload = try? decoder.decode(Payload.self, from: data) else { return }
        items = payload.items
        streak = payload.streak
        lastStreakDay = payload.lastStreakDay
    }
}