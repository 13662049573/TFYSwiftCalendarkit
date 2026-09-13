import EventKit
import SwiftUI
import TFYSwiftCalendarkit
import UIKit

final class DIYExampleViewController: UIViewController, TFYSwiftCalendarDataSource, TFYSwiftCalendarDelegate, EventDemoPresenting {
    let calendarView = TFYSwiftCalendar()
    let eventStore = DemoEventStore()
    let eventMinimumDate = DemoDate.adding(.year, value: -1)
    let eventMaximumDate = DemoDate.adding(.year, value: 4)
    private let lunarFormatter = TFYSwiftLunarFormatter(timeZone: TimeZone(identifier: "Asia/Shanghai") ?? .current)
    private let statusLabel = UILabel()
    private var showsLunar = false
    private var showsEvents = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "DIY 日历"
        view.backgroundColor = .systemGroupedBackground

        calendarView.applyDemoDefaults()
        calendarView.dataSource = self
        calendarView.delegate = self
        calendarView.allowsMultipleSelection = true
        calendarView.today = nil
        calendarView.calendarHeaderView.backgroundColor = UIColor.systemRed.withAlphaComponent(0.10)
        calendarView.calendarWeekdayView.backgroundColor = .systemOrange
        calendarView.appearance.eventSelectionColor = .white
        calendarView.appearance.selectionColor = .systemOrange
        calendarView.appearance.fillType = .linked

        statusLabel.font = .preferredFont(forTextStyle: .footnote)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.text = "可切换农历和设备日历事件；支持多选"

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "事件", style: .plain, target: self, action: #selector(toggleEvents)),
            UIBarButtonItem(title: "农历", style: .plain, target: self, action: #selector(toggleLunar)),
            UIBarButtonItem(title: "今天", style: .plain, target: self, action: #selector(showToday))
        ]

        [calendarView, statusLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calendarView.heightAnchor.constraint(equalToConstant: calendarView.preferredHeight),
            statusLabel.topAnchor.constraint(equalTo: calendarView.bottomAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    func minimumDate(for calendar: TFYSwiftCalendar) -> Date? { eventMinimumDate }
    func maximumDate(for calendar: TFYSwiftCalendar) -> Date? { eventMaximumDate }

    func calendar(_ calendar: TFYSwiftCalendar, contentFor date: Date) -> TFYSwiftCalendarDayContent {
        let events = showsEvents ? eventStore.events(on: date, calendar: calendar.calendar) : []
        let subtitle = events.first?.title ?? (showsLunar ? lunarFormatter.string(from: date) : nil)
        return TFYSwiftCalendarDayContent(
            title: calendar.calendar.isDateInToday(date) ? "今" : nil,
            subtitle: subtitle,
            eventColors: Array(events.prefix(3)).map(eventColor)
        )
    }

    func calendar(_ calendar: TFYSwiftCalendar, styleFor date: Date) -> TFYSwiftCalendarDayStyle? {
        var style = TFYSwiftCalendarDayStyle()
        style.selectionFillColor = .systemOrange
        style.fillType = .linked
        return style
    }

    func calendar(
        _ calendar: TFYSwiftCalendar,
        didSelect date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) {
        statusLabel.text = "已选 \(calendar.selectedDates.count) 天，最近：\(DemoDate.text(date))"
    }

    private func eventColor(_ event: EKEvent) -> UIColor {
        UIColor(cgColor: event.calendar.cgColor)
    }

    @objc private func showToday() { calendarView.setCurrentPage(Date(), animated: true) }

    @objc private func toggleLunar() {
        showsLunar.toggle()
        calendarView.reloadData()
    }

    @objc private func toggleEvents() {
        showsEvents.toggle()
        calendarView.reloadData()
        if showsEvents && eventStore.events.isEmpty { requestCalendarEvents() }
    }
}

final class FullScreenExampleViewController: UIViewController, TFYSwiftCalendarDataSource, TFYSwiftCalendarDelegate, EventDemoPresenting {
    let calendarView = TFYSwiftCalendar()
    let eventStore = DemoEventStore()
    let eventMinimumDate = DemoDate.adding(.year, value: -8)
    let eventMaximumDate = DemoDate.adding(.year, value: 5)
    private let lunarFormatter = TFYSwiftLunarFormatter(timeZone: TimeZone(identifier: "Asia/Shanghai") ?? .current)
    private var showsLunar = false
    private var showsEvents = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "全屏日历"
        view.backgroundColor = .systemBackground

        calendarView.applyDemoDefaults()
        calendarView.dataSource = self
        calendarView.delegate = self
        calendarView.pagingEnabled = false
        calendarView.scrollDirection = .vertical
        calendarView.allowsMultipleSelection = true
        calendarView.placeholderType = .fillHeadTail
        calendarView.appearance.caseOptions = [.weekdaySingleCharacter, .headerUppercase]
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(calendarView)
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calendarView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(title: "事件", style: .plain, target: self, action: #selector(toggleEvents)),
            UIBarButtonItem(title: "农历", style: .plain, target: self, action: #selector(toggleLunar)),
            UIBarButtonItem(title: "今天", style: .plain, target: self, action: #selector(showToday))
        ]
    }

    func minimumDate(for calendar: TFYSwiftCalendar) -> Date? { eventMinimumDate }
    func maximumDate(for calendar: TFYSwiftCalendar) -> Date? { eventMaximumDate }

    func calendar(_ calendar: TFYSwiftCalendar, contentFor date: Date) -> TFYSwiftCalendarDayContent {
        let events = showsEvents ? eventStore.events(on: date, calendar: calendar.calendar) : []
        let detail = events.first?.title ?? (showsLunar ? lunarFormatter.string(from: date) : nil)
        return TFYSwiftCalendarDayContent(
            subtitle: detail,
            topSubtitle: detail,
            eventColors: Array(events.prefix(3)).map { UIColor(cgColor: $0.calendar.cgColor) }
        )
    }

    @objc private func showToday() { calendarView.setCurrentPage(Date(), animated: true) }

    @objc private func toggleLunar() {
        showsLunar.toggle()
        calendarView.reloadData()
    }

    @objc private func toggleEvents() {
        showsEvents.toggle()
        calendarView.reloadData()
        if showsEvents && eventStore.events.isEmpty { requestCalendarEvents() }
    }
}

final class DelegateAppearanceViewController: UIViewController, TFYSwiftCalendarDataSource, TFYSwiftCalendarDelegate {
    private let calendarView = TFYSwiftCalendar()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "逐日期外观"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "今天", style: .plain, target: self, action: #selector(showToday))

        calendarView.applyDemoDefaults()
        calendarView.dataSource = self
        calendarView.delegate = self
        calendarView.swipeToChooseGestureRecognizer.isEnabled = true
        calendarView.allowsMultipleSelection = true
        calendarView.appearance.headerDateFormat = "yyyy/MM/dd"
        calendarView.appearance.fillType = .linked
        calendarView.appearance.separatorStyle = .rows
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(calendarView)
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calendarView.heightAnchor.constraint(equalToConstant: calendarView.preferredHeight)
        ])

        calendarView.selectDates(from: DemoDate.day(20), through: DemoDate.day(25), scrollToLastDate: false)
    }

    func calendar(_ calendar: TFYSwiftCalendar, contentFor date: Date) -> TFYSwiftCalendarDayContent {
        let day = calendar.calendar.component(.day, from: date)
        let eventColors: [UIColor]
        switch day {
        case 3, 4, 5, 6: eventColors = [.systemRed]
        case 26, 27, 28, 29: eventColors = [.systemPink, .systemBlue, .label]
        default: eventColors = []
        }
        let hasImage = [11, 13, 15, 17].contains(day)
        let symbol = hasImage ? DemoSymbol.image(day.isMultiple(of: 2) ? "pawprint.fill" : "cat.fill", color: .systemTeal) : nil
        let labels = [6: "晚上", 8: "上午", 17: "中午", 21: "全天"]
        return TFYSwiftCalendarDayContent(
            subtitle: labels[day],
            topSubtitle: labels[day],
            image: symbol,
            topImage: symbol,
            eventColors: eventColors,
            accessibilityHint: hasImage ? "展示自定义图片" : nil
        )
    }

    func calendar(_ calendar: TFYSwiftCalendar, styleFor date: Date) -> TFYSwiftCalendarDayStyle? {
        let day = calendar.calendar.component(.day, from: date)
        var style = TFYSwiftCalendarDayStyle()
        var customized = false

        if (6...17).contains(day) {
            let palette: [UIColor] = [.systemPurple, .systemGreen, .systemCyan, .systemYellow]
            style.fillColor = palette[day % palette.count].withAlphaComponent(0.18)
            customized = true
        }
        if [8, 17, 21, 25].contains(day) {
            style.selectionFillColor = [.systemRed, .systemGray, .systemCyan, .systemIndigo][day % 4]
            style.borderColor = .systemBrown
            style.selectionBorderColor = .systemPurple
            style.borderRadius = 0
            customized = true
        }
        if [6, 8, 17, 21].contains(day) {
            style.subtitleColor = .systemPurple
            style.selectionSubtitleColor = .systemYellow
            style.topSubtitleColor = .systemTeal
            style.selectionTopSubtitleColor = .white
            customized = true
        }
        if [11, 13, 15, 17].contains(day) {
            style.imageOffset = CGPoint(x: 0, y: 2)
            style.topImageOffset = CGPoint(x: 0, y: -3)
            customized = true
        }
        if (20...25).contains(day) {
            style.fillType = .linked
            style.selectionPosition = day == 20 ? .left : (day == 25 ? .right : .middle)
            style.selectionEventColors = [.white, .systemYellow]
            customized = true
        }
        if day == 28 {
            style.titleOffset = CGPoint(x: 3, y: -2)
            style.subtitleOffset = CGPoint(x: 0, y: 2)
            style.eventOffset = CGPoint(x: 0, y: -2)
            customized = true
        }
        return customized ? style : nil
    }

    @objc private func showToday() { calendarView.setCurrentPage(Date(), animated: false) }
}

private struct SwiftUICalendarDemo: View {
    @State private var selectedDates: [Date] = []
    @State private var currentPage = Date()
    @State private var scope = TFYSwiftCalendarScope.month
    private let lunar = TFYSwiftLunarFormatter(timeZone: TimeZone(identifier: "Asia/Shanghai") ?? .current)

    var body: some View {
        VStack(spacing: 20) {
            Picker("范围", selection: $scope) {
                Text("月").tag(TFYSwiftCalendarScope.month)
                Text("周").tag(TFYSwiftCalendarScope.week)
            }
            .pickerStyle(.segmented)

            TFYSwiftCalendarView(
                selectedDates: $selectedDates,
                currentPage: $currentPage,
                scope: $scope,
                content: { date in
                    TFYSwiftCalendarDayContent(
                        subtitle: lunar.string(from: date),
                        eventColors: DemoDate.gregorian.component(.day, from: date).isMultiple(of: 6) ? [.systemPink] : []
                    )
                },
                style: { date in
                    guard DemoDate.gregorian.isDateInWeekend(date) else { return nil }
                    var style = TFYSwiftCalendarDayStyle()
                    style.titleColor = .systemRed
                    return style
                },
                configure: { calendar in
                    calendar.applyDemoDefaults()
                    calendar.allowsMultipleSelection = true
                    calendar.appearance.selectionColor = .systemIndigo
                }
            )
            .frame(height: scope == .month ? 293 : 103)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Text(selectedDates.isEmpty ? "选择一个或多个日期" : "已选择 \(selectedDates.count) 天")
                .font(.body)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("SwiftUI 封装")
    }
}

@MainActor
func makeSwiftUIDemo() -> UIViewController {
    UIHostingController(rootView: SwiftUICalendarDemo())
}
