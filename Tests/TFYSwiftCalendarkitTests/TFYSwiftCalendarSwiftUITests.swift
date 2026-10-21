import SwiftUI
import XCTest
@testable import TFYSwiftCalendarkit

@MainActor
final class TFYSwiftCalendarSwiftUITests: XCTestCase {
    private final class State {
        var dates: [Date] = []
        var page = Date()
        var scope = TFYSwiftCalendarScope.month
        var writes = 0
    }

    private var gregorian: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 2
        return calendar
    }

    private func date(_ day: Int) -> Date {
        gregorian.date(from: DateComponents(year: 2024, month: 5, day: day))!
    }

    private func wrapper(_ state: State, multiple: Bool, maximum: Int? = nil) -> TFYSwiftCalendarView {
        TFYSwiftCalendarView(
            selectedDates: Binding(get: { state.dates }, set: { state.dates = $0; state.writes += 1 }),
            currentPage: Binding(get: { state.page }, set: { state.page = $0; state.writes += 1 }),
            scope: Binding(get: { state.scope }, set: { state.scope = $0; state.writes += 1 }),
            configure: { calendar in
                calendar.calendar = self.gregorian
                calendar.configuredDateRange = self.date(1)...self.date(31)
                calendar.allowsMultipleSelection = multiple
                calendar.maximumSelectedDates = maximum
            }
        )
    }

    func testSynchronizationHonorsSingleSelectionAndDefersBindingWrites() async {
        let state = State()
        state.dates = [date(4), date(5)]
        state.page = date(15)
        let parent = wrapper(state, multiple: false)
        let coordinator = parent.makeCoordinator()
        let calendar = TFYSwiftCalendar()
        coordinator.synchronize(calendar, parent: parent, animated: false)
        XCTAssertFalse(calendar.allowsMultipleSelection)
        XCTAssertEqual(calendar.selectedDates, [date(5)])
        XCTAssertEqual(state.writes, 0)
        for _ in 0..<10 { await Task.yield() }
        XCTAssertEqual(state.dates, [date(5)])
        XCTAssertEqual(state.page, date(1))
    }

    func testSelectionLimitAndPruningArePublishedToBindings() async {
        let state = State()
        state.page = date(1)
        state.dates = [date(1), date(2), date(3)]
        let parent = wrapper(state, multiple: true, maximum: 2)
        let coordinator = parent.makeCoordinator()
        let calendar = TFYSwiftCalendar()
        coordinator.synchronize(calendar, parent: parent, animated: false)
        for _ in 0..<10 { await Task.yield() }
        XCTAssertEqual(state.dates, [date(1), date(2)])
        calendar.configuredDateRange = date(2)...date(31)
        XCTAssertEqual(state.dates, [date(2)])
        calendar.deselectAllDates()
        XCTAssertEqual(state.dates, [])
    }

    func testNewerUpdateAndDismantleCancelDeferredBindingChanges() async {
        let state = State()
        state.page = date(1)
        state.dates = [date(1), date(2)]
        let first = wrapper(state, multiple: true, maximum: 1)
        let coordinator = first.makeCoordinator()
        let calendar = TFYSwiftCalendar()
        coordinator.synchronize(calendar, parent: first, animated: false)
        state.dates = [date(8)]
        let second = wrapper(state, multiple: true)
        coordinator.synchronize(calendar, parent: second, animated: false)
        TFYSwiftCalendarView.dismantleUIView(calendar, coordinator: coordinator)
        for _ in 0..<10 { await Task.yield() }
        XCTAssertEqual(state.writes, 0)
        XCTAssertEqual(state.dates, [date(8)])
        XCTAssertNil(calendar.delegate)
        XCTAssertNil(calendar.dataSource)
    }
    func testScopeBindingKeepsRequestedDayAfterPageBindingIsCanonicalized() async {
        let state = State()
        state.page = date(22)
        let first = wrapper(state, multiple: false)
        let coordinator = first.makeCoordinator()
        let calendar = TFYSwiftCalendar()
        coordinator.synchronize(calendar, parent: first, animated: false)
        for _ in 0..<10 { await Task.yield() }
        XCTAssertEqual(state.page, date(1))
        // An unrelated redraw must not replace the focus day with the canonical month start.
        coordinator.synchronize(calendar, parent: wrapper(state, multiple: false), animated: false)
        state.scope = .week
        coordinator.synchronize(calendar, parent: wrapper(state, multiple: false), animated: false)
        XCTAssertEqual(calendar.currentPage, date(20))
        for _ in 0..<10 { await Task.yield() }
        XCTAssertEqual(state.page, date(20))
    }

}
