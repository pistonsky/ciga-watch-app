import ActivityKit
import AppIntents
import SwiftData
import Foundation
import OSLog

private let logger = Logger(subsystem: "com.pistonsky.Ciga", category: "LiveActivity")

enum LiveActivityManager {

    @MainActor
    static func startActivity(startDate: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            logger.warning("Live Activities are not enabled")
            return
        }

        let attributes = HookahActivityAttributes()
        let state = HookahActivityAttributes.ContentState(startDate: startDate, isActive: true)

        if let existing = Activity<HookahActivityAttributes>.activities.first {
            if existing.content.state.startDate == startDate && existing.content.state.isActive {
                logger.info("Live Activity already active for this session")
                return
            }

            Task {
                await existing.end(nil, dismissalPolicy: .immediate)
            }
        }

        do {
            let _ = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            logger.info("Live Activity started for hookah session")
        } catch {
            logger.error("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }

    @MainActor
    static func endActivity() {
        let finalState = HookahActivityAttributes.ContentState(startDate: Date(), isActive: false)

        for activity in Activity<HookahActivityAttributes>.activities {
            Task {
                await activity.end(
                    .init(state: finalState, staleDate: nil),
                    dismissalPolicy: .default
                )
            }
        }
        logger.info("Live Activity ended")
    }
}

@MainActor
enum HookahSessionService {
    static var modelContainer: ModelContainer?

    static func startSession(startDate: Date = Date()) throws -> Date? {
        guard let context = modelContainer?.mainContext else {
            logger.error("No model container configured for HookahSessionService")
            return nil
        }

        let descriptor = FetchDescriptor<Inhale>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.first(where: { $0.isActiveHookahSession }) == nil else {
            logger.info("Hookah session already active, skipping new start")
            return nil
        }

        let session = Inhale(hookahSession: true, date: startDate)
        context.insert(session)
        PhoneSessionManager.shared.sendStartHookah(date: session.smokeDate)
        LiveActivityManager.startActivity(startDate: session.smokeDate)
        logger.info("Started hookah session from shared service")
        return session.smokeDate
    }
}

struct StartHookahSessionIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Start Hookah Session"
    static var openAppWhenRun = false

    func perform() async throws -> some ProvidesDialog {
        let startedAt = await MainActor.run {
            try? HookahSessionService.startSession()
        }

        if startedAt != nil {
            return .result(dialog: "Started a hookah session.")
        } else {
            return .result(dialog: "A hookah session is already running.")
        }
    }
}

struct EndHookahSessionIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "End Hookah Session"
    static var openAppWhenRun = false

    func perform() async throws -> some ProvidesDialog {
        await MainActor.run {
            LiveActivityManager.endActivity()
        }
        return .result(dialog: "Ended the hookah Live Activity.")
    }
}

struct CigaAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartHookahSessionIntent(),
            phrases: [
                "Start hookah in \(.applicationName)",
                "Start a hookah session in \(.applicationName)",
                "Start hookah with \(.applicationName)",
                "Start a hookah session with \(.applicationName)",
            ],
            shortTitle: "Start Hookah",
            systemImageName: "smoke"
        )
        AppShortcut(
            intent: EndHookahSessionIntent(),
            phrases: [
                "End hookah in \(.applicationName)",
                "End a hookah session in \(.applicationName)",
                "End hookah with \(.applicationName)",
                "End a hookah session with \(.applicationName)",
            ],
            shortTitle: "End Hookah",
            systemImageName: "stop.circle"
        )
    }
}
