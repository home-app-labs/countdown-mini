import AppKit
import Foundation
import SwiftUI

/// One event to count down to. Shared by the app and the widget.
struct CountdownEvent: Codable, Equatable, Identifiable {
    var id = UUID()
    var title: String
    var date: Date
    /// When false the event is a whole day.
    var includesTime = false
    /// An SF Symbol name, or any text such as an emoji.
    var symbol = "sparkles"
    /// Gradient start and end as "RRGGBB".
    var colorA = GradientPreset.all[0].a
    var colorB = GradientPreset.all[0].b
    var countMode = CountMode.allDays
    /// Count today as one of the remaining days.
    var includeToday = false
    /// The length of time a full bar stands for. Every event with the same scale is
    /// comparable: on the 30-day scale 19 days fills more of the bar than 7 days.
    var barScale = BarScale.month
    /// File name of a background picture in the store's images folder; replaces the gradient.
    var imageName: String?
    /// Names this event went by before it was renamed. A widget remembers its event by
    /// name, so these keep the widget attached after a rename.
    var aliases: [String] = []

    enum BarScale: Int, Codable, CaseIterable, Identifiable {
        case week = 7, month = 30, quarter = 90, year = 365
        var id: Int { rawValue }
        var label: String {
            switch self {
            case .week: "7 days"
            case .month: "30 days"
            case .quarter: "90 days"
            case .year: "1 year"
            }
        }
    }

    enum CountMode: String, Codable, CaseIterable, Identifiable {
        case allDays, workingDays
        var id: String { rawValue }
        var label: String { self == .allDays ? "All days" : "Working days" }
    }

    static var placeholder: CountdownEvent {
        let calendar = Calendar.current
        let newYear = calendar.date(from: DateComponents(
            year: calendar.component(.year, from: Date()) + 1, month: 1, day: 1)) ?? Date()
        return CountdownEvent(title: "New Year", date: newYear)
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: colorA), Color(hex: colorB)],
            startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// Tolerant decoding: fields added later get defaults, and the first version's
// single-event file (with a named "theme") still loads.
extension CountdownEvent {
    private enum LegacyKeys: String, CodingKey { case theme }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try c.decode(String.self, forKey: .title)
        date = try c.decode(Date.self, forKey: .date)
        includesTime = try c.decodeIfPresent(Bool.self, forKey: .includesTime) ?? false
        symbol = try c.decodeIfPresent(String.self, forKey: .symbol) ?? "sparkles"
        countMode = try c.decodeIfPresent(CountMode.self, forKey: .countMode) ?? .allDays
        includeToday = try c.decodeIfPresent(Bool.self, forKey: .includeToday) ?? false
        barScale = try c.decodeIfPresent(BarScale.self, forKey: .barScale) ?? .month
        aliases = try c.decodeIfPresent([String].self, forKey: .aliases) ?? []
        imageName = try c.decodeIfPresent(String.self, forKey: .imageName)

        let legacyTheme = try? decoder.container(keyedBy: LegacyKeys.self).decode(String.self, forKey: .theme)
        let fallback = GradientPreset.all.first { $0.name.lowercased() == legacyTheme } ?? GradientPreset.all[0]
        colorA = try c.decodeIfPresent(String.self, forKey: .colorA) ?? fallback.a
        colorB = try c.decodeIfPresent(String.self, forKey: .colorB) ?? fallback.b
    }
}

struct GradientPreset: Identifiable, Equatable {
    let name: String
    let a: String
    let b: String
    var id: String { name }

    static let all: [GradientPreset] = [
        .init(name: "Sunset", a: "FA8C40", b: "DB3859"),
        .init(name: "Ocean", a: "339EF2", b: "2947BF"),
        .init(name: "Forest", a: "4DB87A", b: "146B5C"),
        .init(name: "Grape", a: "A86BF2", b: "5C33B3"),
        .init(name: "Graphite", a: "5C616F", b: "1F2129"),
        .init(name: "Rose", a: "FA85A8", b: "CC3880"),
        .init(name: "Peach", a: "F59A73", b: "D4504C"),
        .init(name: "Mint", a: "3CC6A8", b: "1B86A0"),
        .init(name: "Sky", a: "52B4F0", b: "2F6FD0"),
        .init(name: "Amber", a: "E9A21B", b: "D2601F"),
        .init(name: "Lime", a: "7DBA3C", b: "2E8540"),
        .init(name: "Cherry", a: "F0524F", b: "8E1B3F"),
        .init(name: "Indigo", a: "5B6CF0", b: "2A1F7A"),
        .init(name: "Aurora", a: "43CEA2", b: "5B3FD0"),
        .init(name: "Candy", a: "FF7EB3", b: "7B5CFA"),
        .init(name: "Ember", a: "FF9F1C", b: "B3261E"),
        .init(name: "Sand", a: "D9B382", b: "8A5A3C"),
        .init(name: "Steel", a: "8E9EAB", b: "44566C"),
        .init(name: "Night", a: "34406B", b: "0B1026"),
        .init(name: "Teal", a: "2BC0B4", b: "0E5F76"),
    ]
}

enum SymbolCatalog {
    static let all = [
        // Celebrations
        "sparkles", "gift.fill", "birthday.cake.fill", "party.popper.fill", "balloon.fill", "heart.fill",
        "star.fill", "crown.fill", "trophy.fill", "medal.fill",
        // Travel
        "airplane", "car.fill", "tram.fill", "ferry.fill", "bicycle", "suitcase.fill",
        "map.fill", "globe.europe.africa.fill", "beach.umbrella.fill", "tent.fill", "mountain.2.fill", "sailboat.fill",
        // Work and study
        "briefcase.fill", "calendar", "clock.fill", "flag.checkered", "flag.fill", "target",
        "graduationcap.fill", "book.fill", "pencil", "laptopcomputer", "chart.line.uptrend.xyaxis", "hammer.fill",
        "banknote.fill", "creditcard.fill", "cart.fill", "shippingbox.fill",
        // Home and people
        "house.fill", "key.fill", "person.2.fill", "figure.2.and.child.holdinghands", "pawprint.fill", "stethoscope",
        "cross.case.fill", "fork.knife", "cup.and.saucer.fill", "wineglass.fill",
        // Sport and leisure
        "figure.run", "figure.hiking", "dumbbell.fill", "soccerball", "basketball.fill", "gamecontroller.fill",
        "music.note", "film.fill", "camera.fill", "ticket.fill", "theatermasks.fill", "paintbrush.fill",
        // Nature
        "sun.max.fill", "moon.stars.fill", "snowflake", "leaf.fill", "flame.fill", "bolt.fill",
        "drop.fill", "tree.fill", "cloud.sun.fill", "rainbow",
    ]

    static func isSymbol(_ name: String) -> Bool {
        NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil
    }
}

extension CountdownEvent {
    /// Opens the app with this event selected; widgets link to it.
    /// Opens the app without selecting anything.
    static let appURL = URL(string: "countdownmini://open")!

    var url: URL { URL(string: "countdownmini://event/\(id.uuidString)")! }

    static func id(from url: URL) -> UUID? {
        guard url.scheme == "countdownmini", url.host == "event" else { return nil }
        return UUID(uuidString: url.lastPathComponent)
    }
}

/// What the card shows at a given moment.
enum CountdownState: Equatable {
    case days(Int)
    /// Less than 24 hours to a timed event: a live ticking timer.
    case timer(until: Date)
    case today
    case ago(days: Int)
}

extension CountdownEvent {
    func state(at now: Date, calendar: Calendar = .current) -> CountdownState {
        let today = calendar.startOfDay(for: now)
        let target = calendar.startOfDay(for: date)
        let dayDiff = calendar.dateComponents([.day], from: today, to: target).day ?? 0

        if includesTime {
            let interval = date.timeIntervalSince(now)
            if interval > 0, interval < 24 * 3600 { return .timer(until: date) }
            if interval <= 0, dayDiff == 0 { return .today }
        }
        if dayDiff == 0 { return .today }
        if dayDiff < 0 { return .ago(days: count(after: target, through: today, calendar: calendar)) }

        var n = count(after: today, through: target, calendar: calendar)
        if includeToday, countMode == .allDays || !calendar.isDateInWeekend(today) { n += 1 }
        return .days(n)
    }

    /// Days in (start, end], all of them or only working days. Both are starts of days.
    private func count(after start: Date, through end: Date, calendar: Calendar) -> Int {
        let total = calendar.dateComponents([.day], from: start, to: end).day ?? 0
        guard countMode == .workingDays, total > 0 else { return max(total, 0) }
        // Whole weeks have a fixed number of working days; walk only the remainder.
        var perWeek = 0
        for offset in 1...7 {
            if let d = calendar.date(byAdding: .day, value: offset, to: start), !calendar.isDateInWeekend(d) {
                perWeek += 1
            }
        }
        var n = (total / 7) * perWeek
        let rest = total % 7
        if rest > 0 {
            for offset in 1...rest {
                if let d = calendar.date(byAdding: .day, value: offset, to: start), !calendar.isDateInWeekend(d) {
                    n += 1
                }
            }
        }
        return n
    }

    /// Moments at which the displayed state changes, for the widget timeline.
    func refreshDates(from now: Date, days: Int = 60, calendar: Calendar = .current) -> [Date] {
        var dates: Set<Date> = [now]
        let midnight = calendar.startOfDay(for: now)
        for offset in 1...days {
            if let d = calendar.date(byAdding: .day, value: offset, to: midnight) { dates.insert(d) }
        }
        if includesTime {
            for d in [date.addingTimeInterval(-24 * 3600), date] where d > now { dates.insert(d) }
        }
        return dates.sorted()
    }

    /// "Thu, 10 Dec", with the year when it is not the current one and the time when set.
    var formattedDate: String {
        let calendar = Calendar.current
        var style = Date.FormatStyle.dateTime.weekday(.abbreviated).day().month(.abbreviated)
        if calendar.component(.year, from: date) != calendar.component(.year, from: Date()) {
            style = style.year()
        }
        if includesTime { style = style.hour().minute() }
        return date.formatted(style)
    }

    /// The time left as a share of the bar's scale, 0...1: the bar drains as the event
    /// approaches and is full while the event is further away than the scale.
    func remainingFraction(at now: Date, calendar: Calendar = .current) -> Double {
        let target = includesTime ? date : calendar.startOfDay(for: date)
        let start = includesTime ? now : calendar.startOfDay(for: now)
        let left = target.timeIntervalSince(start)
        return min(max(left / (Double(barScale.rawValue) * 24 * 3600), 0), 1)
    }

    /// Compact remaining text for lists, e.g. "12 d".
    func shortLabel(at now: Date) -> String {
        switch state(at: now) {
        case .days(let n): "\(n) d"
        case .ago(days: let n): "\(n) d ago"
        case .timer: "< 1 d"
        case .today: "Today"
        }
    }
}

extension Array where Element == CountdownEvent {
    /// The name a widget's settings show for an event: its title, with the date added
    /// when several events share the title.
    func label(for event: CountdownEvent) -> String {
        let title = event.title.isEmpty ? "Untitled" : event.title
        let sameTitle = filter { ($0.title.isEmpty ? "Untitled" : $0.title) == title }.count
        return sameTitle > 1 ? "\(title) · \(event.formattedDate)" : title
    }

    /// The event with that name now, or else the one that used to have it.
    func event(labeled label: String) -> CountdownEvent? {
        first { self.label(for: $0) == label } ?? first { $0.aliases.contains(label) }
    }

    /// What a widget shows for the names chosen in its settings, one per slot.
    /// A slot with nothing chosen takes the next event no slot has chosen;
    /// a chosen event that no longer exists is shown as deleted.
    func slots(for labels: [String?]) -> [WidgetSlot] {
        var slots: [WidgetSlot?] = labels.map { label in
            guard let label, !label.isEmpty else { return nil }
            return event(labeled: label).map(WidgetSlot.event) ?? .deleted
        }
        var rest = filter { event in !slots.contains { $0?.event?.id == event.id } }
        for index in slots.indices where slots[index] == nil && !rest.isEmpty {
            slots[index] = .event(rest.removeFirst())
        }
        return slots.compactMap { $0 }
    }
}

/// One place in a widget.
enum WidgetSlot: Equatable {
    case event(CountdownEvent)
    case deleted

    var event: CountdownEvent? {
        if case .event(let event) = self { event } else { nil }
    }
}

extension Color {
    init(hex: String) {
        let value = UInt32(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0x888888
        self.init(
            .sRGB,
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255)
    }

    var hex: String {
        guard let c = NSColor(self).usingColorSpace(.sRGB) else { return "888888" }
        return String(
            format: "%02X%02X%02X",
            Int((c.redComponent * 255).rounded()),
            Int((c.greenComponent * 255).rounded()),
            Int((c.blueComponent * 255).rounded()))
    }
}

/// Reads and writes the events as JSON in ~/Library/Application Support/Countdown Mini.
/// The sandboxed widget has a read-only entitlement for that folder.
enum EventStore {
    private static var folder: URL {
        // NSHomeDirectory() points into the container inside the sandboxed widget,
        // so resolve the real home directory.
        let home = getpwuid(getuid()).flatMap { String(cString: $0.pointee.pw_dir) } ?? NSHomeDirectory()
        return URL(fileURLWithPath: home).appendingPathComponent("Library/Application Support/Countdown Mini")
    }

    static var fileURL: URL { folder.appendingPathComponent("events.json") }
    private static var imagesFolder: URL { folder.appendingPathComponent("images") }
    private static let imageCache = NSCache<NSString, NSImage>()

    /// A background picture saved by `importImage`.
    static func image(named name: String) -> NSImage? {
        if let cached = imageCache.object(forKey: name as NSString) { return cached }
        guard let image = NSImage(contentsOf: imagesFolder.appendingPathComponent(name)) else { return nil }
        imageCache.setObject(image, forKey: name as NSString)
        return image
    }

    /// Copies a picture into the store, scaled down to what a widget needs (widgets refuse
    /// large images), and returns its file name.
    static func importImage(from url: URL) throws -> String {
        guard let source = NSImage(contentsOf: url), source.size.width > 0, source.size.height > 0 else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let scale = min(1, 1000 / max(source.size.width, source.size.height))
        let width = max(1, Int(source.size.width * scale)), height = max(1, Int(source.size.height * scale))
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4,
            hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)
        else { throw CocoaError(.fileWriteUnknown) }
        bitmap.size = NSSize(width: width, height: height)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        source.draw(in: NSRect(x: 0, y: 0, width: width, height: height))
        NSGraphicsContext.restoreGraphicsState()
        guard let data = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.85]) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try FileManager.default.createDirectory(at: imagesFolder, withIntermediateDirectories: true)
        let name = UUID().uuidString + ".jpg"
        try data.write(to: imagesFolder.appendingPathComponent(name), options: .atomic)
        return name
    }

    /// Deletes pictures no event uses any more.
    static func removeImages(except used: Set<String>) {
        let files = (try? FileManager.default.contentsOfDirectory(atPath: imagesFolder.path)) ?? []
        for file in files where !used.contains(file) {
            try? FileManager.default.removeItem(at: imagesFolder.appendingPathComponent(file))
        }
    }
    private static var selectionURL: URL { folder.appendingPathComponent("selection.txt") }

    /// The event selected in the app window, restored on the next launch.
    static func loadSelection() -> UUID? {
        (try? String(contentsOf: selectionURL, encoding: .utf8)).flatMap {
            UUID(uuidString: $0.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    static func saveSelection(_ id: UUID?) {
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try? (id?.uuidString ?? "").write(to: selectionURL, atomically: true, encoding: .utf8)
    }
    /// The first version stored a single event here.
    private static var legacyURL: URL { folder.appendingPathComponent("event.json") }

    /// Nil when nothing has been saved yet.
    static func load() -> [CountdownEvent]? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let data = try? Data(contentsOf: fileURL) {
            return try? decoder.decode([CountdownEvent].self, from: data)
        }
        if let data = try? Data(contentsOf: legacyURL),
           let event = try? decoder.decode(CountdownEvent.self, from: data) {
            return [event]
        }
        return nil
    }

    static func save(_ events: [CountdownEvent]) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try encoder.encode(events).write(to: fileURL, options: .atomic)
    }
}
