import XCTest
@testable import CountdownShared

final class CountdownTests: XCTestCase {
    private var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    private func day(_ year: Int, _ month: Int, _ day: Int, hour: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    // 2 November 2026 is a Monday.
    private var monday: Date { day(2026, 11, 2, hour: 10) }

    func testCountsEveryDay() {
        let event = CountdownEvent(title: "Trip", date: day(2026, 11, 9))
        XCTAssertEqual(event.state(at: monday, calendar: calendar), .days(7))
    }

    func testIncludeTodayAddsOne() {
        var event = CountdownEvent(title: "Trip", date: day(2026, 11, 9))
        event.includeToday = true
        XCTAssertEqual(event.state(at: monday, calendar: calendar), .days(8))
    }

    func testWorkingDaysSkipWeekends() {
        var event = CountdownEvent(title: "Release", date: day(2026, 11, 9))
        event.countMode = .workingDays
        // Tue, Wed, Thu, Fri and the next Monday.
        XCTAssertEqual(event.state(at: monday, calendar: calendar), .days(5))
        event.date = day(2026, 11, 23)
        XCTAssertEqual(event.state(at: monday, calendar: calendar), .days(15))
    }

    func testTodayAndPast() {
        let event = CountdownEvent(title: "Party", date: day(2026, 11, 2))
        XCTAssertEqual(event.state(at: monday, calendar: calendar), .today)
        XCTAssertEqual(event.state(at: day(2026, 11, 5), calendar: calendar), .ago(days: 3))
    }

    func testTimedEventTicksInItsLastDay() {
        let event = CountdownEvent(title: "Launch", date: day(2026, 11, 3, hour: 9), includesTime: true)
        XCTAssertEqual(event.state(at: monday, calendar: calendar), .timer(until: event.date))
    }

    func testBarShowsTimeLeftOnAFixedScale() {
        var event = CountdownEvent(title: "Trip", date: day(2026, 11, 17))
        XCTAssertEqual(event.remainingFraction(at: monday, calendar: calendar), 0.5, accuracy: 0.001)
        event.date = day(2026, 11, 8)
        XCTAssertEqual(event.remainingFraction(at: monday, calendar: calendar), 0.2, accuracy: 0.001)
        event.date = day(2027, 11, 8)
        XCTAssertEqual(event.remainingFraction(at: monday, calendar: calendar), 1)
        event.date = day(2026, 10, 1)
        XCTAssertEqual(event.remainingFraction(at: monday, calendar: calendar), 0)
    }

    func testSlotsFillChosenThenRemainingEvents() {
        let a = CountdownEvent(title: "A", date: monday), b = CountdownEvent(title: "B", date: monday)
        let c = CountdownEvent(title: "C", date: monday)
        let events = [a, b, c]
        XCTAssertEqual(events.slots(for: [nil]), [.event(a)])
        XCTAssertEqual(events.slots(for: ["C", nil]), [.event(c), .event(a)])
        XCTAssertEqual(events.slots(for: [nil, "A", nil]), [.event(b), .event(a), .event(c)])
        XCTAssertEqual([a].slots(for: [nil, nil, nil]), [.event(a)])
    }

    func testDeletedEventKeepsItsPlace() {
        let a = CountdownEvent(title: "A", date: monday)
        XCTAssertEqual([a].slots(for: ["Gone", nil]), [.deleted, .event(a)])
    }

    func testRenamedEventIsFoundByItsOldName() {
        var a = CountdownEvent(title: "Holiday", date: monday)
        a.aliases = ["Trip"]
        let b = CountdownEvent(title: "B", date: monday)
        XCTAssertEqual([b, a].slots(for: ["Trip"]), [.event(a)])
        // A current name wins over an old one.
        let trip = CountdownEvent(title: "Trip", date: monday)
        XCTAssertEqual([a, trip].slots(for: ["Trip"]), [.event(trip)])
    }

    func testEventsWithTheSameTitleGetTheDateInTheirName() {
        let a = CountdownEvent(title: "Trip", date: day(2026, 11, 9)), b = CountdownEvent(title: "Trip", date: day(2026, 12, 9))
        let events = [a, b]
        XCTAssertNotEqual(events.label(for: a), events.label(for: b))
        XCTAssertEqual(events.event(labeled: events.label(for: b)), b)
    }

    func testOldFilesWithoutNewFieldsStillLoad() throws {
        let json = #"[{"title": "Trip", "date": 0}]"#
        let events = try JSONDecoder().decode([CountdownEvent].self, from: Data(json.utf8))
        XCTAssertEqual(events.first?.title, "Trip")
        XCTAssertEqual(events.first?.barScale, .month)
        XCTAssertNil(events.first?.imageName)
    }

    func testLinkRoundTrip() {
        let event = CountdownEvent(title: "Trip", date: monday)
        XCTAssertEqual(CountdownEvent.id(from: event.url), event.id)
        XCTAssertNil(CountdownEvent.id(from: CountdownEvent.appURL))
    }
}
