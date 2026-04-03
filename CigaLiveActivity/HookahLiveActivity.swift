import ActivityKit
import WidgetKit
import SwiftUI

struct HookahLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HookahActivityAttributes.self) { context in
            lockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "smoke")
                        .font(.title2)
                        .foregroundColor(.purple)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text("Hookah")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(timerInterval: context.state.startDate...Date.distantFuture,
                             countsDown: false, showsHours: true)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .monospacedDigit()
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Image(systemName: "circle.fill")
                        .font(.caption2)
                        .foregroundColor(.purple)
                        .opacity(context.state.isActive ? 1 : 0.3)
                }
            } compactLeading: {
                Image(systemName: "smoke")
                    .foregroundColor(.purple)
            } compactTrailing: {
                Text(timerInterval: context.state.startDate...Date.distantFuture,
                     countsDown: false)
                    .monospacedDigit()
                    .frame(width: 50)
                    .foregroundColor(.purple)
            } minimal: {
                Image(systemName: "smoke")
                    .foregroundColor(.purple)
            }
        }
        .supplementalActivityFamilies([.small, .medium])
    }

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<HookahActivityAttributes>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "smoke")
                .font(.title2)
                .foregroundColor(.purple)

            VStack(alignment: .leading, spacing: 2) {
                Text("Hookah")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(timerInterval: context.state.startDate...Date.distantFuture,
                     countsDown: false, showsHours: true)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }

            Spacer()

            if context.state.isActive {
                Circle()
                    .fill(.purple)
                    .frame(width: 10, height: 10)
            }
        }
        .padding()
        .activityBackgroundTint(.black.opacity(0.7))
    }
}
