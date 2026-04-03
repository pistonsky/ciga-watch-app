//
//  TrackerView.swift
//  Ciga Watch App
//
//  Created by Aleksandr Tsygankov on 4/30/23.
//

import Foundation
import SwiftUI
import SwiftData

struct TrackerView: View {
    var inhales: [Inhale]
    var showInhales: Bool

    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    // Only count ciga/vape events, not hookah
                    let cigaInhales = inhales.filter { $0.isCigaEvent }
                    let totalInhales = cigaInhales.reduce(0) { partialResult, inhale in
                        partialResult + (Calendar.current.isDateInToday(inhale.smokeDate) ? inhale.n : 0)
                    }
                    
                    let displayCount = showInhales ? totalInhales : (totalInhales / 8)
                    Text(displayCount, format: .number)
                        .font(.largeTitle)
                        .foregroundColor(.accentColor)
                    
                    let lastInhale = cigaInhales.max(by: { $0.smokeDate < $1.smokeDate })
                    Text(timerInterval: (lastInhale?.smokeDate ?? Date())...((lastInhale?.smokeDate ?? Date()).addingTimeInterval(60*60*24)), countsDown: false, showsHours: false)
                        .foregroundColor(.secondary)
                }
                .frame(width: geometry.size.width / 2, alignment: .center)
                
                List {
                    Button("1 ciga") {
                        let newItem = Inhale(n: 8)
                        modelContext.insert(newItem)
                        WKInterfaceDevice.current().play(.directionDown)
                        WatchSessionManager.shared.sendLogInhale(date: newItem.smokeDate, n: 8)
                    }.foregroundColor(.orange)
                    Button("1 inhale") {
                        let newItem = Inhale(n: 1)
                        modelContext.insert(newItem)
                        WKInterfaceDevice.current().play(.click)
                        WatchSessionManager.shared.sendLogInhale(date: newItem.smokeDate, n: 1)
                    }.foregroundColor(.green)
                    Button("2 inhales") {
                        let newItem = Inhale(n: 2)
                        modelContext.insert(newItem)
                        WKInterfaceDevice.current().play(.success)
                        WatchSessionManager.shared.sendLogInhale(date: newItem.smokeDate, n: 2)
                    }.foregroundColor(.blue)
                    Button("3 inhales") {
                        let newItem = Inhale(n: 3)
                        modelContext.insert(newItem)
                        WKInterfaceDevice.current().play(.success)
                        WatchSessionManager.shared.sendLogInhale(date: newItem.smokeDate, n: 3)
                    }.foregroundColor(.cyan)
                }
                .navigationTitle(showInhales ? "Inhales" : "Cigas")
                .frame(width: geometry.size.width / 2)
                .offset(x: geometry.size.width / 2)
            }
        }
    }
}
