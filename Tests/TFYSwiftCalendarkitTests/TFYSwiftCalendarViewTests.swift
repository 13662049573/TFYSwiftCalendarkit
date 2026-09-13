import XCTest
@testable import TFYSwiftCalendarkit

@MainActor
final class TFYSwiftCalendarViewTests: XCTestCase {
    private var systemCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        systemCalendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    func testSelectionHonorsSingleAndMultipleSelectionModes() {
        let view = makeCalendarView()
        let first = date(2024, 5, 5)
        let second = date(2024, 5, 6)

        view.selectDate(first, scrollToDate: false)
        view.selectDate(second, scrollToDate: false)
        XCTAssertEqual(view.selectedDates.count, 1)
        XCTAssertTrue(systemCalendar.isDate(view.selectedDates[0], inSameDayAs: second))

        view.allowsMultipleSelection = true
        view.selectDate(first, scrollToDate: false)
        XCTAssertEqual(view.selectedDates.count, 2)

        view.deselectDate(second)
        XCTAssertEqual(view.selectedDates.count, 1)
        XCTAssertTrue(systemCalendar.isDate(view.selectedDates[0], inSameDayAs: first))
    }

    func testOutOfRangeDateIsRejectedWithoutCrashing() {
        let view = makeCalendarView()
        view.selectDate(date(2030, 1, 1), scrollToDate: false)
        XCTAssertTrue(view.selectedDates.isEmpty)
    }

    func testDefaultRangeUsesCivilDatesInConfiguredTimeZone() {
        let view = TFYSwiftCalendar()
        view.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let lower = view.calendar.dateComponents([.year, .month, .day], from: view.minimumDate)
        let upper = view.calendar.dateComponents([.year, .month, .day], from: view.maximumDate)
        XCTAssertEqual(lower.year, 1970)
        XCTAssertEqual(lower.month, 1)
        XCTAssertEqual(lower.day, 1)
        XCTAssertEqual(upper.year, 2099)
        XCTAssertEqual(upper.month, 12)
        XCTAssertEqual(upper.day, 31)
    }

    func testScopeChangesPreferredHeightAndNotifiesDelegate() {
        let view = makeCalendarView()
        let spy = DelegateSpy()
        view.delegate = spy
        let monthHeight = view.preferredHeight

        view.setScope(.week, animated: false)

        XCTAssertEqual(view.scope, .week)
        XCTAssertLessThan(view.preferredHeight, monthHeight)
        XCTAssertEqual(spy.boundingRectChanges.count, 1)
        XCTAssertEqual(spy.boundingRectChanges[0].height, view.preferredHeight, accuracy: 0.1)
    }

    func testDataSourceCanOverrideRangeAndContent() {
        let view = makeCalendarView()
        let source = DataSourceStub(
            minimum: date(2024, 4, 1),
            maximum: date(2024, 4, 30)
        )
        view.dataSource = source
        view.reloadData()

        XCTAssertTrue(systemCalendar.isDate(view.minimumDate, inSameDayAs: source.minimum))
        XCTAssertTrue(systemCalendar.isDate(view.maximumDate, inSameDayAs: source.maximum))
        XCTAssertEqual(source.calendar(view, contentFor: date(2024, 4, 3)).subtitle, "Event")
    }

    func testCurrentPageIsClampedToRange() {
        let view = makeCalendarView()
        view.setCurrentPage(date(2030, 1, 1), animated: false)
        XCTAssertTrue(systemCalendar.isDate(view.currentPage, equalTo: date(2024, 12, 1), toGranularity: .month))
    }

    func testVisibleCellReceivesContentAndAccessibilityConfiguration() {
        let view = makeCalendarView()
        let source = DataSourceStub(
            minimum: date(2024, 1, 1),
            maximum: date(2024, 12, 31)
        )
        view.dataSource = source
        view.reloadData()
        view.layoutIfNeeded()
        view.collectionView.layoutIfNeeded()

        let cell = view.cell(for: date(2024, 5, 5))
        XCTAssertNotNil(cell)
        XCTAssertEqual(cell?.subtitleLabel.text, "Event")
        XCTAssertFalse(cell?.accessibilityLabel?.isEmpty ?? true)
    }

    func testRangeSelectionCreatesAContiguousSet() {
        let view = makeCalendarView()
        view.selectDates(
            from: date(2024, 5, 5),
            through: date(2024, 5, 9),
            replacingCurrentSelection: true,
            scrollToLastDate: false
        )
        XCTAssertEqual(view.selectedDates.count, 5)
    }

    func testEmptyEventColorArrayIsSafe() {
        let indicator = TFYSwiftCalendarEventIndicator(frame: CGRect(x: 0, y: 0, width: 80, height: 8))
        indicator.colors = []
        indicator.layoutIfNeeded()
        XCTAssertTrue(indicator.layer.sublayers?.isEmpty ?? true)
    }

    func testChineseSingleCharacterWeekdaysRemainDistinct() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.firstWeekday = 2
        let appearance = TFYSwiftCalendarAppearance()
        appearance.caseOptions = [.weekdaySingleCharacter]
        let weekdayView = TFYSwiftCalendarWeekdayView()

        weekdayView.update(calendar: calendar, locale: Locale(identifier: "zh_CN"), appearance: appearance)

        XCTAssertEqual(weekdayView.weekdayLabels.compactMap(\.text), ["一", "二", "三", "四", "五", "六", "日"])
    }

    func testDenseCalendarLabelsCapDynamicTypeWithoutDisablingIt() {
        let cell = TFYSwiftCalendarCell()
        let header = TFYSwiftCalendarHeaderView()
        let weekday = TFYSwiftCalendarWeekdayView()

        XCTAssertTrue(cell.titleLabel.adjustsFontForContentSizeCategory)
        XCTAssertEqual(cell.titleLabel.maximumContentSizeCategory, .extraExtraLarge)
        XCTAssertTrue(header.titleLabel.adjustsFontForContentSizeCategory)
        XCTAssertEqual(header.titleLabel.maximumContentSizeCategory, .extraExtraExtraLarge)
        XCTAssertTrue(weekday.weekdayLabels.allSatisfy(\.adjustsFontForContentSizeCategory))
        XCTAssertTrue(weekday.weekdayLabels.allSatisfy { $0.maximumContentSizeCategory == .extraExtraLarge })
    }

    func testCustomCellsCanBeDequeuedForBoundaryPlaceholders() {
        let view = TFYSwiftCalendar(frame: CGRect(x: 0, y: 0, width: 390, height: 300))
        view.calendar = systemCalendar
        view.configuredDateRange = date(2024, 5, 1)...date(2024, 5, 31)
        view.placeholderType = .fillHeadTail
        view.register(TestCalendarCell.self, forCellReuseIdentifier: "custom")
        let source = CustomCellDataSource()
        view.dataSource = source
        view.reloadData()
        view.setCurrentPage(date(2024, 5, 1), animated: false)
        view.layoutIfNeeded()
        view.collectionView.layoutIfNeeded()

        XCTAssertGreaterThan(source.dequeuedCellCount, 0)
        XCTAssertTrue(view.visibleCells.contains { $0 is TestCalendarCell })
    }

    private func makeCalendarView() -> TFYSwiftCalendar {
        let view = TFYSwiftCalendar(frame: CGRect(x: 0, y: 0, width: 390, height: 300))
        view.calendar = systemCalendar
        view.locale = Locale(identifier: "en_US_POSIX")
        view.timeZone = TimeZone(secondsFromGMT: 0)!
        view.firstWeekday = 2
        view.configuredDateRange = date(2024, 1, 1)...date(2024, 12, 31)
        view.setCurrentPage(date(2024, 5, 1), animated: false)
        view.layoutIfNeeded()
        return view
    }
}

@MainActor
private final class DelegateSpy: TFYSwiftCalendarDelegate {
    var boundingRectChanges: [CGRect] = []

    func calendar(_ calendar: TFYSwiftCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        boundingRectChanges.append(bounds)
    }
}

@MainActor
private final class DataSourceStub: TFYSwiftCalendarDataSource {
    let minimum: Date
    let maximum: Date

    init(minimum: Date, maximum: Date) {
        self.minimum = minimum
        self.maximum = maximum
    }

    func minimumDate(for calendar: TFYSwiftCalendar) -> Date? { minimum }
    func maximumDate(for calendar: TFYSwiftCalendar) -> Date? { maximum }

    func calendar(_ calendar: TFYSwiftCalendar, contentFor date: Date) -> TFYSwiftCalendarDayContent {
        TFYSwiftCalendarDayContent(subtitle: "Event")
    }
}

@MainActor
private final class TestCalendarCell: TFYSwiftCalendarCell {}

@MainActor
private final class CustomCellDataSource: TFYSwiftCalendarDataSource {
    var dequeuedCellCount = 0

    func calendar(
        _ calendar: TFYSwiftCalendar,
        cellFor date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) -> TFYSwiftCalendarCell? {
        dequeuedCellCount += 1
        return calendar.dequeueReusableCell(withIdentifier: "custom", for: date, at: monthPosition)
    }
}
