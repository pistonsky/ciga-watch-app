import SwiftUI
import Charts

struct iOSComparisonChartView: View {
    var inhales: [Inhale]
    var showInhales: Bool = true

    private var currentHour: Double {
        let components = Calendar.current.dateComponents([.hour, .minute], from: Date())
        return Double(components.hour ?? 0) + Double(components.minute ?? 0) / 60.0
    }

    private var comparisonData: (today: [HourlyData], yesterday: [HourlyData]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

        let cigaVapeInhales = inhales.filter { $0.isCigaEvent }
        let todayInhales = cigaVapeInhales.filter { calendar.isDate($0.smokeDate, inSameDayAs: today) }
        let yesterdayInhales = cigaVapeInhales.filter { calendar.isDate($0.smokeDate, inSameDayAs: yesterday) }

        return (
            today: createHourlyData(inhales: todayInhales, day: today),
            yesterday: createHourlyData(inhales: yesterdayInhales, day: yesterday)
        )
    }

    private func createHourlyData(inhales: [Inhale], day: Date) -> [HourlyData] {
        let calendar = Calendar.current
        var hourlyData = [HourlyData]()
        var cumulativeValue = 0

        for hour in 0..<24 {
            let hourDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day)!
            let nextHour = calendar.date(byAdding: .hour, value: 1, to: hourDate)!

            let hourInhales = inhales.filter { $0.smokeDate >= hourDate && $0.smokeDate < nextHour }
            let hourValue = hourInhales.reduce(0) { $0 + $1.n }
            let adjusted = showInhales ? hourValue : hourValue / 8
            cumulativeValue += adjusted

            hourlyData.append(HourlyData(hour: hour, value: cumulativeValue, isToday: calendar.isDateInToday(day)))
        }

        return hourlyData
    }

    var body: some View {
        Chart {
            ForEach(comparisonData.yesterday) { hourData in
                LineMark(
                    x: .value("Hour", hourData.hour),
                    y: .value(showInhales ? "Inhales" : "Cigas", hourData.value)
                )
                .foregroundStyle(by: .value("Day", "Yesterday"))
                .interpolationMethod(.catmullRom)
                .symbol(.circle)
                .symbolSize(20)
            }

            ForEach(comparisonData.today) { hourData in
                LineMark(
                    x: .value("Hour", hourData.hour),
                    y: .value(showInhales ? "Inhales" : "Cigas", hourData.value)
                )
                .foregroundStyle(by: .value("Day", "Today"))
                .interpolationMethod(.catmullRom)
                .symbol(.circle)
                .symbolSize(20)
            }

            RuleMark(x: .value("Now", currentHour))
                .foregroundStyle(Color.gray.opacity(0.5))
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
        }
        .chartXAxis {
            AxisMarks(preset: .aligned, values: .stride(by: 6)) { value in
                if let hour = value.as(Int.self) {
                    AxisValueLabel { Text("\(hour)") }
                }
            }
        }
        .chartForegroundStyleScale([
            "Today": Color.green,
            "Yesterday": Color.blue
        ])
        .chartLegend(position: .bottom, alignment: .center)
        .frame(minHeight: 300)
        .padding()
        .navigationTitle(showInhales ? "Today vs Yesterday" : "Today vs Yesterday")
    }
}

struct HourlyData: Identifiable {
    var id: Int { hour }
    let hour: Int
    let value: Int
    var isToday: Bool = false
}
