//
//  StatsEngine.swift
//  Ciga Watch App
//
//  Stats engine to compute streaks, hookah scores, and equivalent cigarettes.
//

import Foundation

struct StatsEngine {

    // MARK: - Ciga-Free Streak

    /// Time since the last cigarette or vape inhale event.
    /// Returns nil if no ciga/vape events exist (infinite streak).
    static func cigaFreeStreak(inhales: [Inhale]) -> TimeInterval? {
        let cigaEvents = inhales.filter { $0.isCigaEvent }
        guard let lastEvent = cigaEvents.max(by: { $0.smokeDate < $1.smokeDate }) else {
            return nil // no ciga/vape events ever — infinite streak
        }
        return Date().timeIntervalSince(lastEvent.smokeDate)
    }

    // MARK: - Nicotine-Free Streak

    /// Time since the last nicotine exposure of any kind (cigarette, vape, or hookah).
    /// For hookah: uses endAt if completed, or treats active session as exposure now (streak = 0).
    /// Returns nil if no events exist (infinite streak).
    static func nicotineFreeStreak(inhales: [Inhale]) -> TimeInterval? {
        guard !inhales.isEmpty else {
            return nil // no events ever
        }

        // Check for any active hookah session — if so, nicotine-free streak is 0
        if inhales.contains(where: { $0.isActiveHookahSession }) {
            return 0
        }

        // Find the most recent exposure date across all event types
        guard let lastExposure = inhales.map({ $0.exposureDate }).max() else {
            return nil
        }
        return Date().timeIntervalSince(lastExposure)
    }

    // MARK: - Hookah-Free Streak

    /// Time since the last hookah exposure (session end or active session).
    /// Returns nil if no hookah sessions exist (infinite streak).
    static func hookahFreeStreak(inhales: [Inhale]) -> TimeInterval? {
        let hookahSessions = inhales.filter { $0.isHookahSession }
        guard !hookahSessions.isEmpty else {
            return nil // no hookah sessions ever
        }

        // Active hookah session = exposure right now = streak 0
        if hookahSessions.contains(where: { $0.isActiveHookahSession }) {
            return 0
        }

        // Find the most recent hookah exposure date
        guard let lastHookah = hookahSessions.map({ $0.exposureDate }).max() else {
            return nil
        }
        return Date().timeIntervalSince(lastHookah)
    }

    // MARK: - Hookah Exposure Score (Monthly)

    /// Hookah exposure score for a given month.
    /// nicotineLoad = durationMinutes × intensity per session.
    /// totalLoadThisMonth = sum of loads.
    /// hookahScore = Int(round(totalLoadThisMonth / 200.0))
    static func hookahExposureScore(inhales: [Inhale], month: Date = Date()) -> Int {
        let totalLoad = totalHookahNicotineLoad(inhales: inhales, month: month)
        return Int(round(totalLoad / 200.0))
    }

    // MARK: - Equivalent Cigarettes (Monthly)

    /// Estimated equivalent cigarettes for hookah sessions this month.
    /// equivCigarettes = Int(round(totalLoadThisMonth / 50.0))
    static func equivalentCigarettes(inhales: [Inhale], month: Date = Date()) -> Int {
        let totalLoad = totalHookahNicotineLoad(inhales: inhales, month: month)
        return Int(round(totalLoad / 50.0))
    }

    // MARK: - Helpers

    /// Total hookah nicotine load for a given month.
    static func totalHookahNicotineLoad(inhales: [Inhale], month: Date = Date()) -> Double {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: month)
        guard let monthStart = calendar.date(from: components),
              let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return 0
        }

        let hookahThisMonth = inhales.filter { inhale in
            inhale.isHookahSession &&
            !inhale.isActiveHookahSession && // only completed sessions
            inhale.smokeDate >= monthStart &&
            inhale.smokeDate < monthEnd
        }

        return hookahThisMonth.compactMap { $0.nicotineLoad }.reduce(0, +)
    }

    /// Format a time interval as a human-readable streak string.
    static func formatStreak(_ interval: TimeInterval?) -> String {
        guard let interval = interval else {
            return "∞" // no events ever = infinite streak
        }
        if interval < 60 {
            return "< 1m"
        }
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        if interval >= 86400 {
            formatter.allowedUnits = [.day, .hour]
        } else if interval >= 3600 {
            formatter.allowedUnits = [.hour, .minute]
        } else {
            formatter.allowedUnits = [.minute]
        }
        return formatter.string(from: interval) ?? "0m"
    }

    /// Count of completed hookah sessions this month.
    static func hookahSessionsThisMonth(inhales: [Inhale], month: Date = Date()) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: month)
        guard let monthStart = calendar.date(from: components),
              let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else {
            return 0
        }

        return inhales.filter { inhale in
            inhale.isHookahSession &&
            !inhale.isActiveHookahSession &&
            inhale.smokeDate >= monthStart &&
            inhale.smokeDate < monthEnd
        }.count
    }
}
