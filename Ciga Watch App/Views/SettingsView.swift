//
//  SettingsView.swift
//  Ciga Watch App
//
//  Created by Aleksandr Tsygankov on 4/30/23.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Binding var showInhales: Bool
    @Binding var showHookahInChart: Bool
    @State private var arcPeriodHours: Double
    @Query private var inhales: [Inhale]
    @ObservedObject private var watchSession = WatchSessionManager.shared
    @State private var isExporting = false
    @State private var exportDone = false
    @State private var exportError: String?
    @State private var isImporting = false
    @State private var importDone = false
    @State private var importMessage: String?

    init(showInhales: Binding<Bool>, showHookahInChart: Binding<Bool>) {
        self._showInhales = showInhales
        self._showHookahInChart = showHookahInChart
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
                        AppGroupConstants.sharedUserDefaults.set(arcPeriodHours, forKey: AppGroupConstants.arcPeriodHoursKey)
                    }
                }
            } header: {
                Text("Complication Settings")
            } footer: {
                Text("The arc in the corner complication completes one full circle after this many hours.")
                    .font(.footnote)
            }

            Section {
                Button {
                    exportToiPhone()
                } label: {
                    HStack {
                        Text("Export to iPhone")
                        Spacer()
                        if isExporting {
                            ProgressView()
                        } else if exportDone {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
                .disabled(isExporting)
            } header: {
                Text("Data Export")
            } footer: {
                if exportDone {
                    Text("Sent to iPhone. Open Ciga on iPhone to save the file.")
                        .font(.footnote)
                } else if let error = exportError {
                    Text(error)
                        .font(.footnote)
                        .foregroundColor(.red)
                } else {
                    Text("Exports all \(inhales.count) records as JSON to your iPhone.")
                        .font(.footnote)
                }
            }

            Section {
                Button {
                    importFromiPhone()
                } label: {
                    HStack {
                        Text("Import from iPhone")
                        Spacer()
                        if isImporting {
                            ProgressView()
                        } else if importDone {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                        }
                    }
                }
                .disabled(isImporting)
            } header: {
                Text("Data Import")
            } footer: {
                if let message = importMessage {
                    Text(message)
                        .font(.footnote)
                } else {
                    Text("Imports records from iPhone's database into this Watch.")
                        .font(.footnote)
                }
            }
        }
        .navigationTitle("Settings")
        .onChange(of: watchSession.importedRecordCount) { _, count in
            guard let count else { return }
            isImporting = false
            importDone = true
            importMessage = "Imported \(count) new records from iPhone."
            watchSession.importedRecordCount = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                importDone = false
                importMessage = nil
            }
        }
    }

    private func importFromiPhone() {
        isImporting = true
        importDone = false
        importMessage = nil
        WatchSessionManager.shared.requestImportFromiPhone()
    }

    private func exportToiPhone() {
        isExporting = true
        exportDone = false
        exportError = nil

        do {
            let data = try DataExporter.createExportData(from: inhales)
            let url = try DataExporter.writeToTemporaryFile(data)
            WatchSessionManager.shared.sendExportFile(url: url)
            isExporting = false
            exportDone = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                exportDone = false
            }
        } catch {
            isExporting = false
            exportError = "Export failed: \(error.localizedDescription)"
        }
    }
}

#Preview {
    SettingsView(showInhales: .constant(true), showHookahInChart: .constant(false))
}
