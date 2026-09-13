import XCTest
@testable import TFYSwiftCalendarkit

final class TFYSwiftCalendarMathTests: XCTestCase {
    private func makeCalendar(firstWeekday: Int = 2) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        calendar.firstWeekday = firstWeekday
        return calendar
    }

    private func makeDate(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        hour: Int = 12,
        calendar: Calendar
    ) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    func testAddingCalendarDayAcrossDaylightSavingTime() {
        let calendar = makeCalendar()
        let math = TFYSwiftCalendarMath(calendar: calendar)
        let beforeDST = makeDate(2024, 3, 9, hour: 12, calendar: calendar)
        let result = math.addingDays(1, to: beforeDST)
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: result)
        XCTAssertEqual(components.year, 2024)
        XCTAssertEqual(components.month, 3)
        XCTAssertEqual(components.day, 10)
        XCTAssertEqual(components.hour, 12)
        XCTAssertEqual(result.timeIntervalSince(beforeDST), 23 * 60 * 60)
    }

    func testLeapYearMonthGridWithMondayFirstWeekday() {
        let calendar = makeCalendar()
        let math = TFYSwiftCalendarMath(calendar: calendar)
        let february = makeDate(2024, 2, 1, calendar: calendar)
        let items = math.gridItems(for: february, scope: .month, placeholderType: .fillHeadTail)

        XCTAssertEqual(items.count, 35)
        XCTAssertEqual(items.filter { $0.monthPosition == .current }.count, 29)
        XCTAssertEqual(items.first?.monthPosition, .previous)
        XCTAssertEqual(items.last?.monthPosition, .next)
    }

    func testNoPlaceholderGridKeepsGeometryButUsesBlankItems() {
        let calendar = makeCalendar()
        let math = TFYSwiftCalendarMath(calendar: calendar)
        let february = makeDate(2024, 2, 1, calendar: calendar)
        let items = math.gridItems(for: february, scope: .month, placeholderType: .none)

        XCTAssertEqual(items.count, 35)
        XCTAssertEqual(items.compactMap(\.date).count, 29)
        XCTAssertNil(items.first?.date)
        XCTAssertNil(items.last?.date)
    }

    func testSixRowGridAlwaysContainsFortyTwoItems() {
        let calendar = makeCalendar(firstWeekday: 1)
        let math = TFYSwiftCalendarMath(calendar: calendar)
        let month = makeDate(2024, 9, 1, calendar: calendar)
        XCTAssertEqual(math.gridItems(for: month, scope: .month, placeholderType: .fillSixRows).count, 42)
    }

    func testRowCountMatchesGeneratedGrid() {
        let calendar = makeCalendar(firstWeekday: 2)
        let math = TFYSwiftCalendarMath(calendar: calendar)
        let months = (1...12).map { makeDate(2024, $0, 1, calendar: calendar) }

        for month in months {
            let expected = math.gridItems(for: month, scope: .month, placeholderType: .fillHeadTail).count / 7
            XCTAssertEqual(
                math.numberOfRows(inMonthContaining: month, placeholderType: .fillHeadTail),
                expected
            )
            XCTAssertEqual(math.numberOfRows(inMonthContaining: month, placeholderType: .fillSixRows), 6)
        }
    }

    func testWeekGridUsesConfiguredFirstWeekday() {
        let calendar = makeCalendar(firstWeekday: 2)
        let math = TFYSwiftCalendarMath(calendar: calendar)
        let wednesday = makeDate(2024, 5, 8, calendar: calendar)
        let items = math.gridItems(for: wednesday, scope: .week, placeholderType: .fillSixRows)
        let first = calendar.dateComponents([.year, .month, .day, .weekday], from: items[0].date!)
        let last = calendar.dateComponents([.year, .month, .day], from: items[6].date!)

        XCTAssertEqual(first.weekday, 2)
        XCTAssertEqual(first.day, 6)
        XCTAssertEqual(last.day, 12)
    }

    func testMonthAndWeekPageIndexRoundTrip() {
        let calendar = makeCalendar()
        let math = TFYSwiftCalendarMath(calendar: calendar)
        let start = makeDate(2023, 1, 15, calendar: calendar)
        let target = makeDate(2024, 6, 20, calendar: calendar)

        let monthIndex = math.pageIndex(for: target, scope: .month, startingAt: start)
        XCTAssertEqual(monthIndex, 17)
        XCTAssertEqual(math.pageIndex(for: math.pageDate(at: monthIndex, scope: .month, startingAt: start), scope: .month, startingAt: start), monthIndex)

        let weekIndex = math.pageIndex(for: target, scope: .week, startingAt: start)
        XCTAssertGreaterThan(weekIndex, 0)
        XCTAssertEqual(math.pageIndex(for: math.pageDate(at: weekIndex, scope: .week, startingAt: start), scope: .week, startingAt: start), weekIndex)
    }
}
