//
//  CigaApp.swift
//  Ciga Watch App
//
//  Created by Aleksandr Tsygankov on 4/30/23.
//

import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.pistonsky.Ciga", category: "Migration")

@main
struct CigaWatchApp: App {
    let container: ModelContainer

    init() {
        // Use the same initializer as the original .modelContainer(for:) modifier
        // to guarantee the store is at the same default location as before.
        do {
            container = try ModelContainer(for: Inhale.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }

        // Run one-time v2 migration to set correct `kind` for existing records
        performMigrationIfNeeded()
        performHookahCapMigrationIfNeeded()

        WatchSessionManager.shared.modelContainer = container
        WatchSessionManager.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }

    // MARK: - Migration

    /// One-time migration from v1 (no `kind` field) to v2 (with `kind`).
    /// SwiftData lightweight migration adds `kind` with default "vapeInhale".
    /// This fixup sets records with n >= 8 to "cigarette" and backfills
    /// UserDefaults nicotine/hookah date keys.
    private func performMigrationIfNeeded() {
        let defaults = AppGroupConstants.sharedUserDefaults
        guard !defaults.bool(forKey: AppGroupConstants.migrationV2CompletedKey) else {
            return // already migrated
        }

        logger.info("Starting v2 migration...")

        let context = container.mainContext
        let fetchDescriptor = FetchDescriptor<Inhale>()

        do {
            let allInhales = try context.fetch(fetchDescriptor)
            var fixedCount = 0

            for inhale in allInhales {
                // Fix cigarette records: n >= 8 should be "cigarette", not default "vapeInhale"
                if inhale.n >= 8 && inhale.kind == Inhale.Kind.vapeInhale.rawValue {
                    inhale.kind = Inhale.Kind.cigarette.rawValue
                    fixedCount += 1
                }
            }

            try context.save()
            logger.info("v2 migration complete. Fixed \(fixedCount) cigarette records out of \(allInhales.count) total.")

            // Backfill lastNicotineDate from lastSmokeDate if not set
            if defaults.object(forKey: AppGroupConstants.lastNicotineDateKey) == nil,
               let lastSmoke = defaults.object(forKey: AppGroupConstants.lastSmokeDateKey) as? Date {
                defaults.set(lastSmoke, forKey: AppGroupConstants.lastNicotineDateKey)
            }

            defaults.set(true, forKey: AppGroupConstants.migrationV2CompletedKey)

        } catch {
            logger.error("v2 migration failed: \(error.localizedDescription)")
            // Don't mark as completed so it retries on next launch
        }
    }

    /// One-time v3 migration: clamp every historical hookah session to the 3h cap
    /// and close out any orphan active sessions with a default intensity. The
    /// Watch store is independent from the iPhone store, so both targets must
    /// heal their own data (same as v2).
    private func performHookahCapMigrationIfNeeded() {
        let defaults = AppGroupConstants.sharedUserDefaults
        guard !defaults.bool(forKey: AppGroupConstants.migrationV3CompletedKey) else {
            return
        }

        logger.info("Starting v3 hookah cap migration...")

        let context = container.mainContext
        let fetchDescriptor = FetchDescriptor<Inhale>()

        do {
            let allInhales = try context.fetch(fetchDescriptor)
            var cappedCount = 0
            var orphanEndedCount = 0

            for inhale in allInhales where inhale.isHookahSession {
                let hardCap = inhale.smokeDate.addingTimeInterval(Inhale.maxSessionDuration)

                if let end = inhale.endAt {
                    if end > hardCap {
                        inhale.endAt = hardCap
                        cappedCount += 1
                    }
                } else if Date() >= hardCap {
                    inhale.endAt = hardCap
                    if inhale.intensity == nil {
                        inhale.intensity = 5
                    }
                    orphanEndedCount += 1
                }
            }

            try context.save()
            logger.info("v3 migration complete. Capped \(cappedCount) overlong sessions; closed \(orphanEndedCount) orphan active sessions.")

            defaults.set(true, forKey: AppGroupConstants.migrationV3CompletedKey)

        } catch {
            logger.error("v3 migration failed: \(error.localizedDescription)")
        }
    }
}
