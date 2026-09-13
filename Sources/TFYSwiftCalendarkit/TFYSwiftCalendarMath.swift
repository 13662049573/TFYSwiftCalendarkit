import Foundation

public struct TFYSwiftCalendarMath: Sendable {
    public var calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    public func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    public func startOfMonth(for date: Date) -> Date {
        let components = calendar.dateComponents([.era, .year, .month], from: date)
        return calendar.date(from: components) ?? startOfDay(for: date)
    }

    public func startOfWeek(for date: Date) -> Date {
        let day = startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: day)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: -offset, to: day) ?? day
    }

    public func addingDays(_ value: Int, to date: Date) -> Date {
        calendar.date(byAdding: .day, value: value, to: date) ?? date
    }

    public func addingMonths(_ value: Int, to date: Date) -> Date {
        calendar.date(byAdding: .month, value: value, to: startOfMonth(for: date)) ?? date
    }

    public func addingWeeks(_ value: Int, to date: Date) -> Date {
        calendar.date(byAdding: .weekOfYear, value: value, to: startOfWeek(for: date)) ?? date
    }

    public func numberOfDays(inMonthContaining date: Date) -> Int {
        calendar.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    /// Returns the number of visible rows needed to render the month.
    public func numberOfRows(
        inMonthContaining date: Date,
        placeholderType: TFYSwiftCalendarPlaceholderType
    ) -> Int {
        if placeholderType == .fillSixRows { return 6 }
        let month = startOfMonth(for: date)
        let weekday = calendar.component(.weekday, from: month)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        let requiredItems = leading + numberOfDays(inMonthContaining: month)
        return max(1, Int(ceil(Double(requiredItems) / 7.0)))
    }

    public func numberOfMonths(from start: Date, through end: Date) -> Int {
        let lower = startOfMonth(for: start)
        let upper = startOfMonth(for: end)
        return max(1, (calendar.dateComponents([.month], from: lower, to: upper).month ?? 0) + 1)
    }

    public func numberOfWeeks(from start: Date, through end: Date) -> Int {
        let lower = startOfWeek(for: start)
        let upper = startOfWeek(for: end)
        let days = calendar.dateComponents([.day], from: lower, to: upper).day ?? 0
        return max(1, days / 7 + 1)
    }

    public func monthOffset(of date: Date, from start: Date) -> Int {
        calendar.dateComponents(
            [.month],
            from: startOfMonth(for: start),
            to: startOfMonth(for: date)
        ).month ?? 0
    }

    public func weekOffset(of date: Date, from start: Date) -> Int {
        let days = calendar.dateComponents(
            [.day],
            from: startOfWeek(for: start),
            to: startOfWeek(for: date)
        ).day ?? 0
        return days / 7
    }

    public func pageDate(at index: Int, scope: TFYSwiftCalendarScope, startingAt start: Date) -> Date {
        switch scope {
        case .month:
            return addingMonths(index, to: start)
        case .week:
            return addingWeeks(index, to: start)
        }
    }

    public func pageIndex(for date: Date, scope: TFYSwiftCalendarScope, startingAt start: Date) -> Int {
        switch scope {
        case .month:
            return monthOffset(of: date, from: start)
        case .week:
            return weekOffset(of: date, from: start)
        }
    }

    internal func gridItems(
        for pageDate: Date,
        scope: TFYSwiftCalendarScope,
        placeholderType: TFYSwiftCalendarPlaceholderType
    ) -> [TFYSwiftCalendarGridItem] {
        switch scope {
        case .week:
            let first = startOfWeek(for: pageDate)
            return (0..<7).map {
                TFYSwiftCalendarGridItem(date: addingDays($0, to: first), monthPosition: .current)
            }
        case .month:
            return monthGridItems(for: pageDate, placeholderType: placeholderType)
        }
    }

    private func monthGridItems(
        for pageDate: Date,
        placeholderType: TFYSwiftCalendarPlaceholderType
    ) -> [TFYSwiftCalendarGridItem] {
        let month = startOfMonth(for: pageDate)
        let weekday = calendar.component(.weekday, from: month)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        let days = numberOfDays(inMonthContaining: month)
        let total = numberOfRows(inMonthContaining: month, placeholderType: placeholderType) * 7

        return (0..<total).map { item in
            let dayOffset = item - leading
            let date = addingDays(dayOffset, to: month)
            let position: TFYSwiftCalendarMonthPosition
            if dayOffset < 0 {
                position = .previous
            } else if dayOffset >= days {
                position = .next
            } else {
                position = .current
            }
            if placeholderType == .none, position != .current {
                return TFYSwiftCalendarGridItem(date: nil, monthPosition: position)
            }
            return TFYSwiftCalendarGridItem(date: date, monthPosition: position)
        }
    }

    public func isWeekend(_ date: Date) -> Bool {
        calendar.isDateInWeekend(date)
    }

    public func isDate(_ lhs: Date, inSameDayAs rhs: Date) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }
}
