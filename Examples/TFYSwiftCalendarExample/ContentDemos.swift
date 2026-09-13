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
    private var calendarHeightConstraint: NSLayoutConstraint!

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
        calendarHeightConstraint = calendarView.heightAnchor.constraint(equalToConstant: calendarView.preferredHeight)
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calendarHeightConstraint,
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

    func calendar(_ calendar: TFYSwiftCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        calendarHeightConstraint.constant = bounds.height
        let changes = { self.view.layoutIfNeeded() }
        if animated {
            UIView.animate(
                withDuration: 0.28,
                delay: 0,
                options: [.curveEaseInOut, .beginFromCurrentState],
                animations: changes
            )
        } else {
            changes()
        }
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

final class FullScreenExampleViewController: UIViewController, TFYSwiftCalendarDataSource, TFYSwiftCalendarDelegate, EventDemoPresenting, DemoSmokeTestable {
    let calendarView = TFYSwiftCalendar()
    let eventStore = DemoEventStore()
    let eventMinimumDate = DemoDate.adding(.year, value: -8)
    let eventMaximumDate = DemoDate.adding(.year, value: 5)
    private let lunarFormatter = TFYSwiftLunarFormatter(timeZone: TimeZone(identifier: "Asia/Shanghai") ?? .current)
    private var showsLunar = false
    private var showsEvents = false
    private var displayMenuItem: UIBarButtonItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "全屏日历"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemBackground

        calendarView.applyDemoDefaults()
        calendarView.dataSource = self
        calendarView.delegate = self
        calendarView.pagingEnabled = false
        calendarView.scrollDirection = .vertical
        calendarView.allowsMultipleSelection = true
        calendarView.placeholderType = .none
        calendarView.headerHeight = 0
        calendarView.weekdayHeight = 32
        calendarView.rowHeight = 64
        calendarView.continuousSectionHeaderHeight = 44
        calendarView.sectionInsets = UIEdgeInsets(top: 4, left: 8, bottom: 16, right: 8)
        calendarView.appearance.caseOptions = [.weekdaySingleCharacter, .headerUppercase]
        calendarView.appearance.weekdayTextColor = .secondaryLabel
        calendarView.collectionView.showsVerticalScrollIndicator = true
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(calendarView)
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calendarView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        configureNavigationItems()
    }

    func minimumDate(for calendar: TFYSwiftCalendar) -> Date? { eventMinimumDate }
    func maximumDate(for calendar: TFYSwiftCalendar) -> Date? { eventMaximumDate }

    func calendar(_ calendar: TFYSwiftCalendar, contentFor date: Date) -> TFYSwiftCalendarDayContent {
        let events = showsEvents ? eventStore.events(on: date, calendar: calendar.calendar) : []
        let detail = events.first?.title ?? (showsLunar ? lunarFormatter.string(from: date) : nil)
        return TFYSwiftCalendarDayContent(
            subtitle: detail,
            eventColors: Array(events.prefix(3)).map { UIColor(cgColor: $0.calendar.cgColor) }
        )
    }

    func runSmokeTest() {
        toggleLunar()
        calendarView.selectDate(DemoDate.day(-4), scrollToDate: false)
        calendarView.selectDate(DemoDate.day(3), scrollToDate: false)
    }

    private func configureNavigationItems() {
        let todayItem = UIBarButtonItem(
            image: UIImage(systemName: "calendar"),
            style: .plain,
            target: self,
            action: #selector(showToday)
        )
        todayItem.accessibilityLabel = "回到今天"

        let menuItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis.circle"),
            style: .plain,
            target: nil,
            action: nil
        )
        menuItem.accessibilityLabel = "显示选项"
        displayMenuItem = menuItem
        updateDisplayMenu()
        navigationItem.rightBarButtonItems = [menuItem, todayItem]
    }

    private func updateDisplayMenu() {
        let lunarAction = UIAction(
            title: "显示农历",
            image: UIImage(systemName: "moon.stars"),
            state: showsLunar ? .on : .off
        ) { [weak self] _ in
            self?.toggleLunar()
        }
        let eventAction = UIAction(
            title: "显示系统事件",
            image: UIImage(systemName: "calendar.badge.exclamationmark"),
            state: showsEvents ? .on : .off
        ) { [weak self] _ in
            self?.toggleEvents()
        }
        displayMenuItem?.menu = UIMenu(title: "日历内容", children: [lunarAction, eventAction])
    }

    @objc private func showToday() { calendarView.setCurrentPage(Date(), animated: true) }

    @objc private func toggleLunar() {
        showsLunar.toggle()
        updateDisplayMenu()
        calendarView.reloadData()
    }

    @objc private func toggleEvents() {
        showsEvents.toggle()
        updateDisplayMenu()
        calendarView.reloadData()
        if showsEvents && eventStore.events.isEmpty { requestCalendarEvents() }
    }
}

final class DelegateAppearanceViewController: UIViewController, TFYSwiftCalendarDataSource, TFYSwiftCalendarDelegate {
    private let calendarView = TFYSwiftCalendar()
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let calendarCard = UIView()
    private let legendCard = UIView()
    private let selectionLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "逐日期外观"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "今天",
            style: .plain,
            target: self,
            action: #selector(showToday)
        )

        calendarView.applyDemoDefaults()
        calendarView.dataSource = self
        calendarView.delegate = self
        calendarView.headerHeight = 52
        calendarView.weekdayHeight = 30
        calendarView.rowHeight = 54
        calendarView.appearance.selectionColor = .systemIndigo
        calendarView.appearance.todayColor = UIColor.systemOrange.withAlphaComponent(0.12)
        calendarView.appearance.todaySelectionColor = .systemOrange
        calendarView.appearance.fillType = .separate
        calendarView.appearance.separatorStyle = .none

        configureLayout()
        selectShowcaseDate()
    }

    private func configureLayout() {
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        calendarCard.backgroundColor = .secondarySystemGroupedBackground
        calendarCard.layer.cornerRadius = 24
        calendarCard.layer.cornerCurve = .continuous
        calendarCard.layer.shadowColor = UIColor.black.cgColor
        calendarCard.layer.shadowOpacity = 0.06
        calendarCard.layer.shadowRadius = 14
        calendarCard.layer.shadowOffset = CGSize(width: 0, height: 5)

        calendarView.layer.cornerRadius = 24
        calendarView.layer.cornerCurve = .continuous
        calendarView.backgroundColor = .secondarySystemGroupedBackground
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        calendarCard.addSubview(calendarView)
        contentStack.addArrangedSubview(calendarCard)

        legendCard.backgroundColor = .secondarySystemGroupedBackground
        legendCard.layer.cornerRadius = 20
        legendCard.layer.cornerCurve = .continuous
        contentStack.addArrangedSubview(legendCard)
        configureLegend()

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),

            calendarView.topAnchor.constraint(equalTo: calendarCard.topAnchor, constant: 8),
            calendarView.leadingAnchor.constraint(equalTo: calendarCard.leadingAnchor, constant: 8),
            calendarView.trailingAnchor.constraint(equalTo: calendarCard.trailingAnchor, constant: -8),
            calendarView.bottomAnchor.constraint(equalTo: calendarCard.bottomAnchor, constant: -8),
            calendarView.heightAnchor.constraint(equalToConstant: calendarView.preferredHeight)
        ])
    }

    func calendar(_ calendar: TFYSwiftCalendar, contentFor date: Date) -> TFYSwiftCalendarDayContent {
        guard calendar.calendar.isDate(date, equalTo: calendar.currentPage, toGranularity: .month) else {
            return TFYSwiftCalendarDayContent()
        }
        let day = calendar.calendar.component(.day, from: date)
        let eventColors: [UIColor]
        switch day {
        case 3, 10: eventColors = [.systemPink]
        case 17: eventColors = [.systemTeal, .systemBlue]
        case 24: eventColors = [.systemPink, .systemBlue, .label]
        default: eventColors = []
        }
        let imageDays = [7, 21]
        let symbol = imageDays.contains(day) ? DemoSymbol.image("sparkles", color: .systemTeal) : nil
        let labels = [6: "提醒", 15: "假期", 26: "全天"]
        return TFYSwiftCalendarDayContent(
            subtitle: labels[day],
            topImage: symbol,
            eventColors: eventColors,
            accessibilityHint: imageDays.contains(day) ? "展示自定义日期图标" : nil
        )
    }

    func calendar(_ calendar: TFYSwiftCalendar, styleFor date: Date) -> TFYSwiftCalendarDayStyle? {
        guard calendar.calendar.isDate(date, equalTo: calendar.currentPage, toGranularity: .month) else { return nil }
        let day = calendar.calendar.component(.day, from: date)
        var style = TFYSwiftCalendarDayStyle()
        var customized = false

        if let index = [2, 9, 16, 23].firstIndex(of: day) {
            let palette: [UIColor] = [.systemPurple, .systemGreen, .systemCyan, .systemOrange]
            style.fillColor = palette[index].withAlphaComponent(0.14)
            style.borderRadius = 1
            style.fillType = .separate
            customized = true
        }

        if let index = [4, 11, 18, 25].firstIndex(of: day) {
            let palette: [UIColor] = [.systemIndigo, .systemTeal, .systemOrange, .systemPink]
            let color = palette[index]
            style = .circularBorder(
                borderColor: color,
                borderWidth: 2,
                selectionFillColor: color
            )
            style.selectionTitleColor = .white
            customized = true
        }

        if [6, 15, 26].contains(day) {
            style.subtitleColor = .systemIndigo
            style.selectionSubtitleColor = .white
            customized = true
        }

        if [7, 21].contains(day) {
            style.titleColor = .systemTeal
            customized = true
        }

        if calendar.calendar.isDateInToday(date) {
            style.fillType = .separate
            style.borderRadius = 1
            style.fillColor = UIColor.systemOrange.withAlphaComponent(0.10)
            style.borderColor = .systemOrange
            style.borderWidth = 2
            style.selectionFillColor = .systemOrange
            style.selectionBorderColor = .systemOrange
            style.selectionBorderWidth = 2
            customized = true
        }

        return customized ? style : nil
    }

    func calendar(
        _ calendar: TFYSwiftCalendar,
        didSelect date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) {
        selectionLabel.text = "已选择 " + DemoDate.text(date, format: "M月d日 EEEE") + " · 圆形选中态"
    }

    func calendarCurrentPageDidChange(_ calendar: TFYSwiftCalendar) {
        selectShowcaseDate()
    }

    private func configureLegend() {
        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.text = "样式说明"

        selectionLabel.font = .preferredFont(forTextStyle: .footnote)
        selectionLabel.adjustsFontForContentSizeCategory = true
        selectionLabel.textColor = .secondaryLabel
        selectionLabel.numberOfLines = 0
        selectionLabel.text = "点击日期可查看圆形选中态"

        let stack = UIStackView(arrangedSubviews: [
            titleLabel,
            selectionLabel,
            makeLegendRow(symbol: "circle.fill", color: .systemPurple, title: "柔和填充", detail: "低对比背景，不抢占日期信息"),
            makeLegendRow(symbol: "circle", color: .systemIndigo, title: "圆形描边", detail: "支持逐日颜色与 2pt 独立线宽", outlined: true),
            makeLegendRow(symbol: "ellipsis", color: .systemPink, title: "事件标记", detail: "最多三个语义色事件点"),
            makeLegendRow(symbol: "sparkles", color: .systemTeal, title: "图标与标签", detail: "错位展示，避免内容相互叠压")
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.setCustomSpacing(16, after: selectionLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        legendCard.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: legendCard.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: legendCard.leadingAnchor, constant: 18),
            stack.trailingAnchor.constraint(equalTo: legendCard.trailingAnchor, constant: -18),
            stack.bottomAnchor.constraint(equalTo: legendCard.bottomAnchor, constant: -18)
        ])
    }

    private func makeLegendRow(
        symbol: String,
        color: UIColor,
        title: String,
        detail: String,
        outlined: Bool = false
    ) -> UIView {
        let iconContainer = UIView()
        iconContainer.backgroundColor = outlined ? .clear : color.withAlphaComponent(0.12)
        iconContainer.layer.cornerRadius = 18
        iconContainer.layer.borderColor = color.cgColor
        iconContainer.layer.borderWidth = outlined ? 2 : 0
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            iconContainer.widthAnchor.constraint(equalToConstant: 36),
            iconContainer.heightAnchor.constraint(equalToConstant: 36)
        ])

        if outlined {
            let dateLabel = UILabel()
            dateLabel.font = .preferredFont(forTextStyle: .caption1)
            dateLabel.adjustsFontForContentSizeCategory = true
            dateLabel.textAlignment = .center
            dateLabel.textColor = color
            dateLabel.text = "11"
            dateLabel.translatesAutoresizingMaskIntoConstraints = false
            iconContainer.addSubview(dateLabel)
            NSLayoutConstraint.activate([
                dateLabel.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
                dateLabel.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor)
            ])
        } else {
            let imageView = UIImageView(image: UIImage(systemName: symbol))
            imageView.tintColor = color
            imageView.contentMode = .scaleAspectFit
            imageView.translatesAutoresizingMaskIntoConstraints = false
            iconContainer.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
                imageView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
                imageView.widthAnchor.constraint(equalToConstant: 18),
                imageView.heightAnchor.constraint(equalToConstant: 18)
            ])
        }

        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .subheadline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.text = title

        let detailLabel = UILabel()
        detailLabel.font = .preferredFont(forTextStyle: .footnote)
        detailLabel.adjustsFontForContentSizeCategory = true
        detailLabel.textColor = .secondaryLabel
        detailLabel.numberOfLines = 0
        detailLabel.text = detail

        let textStack = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        let row = UIStackView(arrangedSubviews: [iconContainer, textStack])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = 12
        row.isAccessibilityElement = true
        row.accessibilityLabel = "\(title)，\(detail)"
        return row
    }

    private func selectShowcaseDate() {
        var components = calendarView.calendar.dateComponents([.era, .year, .month], from: calendarView.currentPage)
        components.day = 11
        guard let date = calendarView.calendar.date(from: components) else { return }
        calendarView.selectDate(date, scrollToDate: false)
        selectionLabel.text = "已选择 " + DemoDate.text(date, format: "M月d日 EEEE") + " · 圆形选中态"
    }

    @objc private func showToday() {
        let today = Date()
        calendarView.setCurrentPage(today, animated: false)
        calendarView.selectDate(today, scrollToDate: false)
        selectionLabel.text = "已返回今天 · " + DemoDate.text(today, format: "M月d日 EEEE")
    }
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
                    calendar.maximumSelectedDates = 5
                    calendar.appearance.selectionColor = .systemIndigo
                }
            )
            .frame(height: scope == .month ? 297 : 107)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Text(
                selectedDates.isEmpty
                    ? "最多选择 5 个日期"
                    : "已选择 \(selectedDates.count) 天，还可选择 \(max(0, 5 - selectedDates.count)) 天"
            )
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
