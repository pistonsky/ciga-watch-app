import SwiftUI
import SwiftData

struct CigaTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
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
                iOSTrackerView(inhales: inhales, showInhales: showInhales)
            }
            .tabItem {
                Label("Tracker", systemImage: "flame")
            }

            NavigationStack {
                iOSHookahTrackerView(inhales: inhales)
            }
            .tabItem {
                Label("Hookah", systemImage: "smoke")
            }

            NavigationStack {
                iOSStatsView(inhales: inhales)
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }

            NavigationStack {
                iOSChartView(inhales: inhales, showInhales: showInhales, showHookahInChart: showHookahInChart)
            }
            .tabItem {
                Label("Chart", systemImage: "chart.xyaxis.line")
            }

            NavigationStack {
                iOSSettingsView(showInhales: $showInhales, showHookahInChart: $showHookahInChart)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .onAppear {
            enforceSessionCap()
            reconcileLiveActivity()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            enforceSessionCap()
            reconcileLiveActivity()
        }
        .onChange(of: activeHookahStartDate) { _, _ in
            guard scenePhase == .active else { return }
            enforceSessionCap()
            reconcileLiveActivity()
        }
    }

    private var activeHookahStartDate: Date? {
        inhales.first(where: { $0.isActiveHookahSession })?.smokeDate
    }

    private func reconcileLiveActivity() {
        if let startDate = activeHookahStartDate {
            LiveActivityManager.startActivity(startDate: startDate)
        } else {
            LiveActivityManager.endActivity()
        }
    }

    /// Force-end any active hookah session that has exceeded the 3h hard cap.
    /// This protects against runaway sessions (crashes, missed sync, user forgot to end).
    private func enforceSessionCap() {
        guard let active = inhales.first(where: { $0.isActiveHookahSession }),
              active.exceedsMaxDuration else { return }
        active.forceEndAtCap(defaultIntensity: 5)
        if let endAt = active.endAt, let intensity = active.intensity {
            PhoneSessionManager.shared.sendEndHookah(date: endAt, intensity: intensity)
        }
        LiveActivityManager.endActivity()
    }
}
