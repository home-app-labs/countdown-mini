import SwiftUI

/// A whole widget: one event (small), two side by side (medium) or three lines (large).
/// Drawn by the widget extension; kept here so it can be rendered outside a widget too.
struct WidgetFace: View {
    let slots: [WidgetSlot]
    let now: Date
    /// How many events this size holds: 1, 2 or 3.
    let capacity: Int

    private var shown: [WidgetSlot] { Array(slots.prefix(capacity)) }

    var body: some View {
        if shown.isEmpty {
            Notice(symbol: "calendar.badge.plus", title: "No events", detail: "Add one in Countdown Mini")
        } else if capacity == 1 {
            switch shown[0] {
            case .event(let event): CountdownCard(event: event, now: now).padding(16)
            case .deleted: DeletedNotice()
            }
        } else if capacity == 2 {
            // Two halves of one block: they fill the widget and meet in a straight line.
            HStack(spacing: 0) {
                ForEach(Array(shown.enumerated()), id: \.offset) { _, slot in
                    switch slot {
                    case .event(let event):
                        CountdownCard(event: event, now: now)
                            .padding(16)
                    case .deleted:
                        DeletedNotice()
                    }
                }
            }
        } else {
            // Up to three bands joined into one block that always fills the widget:
            // three compact lines, two tall bands, or one event on the whole widget.
            VStack(spacing: 0) {
                ForEach(Array(shown.enumerated()), id: \.offset) { _, slot in
                    switch slot {
                    case .event(let event):
                        switch shown.count {
                        case 1: CountdownBand(event: event, now: now, badge: 44, title: 22, number: 120)
                        case 2: CountdownBand(event: event, now: now, badge: 32, title: 17, number: 62)
                        default: CountdownRow(event: event, now: now)
                        }
                    case .deleted:
                        DeletedNotice()
                    }
                }
            }
        }
    }
}

/// What fills the widget behind its face: each event's background under its own part,
/// split the same way as the face (side by side for two places, stacked for three).
/// It is the widget's container background rather than part of the face because the
/// desktop fades widgets while a window is in front and keeps only that background.
struct WidgetBackdrop: View {
    let slots: [WidgetSlot]
    let capacity: Int

    var body: some View {
        let shown = Array(slots.prefix(capacity))
        if shown.isEmpty {
            Rectangle().fill(.fill.tertiary)
        } else {
            let layout = capacity == 2 ? AnyLayout(HStackLayout(spacing: 0)) : AnyLayout(VStackLayout(spacing: 0))
            layout {
                ForEach(Array(shown.enumerated()), id: \.offset) { _, slot in
                    switch slot {
                    case .event(let event): CardBackground(event: event)
                    case .deleted: Rectangle().fill(.fill.tertiary)
                    }
                }
            }
        }
    }
}

/// Shown in place of an event that was deleted in the app.
struct DeletedNotice: View {
    var body: some View {
        Notice(symbol: "trash.slash", title: "Event deleted", detail: "Edit Widget to choose another")
    }
}

struct Notice: View {
    let symbol: String
    let title: String
    let detail: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: symbol).font(.system(size: 20, weight: .medium))
            Text(title).font(.system(size: 13, weight: .semibold, design: .rounded))
            Text(detail).font(.system(size: 10, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.secondary)
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// The countdown face for one event, without a background.
struct CountdownCard: View {
    let event: CountdownEvent
    let now: Date

    private var state: CountdownState { event.state(at: now) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 7) {
                IconBadge(symbol: event.symbol, size: 22)
                Text(event.displayTitle)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
            CountdownNumber(state: state, now: now, size: 46)
            UnitCaption(text: event.caption(for: state))
            Spacer(minLength: 6)
            ProgressBar(value: event.remainingFraction(at: now))
            DateLine(text: event.formattedDate)
                .padding(.top, 6)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

/// One event on half or all of the large widget: name and date on top, a big count
/// and the bar at the bottom, sized by the caller to the room there is.
struct CountdownBand: View {
    let event: CountdownEvent
    let now: Date
    let badge: CGFloat
    let title: CGFloat
    let number: CGFloat

    private var state: CountdownState { event.state(at: now) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                IconBadge(symbol: event.symbol, size: badge)
                VStack(alignment: .leading, spacing: 1) {
                    Text(event.displayTitle)
                        .font(.system(size: title, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    DateLine(text: event.formattedDate)
                }
            }
            Spacer(minLength: 0)
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                CountdownNumber(state: state, now: now, size: number)
                UnitCaption(text: event.caption(for: state))
                Spacer(minLength: 0)
            }
            ProgressBar(value: event.remainingFraction(at: now))
                .padding(.top, 6)
        }
        .foregroundStyle(.white)
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

/// One event as a line of the large widget when it holds three: its own background, count and progress.
struct CountdownRow: View {
    let event: CountdownEvent
    let now: Date

    private var state: CountdownState { event.state(at: now) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 9) {
                IconBadge(symbol: event.symbol, size: 28)
                VStack(alignment: .leading, spacing: 1) {
                    Text(event.displayTitle)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    DateLine(text: event.formattedDate)
                }
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: -2) {
                    CountdownNumber(state: state, now: now, size: 28)
                    UnitCaption(text: event.caption(for: state))
                }
            }
            ProgressBar(value: event.remainingFraction(at: now))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// The event's picture, darkened so white text stays readable, or else its gradient
/// with a soft highlight in the top-left corner for depth.
struct CardBackground: View {
    let event: CountdownEvent

    var body: some View {
        if let image = event.imageName.flatMap(EventStore.image(named:)) {
            Color.black
                .overlay { Image(nsImage: image).resizable().scaledToFill() }
                .overlay {
                    LinearGradient(
                        colors: [.black.opacity(0.25), .black.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                }
                .clipped()
        } else {
            ZStack {
                event.gradient
                RadialGradient(
                    colors: [.white.opacity(0.22), .clear],
                    center: .topLeading, startRadius: 0, endRadius: 220)
            }
        }
    }
}

struct CountdownNumber: View {
    let state: CountdownState
    let now: Date
    let size: CGFloat

    var body: some View {
        Group {
            switch state {
            case .days(let n), .ago(days: let n):
                Text("\(n)")
                    .font(.system(size: size, weight: .heavy, design: .rounded))
            case .timer(let until):
                Text(timerInterval: min(now, until)...until, countsDown: true)
                    .font(.system(size: size * 0.66, weight: .heavy, design: .rounded))
            case .today:
                Text("Today")
                    .font(.system(size: size * 0.74, weight: .heavy, design: .rounded))
            }
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.4)
    }
}

/// Small spaced capitals under or beside the number: "DAYS LEFT".
struct UnitCaption: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .tracking(0.8)
            .opacity(0.82)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
    }
}

struct DateLine: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .opacity(0.85)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

struct ProgressBar: View {
    let value: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.25))
                Capsule().fill(.white.opacity(0.95))
                    .frame(width: value > 0 ? max(geo.size.height, geo.size.width * value) : 0)
            }
        }
        .frame(height: 5)
        .accessibilityLabel("Time left")
        .accessibilityValue(Text(value, format: .percent.precision(.fractionLength(0))))
    }
}

/// The icon on a translucent disc.
struct IconBadge: View {
    let symbol: String
    let size: CGFloat

    var body: some View {
        EventIcon(symbol: symbol)
            .font(.system(size: size * 0.5, weight: .semibold))
            .frame(width: size, height: size)
            .background(.white.opacity(0.22), in: Circle())
    }
}

/// An SF Symbol when the name is one, otherwise the text itself (an emoji, for example).
struct EventIcon: View {
    let symbol: String

    var body: some View {
        if SymbolCatalog.isSymbol(symbol) {
            Image(systemName: symbol)
        } else {
            Text(symbol).lineLimit(1)
        }
    }
}

extension CountdownEvent {
    var displayTitle: String { title.isEmpty ? "Untitled" : title }

    func caption(for state: CountdownState) -> String {
        func unit(_ n: Int) -> String {
            let day = n == 1 ? "day" : "days"
            return countMode == .workingDays ? "working \(day)" : day
        }
        switch state {
        case .days(let n): return "\(unit(n)) left"
        case .ago(days: let n): return "\(unit(n)) ago"
        case .timer: return "remaining"
        case .today: return "It's the day"
        }
    }
}
