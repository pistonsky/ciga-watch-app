//
//  AppGroupConstants.swift
//  Ciga
//
//  Created by Aleksandr Tsygankov on 4/28/25.
//

import Foundation

// Shared constants for both app and widget extension
enum AppGroupConstants {
    static let suiteName = "group.com.pistonsky.Ciga"
    static let lastSmokeDateKey = "lastSmokeDate"
    
    static let sharedUserDefaults = UserDefaults(suiteName: suiteName) ?? UserDefaults.standard
} 