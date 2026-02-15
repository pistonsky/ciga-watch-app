//
//  ContentView.swift
//  Ciga Watch App
//
//  Created by Aleksandr Tsygankov on 4/30/23.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var inhales: [Inhale]
    @State private var showInhales = true
    @State private var showHookahInChart: Bool

    init() {
        let saved = AppGroupConstants.sharedUserDefaults.bool(forKey: AppGroupConstants.showHookahInChartKey)
        _showHookahInChart = State(initialValue: saved)
    }

    var body: some View {
        TabView {
            NavigationStack {
                TrackerView(inhales: inhales, showInhales: showInhales)
            }
            NavigationStack {
                HookahTrackerView(inhales: inhales)
            }
            NavigationStack {
                StatsView(inhales: inhales)
            }
            NavigationStack {
                ChartView(inhales: inhales, showInhales: showInhales, showHookahInChart: showHookahInChart)
            }
            NavigationStack {
                ComparisonChartView(inhales: inhales, showInhales: showInhales)
            }
            NavigationStack {
                SettingsView(showInhales: $showInhales, showHookahInChart: $showHookahInChart)
            }
        }.tabViewStyle(.page)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(InhaleRecordModel.init())
    }
}
