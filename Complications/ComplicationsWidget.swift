//
//  Complications.swift
//  Complications
//
//  Created by Aleksandr Tsygankov on 5/3/23.
//

import WidgetKit
import SwiftUI
import Intents

// Force early access to shared UserDefaults to properly initialize container
private let _ensureContainerAccess = AppGroupConstants.sharedUserDefaults

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), lastSmokeDate: Date().addingTimeInterval(-3600), configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let lastSmokeDate = getLastSmokeDate() ?? Date().addingTimeInterval(-3600)
        let entry = SimpleEntry(date: Date(), lastSmokeDate: lastSmokeDate, configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        let lastSmokeDate = getLastSmokeDate() ?? Date().addingTimeInterval(-3600)
        
        // Generate a timeline with entries every minute
        let currentDate = Date()
        let calendar = Calendar.current
        for minuteOffset in stride(from: 0, to: 30, by: 1) {
            let entryDate = calendar.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, lastSmokeDate: lastSmokeDate, configuration: configuration)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private func getLastSmokeDate() -> Date? {
        return AppGroupConstants.sharedUserDefaults.object(forKey: AppGroupConstants.lastSmokeDateKey) as? Date
    }

    func recommendations() -> [IntentRecommendation<ConfigurationIntent>] {
        return [
            IntentRecommendation(intent: ConfigurationIntent(), description: "Ciga Timer")
        ]
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let lastSmokeDate: Date
    let configuration: ConfigurationIntent
    
    var elapsedTimeInterval: TimeInterval {
        return date.timeIntervalSince(lastSmokeDate)
    }
    
    var formattedElapsedTime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: elapsedTimeInterval) ?? "00:00:00"
    }
}

struct ComplicationsEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularView(entry: entry)
        case .accessoryCorner:
            CornerView(entry: entry)
        case .accessoryRectangular:
            RectangularView(entry: entry)
        case .accessoryInline:
            InlineView(entry: entry)
        default:
            CircularView(entry: entry)
        }
    }
}

struct CircularView: View {
    var entry: Provider.Entry
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.accentColor.opacity(0.3),
                    lineWidth: 4
                )
            Circle()
                .trim(from: 0, to: min(1.0, CGFloat(entry.elapsedTimeInterval / (24*3600))))
                .stroke(
                    Color.accentColor,
                    style: StrokeStyle(
                        lineWidth: 4,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
            
            Text(entry.formattedElapsedTime)
                .font(.system(size: 10))
                .monospacedDigit()
                .minimumScaleFactor(0.6)
        }
    }
}

struct CornerView: View {
    var entry: Provider.Entry
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "wind")
                .font(.title.bold())
        }
        .widgetLabel {
            // Use the proper structure as shown in WWDC 22
            Gauge(value: min(entry.elapsedTimeInterval, getArcPeriodSeconds()),
                  in: 0...getArcPeriodSeconds()) {
                // Label with icon representing cigarettes
                // Image(systemName: "clock.arrow.2.circlepath")
                //     .font(.title.bold())
            } currentValueLabel: {
                // Format the value appropriately
                if entry.elapsedTimeInterval >= 3600 {
                    Text("\(Int(entry.elapsedTimeInterval / 3600))h")
                        .monospacedDigit()
                } else {
                    Text("\(max(1, Int(entry.elapsedTimeInterval / 60)))m")
                        .monospacedDigit()
                }
            } minimumValueLabel: {
                Text("0")
            } maximumValueLabel: {
                // Show the configured maximum
                Text("\(Int(getArcPeriodSeconds() / 3600))")
            }
            .gaugeStyle(.accessoryLinearCapacity)
            .tint(Gradient(colors: [.orange, .orange.opacity(0.5)]))
        }
    }
    
    // Get arc period in seconds from settings
    private func getArcPeriodSeconds() -> TimeInterval {
        let hours = AppGroupConstants.sharedUserDefaults.double(forKey: AppGroupConstants.arcPeriodHoursKey)
        return hours > 0 ? hours * 3600 : AppGroupConstants.defaultArcPeriodHours * 3600
    }
}

struct RectangularView: View {
    var entry: Provider.Entry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "clock.arrow.2.circlepath")
                    .font(.caption)
                Text("Since last cigarette")
                    .font(.caption)
                    .lineLimit(1)
            }
            Text(entry.formattedElapsedTime)
                .font(.system(.title3, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundColor(.accentColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
    }
}

struct InlineView: View {
    var entry: Provider.Entry
    
    var body: some View {
        Text("Since last: \(entry.formattedElapsedTime)")
    }
}

@main
struct ComplicationsWidget: Widget {
    let kind: String = "Ciga Timer"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            ComplicationsEntryView(entry: entry)
        }
        .configurationDisplayName("Ciga Timer")
        .description("Shows time since your last cigarette")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

struct Complications_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ComplicationsEntryView(entry: SimpleEntry(date: Date(), lastSmokeDate: Date().addingTimeInterval(-3600), configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .accessoryCircular))
            
            ComplicationsEntryView(entry: SimpleEntry(date: Date(), lastSmokeDate: Date().addingTimeInterval(-3600), configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
            
            ComplicationsEntryView(entry: SimpleEntry(date: Date(), lastSmokeDate: Date().addingTimeInterval(-3600), configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .accessoryInline))
            
            ComplicationsEntryView(entry: SimpleEntry(date: Date(), lastSmokeDate: Date().addingTimeInterval(-3600), configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .accessoryCorner))
        }
    }
}
