import Foundation
import WatchConnectivity
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.pistonsky.Ciga", category: "WatchConnectivity")

final class PhoneSessionManager: NSObject, ObservableObject {
    static let shared = PhoneSessionManager()
    var modelContainer: ModelContainer?

    @Published var receivedExportURL: URL?

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

    func requestFullSyncIfNeeded() {
        let defaults = AppGroupConstants.sharedUserDefaults
        guard !defaults.bool(forKey: AppGroupConstants.historyBootstrapCompletedKey) else {
            return
        }

        let payload: [String: Any] = ["action": "requestFullSync"]
        logger.info("Requesting full history sync from Watch")
        sendPayload(payload)
    }

    func sendStartHookah(date: Date) {
        let uuid = UUID().uuidString
        let payload: [String: Any] = [
            "action": "startHookah",
            "uuid": uuid,
            "date": date.timeIntervalSince1970
        ]
        recentSyncIDs.insert(uuid)
        sendPayload(payload)
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

    // MARK: - Export to Watch

    @MainActor
    func sendExportToWatch() {
        guard let context = modelContainer?.mainContext else {
            logger.error("No modelContainer for export to Watch")
            return
        }
        let descriptor = FetchDescriptor<Inhale>(sortBy: [SortDescriptor(\.smokeDate)])
        guard let inhales = try? context.fetch(descriptor) else {
            logger.error("Failed to fetch inhales for export to Watch")
            return
        }
        do {
            let data = try DataExporter.createExportData(from: inhales)
            let url = try DataExporter.writeToTemporaryFile(data)
            let session = WCSession.default
            guard session.activationState == .activated else {
                logger.error("Cannot send export to Watch: WCSession not activated")
                return
            }
            session.transferFile(url, metadata: ["type": "cigaExport"])
            logger.info("Sent export file to Watch (\(inhales.count) records)")
        } catch {
            logger.error("Failed to create export for Watch: \(error.localizedDescription)")
        }
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

    // MARK: - Application Context (session state from Watch)

    /// Reads the latest application context from the Watch to sync hookah session state.
    /// Called when WCSession activation completes.
    @MainActor
    private func syncFromApplicationContext(_ context: [String: Any]) {
        guard let hasActive = context["hasActiveHookah"] as? Bool else { return }

        guard let mc = modelContainer?.mainContext else {
            logger.error("No modelContainer for application context sync")
            return
        }

        let descriptor = FetchDescriptor<Inhale>()
        let existingInhales = (try? mc.fetch(descriptor)) ?? []
        let localActive = existingInhales.first(where: { $0.isActiveHookahSession })

        if hasActive, let startTimestamp = context["hookahStartDate"] as? TimeInterval {
            let startDate = Date(timeIntervalSince1970: startTimestamp)

            if localActive == nil {
                let session = Inhale(
                    smokeDate: startDate,
                    n: 0,
                    kind: .hookahSession,
                    endAt: nil,
                    intensity: nil,
                    syncSharedState: false
                )
                mc.insert(session)
                LiveActivityManager.startActivity(startDate: startDate)
                logger.info("Synced active hookah session from Watch context (started \(startDate))")
            }
        } else if !hasActive, localActive == nil {
            LiveActivityManager.endActivity()
        }
    }

    // MARK: - Incoming Events

    private func datesMatch(_ lhs: Date?, _ rhs: Date?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case let (left?, right?):
            return abs(left.timeIntervalSince1970 - right.timeIntervalSince1970) < 0.001
        default:
            return false
        }
    }

    private func existingInhale(
        matching snapshot: [String: Any],
        in inhales: [Inhale]
    ) -> Inhale? {
        guard
            let smokeDateValue = snapshot["smokeDate"] as? TimeInterval,
            let n = snapshot["n"] as? Int,
            let kind = snapshot["kind"] as? String
        else {
            return nil
        }

        let smokeDate = Date(timeIntervalSince1970: smokeDateValue)
        let endAt = (snapshot["endAt"] as? TimeInterval).map(Date.init(timeIntervalSince1970:))
        let intensity = snapshot["intensity"] as? Int

        return inhales.first { inhale in
            inhale.n == n &&
            inhale.kind == kind &&
            datesMatch(inhale.smokeDate, smokeDate) &&
            datesMatch(inhale.endAt, endAt) &&
            inhale.intensity == intensity
        }
    }

    @MainActor
    private func importHistoryBatch(_ items: [[String: Any]]) {
        guard let context = modelContainer?.mainContext else {
            logger.error("No modelContainer available for history import")
            return
        }

        let descriptor = FetchDescriptor<Inhale>(sortBy: [SortDescriptor(\.smokeDate)])
        var existing = (try? context.fetch(descriptor)) ?? []

        for item in items {
            guard
                let smokeDateValue = item["smokeDate"] as? TimeInterval,
                let n = item["n"] as? Int,
                let kindRaw = item["kind"] as? String,
                let kind = Inhale.Kind(rawValue: kindRaw)
            else {
                continue
            }

            let smokeDate = Date(timeIntervalSince1970: smokeDateValue)
            let endAt = (item["endAt"] as? TimeInterval).map(Date.init(timeIntervalSince1970:))
            let intensity = item["intensity"] as? Int

            if existingInhale(matching: item, in: existing) != nil {
                continue
            }

            if kind == .hookahSession,
               let currentActive = existing.first(where: { $0.isActiveHookahSession }),
               endAt == nil,
               datesMatch(currentActive.smokeDate, smokeDate) {
                continue
            }

            let inhale = Inhale(
                smokeDate: smokeDate,
                n: n,
                kind: kind,
                endAt: endAt,
                intensity: intensity,
                syncSharedState: false
            )
            context.insert(inhale)
            existing.append(inhale)

            if inhale.isActiveHookahSession {
                LiveActivityManager.startActivity(startDate: inhale.smokeDate)
            }
        }

        logger.info("Imported history batch with \(items.count) records")
    }

    @MainActor
    private func handlePayload(_ payload: [String: Any]) {
        guard let action = payload["action"] as? String else { return }

        if action == "historyBatch" {
            let items = payload["items"] as? [[String: Any]] ?? []
            importHistoryBatch(items)
            return
        }

        if action == "historySyncComplete" {
            AppGroupConstants.sharedUserDefaults.set(true, forKey: AppGroupConstants.historyBootstrapCompletedKey)
            logger.info("History bootstrap completed")
            return
        }

        if action == "requestExportFile" {
            sendExportToWatch()
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
            let descriptor = FetchDescriptor<Inhale>()
            let existing = (try? context.fetch(descriptor)) ?? []
            let snapshot: [String: Any] = [
                "smokeDate": date.timeIntervalSince1970,
                "n": 0,
                "kind": Inhale.Kind.hookahSession.rawValue,
            ]
            if existingInhale(matching: snapshot, in: existing) == nil,
               existing.first(where: { $0.isActiveHookahSession }) == nil {
                let session = Inhale(
                    smokeDate: date,
                    n: 0,
                    kind: .hookahSession,
                    endAt: nil,
                    intensity: nil,
                    syncSharedState: false
                )
                context.insert(session)
                LiveActivityManager.startActivity(startDate: date)
                logger.info("Synced: hookah session started")
            }

        case "endHookah":
            guard let intensity = payload["intensity"] as? Int else { return }
            let descriptor = FetchDescriptor<Inhale>()
            if let inhales = try? context.fetch(descriptor),
               let active = inhales.first(where: { $0.isActiveHookahSession }) {
                active.endHookahSession(intensity: intensity)
                logger.info("Synced: hookah session ended")
            }
            LiveActivityManager.endActivity()

        case "logInhale":
            guard let n = payload["n"] as? Int else { return }
            let descriptor = FetchDescriptor<Inhale>()
            let existing = (try? context.fetch(descriptor)) ?? []
            let snapshot: [String: Any] = [
                "smokeDate": date.timeIntervalSince1970,
                "n": n,
                "kind": n >= 8 ? Inhale.Kind.cigarette.rawValue : Inhale.Kind.vapeInhale.rawValue,
            ]
            if existingInhale(matching: snapshot, in: existing) == nil {
                let inhale = Inhale(n: n, date: date)
                context.insert(inhale)
                logger.info("Synced: inhale logged (n=\(n))")
            }

        default:
            break
        }
    }
}

extension PhoneSessionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            logger.error("WCSession activation failed: \(error.localizedDescription)")
        } else {
            logger.info("WCSession activated: \(activationState.rawValue)")
            if activationState == .activated {
                flushPendingPayloads()
                requestFullSyncIfNeeded()
                let ctx = session.receivedApplicationContext
                if !ctx.isEmpty {
                    logger.info("Reading application context on activation: \(ctx.keys.joined(separator: ", "))")
                    Task { @MainActor in
                        syncFromApplicationContext(ctx)
                    }
                }
            }
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        logger.info("Received application context update: \(applicationContext.keys.joined(separator: ", "))")
        Task { @MainActor in
            syncFromApplicationContext(applicationContext)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        logger.info("Received message: \(message["action"] as? String ?? "unknown")")
        Task { @MainActor in
            handlePayload(message)
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any]) {
        logger.info("Received transferUserInfo: \(userInfo["action"] as? String ?? "unknown")")
        Task { @MainActor in
            handlePayload(userInfo)
        }
    }

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        guard let metadata = file.metadata,
              metadata["type"] as? String == "cigaExport" else { return }

        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destURL = documentsDir.appendingPathComponent(file.fileURL.lastPathComponent)

        do {
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.copyItem(at: file.fileURL, to: destURL)
            logger.info("Export file received from Watch: \(destURL.lastPathComponent)")

            DispatchQueue.main.async {
                self.receivedExportURL = destURL
            }
        } catch {
            logger.error("Failed to save export file from Watch: \(error.localizedDescription)")
        }
    }
}
