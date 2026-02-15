//
//  InhalesLogModel.swift
//  Ciga
//
//  Created by Aleksandr Tsygankov on 8/31/23.
//

import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.pistonsky.Ciga", category: "AppGroup")

@Model
final class Inhale {
    var smokeDate: Date
    var n: Int // how many inhales did you make? (0 for hookah)
    var kind: String = "vapeInhale" // "cigarette", "vapeInhale", "hookahSession"
    var endAt: Date? = nil
    var intensity: Int? = nil // hookah intensity 1..10

    // MARK: - Event Kind Enum

    enum Kind: String, CaseIterable, Codable {
        case cigarette
        case vapeInhale
        case hookahSession
    }

    // MARK: - Computed Properties

    var eventKind: Kind {
        Kind(rawValue: kind) ?? .vapeInhale
    }

    /// True for cigarette or vape inhale events (not hookah).
    var isCigaEvent: Bool {
        eventKind == .cigarette || eventKind == .vapeInhale
    }

    /// True for any nicotine exposure (all event types).
    var isNicotineExposure: Bool {
        true
    }

    /// True only for hookah sessions.
    var isHookahSession: Bool {
        eventKind == .hookahSession
    }

    /// True if this is an active (ongoing) hookah session.
    var isActiveHookahSession: Bool {
        isHookahSession && endAt == nil
    }

    /// Duration in seconds for hookah sessions. Active sessions use current time.
    var durationSeconds: TimeInterval? {
        guard isHookahSession else { return nil }
        let end = endAt ?? Date()
        return end.timeIntervalSince(smokeDate)
    }

    /// Duration in minutes for hookah sessions.
    var durationMinutes: Double? {
        guard let seconds = durationSeconds else { return nil }
        return seconds / 60.0
    }

    /// Nicotine load for hookah: durationMinutes × intensity.
    var nicotineLoad: Double? {
        guard let minutes = durationMinutes, let intensity = intensity else { return nil }
        return minutes * Double(intensity)
    }

    /// The relevant date for "last exposure" streak calculations.
    /// For hookah: endAt if completed, or current time if active.
    /// For ciga/vape: smokeDate.
    var exposureDate: Date {
        if isHookahSession {
            return endAt ?? Date() // active session = exposure right now
        }
        return smokeDate
    }

    // MARK: - Initializers

    /// Backward-compatible init for cigarette / vape inhale events.
    /// n >= 8 is treated as cigarette, otherwise vape inhale.
    init(n: Int = 1) {
        self.smokeDate = Date()
        self.n = n
        self.kind = (n >= 8) ? Kind.cigarette.rawValue : Kind.vapeInhale.rawValue
        self.endAt = nil
        self.intensity = nil

        // Store the latest smoke date in UserDefaults for widget access
        AppGroupConstants.sharedUserDefaults.set(self.smokeDate, forKey: AppGroupConstants.lastSmokeDateKey)
        AppGroupConstants.sharedUserDefaults.set(self.smokeDate, forKey: AppGroupConstants.lastNicotineDateKey)

        // Verify data was saved
        if let savedDate = AppGroupConstants.sharedUserDefaults.object(forKey: AppGroupConstants.lastSmokeDateKey) as? Date {
            logger.info("Successfully saved and retrieved smoke date: \(savedDate)")
        } else {
            logger.error("Failed to save smoke date to app group")
        }
    }

    /// Init for starting a hookah session. Call `endHookahSession(intensity:)` when done.
    init(hookahSession: Bool) {
        self.smokeDate = Date()
        self.n = 0
        self.kind = Kind.hookahSession.rawValue
        self.endAt = nil
        self.intensity = nil

        // Update nicotine exposure date (hookah is nicotine exposure)
        AppGroupConstants.sharedUserDefaults.set(self.smokeDate, forKey: AppGroupConstants.lastNicotineDateKey)
        AppGroupConstants.sharedUserDefaults.set(self.smokeDate, forKey: AppGroupConstants.lastHookahDateKey)

        logger.info("Hookah session started at \(self.smokeDate)")
    }

    // MARK: - Hookah Session Management

    /// End an active hookah session with the given intensity (1..10).
    func endHookahSession(intensity: Int) {
        let now = Date()
        self.endAt = now
        self.intensity = max(1, min(10, intensity))

        AppGroupConstants.sharedUserDefaults.set(now, forKey: AppGroupConstants.lastNicotineDateKey)
        AppGroupConstants.sharedUserDefaults.set(now, forKey: AppGroupConstants.lastHookahDateKey)

        logger.info("Hookah session ended. Duration: \(self.durationMinutes ?? 0) min, intensity: \(self.intensity ?? 0)")
    }
}
