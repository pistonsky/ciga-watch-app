//
//  InhalesLogModel.swift
//  Ciga
//
//  Created by Aleksandr Tsygankov on 8/31/23.
//

import Foundation
import SwiftData

@Model
final class Inhale {
    var smokeDate: Date
    var n: Int // how many inhales did you make?
    
    init(n: Int = 1) {
        self.smokeDate = Date()
        self.n = n
    }
}
