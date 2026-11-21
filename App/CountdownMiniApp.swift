import AppKit
import SwiftUI
import UniformTypeIdentifiers
import WidgetKit

@main
struct CountdownMiniApp: App {
    var body: some Scene {
        Window("Countdown Mini", id: "main") {
            ContentView()
        }
        .defaultSize(width: 1040, height: 680)
        .windowResizability(.contentMinSize)
    }
}

struct ContentView: View {
    @State private var events = EventStore.load() ?? [.placeholder]
    @State private var selection: CountdownEvent.ID?
    @State private var saveError: String?
    /// Edits not saved yet, by event. Widgets and the file only see `events`.
    @State private var drafts: [CountdownEvent.ID: CountdownEvent] = [:]

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(events) { event in
                    EventRow(event: event, hasUnsavedChanges: drafts[event.id] != nil)
                        .tag(event.id)
                        .contextMenu {
                            Button("Duplicate") { duplicate(event) }
                            Button("Delete", role: .destructive) { delete(event.id) }
                        }
                }
                .onMove { events.move(fromOffsets: $0, toOffset: $1) }
            }
            .navigationSplitViewColumnWidth(min: 210, ideal: 240, max: 320)
            .onDeleteCommand { if let selection { delete(selection) } }
            .safeAreaInset(edge: .bottom) {
                Button(action: add) {
                    Label("New Event", systemImage: "plus").frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .keyboardShortcut("n")
                .padding(10)
            }
        } detail: {
            if let index = events.firstIndex(where: { $0.id == selection }) {
                EditorView(
                    event: draft(for: events[index]),
                    hasUnsavedChanges: drafts[events[index].id] != nil,
                    save: { saveDraft(of: events[index].id) },
                    revert: { drafts[events[index].id] = nil }
                )
                .id(events[index].id)
                    .frame(minWidth: 760, minHeight: 560)
            } else {
                ContentUnavailableView {
                    Label("No Event Selected", systemImage: "calendar")
                } description: {
                    Text("Select an event or create a new one.")
                } actions: {
                    Button("New Event", action: add)
                }
            }
        }
        .overlay(alignment: .bottom) {
            if let saveError {
                Text(saveError).font(.caption).foregroundStyle(.red).padding(8)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("New Event", systemImage: "plus", action: add)
                    .help("New event")
                Button("Delete Event", systemImage: "trash") {
                    if let selection { delete(selection) }
                }
                .help("Delete the selected event")
                .disabled(selection == nil)
            }
        }
        .onAppear {
            if selection == nil {
                let saved = EventStore.loadSelection()
                selection = events.contains { $0.id == saved } ? saved : events.first?.id
            }
            save()
        }
        .onChange(of: events) { save() }
        .onChange(of: selection) {
            // Remembered for the next launch only; widgets never follow the window.
            EventStore.saveSelection(selection)
        }
        .onOpenURL { url in
            // A widget was clicked: show its event.
            if let id = CountdownEvent.id(from: url), events.contains(where: { $0.id == id }) {
                selection = id
            }
        }
    }

    private func add() {
        let start = Calendar.current.startOfDay(for: Date())
        let preset = GradientPreset.all[events.count % GradientPreset.all.count]
        let event = CountdownEvent(
            title: "New Event",
            date: Calendar.current.date(byAdding: .day, value: 7, to: start) ?? start,
            symbol: "calendar", colorA: preset.a, colorB: preset.b)
        events.append(event)
        select(event.id)
    }

    private func duplicate(_ event: CountdownEvent) {
        var copy = event
        copy.id = UUID()
        copy.aliases = []
        copy.title += " copy"
        events.append(copy)
        select(copy.id)
    }

    /// Selects on the next run loop pass, once the list has a row for the new event;
    /// selecting in the same update can be dropped by the list.
    private func select(_ id: CountdownEvent.ID) {
        DispatchQueue.main.async { selection = id }
    }

    private func delete(_ id: CountdownEvent.ID) {
        guard let index = events.firstIndex(where: { $0.id == id }) else { return }
        events.remove(at: index)
        drafts[id] = nil
        if selection == id {
            selection = events.isEmpty ? nil : events[min(index, events.count - 1)].id
        }
    }

    /// The event as shown in the editor: its unsaved edits when there are any.
    private func draft(for event: CountdownEvent) -> Binding<CountdownEvent> {
        Binding(
            get: { drafts[event.id] ?? event },
            set: { drafts[event.id] = $0 == event ? nil : $0 })
    }

    /// Applies the edits. A widget remembers its event by name, so names that change here
    /// are kept as aliases and widgets set to the old name stay with the event.
    private func saveDraft(of id: CountdownEvent.ID) {
        guard let draft = drafts[id], let index = events.firstIndex(where: { $0.id == id }) else { return }
        var updated = events
        updated[index] = draft
        for i in updated.indices {
            let old = events.label(for: events[i])
            if old != updated.label(for: updated[i]), !updated[i].aliases.contains(old) {
                updated[i].aliases = Array((updated[i].aliases + [old]).suffix(30))
            }
        }
        events = updated
        drafts[id] = nil
    }

    private func save() {
        do {
            try EventStore.save(events)
            EventStore.removeImages(except: Set((events + drafts.values).compactMap(\.imageName)))
            saveError = nil
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            saveError = "Could not save: \(error.localizedDescription)"
        }
    }
}

struct EventRow: View {
    let event: CountdownEvent
    var hasUnsavedChanges = false

    var body: some View {
        HStack(spacing: 10) {
            EventIcon(symbol: event.symbol)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(event.gradient, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            VStack(alignment: .leading, spacing: 1) {
                Text(event.title.isEmpty ? "Untitled" : event.title).lineLimit(1)
                Text(event.formattedDate).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 4)
            if hasUnsavedChanges {
                Circle().fill(.orange).frame(width: 7, height: 7)
                    .help("Unsaved changes")
                    .accessibilityLabel("Unsaved changes")
            }
            Text(event.shortLabel(at: Date()))
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 3)
    }
}

struct EditorView: View {
    @Binding var event: CountdownEvent
    let hasUnsavedChanges: Bool
    let save: () -> Void
    let revert: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            ScrollView {
                form.padding(20)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    Divider()
                    HStack {
                        Text(hasUnsavedChanges ? "Unsaved changes" : "Saved")
                            .font(.caption)
                            .foregroundStyle(hasUnsavedChanges ? .orange : .secondary)
                        Spacer()
                        Button("Revert", action: revert)
                        Button("Save", action: save)
                            .buttonStyle(.borderedProminent)
                            .keyboardShortcut("s")
                    }
                    .controlSize(.large)
                    .disabled(!hasUnsavedChanges)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .background(.bar)
            }
            .frame(width: 360)
            Divider()
            preview
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var form: some View {
        VStack(alignment: .leading, spacing: 18) {
            section("Event") {
                TextField("Name", text: $event.title)
                    .textFieldStyle(.roundedBorder)
            }

            section("Date") {
                DateField(title: "Event date", date: $event.date, includesTime: event.includesTime)
                Toggle("Set a time", isOn: $event.includesTime)
            }

            section("Count") {
                Picker("Count", selection: $event.countMode) {
                    ForEach(CountdownEvent.CountMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                Toggle("Include today", isOn: $event.includeToday)
                Picker("Full bar is", selection: $event.barScale) {
                    ForEach(CountdownEvent.BarScale.allCases) { scale in
                        Text(scale.label).tag(scale)
                    }
                }
                .help("The bar shows the time left on this scale and drains as the day comes closer.")
                Text(event.countMode == .workingDays
                     ? "Counts Monday to Friday only, up to and including the event day."
                     : "Counts every day up to and including the event day.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            section("Background") {
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(26), spacing: 6), count: 10), spacing: 8) {
                    ForEach(GradientPreset.all) { preset in
                        let selected = event.colorA == preset.a && event.colorB == preset.b
                        Button {
                            event.colorA = preset.a
                            event.colorB = preset.b
                        } label: {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color(hex: preset.a), Color(hex: preset.b)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 24, height: 24)
                                .overlay(Circle().strokeBorder(Color.primary, lineWidth: selected ? 2 : 0).padding(-3))
                        }
                        .buttonStyle(.plain)
                        .help(preset.name)
                        .accessibilityLabel(preset.name)
                    }
                }
                .padding(.vertical, 4)
                HStack(spacing: 16) {
                    ColorPicker("From", selection: color(\.colorA), supportsOpacity: false)
                    ColorPicker("To", selection: color(\.colorB), supportsOpacity: false)
                    Button {
                        (event.colorA, event.colorB) = (event.colorB, event.colorA)
                    } label: {
                        Image(systemName: "arrow.left.arrow.right")
                    }
                    .help("Swap colors")
                }
                HStack {
                    Button(event.imageName == nil ? "Choose Picture…" : "Change Picture…", action: choosePicture)
                    if event.imageName != nil {
                        Button("Remove Picture") { event.imageName = nil }
                    }
                }
                Text(event.imageName == nil
                     ? "A picture replaces the gradient."
                     : "The picture is used instead of the gradient.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            section("Icon") {
                ScrollView {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(30), spacing: 4), count: 9), spacing: 4) {
                        ForEach(SymbolCatalog.all, id: \.self) { symbol in
                            Button {
                                event.symbol = symbol
                            } label: {
                                Image(systemName: symbol)
                                    .frame(width: 30, height: 30)
                                    .background(
                                        event.symbol == symbol ? Color.accentColor.opacity(0.25) : Color.clear,
                                        in: RoundedRectangle(cornerRadius: 7))
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(symbol)
                        }
                    }
                    .padding(4)
                }
                .frame(height: 150)
                .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 8))
                // The symbol's name is internal; the field is only for using an emoji instead.
                TextField("Or type an emoji", text: Binding(
                    get: { SymbolCatalog.isSymbol(event.symbol) ? "" : event.symbol },
                    set: { if !$0.isEmpty { event.symbol = $0 } }))
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var preview: some View {
        VStack(spacing: 14) {
            TimelineView(.periodic(from: .now, by: 60)) { context in
                VStack(spacing: 14) {
                    CountdownCard(event: event, now: context.date)
                        .padding(16)
                        .frame(width: 164, height: 164)
                        .background {
                            CardBackground(event: event).clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        }
                }
                .shadow(color: .black.opacity(0.18), radius: 8, y: 3)
            }
            Text("""
                To put it on the desktop: right-click the desktop, choose Edit Widgets, and add Countdown Mini. \
                The small widget shows one event, the medium two, the large three. Right-click a widget and \
                choose Edit to pick them. Click a widget to open its first event here. \
                Widgets update when you press Save.
                """)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 344)
        }
    }

    private func choosePicture() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.message = "Choose a background picture for this event"
        if panel.runModal() == .OK, let url = panel.url, let name = try? EventStore.importImage(from: url) {
            event.imageName = name
        }
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            content()
        }
    }

    private func color(_ keyPath: WritableKeyPath<CountdownEvent, String>) -> Binding<Color> {
        Binding(
            get: { Color(hex: event[keyPath: keyPath]) },
            set: { event[keyPath: keyPath] = $0.hex })
    }
}

/// A compact date row: shows the date, and opens a calendar in a popover when clicked.
struct DateField: View {
    let title: String
    @Binding var date: Date
    let includesTime: Bool
    @State private var isOpen = false

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Button {
                isOpen.toggle()
            } label: {
                Label(label, systemImage: "calendar")
            }
            .popover(isPresented: $isOpen, arrowEdge: .trailing) {
                VStack(spacing: 10) {
                    DatePicker(title, selection: $date, displayedComponents: [.date])
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                    if includesTime {
                        DatePicker("Time", selection: $date, displayedComponents: [.hourAndMinute])
                            .datePickerStyle(.stepperField)
                    }
                    HStack {
                        Button("Today") { date = merged(day: Date()) }
                        Spacer()
                        Button("Done") { isOpen = false }
                            .keyboardShortcut(.defaultAction)
                    }
                }
                .padding(14)
            }
        }
    }

    private var label: String {
        var style = Date.FormatStyle.dateTime.weekday(.abbreviated).day().month(.abbreviated).year()
        if includesTime { style = style.hour().minute() }
        return date.formatted(style)
    }

    /// Moves to the given day, keeping the time of day.
    private func merged(day: Date) -> Date {
        let calendar = Calendar.current
        let time = calendar.dateComponents([.hour, .minute], from: date)
        return calendar.date(
            bySettingHour: time.hour ?? 0, minute: time.minute ?? 0, second: 0,
            of: calendar.startOfDay(for: day)) ?? day
    }
}
