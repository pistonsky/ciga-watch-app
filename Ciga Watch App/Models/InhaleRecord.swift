//
//  InhaleRecord.swift
//  Ciga Watch App
//
//  Created by Aleksandr Tsygankov on 4/30/23.
//

import Foundation

struct InhaleRecord: Identifiable, Hashable {
    
    let id = UUID()
    var date: Date = Date() // when did you smoke?
    var n: NSNumber // how many inhales did you make?
    
    init(_ n: NSNumber, date: Date) {
        self.n = n
        self.date = date // TODO: use now by default
    }
}
