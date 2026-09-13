#if canImport(SwiftUI)
import SwiftUI

@available(iOS 15.0, *)
public struct TFYSwiftCalendarView: UIViewRepresentable {
    @Binding private var selectedDates: [Date]
    private var currentPage: Binding<Date>?
    private var scope: Binding<TFYSwiftCalendarScope>?
    private let contentProvider: (Date) -> TFYSwiftCalendarDayContent
    private let styleProvider: (Date) -> TFYSwiftCalendarDayStyle?
    private let configure: (TFYSwiftCalendar) -> Void

    public init(
        selectedDates: Binding<[Date]>,
        currentPage: Binding<Date>? = nil,
        scope: Binding<TFYSwiftCalendarScope>? = nil,
        content: @escaping (Date) -> TFYSwiftCalendarDayContent = { _ in TFYSwiftCalendarDayContent() },
        style: @escaping (Date) -> TFYSwiftCalendarDayStyle? = { _ in nil },
        configure: @escaping (TFYSwiftCalendar) -> Void = { _ in }
    ) {
        _selectedDates = selectedDates
        self.currentPage = currentPage
        self.scope = scope
        contentProvider = content
        styleProvider = style
        self.configure = configure
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public func makeUIView(context: Context) -> TFYSwiftCalendar {
        let calendar = TFYSwiftCalendar()
        configure(calendar)
        calendar.dataSource = context.coordinator
        calendar.delegate = context.coordinator
        synchronizeSelections(in: calendar)
        if let page = currentPage?.wrappedValue {
            calendar.setCurrentPage(page, animated: false)
        }
        if let scope = scope?.wrappedValue {
            calendar.setScope(scope, animated: false)
        }
        return calendar
    }

    public func updateUIView(_ calendar: TFYSwiftCalendar, context: Context) {
        context.coordinator.parent = self
        configure(calendar)
        calendar.dataSource = context.coordinator
        calendar.delegate = context.coordinator
        synchronizeSelections(in: calendar)
        if let page = currentPage?.wrappedValue,
           calendar.calendar.compare(page, to: calendar.currentPage, toGranularity: calendar.scope == .month ? .month : .weekOfYear) != .orderedSame {
            calendar.setCurrentPage(page, animated: true)
        }
        if let requestedScope = scope?.wrappedValue, calendar.scope != requestedScope {
            calendar.setScope(requestedScope, animated: true)
        }
        calendar.invalidateAppearance()
    }

    private func synchronizeSelections(in calendar: TFYSwiftCalendar) {
        let requested = selectedDates.map { calendar.calendar.startOfDay(for: $0) }
        let existing = calendar.selectedDates.map { calendar.calendar.startOfDay(for: $0) }
        for date in existing where !requested.contains(where: { calendar.calendar.isDate($0, inSameDayAs: date) }) {
            calendar.deselectDate(date)
        }
        if requested.count > 1 { calendar.allowsMultipleSelection = true }
        for date in requested where !existing.contains(where: { calendar.calendar.isDate($0, inSameDayAs: date) }) {
            calendar.selectDate(date, scrollToDate: false)
        }
    }

    @MainActor
    public final class Coordinator: NSObject, TFYSwiftCalendarDataSource, TFYSwiftCalendarDelegate {
        fileprivate var parent: TFYSwiftCalendarView

        fileprivate init(parent: TFYSwiftCalendarView) {
            self.parent = parent
        }

        public func calendar(_ calendar: TFYSwiftCalendar, contentFor date: Date) -> TFYSwiftCalendarDayContent {
            parent.contentProvider(date)
        }

        public func calendar(_ calendar: TFYSwiftCalendar, styleFor date: Date) -> TFYSwiftCalendarDayStyle? {
            parent.styleProvider(date)
        }

        public func calendar(
            _ calendar: TFYSwiftCalendar,
            didSelect date: Date,
            at monthPosition: TFYSwiftCalendarMonthPosition
        ) {
            parent.selectedDates = calendar.selectedDates
        }

        public func calendar(
            _ calendar: TFYSwiftCalendar,
            didDeselect date: Date,
            at monthPosition: TFYSwiftCalendarMonthPosition
        ) {
            parent.selectedDates = calendar.selectedDates
        }

        public func calendarCurrentPageDidChange(_ calendar: TFYSwiftCalendar) {
            parent.currentPage?.wrappedValue = calendar.currentPage
        }

        public func calendar(_ calendar: TFYSwiftCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
            parent.scope?.wrappedValue = calendar.scope
        }
    }
}
#endif
