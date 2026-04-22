//
//  HookahTrackerView.swift
//  Ciga Watch App
//
//  Hookah session management: start, track duration, end with intensity.
//

import SwiftUI
import SwiftData
import UserNotifications

struct HookahTrackerView: View {
    var inhales: [Inhale]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @State private var showIntensityPicker = false
    @State private var selectedIntensity: Double = 5

    private var activeSession: Inhale? {
        inhales.first(where: { $0.isActiveHookahSession })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if let session = activeSession {
                    activeSessionView(session: session)
                } else {
                    idleView
                }
            }
            .padding(.horizontal, 8)
        }
        .navigationTitle("Hookah")
        .sheet(isPresented: $showIntensityPicker) {
            intensityPickerSheet
        }
        .onAppear {
            enforceSessionCap()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            enforceSessionCap()
        }
    }

    /// Force-end any active hookah session that has exceeded the 3h hard cap.
    private func enforceSessionCap() {
        guard let active = activeSession, active.exceedsMaxDuration else { return }
        active.forceEndAtCap(defaultIntensity: 5)
        cancelSessionReminders()
        if let endAt = active.endAt, let intensity = active.intensity {
            WatchSessionManager.shared.sendEndHookah(date: endAt, intensity: intensity)
        }
    }

    // MARK: - Idle State (no active session)

    private var idleView: some View {
        VStack(spacing: 16) {
            Image(systemName: "smoke")
                .font(.system(size: 36))
                .foregroundColor(.secondary)
                .padding(.top, 8)

            Text("No active session")
                .font(.caption)
                .foregroundColor(.secondary)

            Button {
                let session = Inhale(hookahSession: true)
                modelContext.insert(session)
                scheduleSessionReminders(from: session.smokeDate)
                WKInterfaceDevice.current().play(.start)
                WatchSessionManager.shared.sendStartHookah(date: session.smokeDate)
            } label: {
                Label("Start Session", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)

            // Quick stats
            let hookahSessions = inhales.filter { $0.isHookahSession && !$0.isActiveHookahSession }
            if !hookahSessions.isEmpty {
                Divider()
                VStack(spacing: 4) {
                    let streak = StatsEngine.hookahFreeStreak(inhales: inhales)
                    HStack {
                        Text("Hookah-free")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(StatsEngine.formatStreak(streak))
                            .font(.caption2)
                            .foregroundColor(.purple)
                    }

                    let sessionsCount = StatsEngine.hookahSessionsThisMonth(inhales: inhales)
                    HStack {
                        Text("This month")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(sessionsCount) sessions")
                            .font(.caption2)
                            .foregroundColor(.purple)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Active Session View

    private func activeSessionView(session: Inhale) -> some View {
        VStack(spacing: 12) {
            // Live timer
            Text("Session Active")
                .font(.caption)
                .foregroundColor(.purple)
                .textCase(.uppercase)

            // Timer showing elapsed time since session start
            Text(timerInterval: session.smokeDate...session.smokeDate.addingTimeInterval(86400),
                 countsDown: false,
                 showsHours: true)
                .font(.system(.title2, design: .monospaced))
                .foregroundColor(.purple)
                .monospacedDigit()

            Text("Started \(session.smokeDate, style: .time)")
                .font(.caption2)
                .foregroundColor(.secondary)

            Button {
                selectedIntensity = 5
                showIntensityPicker = true
            } label: {
                Label("End Session", systemImage: "stop.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }

    // MARK: - Intensity Picker Sheet

    private var intensityPickerSheet: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Session Intensity")
                    .font(.headline)

                Text("\(Int(selectedIntensity))")
                    .font(.system(.largeTitle, design: .rounded))
                    .foregroundColor(intensityColor)
                    .fontWeight(.bold)

                Slider(value: $selectedIntensity, in: 1...10, step: 1)
                    .tint(intensityColor)

                HStack {
                    Text("Light")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Heavy")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Button("Done") {
                    if let session = activeSession {
                        let intensity = Int(selectedIntensity)
                        session.endHookahSession(intensity: intensity)
                        cancelSessionReminders()
                        WKInterfaceDevice.current().play(.stop)
                        WatchSessionManager.shared.sendEndHookah(date: Date(), intensity: intensity)
                    }
                    showIntensityPicker = false
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
            }
            .padding(.horizontal, 8)
        }
    }

    private var intensityColor: Color {
        let t = (selectedIntensity - 1) / 9.0 // 0..1
        if t < 0.5 {
            return .green
        } else if t < 0.75 {
            return .yellow
        } else {
            return .red
        }
    }

    // MARK: - Session Reminders

    private static let reminderCategory = "hookahSessionReminder"
    private static let reminderMinutes = [60, 90, 120, 150, 180, 210, 240]

    private func scheduleSessionReminders(from startTime: Date) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }

        for minutes in Self.reminderMinutes {
            let hours = minutes / 60
            let mins = minutes % 60
            let label = mins > 0 ? "\(hours)h \(mins)m" : "\(hours)h"

            let content = UNMutableNotificationContent()
            content.title = "Hookah session active"
            content.body = "Your session has been running for \(label). Forgot to stop?"
            content.sound = .default
            content.categoryIdentifier = Self.reminderCategory

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: TimeInterval(minutes * 60),
                repeats: false
            )
            let request = UNNotificationRequest(
                identifier: "\(Self.reminderCategory)_\(minutes)m",
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    private func cancelSessionReminders() {
        let ids = Self.reminderMinutes.map { "\(Self.reminderCategory)_\($0)m" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }
}
