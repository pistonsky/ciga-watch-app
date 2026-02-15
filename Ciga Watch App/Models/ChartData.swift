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

    /// Hookah chart data element representing daily hookah equivalent cigarettes.
    struct HookahDataElement: Identifiable {
        var id: Date { return date }
        let date: Date
        let equivalentCigarettes: Double
        let nicotineLoad: Double
    }

    // MARK: - Ciga/Vape Data (existing behavior, now explicitly filters)

    /// Creates daily aggregate data for cigarette and vape inhale events only.
    /// Hookah sessions (n=0) are excluded.
    static func createData(_ items: [Inhale]) -> [DataElement] {
        let calendar = Calendar.current
        let cigaItems = items.filter { $0.isCigaEvent }

        return Dictionary(grouping: cigaItems) { element in
            return calendar.startOfDay(for: element.smokeDate)
        }
        .compactMap { (key, inhale) in
            return DataElement(date: key, inhales: UInt32(inhale.reduce(0, { partialResult, inhale in
                partialResult + inhale.n
            })))
        }
        .sorted {
            $0.date < $1.date
        }
    }

    // MARK: - Hookah Chart Data

    /// Creates daily aggregate data for completed hookah sessions.
    /// Each day's value is the sum of nicotine loads converted to equivalent cigarettes.
    static func createHookahData(_ items: [Inhale]) -> [HookahDataElement] {
        let calendar = Calendar.current
        let hookahItems = items.filter { $0.isHookahSession && !$0.isActiveHookahSession }

        return Dictionary(grouping: hookahItems) { element in
            return calendar.startOfDay(for: element.smokeDate)
        }
        .compactMap { (key, sessions) in
            let totalLoad = sessions.compactMap { $0.nicotineLoad }.reduce(0, +)
            let equivCigs = totalLoad / 50.0
            return HookahDataElement(
                date: key,
                equivalentCigarettes: equivCigs,
                nicotineLoad: totalLoad
            )
        }
        .sorted {
            $0.date < $1.date
        }
    }
}

extension ChartData {

    /// Some static sample data to show a two-week chart. To use your own data,
    /// use ChartData.createData(_: [Inhale]) with the data in the model.
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
