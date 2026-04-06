import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class HistoryViewModel {
    enum Filter: String, CaseIterable, Identifiable {
        case today
        case thisWeek
        case thisMonth
        case customRange

        var id: String { rawValue }

        var title: String {
            switch self {
            case .today:
                return L10n.historyFilterToday
            case .thisWeek:
                return L10n.historyFilterWeek
            case .thisMonth:
                return L10n.historyFilterMonth
            case .customRange:
                return L10n.historyFilterCustom
            }
        }
    }

    var selectedFilter: Filter = .today
    var customStartDate: Date
    var customEndDate: Date
    var exportErrorMessage: String?

    private var modelContext: ModelContext?
    private let calendar = Calendar.current

    private let timeFormatter: DateFormatter

    init() {
        timeFormatter = Self.makeTimeFormatter()
        let startOfToday = calendar.startOfDay(for: Date())
        customStartDate = startOfToday
        customEndDate = startOfToday
    }

    func setModelContext(_ modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func filteredRecords(from records: [TaskRecord]) -> [TaskRecord] {
        let interval = selectedInterval(referenceDate: Date())

        return records
            .filter { interval.contains($0.startedAt) }
            .sorted { $0.startedAt > $1.startedAt }
    }

    func primaryLine(for record: TaskRecord) -> String {
        let start = timeFormatter.string(from: record.startedAt)
        let finish = timeFormatter.string(from: record.finishedAt)
        let taskName = record.wasStopwatch ? "\(record.name)\(L10n.historyStopwatchSuffix)" : record.name
        return String(format: L10n.historyPrimaryFormat, start, finish, taskName)
    }

    func secondaryLine(for record: TaskRecord) -> String {
        let duration = max(Int(record.finishedAt.timeIntervalSince(record.startedAt)), 0)
        let actualMinutes = duration / 60
        let actualSeconds = duration % 60

        return String(
            format: L10n.historySecondaryFormat,
            record.plannedMinutes,
            actualMinutes,
            actualSeconds
        )
    }

    func dateLabelForSelection(referenceDate: Date = Date()) -> String {
        let interval = selectedInterval(referenceDate: referenceDate)
        return makeDateLabel(interval: interval)
    }

    func export(records: [TaskRecord], format: ExportManager.FileFormat) {
        guard !records.isEmpty else {
            return
        }

        do {
            try ExportManager.export(
                records: records,
                format: format,
                dateLabel: dateLabelForSelection()
            )
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    private func selectedInterval(referenceDate: Date) -> DateInterval {
        switch selectedFilter {
        case .today:
            let start = calendar.startOfDay(for: referenceDate)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? referenceDate
            return DateInterval(start: start, end: end)
        case .thisWeek:
            return calendar.dateInterval(of: .weekOfYear, for: referenceDate)
                ?? fallbackTodayInterval(referenceDate: referenceDate)
        case .thisMonth:
            return calendar.dateInterval(of: .month, for: referenceDate)
                ?? fallbackTodayInterval(referenceDate: referenceDate)
        case .customRange:
            let start = calendar.startOfDay(for: min(customStartDate, customEndDate))
            let endDay = calendar.startOfDay(for: max(customStartDate, customEndDate))
            let end = calendar.date(byAdding: .day, value: 1, to: endDay) ?? endDay
            return DateInterval(start: start, end: end)
        }
    }

    private func fallbackTodayInterval(referenceDate: Date) -> DateInterval {
        let start = calendar.startOfDay(for: referenceDate)
        let end = calendar.date(byAdding: .day, value: 1, to: start) ?? referenceDate
        return DateInterval(start: start, end: end)
    }

    private static func makeTimeFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeZone = .current
        formatter.dateFormat = "HH:mm"
        return formatter
    }

    private func makeDateLabel(interval: DateInterval) -> String {
        let start = interval.start
        let endExclusive = interval.end
        let endInclusive = calendar.date(byAdding: .second, value: -1, to: endExclusive) ?? endExclusive

        if calendar.isDate(start, inSameDayAs: endInclusive) {
            return start.formatted(.dateTime.month(.wide).day().year())
        }

        let sameYear = calendar.component(.year, from: start) == calendar.component(.year, from: endInclusive)
        let sameMonth = sameYear && calendar.component(.month, from: start) == calendar.component(.month, from: endInclusive)

        if sameMonth {
            let month = start.formatted(.dateTime.month(.wide))
            let startDay = calendar.component(.day, from: start)
            let endDay = calendar.component(.day, from: endInclusive)
            let year = calendar.component(.year, from: start)
            return "\(month) \(startDay)–\(endDay), \(year)"
        }

        if sameYear {
            let startPart = start.formatted(.dateTime.month(.wide).day())
            let endPart = endInclusive.formatted(.dateTime.month(.wide).day())
            let year = calendar.component(.year, from: start)
            return "\(startPart)–\(endPart), \(year)"
        }

        let startPart = start.formatted(.dateTime.month(.wide).day().year())
        let endPart = endInclusive.formatted(.dateTime.month(.wide).day().year())
        return "\(startPart)–\(endPart)"
    }
}
