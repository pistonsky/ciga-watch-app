//
//  ComparisonChartView.swift
//  Ciga Watch App
//
//  Created by Aleksandr Tsygankov on 7/2/24.
//

import SwiftUI
import Charts

struct ComparisonChartView: View {
    var inhales: [Inhale]
    var showInhales: Bool = true
    
    private var currentHour: Double {
        let components = Calendar.current.dateComponents([.hour, .minute], from: Date())
        let hour = Double(components.hour ?? 0)
        let minute = Double(components.minute ?? 0) / 60.0
        return hour + minute
    }
    
    private var comparisonData: (today: [HourlyData], yesterday: [HourlyData]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        // Filter inhales for today and yesterday
        let todayInhales = inhales.filter { calendar.isDate($0.smokeDate, inSameDayAs: today) }
        let yesterdayInhales = inhales.filter { calendar.isDate($0.smokeDate, inSameDayAs: yesterday) }
        
        // Group by hour and calculate count
        let todayData = createHourlyData(inhales: todayInhales, day: today)
        let yesterdayData = createHourlyData(inhales: yesterdayInhales, day: yesterday)
        
        return (today: todayData, yesterday: yesterdayData)
    }
    
    private func createHourlyData(inhales: [Inhale], day: Date) -> [HourlyData] {
        let calendar = Calendar.current
        var hourlyData = [HourlyData]()
        var cumulativeValue = 0
        
        // Create hourly buckets
        for hour in 0..<24 {
            let hourDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
            let nextHour = calendar.date(byAdding: .hour, value: 1, to: hourDate)!
            
            // Filter inhales for this hour
            let hourInhales = inhales.filter { inhale in
                inhale.smokeDate >= hourDate && inhale.smokeDate < nextHour
            }
            
            // Calculate total inhales for this hour
            let hourValue = hourInhales.reduce(0) { result, inhale in
                result + inhale.n
            }
            
            // Convert to cigarettes if needed
            let adjustedHourValue = showInhales ? hourValue : hourValue / 8
            
            // Add to cumulative total
            cumulativeValue += adjustedHourValue
            
            hourlyData.append(HourlyData(hour: hour, value: cumulativeValue, isToday: calendar.isDateInToday(day)))
        }
        
        return hourlyData
    }
    
    var body: some View {
        VStack {
            Text(showInhales ? "Inhales Comparison" : "Cigas Comparison")
                .font(.headline)
                .padding(.top, 5)
            
            Chart {
                // Yesterday data rendered first (so it's below today's data)
                ForEach(comparisonData.yesterday) { hourData in
                    LineMark(
                        x: .value("Hour", hourData.hour),
                        y: .value(showInhales ? "Inhales" : "Cigas", hourData.value)
                    )
                    .foregroundStyle(by: .value("Day", "Yesterday"))
                    .interpolationMethod(.catmullRom)
                    .symbol(.circle)
                    .symbolSize(10)
                }
                
                // Today data rendered last (so it's on top)
                ForEach(comparisonData.today) { hourData in
                    LineMark(
                        x: .value("Hour", hourData.hour),
                        y: .value(showInhales ? "Inhales" : "Cigas", hourData.value)
                    )
                    .foregroundStyle(by: .value("Day", "Today"))
                    .interpolationMethod(.catmullRom)
                    .symbol(.circle)
                    .symbolSize(10)
                }
                
                // Current time indicator
                RuleMark(x: .value("Now", currentHour))
                    .foregroundStyle(Color.gray.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }
            .chartXAxis {
                AxisMarks(preset: .aligned, values: .stride(by: 6)) { value in
                    if let hour = value.as(Int.self) {
                        AxisValueLabel {
                            Text("\(hour)")
                        }
                    }
                }
            }
            .chartForegroundStyleScale([
                "Today": Color.green,
                "Yesterday": Color.blue
            ])
            .chartLegend(position: .bottom, alignment: .center)
        }
        .padding(.horizontal, 10)
    }
}

// Data structure for hourly inhale data
struct HourlyData: Identifiable {
    var id: Int { hour }
    let hour: Int
    let value: Int
    var isToday: Bool = false
} 