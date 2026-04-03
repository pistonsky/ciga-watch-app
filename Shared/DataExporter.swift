import Foundation
import SwiftData

struct CigaExport: Codable {
    let version: Int
    let exportDate: Date
    let records: [Record]

    struct Record: Codable {
        let smokeDate: Date
        let n: Int
        let kind: String
        let endAt: Date?
        let intensity: Int?
    }
}

enum DataExporter {
    static func createExportData(from inhales: [Inhale]) throws -> Data {
        let records = inhales
            .sorted { $0.smokeDate < $1.smokeDate }
            .map { inhale in
                CigaExport.Record(
                    smokeDate: inhale.smokeDate,
                    n: inhale.n,
                    kind: inhale.kind,
                    endAt: inhale.endAt,
                    intensity: inhale.intensity
                )
            }

        let export = CigaExport(
            version: 1,
            exportDate: Date(),
            records: records
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(export)
    }

    static func writeToTemporaryFile(_ data: Data) throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let fileName = "ciga-export-\(timestamp).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: url)
        return url
    }

    // MARK: - Import

    /// Parses a JSON export file and inserts new (non-duplicate) records into the given context.
    /// Returns the number of newly imported records.
    @MainActor
    static func importRecords(from data: Data, into context: ModelContext) throws -> Int {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let export = try decoder.decode(CigaExport.self, from: data)

        let descriptor = FetchDescriptor<Inhale>(sortBy: [SortDescriptor(\.smokeDate)])
        let existing = try context.fetch(descriptor)

        var importedCount = 0

        for record in export.records {
            let isDuplicate = existing.contains { inhale in
                abs(inhale.smokeDate.timeIntervalSince1970 - record.smokeDate.timeIntervalSince1970) < 0.001 &&
                inhale.n == record.n &&
                inhale.kind == record.kind &&
                datesMatch(inhale.endAt, record.endAt) &&
                inhale.intensity == record.intensity
            }

            guard !isDuplicate else { continue }
            guard let kind = Inhale.Kind(rawValue: record.kind) else { continue }

            let inhale = Inhale(
                smokeDate: record.smokeDate,
                n: record.n,
                kind: kind,
                endAt: record.endAt,
                intensity: record.intensity,
                syncSharedState: false
            )
            context.insert(inhale)
            importedCount += 1
        }

        return importedCount
    }

    private static func datesMatch(_ lhs: Date?, _ rhs: Date?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil): return true
        case let (left?, right?): return abs(left.timeIntervalSince1970 - right.timeIntervalSince1970) < 0.001
        default: return false
        }
    }
}
