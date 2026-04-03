import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct iOSSettingsView: View {
    @Binding var showInhales: Bool
    @Binding var showHookahInChart: Bool
    @State private var arcPeriodHours: Double
    @Query private var inhales: [Inhale]
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var phoneSession: PhoneSessionManager
    @State private var showShareSheet = false
    @State private var exportURL: URL?
    @State private var showFileImporter = false
    @State private var importResult: String?

    init(showInhales: Binding<Bool>, showHookahInChart: Binding<Bool>) {
        self._showInhales = showInhales
        self._showHookahInChart = showHookahInChart
        let savedPeriod = AppGroupConstants.sharedUserDefaults.double(forKey: AppGroupConstants.arcPeriodHoursKey)
        self._arcPeriodHours = State(initialValue: savedPeriod > 0 ? savedPeriod : AppGroupConstants.defaultArcPeriodHours)
    }

    var body: some View {
        Form {
            Section {
                Toggle("Show as Inhales", isOn: $showInhales)
                Text(showInhales
                     ? "Shows total inhales (8 per cigarette)"
                     : "Shows equivalent cigarettes (1 cig = 8 inhales)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } header: {
                Text("Display Mode")
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
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Arc Period:")
                        Text("\(Int(arcPeriodHours)) hours")
                            .bold()
                    }
                    Slider(value: $arcPeriodHours, in: 1...24, step: 1) { _ in
                        AppGroupConstants.sharedUserDefaults.set(arcPeriodHours, forKey: AppGroupConstants.arcPeriodHoursKey)
                    }
                }
            } header: {
                Text("Watch Complication")
            } footer: {
                Text("The arc in the corner complication completes one full circle after this many hours.")
            }

            Section {
                Button {
                    exportData()
                } label: {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }

                Text("\(inhales.count) records")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            } header: {
                Text("Data Export")
            } footer: {
                Text("Export all records as a JSON file for importing into another app.")
            }

            Section {
                Button {
                    showFileImporter = true
                } label: {
                    Label("Import Data", systemImage: "square.and.arrow.down")
                }

                if let result = importResult {
                    Text(result)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Data Import")
            } footer: {
                Text("Import records from a previously exported JSON file.")
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ActivityView(activityItems: [url])
            }
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.json]) { result in
            handleFileImport(result)
        }
        .onChange(of: phoneSession.receivedExportURL) { _, url in
            guard let url else { return }
            exportURL = url
            showShareSheet = true
            phoneSession.receivedExportURL = nil
        }
    }

    private func exportData() {
        do {
            let data = try DataExporter.createExportData(from: inhales)
            exportURL = try DataExporter.writeToTemporaryFile(data)
            showShareSheet = true
        } catch {
            // Silently fail — the button simply won't present a sheet
        }
    }

    private func handleFileImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                importResult = "Cannot access file."
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let data = try Data(contentsOf: url)
                let count = try DataExporter.importRecords(from: data, into: modelContext)
                importResult = "Imported \(count) new records."
            } catch {
                importResult = "Import failed: \(error.localizedDescription)"
            }
        case .failure(let error):
            importResult = "Could not open file: \(error.localizedDescription)"
        }
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
