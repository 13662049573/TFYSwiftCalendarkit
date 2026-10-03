#if canImport(SwiftUI)
import SwiftUI

@available(iOS 16.0, *)
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
        context.coordinator.synchronize(calendar, parent: self, animated: false)
        return calendar
    }

    public func updateUIView(_ calendar: TFYSwiftCalendar, context: Context) {
        context.coordinator.synchronize(calendar, parent: self, animated: true)
    }

    public static func dismantleUIView(_ calendar: TFYSwiftCalendar, coordinator: Coordinator) {
        coordinator.invalidatePendingSynchronization()
        calendar.delegate = nil
        calendar.dataSource = nil
    }

    @MainActor
    public final class Coordinator: NSObject, TFYSwiftCalendarDataSource, TFYSwiftCalendarDelegate {
        fileprivate var parent: TFYSwiftCalendarView
        private var isSynchronizingFromSwiftUI = false
        private var synchronizationRevision = 0
        private var lastBoundPage: Date?

        fileprivate init(parent: TFYSwiftCalendarView) {
            self.parent = parent
        }

        public func calendar(_ calendar: TFYSwiftCalendar, contentFor date: Date) -> TFYSwiftCalendarDayContent {
            parent.contentProvider(date)
        }

        public func calendar(_ calendar: TFYSwiftCalendar, styleFor date: Date) -> TFYSwiftCalendarDayStyle? {
            parent.styleProvider(date)
        }

        // Shared by make/update so configuration callbacks cannot write bindings during a SwiftUI update.
        internal func synchronize(_ calendar: TFYSwiftCalendar, parent: TFYSwiftCalendarView, animated: Bool) {
            self.parent = parent
            invalidatePendingSynchronization()
            isSynchronizingFromSwiftUI = true
            defer { isSynchronizingFromSwiftUI = false }
            parent.configure(calendar)
            calendar.dataSource = self
            calendar.delegate = self
            if let scope = parent.scope?.wrappedValue { calendar.setScope(scope, animated: animated) }
            // The configuration's single/multiple selection policy is authoritative.
            calendar.selectDates(parent.selectedDates, replacingCurrentSelection: true, scrollToLastDate: false)
            if let page = parent.currentPage?.wrappedValue, page != lastBoundPage {
                calendar.setCurrentPage(page, animated: animated)
                lastBoundPage = page
            }
            calendar.invalidateAppearance()
            reconcileBindingsAfterUpdate(calendar)
        }

        fileprivate func invalidatePendingSynchronization() {
            synchronizationRevision += 1
        }

        private func reconcileBindingsAfterUpdate(_ calendar: TFYSwiftCalendar) {
            let revision = synchronizationRevision
            Task { @MainActor [weak self, weak calendar] in
                await Task.yield()
                guard let self, let calendar, revision == self.synchronizationRevision else { return }
                self.publishState(calendar)
            }
        }

        private func publishState(_ calendar: TFYSwiftCalendar) {
            if parent.selectedDates != calendar.selectedDates { parent.selectedDates = calendar.selectedDates }
            if let page = parent.currentPage {
                lastBoundPage = calendar.currentPage
                if page.wrappedValue != calendar.currentPage { page.wrappedValue = calendar.currentPage }
            }
            if let scope = parent.scope, scope.wrappedValue != calendar.scope { scope.wrappedValue = calendar.scope }
        }

        public func calendarSelectionDidChange(_ calendar: TFYSwiftCalendar) {
            guard !isSynchronizingFromSwiftUI else { return }
            invalidatePendingSynchronization()
            publishState(calendar)
        }

        public func calendarCurrentPageDidChange(_ calendar: TFYSwiftCalendar) {
            guard !isSynchronizingFromSwiftUI else { return }
            invalidatePendingSynchronization()
            publishState(calendar)
        }

        public func calendar(_ calendar: TFYSwiftCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
            guard !isSynchronizingFromSwiftUI else { return }
            invalidatePendingSynchronization()
            publishState(calendar)
        }
    }
}
#endif
