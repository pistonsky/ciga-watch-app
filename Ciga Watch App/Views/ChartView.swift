//
//  ChartView.swift
//  Ciga Watch App
//
//  Created by Aleksandr Tsygankov on 4/30/23.
//

import Charts
import SwiftUI

struct ChartView: View {
    var inhales: [Inhale]
    var showInhales: Bool = true
    var showHookahInChart: Bool = false

    private var chartData: [ChartData.DataElement] {
        var data = ChartData.createData(inhales)

        if !showInhales {
            // Convert inhales to cigarettes (1 cig = 8 inhales)
            data = data.map { element in
                ChartData.DataElement(
                    date: element.date,
                    inhales: element.inhales / 8
                )
            }
        }

        return data.isEmpty ? [] : data
    }

    private var hookahChartData: [ChartData.HookahDataElement] {
        guard showHookahInChart else { return [] }
        return ChartData.createHookahData(inhales)
    }

    var body: some View {
        Chart {
            // Ciga/vape bars (existing)
            ForEach(chartData, id: \.id) {
                BarMark(
                    x: .value("Day", $0.date),
                    y: .value(showInhales ? "Inhales" : "Cigarettes", $0.inhales),
                    width: showHookahInChart ? 6 : 10
                )
                .cornerRadius(4)
                .foregroundStyle(by: .value("Type", showInhales ? "Inhales" : "Cigas"))
            }

            // Hookah bars (optional overlay)
            if showHookahInChart {
                ForEach(hookahChartData, id: \.id) { element in
                    BarMark(
                        x: .value("Day", element.date),
                        y: .value("Hookah ≈ Cigs", element.equivalentCigarettes),
                        width: 6
                    )
                    .cornerRadius(4)
                    .foregroundStyle(by: .value("Type", "Hookah"))
                    .position(by: .value("Type", "Hookah"))
                }
            }
        }
        .chartForegroundStyleScale(chartColorScale)
        .chartScrollableAxes(.horizontal)
        .chartXAxis(.hidden)
        .chartXVisibleDomain(length: 3600 * 24 * 10)
        .defaultScrollAnchor(.topTrailing)
        .chartLegend(showHookahInChart ? .visible : .hidden)
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
