//
//  InhaleRecordModel.swift
//  Ciga Watch App
//
//  Created by Aleksandr Tsygankov on 4/30/23.
//

import Foundation

class InhaleRecordModel: NSObject, ObservableObject {
    @Published var items = [InhaleRecord]()
}

extension InhaleRecordModel {
    
    /// A model with 4 days of data prepopulated for preview and testing.
    static var shortList: InhaleRecordModel {
        let model = InhaleRecordModel()
        model.items.append(contentsOf: [
            InhaleRecord(80, date: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date()),
            InhaleRecord(48, date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()),
            InhaleRecord(47, date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()),
            InhaleRecord(38, date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()),
            InhaleRecord(23, date: Date()),
        ])
        return model
    }
    
    /// A model with 7 days of data prepopulated for preview and testing.
    static var longList: InhaleRecordModel {
        let model = InhaleRecordModel()
        model.items.append(contentsOf: [
            InhaleRecord(80, date: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()),
            InhaleRecord(93, date: Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date()),
            InhaleRecord(78, date: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()),
            InhaleRecord(58, date: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date()),
            InhaleRecord(48, date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()),
            InhaleRecord(47, date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()),
            InhaleRecord(38, date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()),
            InhaleRecord(23, date: Date()),
        ])
        return model
    }
}
