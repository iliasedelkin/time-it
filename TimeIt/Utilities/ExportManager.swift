import AppKit
import Foundation
import UniformTypeIdentifiers

@MainActor
enum ExportManager {
    enum FileFormat {
        case txt
        case csv

        var contentType: UTType {
            switch self {
            case .txt:
                return .plainText
            case .csv:
                return .commaSeparatedText
            }
        }

        var fileExtension: String {
            switch self {
            case .txt:
                return "txt"
            case .csv:
                return "csv"
            }
        }
    }

    enum ExportError: LocalizedError {
        case encodingFailed
        case fileWriteFailed

        var errorDescription: String? {
            switch self {
            case .encodingFailed:
                return L10n.exportEncodingError
            case .fileWriteFailed:
                return L10n.exportWriteError
            }
        }
    }

    static func export(records: [TaskRecord], format: FileFormat, dateLabel: String) throws {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.allowedContentTypes = [format.contentType]
        savePanel.nameFieldStringValue = defaultFileName(dateLabel: dateLabel, extension: format.fileExtension)

        guard savePanel.runModal() == .OK, let url = savePanel.url else {
            return
        }

        let data: Data
        switch format {
        case .txt:
            guard let textData = txtContent(records: records, dateLabel: dateLabel).data(using: .utf8) else {
                throw ExportError.encodingFailed
            }
            data = textData
        case .csv:
            guard let csvData = csvContent(records: records).data(using: .utf8) else {
                throw ExportError.encodingFailed
            }
            data = Data([0xEF, 0xBB, 0xBF]) + csvData
        }

        try write(data: data, to: url)
    }

    private static func defaultFileName(dateLabel: String, extension fileExtension: String) -> String {
        let sanitized = dateLabel
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: "–", with: "-")
        return "timeit_\(sanitized).\(fileExtension)"
    }

    private static func txtContent(records: [TaskRecord], dateLabel: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeZone = .current
        formatter.dateFormat = "HH:mm"

        let sortedRecords = records.sorted { $0.startedAt < $1.startedAt }
        let lines = sortedRecords.map { record in
            let start = formatter.string(from: record.startedAt)
            let finish = formatter.string(from: record.finishedAt)
            return String(format: L10n.exportTXTLineFormat, start, finish, record.name)
        }

        let header = String(format: L10n.exportTXTHeaderFormat, dateLabel)
        return ([header] + lines).joined(separator: "\n") + "\n"
    }

    private static func csvContent(records: [TaskRecord]) -> String {
        let formatter = ISO8601DateFormatter()
        let posixLocale = Locale(identifier: "en_US_POSIX")
        let sortedRecords = records.sorted { $0.startedAt < $1.startedAt }

        let header = "id,name,planned_minutes,actual_minutes,started_at,finished_at,was_stopwatch"
        let rows = sortedRecords.map { record -> String in
            let duration = max(Int(record.finishedAt.timeIntervalSince(record.startedAt)), 0)
            let actualMinutes = String(format: "%.2f", locale: posixLocale, Double(duration) / 60.0)
            let id = escaped(record.id.uuidString)
            let name = escaped(record.name)
            let planned = String(record.plannedMinutes)
            let started = escaped(formatter.string(from: record.startedAt))
            let finished = escaped(formatter.string(from: record.finishedAt))
            let wasStopwatch = record.wasStopwatch ? "true" : "false"
            return [id, name, planned, actualMinutes, started, finished, wasStopwatch].joined(separator: ",")
        }

        return ([header] + rows).joined(separator: "\n") + "\n"
    }

    private static func escaped(_ value: String) -> String {
        let escapedQuotes = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escapedQuotes)\""
    }

    private static func write(data: Data, to url: URL) throws {
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }

        let created = fileManager.createFile(atPath: url.path, contents: data)
        if !created {
            throw ExportError.fileWriteFailed
        }
    }
}
