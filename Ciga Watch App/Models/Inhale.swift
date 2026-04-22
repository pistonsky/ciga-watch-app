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

    // MARK: - Session Cap

    /// Hard ceiling on how long any hookah session is allowed to run.
    /// Anything beyond this is treated as a runaway session and clamped.
    static let maxSessionDuration: TimeInterval = 3 * 60 * 60

    /// Effective end date for a hookah session, clamped to `smokeDate + maxSessionDuration`.
    /// For active sessions this is min(now, cap). Returns nil for non-hookah events.
    var cappedEndDate: Date? {
        guard isHookahSession else { return nil }
        let hardCap = smokeDate.addingTimeInterval(Self.maxSessionDuration)
        let candidate = endAt ?? Date()
        return min(candidate, hardCap)
    }

    /// True when an active hookah session has blown past the 3h cap and should be force-ended.
    var exceedsMaxDuration: Bool {
        guard isHookahSession else { return false }
        return Date() >= smokeDate.addingTimeInterval(Self.maxSessionDuration)
    }

    /// Duration in seconds for hookah sessions, clamped to the 3h cap.
    var durationSeconds: TimeInterval? {
        guard let end = cappedEndDate else { return nil }
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
            return cappedEndDate ?? smokeDate
        }
        return smokeDate
    }

    // MARK: - Initializers

    init(
        smokeDate: Date,
        n: Int,
        kind: Kind,
        endAt: Date? = nil,
        intensity: Int? = nil,
        syncSharedState: Bool = false
    ) {
        self.smokeDate = smokeDate
        self.n = n
        self.kind = kind.rawValue
        self.endAt = endAt
        self.intensity = intensity

        guard syncSharedState else { return }

        switch kind {
        case .cigarette, .vapeInhale:
            AppGroupConstants.sharedUserDefaults.set(smokeDate, forKey: AppGroupConstants.lastSmokeDateKey)
            AppGroupConstants.sharedUserDefaults.set(smokeDate, forKey: AppGroupConstants.lastNicotineDateKey)
        case .hookahSession:
            let exposureDate = endAt ?? smokeDate
            AppGroupConstants.sharedUserDefaults.set(exposureDate, forKey: AppGroupConstants.lastNicotineDateKey)
            AppGroupConstants.sharedUserDefaults.set(exposureDate, forKey: AppGroupConstants.lastHookahDateKey)
        }
    }

    /// Backward-compatible init for cigarette / vape inhale events.
    /// n >= 8 is treated as cigarette, otherwise vape inhale.
    init(n: Int = 1, date: Date = Date()) {
        let kind: Kind = (n >= 8) ? .cigarette : .vapeInhale
        self.smokeDate = date
        self.n = n
        self.kind = kind.rawValue
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
    init(hookahSession: Bool, date: Date = Date()) {
        self.smokeDate = date
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
    /// The end time is clamped to `smokeDate + maxSessionDuration`, guaranteeing
    /// no session can ever be persisted with a duration greater than the cap.
    func endHookahSession(intensity: Int) {
        let hardCap = smokeDate.addingTimeInterval(Self.maxSessionDuration)
        let effectiveEnd = min(Date(), hardCap)
        self.endAt = effectiveEnd
        self.intensity = max(1, min(10, intensity))

        AppGroupConstants.sharedUserDefaults.set(effectiveEnd, forKey: AppGroupConstants.lastNicotineDateKey)
        AppGroupConstants.sharedUserDefaults.set(effectiveEnd, forKey: AppGroupConstants.lastHookahDateKey)

        logger.info("Hookah session ended. Duration: \(self.durationMinutes ?? 0) min, intensity: \(self.intensity ?? 0)")
    }

    /// Force-end an active or runaway hookah session at the 3h cap.
    /// Used by live enforcement and the v3 history migration for sessions that
    /// were never properly ended. If `intensity` is already set it is preserved;
    /// otherwise `defaultIntensity` is used.
    func forceEndAtCap(defaultIntensity: Int = 5) {
        guard isHookahSession else { return }
        let cappedEnd = smokeDate.addingTimeInterval(Self.maxSessionDuration)
        self.endAt = cappedEnd
        if self.intensity == nil {
            self.intensity = max(1, min(10, defaultIntensity))
        }

        AppGroupConstants.sharedUserDefaults.set(cappedEnd, forKey: AppGroupConstants.lastNicotineDateKey)
        AppGroupConstants.sharedUserDefaults.set(cappedEnd, forKey: AppGroupConstants.lastHookahDateKey)

        logger.info("Hookah session force-ended at 3h cap. Intensity: \(self.intensity ?? 0)")
    }
}
