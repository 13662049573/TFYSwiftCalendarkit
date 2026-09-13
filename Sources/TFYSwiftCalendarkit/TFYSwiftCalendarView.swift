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
        if let scope = scope?.wrappedValue {
            calendar.setScope(scope, animated: false)
        }
        synchronizeSelections(in: calendar, coordinator: context.coordinator)
        if let page = currentPage?.wrappedValue {
            calendar.setCurrentPage(page, animated: false)
        }
        return calendar
    }

    public func updateUIView(_ calendar: TFYSwiftCalendar, context: Context) {
        context.coordinator.parent = self
        configure(calendar)
        calendar.dataSource = context.coordinator
        calendar.delegate = context.coordinator
        context.coordinator.isSynchronizingFromSwiftUI = true
        defer { context.coordinator.isSynchronizingFromSwiftUI = false }
        if let requestedScope = scope?.wrappedValue, calendar.scope != requestedScope {
            calendar.setScope(requestedScope, animated: true)
        }
        synchronizeSelections(in: calendar, coordinator: context.coordinator)
        if let page = currentPage?.wrappedValue,
           calendar.calendar.compare(page, to: calendar.currentPage, toGranularity: calendar.scope == .month ? .month : .weekOfYear) != .orderedSame {
            calendar.setCurrentPage(page, animated: true)
        }
        calendar.invalidateAppearance()
    }

    private func synchronizeSelections(in calendar: TFYSwiftCalendar, coordinator: Coordinator) {
        let wasSynchronizing = coordinator.isSynchronizingFromSwiftUI
        coordinator.isSynchronizingFromSwiftUI = true
        defer { coordinator.isSynchronizingFromSwiftUI = wasSynchronizing }
        let requested = selectedDates.map { calendar.calendar.startOfDay(for: $0) }
        if requested.count > 1 { calendar.allowsMultipleSelection = true }
        calendar.selectDates(requested, replacingCurrentSelection: true, scrollToLastDate: false)
    }

    @MainActor
    public final class Coordinator: NSObject, TFYSwiftCalendarDataSource, TFYSwiftCalendarDelegate {
        fileprivate var parent: TFYSwiftCalendarView
        fileprivate var isSynchronizingFromSwiftUI = false

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
            guard !isSynchronizingFromSwiftUI else { return }
            parent.selectedDates = calendar.selectedDates
        }

        public func calendar(
            _ calendar: TFYSwiftCalendar,
            didDeselect date: Date,
            at monthPosition: TFYSwiftCalendarMonthPosition
        ) {
            guard !isSynchronizingFromSwiftUI else { return }
            parent.selectedDates = calendar.selectedDates
        }

        public func calendarCurrentPageDidChange(_ calendar: TFYSwiftCalendar) {
            guard !isSynchronizingFromSwiftUI else { return }
            parent.currentPage?.wrappedValue = calendar.currentPage
        }

        public func calendar(_ calendar: TFYSwiftCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
            guard !isSynchronizingFromSwiftUI else { return }
            parent.scope?.wrappedValue = calendar.scope
        }
    }
}
#endif
