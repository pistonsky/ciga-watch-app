import Foundation
import WatchConnectivity
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.pistonsky.Ciga", category: "WatchConnectivity")

final class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()
    var modelContainer: ModelContainer?

    @Published var importedRecordCount: Int?

    private var recentSyncIDs = Set<String>()
    private var pendingPayloads: [[String: Any]] = []

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Outgoing Events

    func sendStartHookah(date: Date) {
        let uuid = UUID().uuidString
        let payload: [String: Any] = [
            "action": "startHookah",
            "uuid": uuid,
            "date": date.timeIntervalSince1970
        ]
        recentSyncIDs.insert(uuid)
        sendPayload(payload)
        updateSessionContext(activeHookahStartDate: date)
    }

    func sendEndHookah(date: Date, intensity: Int) {
        let uuid = UUID().uuidString
        let payload: [String: Any] = [
            "action": "endHookah",
            "uuid": uuid,
            "date": date.timeIntervalSince1970,
            "intensity": intensity
        ]
        recentSyncIDs.insert(uuid)
        sendPayload(payload)
        updateSessionContext(activeHookahStartDate: nil)
    }

    func sendLogInhale(date: Date, n: Int) {
        let uuid = UUID().uuidString
        let payload: [String: Any] = [
            "action": "logInhale",
            "uuid": uuid,
            "date": date.timeIntervalSince1970,
            "n": n
        ]
        recentSyncIDs.insert(uuid)
        sendPayload(payload)
    }

    /// Pushes the current hookah session state so the iPhone can read it
    /// immediately when its WCSession activates.
    func updateSessionContext(activeHookahStartDate: Date?) {
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        var context: [String: Any] = ["hasActiveHookah": activeHookahStartDate != nil]
        if let start = activeHookahStartDate {
            context["hookahStartDate"] = start.timeIntervalSince1970
        }
        do {
            try session.updateApplicationContext(context)
            logger.info("Application context updated: hasActiveHookah=\(activeHookahStartDate != nil)")
        } catch {
            logger.error("Failed to update application context: \(error.localizedDescription)")
        }
    }

    /// Syncs the current session state from the local SwiftData store.
    /// Call on activation to ensure the iPhone has the latest state.
    @MainActor
    func syncCurrentState() {
        guard let context = modelContainer?.mainContext else { return }
        let descriptor = FetchDescriptor<Inhale>()
        if let inhales = try? context.fetch(descriptor),
           let active = inhales.first(where: { $0.isActiveHookahSession }) {
            updateSessionContext(activeHookahStartDate: active.smokeDate)
        } else {
            updateSessionContext(activeHookahStartDate: nil)
        }
    }

    @MainActor
    func sendFullHistorySnapshot() {
        guard let context = modelContainer?.mainContext else { return }

        let descriptor = FetchDescriptor<Inhale>(sortBy: [SortDescriptor(\.smokeDate)])
        let inhales = (try? context.fetch(descriptor)) ?? []
        let snapshots = inhales.map(makeSnapshot)
        let chunkSize = 50

        guard !snapshots.isEmpty else {
            sendPayload(["action": "historySyncComplete", "count": 0])
            logger.info("Sent empty history snapshot")
            return
        }

        for start in stride(from: 0, to: snapshots.count, by: chunkSize) {
            let end = min(start + chunkSize, snapshots.count)
            let batch = Array(snapshots[start..<end])
            sendPayload([
                "action": "historyBatch",
                "items": batch,
            ])
        }

        sendPayload([
            "action": "historySyncComplete",
            "count": snapshots.count,
        ])
        logger.info("Sent full history snapshot with \(snapshots.count) records")
    }

    // MARK: - File Transfer

    func requestImportFromiPhone() {
        sendPayload(["action": "requestExportFile"])
        logger.info("Requested export file from iPhone for import")
    }

    func sendExportFile(url: URL) {
        let session = WCSession.default
        guard session.activationState == .activated else {
            logger.error("Cannot send export file: WCSession not activated")
            return
        }
        session.transferFile(url, metadata: ["type": "cigaExport"])
        logger.info("Export file transfer queued: \(url.lastPathComponent)")
    }

    // MARK: - Transport

    private func sendPayload(_ payload: [String: Any]) {
        let session = WCSession.default
        guard session.activationState == .activated else {
            logger.info("Session not activated yet, queuing payload")
            pendingPayloads.append(payload)
            return
        }
        doSend(payload, via: session)
    }

    private func doSend(_ payload: [String: Any], via session: WCSession) {
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { error in
                logger.error("sendMessage failed: \(error.localizedDescription)")
            }
        }
        session.transferUserInfo(payload)
    }

    private func flushPendingPayloads() {
        guard !pendingPayloads.isEmpty else { return }
        let session = WCSession.default
        let payloads = pendingPayloads
        pendingPayloads.removeAll()
        for payload in payloads {
            doSend(payload, via: session)
        }
        logger.info("Flushed \(payloads.count) pending payloads")
    }

    // MARK: - Incoming Events

    private func makeSnapshot(from inhale: Inhale) -> [String: Any] {
        var snapshot: [String: Any] = [
            "smokeDate": inhale.smokeDate.timeIntervalSince1970,
            "n": inhale.n,
            "kind": inhale.kind,
        ]

        if let endAt = inhale.endAt {
            snapshot["endAt"] = endAt.timeIntervalSince1970
        }
        if let intensity = inhale.intensity {
            snapshot["intensity"] = intensity
        }

        return snapshot
    }

    @MainActor
    private func handlePayload(_ payload: [String: Any]) {
        guard let action = payload["action"] as? String else { return }

        if action == "requestFullSync" {
            sendFullHistorySnapshot()
            return
        }

        guard let uuid = payload["uuid"] as? String else { return }
        guard !recentSyncIDs.contains(uuid) else { return }
        recentSyncIDs.insert(uuid)

        guard let timestamp = payload["date"] as? TimeInterval else { return }
        let date = Date(timeIntervalSince1970: timestamp)

        guard let context = modelContainer?.mainContext else {
            logger.error("No modelContainer available for handling payload")
            return
        }

        switch action {
        case "startHookah":
            let session = Inhale(hookahSession: true, date: date)
            context.insert(session)
            logger.info("Synced: hookah session started")

        case "endHookah":
            guard let intensity = payload["intensity"] as? Int else { return }
            let descriptor = FetchDescriptor<Inhale>()
            if let inhales = try? context.fetch(descriptor),
               let active = inhales.first(where: { $0.isActiveHookahSession }) {
                active.endHookahSession(intensity: intensity)
                logger.info("Synced: hookah session ended")
            }

        case "logInhale":
            guard let n = payload["n"] as? Int else { return }
            let inhale = Inhale(n: n, date: date)
            context.insert(inhale)
            logger.info("Synced: inhale logged (n=\(n))")

        default:
            break
        }
    }
}

extension WatchSessionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            logger.error("WCSession activation failed: \(error.localizedDescription)")
        } else {
            logger.info("WCSession activated: \(activationState.rawValue)")
            if activationState == .activated {
                flushPendingPayloads()
                Task { @MainActor in
                    syncCurrentState()
                }
            }
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            handlePayload(message)
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        Task { @MainActor in
            handlePayload(userInfo)
        }
    }

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        guard let metadata = file.metadata,
              metadata["type"] as? String == "cigaExport" else { return }

        do {
            let data = try Data(contentsOf: file.fileURL)
            Task { @MainActor in
                guard let context = modelContainer?.mainContext else {
                    logger.error("No modelContainer for import")
                    return
                }
                do {
                    let count = try DataExporter.importRecords(from: data, into: context)
                    importedRecordCount = count
                    logger.info("Imported \(count) records from iPhone export file")
                } catch {
                    logger.error("Failed to import records: \(error.localizedDescription)")
                }
            }
        } catch {
            logger.error("Failed to read import file from iPhone: \(error.localizedDescription)")
        }
    }
}
