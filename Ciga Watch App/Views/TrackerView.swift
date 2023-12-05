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

    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    let inhalesCount = inhales.reduce(0) { partialResult, Inhale in
                        partialResult + (Calendar.current.isDateInToday(Inhale.smokeDate) ? Inhale.n : 0)
                    }
                    Text(inhalesCount, format: .number)
                        .font(.largeTitle)
                        .foregroundColor(.accentColor)
                    
                    let lastInhale = inhales.last
                    Text(timerInterval: (lastInhale?.smokeDate ?? Date())...((lastInhale?.smokeDate ?? Date()).addingTimeInterval(3600)), countsDown: false, showsHours: false)
                        .foregroundColor(.secondary)
                }
                .frame(width: geometry.size.width / 2, alignment: .center)
                
                List {
                    Button("1 ciga") {
                        let newItem = Inhale(n: 8)
                        modelContext.insert(newItem)
                        WKInterfaceDevice.current().play(.directionDown)
                    }.foregroundColor(.orange)
                    Button("1 inhale") {
                        let newItem = Inhale(n: 1)
                        modelContext.insert(newItem)
                        WKInterfaceDevice.current().play(.click)
                    }.foregroundColor(.green)
                    Button("2 inhales") {
                        let newItem = Inhale(n: 2)
                        modelContext.insert(newItem)
                        WKInterfaceDevice.current().play(.success)
                    }.foregroundColor(.blue)
                    Button("3 inhales") {
                        let newItem = Inhale(n: 3)
                        modelContext.insert(newItem)
                        WKInterfaceDevice.current().play(.success)
                    }.foregroundColor(.cyan)
                }
                .navigationTitle("Ciga")
                .frame(width: geometry.size.width / 2)
                .offset(x: geometry.size.width / 2)
            }
        }
    }
}
