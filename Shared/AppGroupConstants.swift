//
//  AppGroupConstants.swift
//  Ciga
//
//  Created by Aleksandr Tsygankov on 4/28/25.
//

import Foundation

// Shared constants for both app and widget extension
enum AppGroupConstants {
    static let suiteName = "group.dev.pistonsky.ciga"

    // MARK: - Existing Keys
    static let lastSmokeDateKey = "lastSmokeDate"        // last cigarette or vape date
    static let arcPeriodHoursKey = "arcPeriodHours"
    static let defaultArcPeriodHours: Double = 2.0

    // MARK: - Hookah / Nicotine Keys
    static let lastNicotineDateKey = "lastNicotineDate"   // last any nicotine exposure
    static let lastHookahDateKey = "lastHookahDate"       // last hookah session end
    static let showHookahInChartKey = "showHookahInChart"  // toggle for chart overlay

    // MARK: - Migration
    static let migrationV2CompletedKey = "migrationV2Completed"
    static let migrationV3CompletedKey = "migrationV3Completed"
    static let historyBootstrapCompletedKey = "historyBootstrapCompleted"

    static let sharedUserDefaults = UserDefaults(suiteName: suiteName) ?? UserDefaults.standard
}
