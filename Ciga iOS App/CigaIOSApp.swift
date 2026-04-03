import AppIntents
import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.pistonsky.Ciga", category: "Migration")

@main
struct CigaIOSApp: App {
    let container: ModelContainer
    @StateObject private var phoneSession = PhoneSessionManager.shared

    init() {
        do {
            container = try ModelContainer(for: Inhale.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        performMigrationIfNeeded()
        HookahSessionService.modelContainer = container
        PhoneSessionManager.shared.modelContainer = container
        PhoneSessionManager.shared.activate()
        CigaAppShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            CigaTabView()
                .environmentObject(phoneSession)
        }
        .modelContainer(container)
    }

    private func performMigrationIfNeeded() {
        let defaults = AppGroupConstants.sharedUserDefaults
        guard !defaults.bool(forKey: AppGroupConstants.migrationV2CompletedKey) else {
            return
        }

        logger.info("Starting v2 migration...")

        let context = container.mainContext
        let fetchDescriptor = FetchDescriptor<Inhale>()

        do {
            let allInhales = try context.fetch(fetchDescriptor)
            var fixedCount = 0

            for inhale in allInhales {
                if inhale.n >= 8 && inhale.kind == Inhale.Kind.vapeInhale.rawValue {
                    inhale.kind = Inhale.Kind.cigarette.rawValue
                    fixedCount += 1
                }
            }

            try context.save()
            logger.info("v2 migration complete. Fixed \(fixedCount) cigarette records out of \(allInhales.count) total.")

            if defaults.object(forKey: AppGroupConstants.lastNicotineDateKey) == nil,
               let lastSmoke = defaults.object(forKey: AppGroupConstants.lastSmokeDateKey) as? Date {
                defaults.set(lastSmoke, forKey: AppGroupConstants.lastNicotineDateKey)
            }

            defaults.set(true, forKey: AppGroupConstants.migrationV2CompletedKey)

        } catch {
            logger.error("v2 migration failed: \(error.localizedDescription)")
        }
    }
}
