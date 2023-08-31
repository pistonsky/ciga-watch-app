//
//  Complications.swift
//  Complications
//
//  Created by Aleksandr Tsygankov on 5/3/23.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    @EnvironmentObject private var model: InhaleRecordModel

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), inhales: 37, configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), inhales: 37, configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, inhales: 37, configuration: configuration)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    func recommendations() -> [IntentRecommendation<ConfigurationIntent>] {
        return [
            IntentRecommendation(intent: ConfigurationIntent(), description: "Ciga Puffs")
        ]
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let inhales: UInt32
    let configuration: ConfigurationIntent
}

struct ComplicationsEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        CornerView(entry: entry)
    }
}

struct CornerView: View {
    var entry: Provider.Entry

    @EnvironmentObject private var model: InhaleRecordModel
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image(systemName: "wind")
                .font(.title.bold())
                .widgetAccentable()
        }
        .widgetLabel {
            Gauge(value: Float(entry.inhales), in: 0...140) {
                Text("PUFFS")
            } currentValueLabel: {
                Text("\(Int(entry.inhales))")
            } minimumValueLabel: {
                Text("0")
            } maximumValueLabel: {
                Text("140")
            }
        }
    }
}

@main
struct ComplicationsWidget: Widget {
    let kind: String = "Ciga Puffs"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            ComplicationsEntryView(entry: entry)
        }
        .configurationDisplayName("Ciga Puffs")
        .description("See how many you smoked today so far")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline, .accessoryCorner])
    }
}

struct Complications_Previews: PreviewProvider {
    static var previews: some View {
        ComplicationsEntryView(entry: SimpleEntry(date: Date(), inhales: 37, configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
    }
}
