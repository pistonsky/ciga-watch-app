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
    
    var body: some View {
        TabView {
            NavigationStack {
                TrackerView(inhales: inhales, showInhales: showInhales)
            }
            NavigationStack {
                ChartView(inhales: inhales, showInhales: showInhales)
            }
            NavigationStack {
                ComparisonChartView(inhales: inhales, showInhales: showInhales)
            }
            NavigationStack {
                SettingsView(showInhales: $showInhales)
            }
        }.tabViewStyle(.page)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(InhaleRecordModel.init())
    }
}
