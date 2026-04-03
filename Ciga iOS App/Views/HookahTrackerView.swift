import SwiftUI
import SwiftData
import ActivityKit
import UserNotifications

struct iOSHookahTrackerView: View {
    var inhales: [Inhale]

    @Environment(\.modelContext) private var modelContext
    @State private var showIntensityPicker = false
    @State private var selectedIntensity: Double = 5

    private var activeSession: Inhale? {
        inhales.first(where: { $0.isActiveHookahSession })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let session = activeSession {
                    activeSessionView(session: session)
                } else {
                    idleView
                }
            }
            .padding()
        }
        .navigationTitle("Hookah")
        .sheet(isPresented: $showIntensityPicker) {
            intensityPickerSheet
        }
    }

    // MARK: - Idle State

    private var idleView: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)

            Image(systemName: "smoke")
                .font(.system(size: 64))
                .foregroundColor(.secondary)

            Text("No active session")
                .font(.title3)
                .foregroundColor(.secondary)

            Button {
                startSession()
            } label: {
                Label("Start Session", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.purple)
            .controlSize(.large)
            .padding(.horizontal, 24)

            let hookahSessions = inhales.filter { $0.isHookahSession && !$0.isActiveHookahSession }
            if !hookahSessions.isEmpty {
                Divider()
                VStack(spacing: 8) {
                    let streak = StatsEngine.hookahFreeStreak(inhales: inhales)
                    HStack {
                        Text("Hookah-free")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(StatsEngine.formatStreak(streak))
                            .fontWeight(.semibold)
                            .foregroundColor(.purple)
                    }

                    let sessionsCount = StatsEngine.hookahSessionsThisMonth(inhales: inhales)
                    HStack {
                        Text("This month")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(sessionsCount) sessions")
                            .fontWeight(.semibold)
                            .foregroundColor(.purple)
                    }
                }
                .font(.subheadline)
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Active Session

    private func activeSessionView(session: Inhale) -> some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 40)

            Text("SESSION ACTIVE")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.purple)
                .tracking(2)

            Text(timerInterval: session.smokeDate...session.smokeDate.addingTimeInterval(86400),
                 countsDown: false, showsHours: true)
                .font(.system(size: 56, weight: .medium, design: .monospaced))
                .foregroundColor(.purple)
                .monospacedDigit()

            Text("Started \(session.smokeDate, style: .time)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button {
                selectedIntensity = 5
                showIntensityPicker = true
            } label: {
                Label("End Session", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .controlSize(.large)
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Intensity Picker

    private var intensityPickerSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Text("Session Intensity")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("\(Int(selectedIntensity))")
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundColor(intensityColor)

                Slider(value: $selectedIntensity, in: 1...10, step: 1)
                    .tint(intensityColor)
                    .padding(.horizontal, 32)

                HStack {
                    Text("Light")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Heavy")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 32)

                Spacer()

                Button("Done") {
                    endSession()
                    showIntensityPicker = false
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .controlSize(.large)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
        }
        .presentationDetents([.medium])
    }

    private var intensityColor: Color {
        let t = (selectedIntensity - 1) / 9.0
        if t < 0.5 {
            return .green
        } else if t < 0.75 {
            return .yellow
        } else {
            return .red
        }
    }

    // MARK: - Actions

    private func startSession() {
        if let startDate = try? HookahSessionService.startSession() {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            scheduleSessionReminders(from: startDate)
        }
    }

    private func endSession() {
        guard let session = activeSession else { return }
        let intensity = Int(selectedIntensity)
        session.endHookahSession(intensity: intensity)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        cancelSessionReminders()
        PhoneSessionManager.shared.sendEndHookah(date: Date(), intensity: intensity)
        LiveActivityManager.endActivity()
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
