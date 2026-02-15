//
//  SettingsView.swift
//  Ciga Watch App
//
//  Created by Aleksandr Tsygankov on 4/30/23.
//

import SwiftUI

struct SettingsView: View {
    @Binding var showInhales: Bool
    @Binding var showHookahInChart: Bool
    @State private var arcPeriodHours: Double

    init(showInhales: Binding<Bool>, showHookahInChart: Binding<Bool>) {
        self._showInhales = showInhales
        self._showHookahInChart = showHookahInChart
        // Initialize arcPeriodHours from UserDefaults
        let savedPeriod = AppGroupConstants.sharedUserDefaults.double(forKey: AppGroupConstants.arcPeriodHoursKey)
        self._arcPeriodHours = State(initialValue: savedPeriod > 0 ? savedPeriod : AppGroupConstants.defaultArcPeriodHours)
    }

    var body: some View {
        List {
            Section {
                Toggle("Show as Inhales", isOn: $showInhales)
                Text(showInhales ?
                     "Shows total inhales (8 per cigarette)" :
                     "Shows equivalent cigarettes (1 cig = 8 inhales)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } header: {
                Text("Display Mode")
            } footer: {
                Text("This setting only changes how counts are displayed. Tracking remains the same.")
                    .font(.footnote)
            }

            Section {
                Toggle("Hookah in Chart", isOn: $showHookahInChart)
                    .onChange(of: showHookahInChart) { _, newValue in
                        AppGroupConstants.sharedUserDefaults.set(newValue, forKey: AppGroupConstants.showHookahInChartKey)
                    }
                Text("Shows hookah equivalent cigarettes as a separate bar series in the daily chart.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } header: {
                Text("Hookah")
            }

            Section {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Arc Period: ")
                        Text("\(Int(arcPeriodHours)) hours")
                            .bold()
                    }
                    Slider(value: $arcPeriodHours, in: 1...24, step: 1) { _ in
                        // Save the new value to UserDefaults
                        AppGroupConstants.sharedUserDefaults.set(arcPeriodHours, forKey: AppGroupConstants.arcPeriodHoursKey)
                    }
                }
            } header: {
                Text("Complication Settings")
            } footer: {
                Text("The arc in the corner complication completes one full circle after this many hours.")
                    .font(.footnote)
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView(showInhales: .constant(true), showHookahInChart: .constant(false))
}
