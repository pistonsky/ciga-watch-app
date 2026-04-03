import Charts
import SwiftUI

struct iOSChartView: View {
    var inhales: [Inhale]
    var showInhales: Bool = true
    var showHookahInChart: Bool = false

    private var chartData: [ChartData.DataElement] {
        var data = ChartData.createData(inhales)
        if !showInhales {
            data = data.map { element in
                ChartData.DataElement(date: element.date, inhales: element.inhales / 8)
            }
        }
        return data
    }

    private var hookahChartData: [ChartData.HookahDataElement] {
        guard showHookahInChart else { return [] }
        return ChartData.createHookahData(inhales)
    }

    var body: some View {
        Chart {
            ForEach(chartData, id: \.id) {
                BarMark(
                    x: .value("Day", $0.date),
                    y: .value(showInhales ? "Inhales" : "Cigarettes", $0.inhales),
                    width: showHookahInChart ? 8 : 14
                )
                .cornerRadius(4)
                .foregroundStyle(by: .value("Type", showInhales ? "Inhales" : "Cigas"))
            }

            if showHookahInChart {
                ForEach(hookahChartData, id: \.id) { element in
                    BarMark(
                        x: .value("Day", element.date),
                        y: .value("Hookah ≈ Cigs", element.equivalentCigarettes),
                        width: 8
                    )
                    .cornerRadius(4)
                    .foregroundStyle(by: .value("Type", "Hookah"))
                    .position(by: .value("Type", "Hookah"))
                }
            }
        }
        .chartForegroundStyleScale(chartColorScale)
        .chartScrollableAxes(.horizontal)
        .chartXVisibleDomain(length: 3600 * 24 * 14)
        .defaultScrollAnchor(.topTrailing)
        .chartLegend(showHookahInChart ? .visible : .hidden)
        .frame(minHeight: 300)
        .padding()
        .navigationTitle(chartTitle)
    }

    private var chartTitle: String {
        if showHookahInChart {
            return showInhales ? "Inhales + Hookah" : "Cigs + Hookah"
        }
        return showInhales ? "Inhales" : "Cigarettes"
    }

    private var chartColorScale: KeyValuePairs<String, Color> {
        if showHookahInChart {
            return [
                (showInhales ? "Inhales" : "Cigas"): .blue,
                "Hookah": .purple,
            ]
        }
        return [
            (showInhales ? "Inhales" : "Cigas"): .blue,
        ]
    }
}
