import EventKit
import TFYSwiftCalendarkit
import UIKit

@MainActor
protocol DemoSmokeTestable: AnyObject {
    func runSmokeTest()
}

enum DemoDate {
    static let gregorian: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        calendar.firstWeekday = 2
        return calendar
    }()

    static func adding(_ component: Calendar.Component, value: Int, to date: Date = Date()) -> Date {
        gregorian.date(byAdding: component, value: value, to: date) ?? date
    }

    static func day(_ value: Int, relativeTo date: Date = Date()) -> Date {
        let start = gregorian.startOfDay(for: date)
        return gregorian.date(byAdding: .day, value: value, to: start) ?? start
    }

    static func text(_ date: Date, format: String = "yyyy-MM-dd") -> String {
        let formatter = DateFormatter()
        formatter.calendar = gregorian
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = gregorian.timeZone
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}

enum DemoSymbol {
    static func image(_ name: String, color: UIColor = .label) -> UIImage? {
        let configuration = UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        return UIImage(systemName: name, withConfiguration: configuration)?.withTintColor(color, renderingMode: .alwaysOriginal)
    }
}

extension TFYSwiftCalendar {
    func applyDemoDefaults() {
        locale = Locale(identifier: "zh_CN")
        timeZone = TimeZone(identifier: "Asia/Shanghai") ?? .current
        firstWeekday = 2
        appearance.headerDateFormat = "yyyy年 M月"
        appearance.caseOptions = [.weekdaySingleCharacter]
        accessibilityIdentifier = "calendar"
    }
}

@MainActor
final class DemoEventStore {
    private let store = EKEventStore()
    private(set) var events: [EKEvent] = []
    private(set) var hasLoadedEvents = false
    private var isRequestingEvents = false

    func beginRequest() -> Bool {
        guard !isRequestingEvents else { return false }
        isRequestingEvents = true
        return true
    }

    func endRequest() { isRequestingEvents = false }

    func loadEvents(from startDate: Date, through endDate: Date) async throws -> Bool {
        // Keep the non-Sendable EventKit store on MainActor on older SDKs as well.
        let granted = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, any Error>) in
            let completion: @Sendable (Bool, (any Error)?) -> Void = { granted, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: granted)
                }
            }
            if #available(iOS 17.0, *) {
                store.requestFullAccessToEvents(completion: completion)
            } else {
                store.requestAccess(to: .event, completion: completion)
            }
        }
        guard granted else {
            events = []
            hasLoadedEvents = false
            return false
        }
        let calendar = DemoDate.gregorian
        let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate)) ?? endDate
        let predicate = store.predicateForEvents(withStart: calendar.startOfDay(for: startDate), end: end, calendars: nil)
        events = store.events(matching: predicate)
        hasLoadedEvents = true
        return true
    }

    func events(on date: Date, calendar: Calendar) -> [EKEvent] {
        let start = calendar.startOfDay(for: date)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return [] }
        return events.filter { event in
            guard let eventStart = event.startDate else { return false }
            let eventEnd = event.endDate ?? eventStart
            if eventStart == eventEnd { return eventStart >= start && eventStart < end }
            return eventStart < end && eventEnd > start
        }
    }
}

@MainActor
protocol EventDemoPresenting: AnyObject {
    var eventStore: DemoEventStore { get }
    var eventMinimumDate: Date { get }
    var eventMaximumDate: Date { get }
    var calendarView: TFYSwiftCalendar { get }
    var isDisplayingCalendarEvents: Bool { get }
}

extension EventDemoPresenting where Self: UIViewController {
    func requestCalendarEvents() {
        let store = eventStore
        guard store.beginRequest() else { return }
        Task { [weak self] in
            defer { store.endRequest() }
            guard let self else { return }
            do {
                let granted = try await eventStore.loadEvents(from: eventMinimumDate, through: eventMaximumDate)
                guard isDisplayingCalendarEvents else { return }
                guard granted else {
                    presentDemoAlert(title: "无法读取事件", message: "请在系统设置中允许访问日历；农历和其他示例功能仍可正常使用。")
                    return
                }
                calendarView.reloadVisibleDates()
            } catch {
                guard isDisplayingCalendarEvents else { return }
                presentDemoAlert(title: "事件读取失败", message: error.localizedDescription)
            }
        }
    }

    private func presentDemoAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }
}
