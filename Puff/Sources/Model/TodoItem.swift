import Foundation

struct TodoItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var isDone: Bool = false
    var createdAt: Date = Date()
    var completedAt: Date?

    var isDoneToday: Bool {
        guard isDone, let completedAt else { return false }
        return Calendar.current.isDateInToday(completedAt)
    }
}