//
//  ChartData.swift
//  Ciga Watch App
//
//  Created by Aleksandr Tsygankov on 4/30/23.
//

import Foundation

struct ChartData {
    struct DataElement: Identifiable {
        var id: Date { return date }
        let date: Date
        let inhales: UInt32
    }
    
    static func createData(_ items: [Inhale]) -> [DataElement] {
        let calendar = Calendar.current
        return Dictionary(grouping: items) { element in
            return calendar.startOfDay(for: element.smokeDate)
        }
        .compactMap { (key, inhale) in
            return DataElement(date: key, inhales: UInt32(inhale.reduce(0, { partialResult, inhale in
                partialResult + Int(truncating: inhale.n as NSNumber)
            })))
        }
        .sorted {
            $0.date < $1.date
        }
    }
}

extension ChartData {
    
    /// Some static sample data for displaying a `Chart`.
    static var chartSampleData: [DataElement] {
        let calendar = Calendar.autoupdatingCurrent
        var startDateComponents = calendar.dateComponents(
            [.year, .month, .day], from: Date())
        startDateComponents.setValue(22, for: .day)
        startDateComponents.setValue(5, for: .month)
        startDateComponents.setValue(2022, for: .year)
        startDateComponents.setValue(0, for: .hour)
        startDateComponents.setValue(0, for: .minute)
        startDateComponents.setValue(0, for: .second)
        let startDate = calendar.date(from: startDateComponents)!
        
        let itemsToAdd = [
            68, 39, 19, 42, 13, 22, 71,
            51, 21, 0, 58, 21, 38, 99
        ]
        var items = [DataElement]()
        for dayOffset in (0..<itemsToAdd.count) {
            items.append(DataElement(
                date: calendar.date(byAdding: .day, value: dayOffset, to: startDate)!,
                inhales: UInt32(itemsToAdd[dayOffset])))
        }
        
        return items
    }
}
