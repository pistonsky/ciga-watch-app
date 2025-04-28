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
    var n: Int // how many inhales did you make?
    
    init(n: Int = 1) {
        self.smokeDate = Date()
        self.n = n
        
        // Store the latest smoke date in UserDefaults for widget access
        AppGroupConstants.sharedUserDefaults.set(self.smokeDate, forKey: AppGroupConstants.lastSmokeDateKey)
        
        // Verify data was saved
        if let savedDate = AppGroupConstants.sharedUserDefaults.object(forKey: AppGroupConstants.lastSmokeDateKey) as? Date {
            logger.info("Successfully saved and retrieved smoke date: \(savedDate)")
        } else {
            logger.error("Failed to save smoke date to app group")
        }
    }
}
