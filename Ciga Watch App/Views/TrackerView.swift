//
//  TrackerView.swift
//  Ciga Watch App
//
//  Created by Aleksandr Tsygankov on 4/30/23.
//

import Foundation
import SwiftUI

struct TrackerView: View {
    @EnvironmentObject private var model: InhaleRecordModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Text(model.items.reduce(0) { partialResult, record in
                    partialResult + (Calendar.current.isDateInToday(record.date) ? Int(truncating: record.n) : 0)
                }, format: .number)
                    .font(.largeTitle)
                    .frame(width: geometry.size.width / 2, alignment: .center)
                    .foregroundColor(.accentColor)
                List {
                    Button("1 ciga") {
                        model.items.append(InhaleRecord(8, date: Date()))
                        WKInterfaceDevice.current().play(.directionDown)
                    }.foregroundColor(.orange)
                    Button("1 inhale") {
                        model.items.append(InhaleRecord(1, date: Date()))
                        WKInterfaceDevice.current().play(.click)
                    }.foregroundColor(.green)
                    Button("2 inhales") {
                        model.items.append(InhaleRecord(2, date: Date()))
                        WKInterfaceDevice.current().play(.success)
                    }.foregroundColor(.blue)
                    Button("3 inhales") {
                        model.items.append(InhaleRecord(3, date: Date()))
                        WKInterfaceDevice.current().play(.success)
                    }.foregroundColor(.cyan)
                }
                .navigationTitle("Smoke")
                .frame(width: geometry.size.width / 2)
                .offset(x: geometry.size.width / 2)
            }
        }
    }
}
