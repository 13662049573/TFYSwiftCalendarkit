import UIKit

@MainActor
public protocol TFYSwiftCalendarDataSource: AnyObject {
    func minimumDate(for calendar: TFYSwiftCalendar) -> Date?
    func maximumDate(for calendar: TFYSwiftCalendar) -> Date?
    func calendar(_ calendar: TFYSwiftCalendar, contentFor date: Date) -> TFYSwiftCalendarDayContent
    /// Supplies content with a position that remains stable while adjacent pages are preloaded.
    func calendar(
        _ calendar: TFYSwiftCalendar,
        contentFor date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) -> TFYSwiftCalendarDayContent
    func calendar(
        _ calendar: TFYSwiftCalendar,
        cellFor date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) -> TFYSwiftCalendarCell?
}

public extension TFYSwiftCalendarDataSource {
    func minimumDate(for calendar: TFYSwiftCalendar) -> Date? { nil }
    func maximumDate(for calendar: TFYSwiftCalendar) -> Date? { nil }
    func calendar(_ calendar: TFYSwiftCalendar, contentFor date: Date) -> TFYSwiftCalendarDayContent {
        TFYSwiftCalendarDayContent()
    }
    func calendar(
        _ calendar: TFYSwiftCalendar,
        contentFor date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) -> TFYSwiftCalendarDayContent {
        self.calendar(calendar, contentFor: date)
    }
    func calendar(
        _ calendar: TFYSwiftCalendar,
        cellFor date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) -> TFYSwiftCalendarCell? { nil }
}

@MainActor
public protocol TFYSwiftCalendarDelegate: AnyObject {
    func calendar(
        _ calendar: TFYSwiftCalendar,
        shouldSelect date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) -> Bool
    func calendar(
        _ calendar: TFYSwiftCalendar,
        didSelect date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    )
    func calendar(
        _ calendar: TFYSwiftCalendar,
        shouldDeselect date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) -> Bool
    func calendar(
        _ calendar: TFYSwiftCalendar,
        didDeselect date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    )
    func calendar(_ calendar: TFYSwiftCalendar, boundingRectWillChange bounds: CGRect, animated: Bool)
    func calendar(_ calendar: TFYSwiftCalendar, willDisplay cell: TFYSwiftCalendarCell, for date: Date)
    func calendarCurrentPageDidChange(_ calendar: TFYSwiftCalendar)
    func calendar(_ calendar: TFYSwiftCalendar, didReachMaximumSelectionCount maximum: Int)
    func calendar(_ calendar: TFYSwiftCalendar, styleFor date: Date) -> TFYSwiftCalendarDayStyle?
    /// Supplies a style with a position that remains stable while adjacent pages are preloaded.
    func calendar(
        _ calendar: TFYSwiftCalendar,
        styleFor date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) -> TFYSwiftCalendarDayStyle?
}

public extension TFYSwiftCalendarDelegate {
    func calendar(
        _ calendar: TFYSwiftCalendar,
        shouldSelect date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) -> Bool { true }

    func calendar(
        _ calendar: TFYSwiftCalendar,
        didSelect date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) {}

    func calendar(
        _ calendar: TFYSwiftCalendar,
        shouldDeselect date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) -> Bool { true }

    func calendar(
        _ calendar: TFYSwiftCalendar,
        didDeselect date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) {}

    func calendar(_ calendar: TFYSwiftCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {}
    func calendar(_ calendar: TFYSwiftCalendar, willDisplay cell: TFYSwiftCalendarCell, for date: Date) {}
    func calendarCurrentPageDidChange(_ calendar: TFYSwiftCalendar) {}
    func calendar(_ calendar: TFYSwiftCalendar, didReachMaximumSelectionCount maximum: Int) {}
    func calendar(_ calendar: TFYSwiftCalendar, styleFor date: Date) -> TFYSwiftCalendarDayStyle? { nil }
    func calendar(
        _ calendar: TFYSwiftCalendar,
        styleFor date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) -> TFYSwiftCalendarDayStyle? {
        self.calendar(calendar, styleFor: date)
    }
}
