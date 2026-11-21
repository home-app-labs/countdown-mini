import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Per-widget configuration
//
// Events are chosen by name from a plain list of strings. An AppEntity parameter would be
// the usual way, but with ad hoc signing the system does not register the entity type and
// hands the widget an empty value. Renamed events are still found through their aliases.

struct EventOptions: DynamicOptionsProvider {
    func results() async throws -> [String] {
        let events = EventStore.load() ?? []
        return events.map { events.label(for: $0) }
    }
}

struct ChooseEventsIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Events"
    static var description = IntentDescription(
        "The small widget shows event 1, the medium one events 1 and 2, the large one all three.")

    @Parameter(title: "Event 1", optionsProvider: EventOptions())
    var first: String?

    @Parameter(title: "Event 2 (medium, large)", optionsProvider: EventOptions())
    var second: String?

    @Parameter(title: "Event 3 (large)", optionsProvider: EventOptions())
    var third: String?
}

// MARK: - Timeline

struct CountdownEntry: TimelineEntry {
    let date: Date
    let slots: [WidgetSlot]
}

struct CountdownProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(date: Date(), slots: [.event(.placeholder)])
    }

    func snapshot(for configuration: ChooseEventsIntent, in context: Context) async -> CountdownEntry {
        CountdownEntry(date: Date(), slots: slots(for: configuration, in: context))
    }

    func timeline(for configuration: ChooseEventsIntent, in context: Context) async -> Timeline<CountdownEntry> {
        let slots = slots(for: configuration, in: context)
        let now = Date()
        // Every moment at which any of the events changes what it shows.
        let dates = Set(slots.compactMap(\.event).flatMap { $0.refreshDates(from: now) } + [now]).sorted()
        return Timeline(entries: dates.map { CountdownEntry(date: $0, slots: slots) }, policy: .atEnd)
    }

    private func slots(for configuration: ChooseEventsIntent, in context: Context) -> [WidgetSlot] {
        let chosen = [configuration.first, configuration.second, configuration.third]
        return (EventStore.load() ?? []).slots(for: Array(chosen.prefix(context.family.capacity)))
    }
}

private extension WidgetFamily {
    /// How many events the size holds.
    var capacity: Int {
        switch self {
        case .systemMedium: 2
        case .systemLarge, .systemExtraLarge: 3
        default: 1
        }
    }
}

// MARK: - Widget

private struct CountdownWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CountdownEntry

    var body: some View {
        WidgetFace(slots: entry.slots, now: entry.date, capacity: family.capacity)
            .containerBackground(for: .widget) {
                WidgetBackdrop(slots: entry.slots, capacity: family.capacity)
            }
            // A click opens the app on the widget's first event.
            .widgetURL(entry.slots.compactMap(\.event).first?.url ?? CountdownEvent.appURL)
    }
}

@main
struct CountdownMiniWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "CountdownMiniList", intent: ChooseEventsIntent.self, provider: CountdownProvider()
        ) { entry in
            CountdownWidgetView(entry: entry)
        }
        .configurationDisplayName("Countdown Widget")
        .description("Small shows one event, medium two, large three. Right-click the widget to choose them.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
