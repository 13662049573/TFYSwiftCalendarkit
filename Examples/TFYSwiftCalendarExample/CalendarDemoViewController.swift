import TFYSwiftCalendarkit
import UIKit

final class CalendarDemoViewController: UIViewController {
    private let calendarView = TFYSwiftCalendar()
    private let scopeControl = UISegmentedControl(items: ["月", "周"])
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let scopeCard = UIView()
    private let calendarCard = UIView()
    private let summaryCard = UIView()
    private let selectionLabel = UILabel()
    private let countLabel = UILabel()
    private let clearButton = UIButton(type: .system)
    private let lunarFormatter = TFYSwiftLunarFormatter(timeZone: TimeZone(identifier: "Asia/Shanghai")!)
    private var calendarHeightConstraint: NSLayoutConstraint!

    private lazy var selectionFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = calendarView.calendar
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = calendarView.timeZone
        formatter.dateFormat = "M月d日"
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "TFYSwiftCalendarkit"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "今天",
            style: .plain,
            target: self,
            action: #selector(showToday)
        )

        configureScopeControl()
        configureCalendar()
        configureSummary()
        configureLayout()
        updateSelectionSummary()
    }

    private func configureScopeControl() {
        scopeControl.selectedSegmentIndex = 0
        scopeControl.selectedSegmentTintColor = .systemIndigo
        scopeControl.backgroundColor = .tertiarySystemFill
        scopeControl.setTitleTextAttributes([.foregroundColor: UIColor.label], for: .normal)
        scopeControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        scopeControl.addTarget(self, action: #selector(scopeChanged), for: .valueChanged)
        scopeControl.accessibilityLabel = "日历显示周期"
    }

    private func configureCalendar() {
        calendarView.dataSource = self
        calendarView.delegate = self
        calendarView.locale = Locale(identifier: "zh_CN")
        calendarView.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        calendarView.firstWeekday = 2
        calendarView.allowsMultipleSelection = true
        calendarView.swipeToChooseGestureRecognizer.isEnabled = true
        calendarView.headerHeight = 54
        calendarView.weekdayHeight = 38
        calendarView.rowHeight = 56
        calendarView.appearance.headerDateFormat = "yyyy年 M月"
        calendarView.appearance.headerTitleFont = .preferredFont(forTextStyle: .title3)
        calendarView.appearance.selectionColor = .systemIndigo
        calendarView.appearance.todaySelectionColor = .systemIndigo
        calendarView.appearance.fillType = .linked
        calendarView.appearance.selectionAnimationScale = 0.96
        calendarView.appearance.selectionAnimationDuration = 0.16

        calendarView.appearance.weekdaySymbols = ["日", "一", "二", "三", "四", "五", "六"]
        calendarView.appearance.weekdayTextColors = [
            .systemRed, .secondaryLabel, .secondaryLabel, .secondaryLabel,
            .secondaryLabel, .secondaryLabel, .systemRed
        ]
        calendarView.appearance.weekdayLabelBackgroundColors = [
            UIColor.systemRed.withAlphaComponent(0.08), .clear, .clear, .clear,
            .clear, .clear, UIColor.systemRed.withAlphaComponent(0.08)
        ]
        calendarView.appearance.weekdayLabelCornerRadius = 10
        calendarView.appearance.weekdayContentInsets = UIEdgeInsets(top: 3, left: 8, bottom: 3, right: 8)
        calendarView.appearance.weekdaySpacing = 4
        calendarView.backgroundColor = .secondarySystemGroupedBackground
        calendarView.layer.cornerRadius = 22
        calendarView.layer.cornerCurve = .continuous
        calendarView.invalidateAppearance()
    }

    private func configureSummary() {
        selectionLabel.font = .preferredFont(forTextStyle: .subheadline)
        selectionLabel.adjustsFontForContentSizeCategory = true
        selectionLabel.textColor = .secondaryLabel
        selectionLabel.numberOfLines = 0

        countLabel.font = .preferredFont(forTextStyle: .footnote)
        countLabel.adjustsFontForContentSizeCategory = true
        countLabel.textAlignment = .center
        countLabel.textColor = .systemIndigo
        countLabel.backgroundColor = UIColor.systemIndigo.withAlphaComponent(0.10)
        countLabel.layer.cornerRadius = 12
        countLabel.layer.cornerCurve = .continuous
        countLabel.clipsToBounds = true
        countLabel.setContentHuggingPriority(.required, for: .horizontal)
        countLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            countLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 58),
            countLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 28)
        ])

        var configuration = UIButton.Configuration.plain()
        configuration.title = "清空"
        configuration.image = UIImage(systemName: "xmark.circle")
        configuration.imagePadding = 5
        clearButton.configuration = configuration
        clearButton.addTarget(self, action: #selector(clearSelection), for: .touchUpInside)
        clearButton.accessibilityHint = "取消所有已选择日期"
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
    }

    private func configureLayout() {
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 14
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        [scopeCard, calendarCard, summaryCard].forEach {
            $0.backgroundColor = .secondarySystemGroupedBackground
            $0.layer.cornerCurve = .continuous
            contentStack.addArrangedSubview($0)
        }
        scopeCard.layer.cornerRadius = 18
        calendarCard.layer.cornerRadius = 24
        summaryCard.layer.cornerRadius = 20

        let scopeTitle = UILabel()
        scopeTitle.font = .preferredFont(forTextStyle: .headline)
        scopeTitle.adjustsFontForContentSizeCategory = true
        scopeTitle.text = "显示周期"
        let scopeHint = UILabel()
        scopeHint.font = .preferredFont(forTextStyle: .caption1)
        scopeHint.adjustsFontForContentSizeCategory = true
        scopeHint.textColor = .secondaryLabel
        scopeHint.text = "月视图 / 周视图"
        let scopeTextStack = UIStackView(arrangedSubviews: [scopeTitle, scopeHint])
        scopeTextStack.axis = .vertical
        scopeTextStack.spacing = 2
        let scopeRow = UIStackView(arrangedSubviews: [scopeTextStack, scopeControl])
        scopeRow.axis = .horizontal
        scopeRow.alignment = .center
        scopeRow.spacing = 12
        scopeRow.translatesAutoresizingMaskIntoConstraints = false
        scopeCard.addSubview(scopeRow)

        calendarView.translatesAutoresizingMaskIntoConstraints = false
        calendarCard.addSubview(calendarView)
        calendarHeightConstraint = calendarView.heightAnchor.constraint(equalToConstant: calendarView.preferredHeight)

        let summaryTitle = UILabel()
        summaryTitle.font = .preferredFont(forTextStyle: .headline)
        summaryTitle.adjustsFontForContentSizeCategory = true
        summaryTitle.text = "选择结果"
        let summaryHeader = UIStackView(arrangedSubviews: [summaryTitle, countLabel, clearButton])
        summaryHeader.axis = .horizontal
        summaryHeader.alignment = .center
        summaryHeader.spacing = 8
        let summaryStack = UIStackView(arrangedSubviews: [summaryHeader, selectionLabel])
        summaryStack.axis = .vertical
        summaryStack.spacing = 10
        summaryStack.translatesAutoresizingMaskIntoConstraints = false
        summaryCard.addSubview(summaryStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),

            scopeRow.topAnchor.constraint(equalTo: scopeCard.topAnchor, constant: 12),
            scopeRow.leadingAnchor.constraint(equalTo: scopeCard.leadingAnchor, constant: 16),
            scopeRow.trailingAnchor.constraint(equalTo: scopeCard.trailingAnchor, constant: -12),
            scopeRow.bottomAnchor.constraint(equalTo: scopeCard.bottomAnchor, constant: -12),
            scopeControl.widthAnchor.constraint(equalToConstant: 174),
            scopeControl.heightAnchor.constraint(equalToConstant: 44),

            calendarView.topAnchor.constraint(equalTo: calendarCard.topAnchor, constant: 8),
            calendarView.leadingAnchor.constraint(equalTo: calendarCard.leadingAnchor, constant: 8),
            calendarView.trailingAnchor.constraint(equalTo: calendarCard.trailingAnchor, constant: -8),
            calendarView.bottomAnchor.constraint(equalTo: calendarCard.bottomAnchor, constant: -8),
            calendarHeightConstraint,

            summaryStack.topAnchor.constraint(equalTo: summaryCard.topAnchor, constant: 16),
            summaryStack.leadingAnchor.constraint(equalTo: summaryCard.leadingAnchor, constant: 16),
            summaryStack.trailingAnchor.constraint(equalTo: summaryCard.trailingAnchor, constant: -12),
            summaryStack.bottomAnchor.constraint(equalTo: summaryCard.bottomAnchor, constant: -16)
        ])
    }

    @objc private func scopeChanged() {
        calendarView.setScope(scopeControl.selectedSegmentIndex == 0 ? .month : .week, animated: true)
    }

    @objc private func showToday() {
        calendarView.setCurrentPage(Date(), animated: true)
        calendarView.selectDate(Date())
    }

    @objc private func clearSelection() {
        calendarView.deselectAllDates()
        updateSelectionSummary()
    }

    private func updateSelectionSummary() {
        let values = calendarView.selectedDates.map(selectionFormatter.string(from:))
        countLabel.text = "\(values.count) 天"
        clearButton.isHidden = values.isEmpty
        selectionLabel.text = values.isEmpty
            ? "点击日期进行选择；长按并滑动可快速连续选择。"
            : values.joined(separator: "  ·  ")
        selectionLabel.accessibilityLabel = values.isEmpty
            ? "尚未选择日期"
            : "已选择：" + values.joined(separator: "，")
    }
}

extension CalendarDemoViewController: TFYSwiftCalendarDataSource {
    func minimumDate(for calendar: TFYSwiftCalendar) -> Date? {
        calendar.calendar.date(byAdding: .year, value: -5, to: Date())
    }

    func maximumDate(for calendar: TFYSwiftCalendar) -> Date? {
        calendar.calendar.date(byAdding: .year, value: 5, to: Date())
    }

    func calendar(_ calendar: TFYSwiftCalendar, contentFor date: Date) -> TFYSwiftCalendarDayContent {
        let belongsToVisibleMonth = calendar.scope == .week ||
            calendar.calendar.isDate(date, equalTo: calendar.currentPage, toGranularity: .month)
        guard belongsToVisibleMonth else { return TFYSwiftCalendarDayContent() }
        let day = calendar.calendar.component(.day, from: date)
        return TFYSwiftCalendarDayContent(
            subtitle: lunarFormatter.string(from: date),
            eventColors: day.isMultiple(of: 5) ? [.systemOrange, .systemPink] : []
        )
    }
}

extension CalendarDemoViewController: TFYSwiftCalendarDelegate {
    func calendar(
        _ calendar: TFYSwiftCalendar,
        didSelect date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) {
        updateSelectionSummary()
    }

    func calendar(
        _ calendar: TFYSwiftCalendar,
        didDeselect date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) {
        updateSelectionSummary()
    }

    func calendar(_ calendar: TFYSwiftCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        calendarHeightConstraint.constant = bounds.height
        scopeControl.selectedSegmentIndex = calendar.scope == .month ? 0 : 1
        let changes = { self.view.layoutIfNeeded() }
        animated ? UIView.animate(withDuration: 0.28, animations: changes) : changes()
    }

    func calendar(_ calendar: TFYSwiftCalendar, styleFor date: Date) -> TFYSwiftCalendarDayStyle? {
        guard calendar.scope == .week ||
                calendar.calendar.isDate(date, equalTo: calendar.currentPage, toGranularity: .month),
              calendar.calendar.isDateInWeekend(date) else { return nil }
        var style = TFYSwiftCalendarDayStyle()
        style.titleColor = .systemRed
        return style
    }
}
