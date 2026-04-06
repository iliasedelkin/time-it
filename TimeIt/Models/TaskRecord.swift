import Foundation
import SwiftData

@Model
final class TaskRecord {
    var id: UUID
    var name: String
    var plannedMinutes: Int
    var startedAt: Date
    var finishedAt: Date
    var wasStopwatch: Bool

    init(
        id: UUID = UUID(),
        name: String,
        plannedMinutes: Int,
        startedAt: Date,
        finishedAt: Date,
        wasStopwatch: Bool
    ) {
        self.id = id
        self.name = name
        self.plannedMinutes = plannedMinutes
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.wasStopwatch = wasStopwatch
    }
}
