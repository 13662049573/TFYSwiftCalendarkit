import TFYSwiftCalendarkit
import UIKit

private enum RangeCellRole {
    case none
    case start
    case middle
    case end
    case single
}

private enum RangeActionStyle {
    case tinted
    case gray
}

private final class RangePickerCell: TFYSwiftCalendarCell {
    private let rangeLayer = CALayer()
    private let endpointLayer = CALayer()
    private var role: RangeCellRole = .none

    override init(frame: CGRect) {
        super.init(frame: frame)
        rangeLayer.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.24).cgColor
        endpointLayer.backgroundColor = UIColor.systemOrange.cgColor
        contentView.layer.insertSublayer(rangeLayer, below: titleLabel.layer)
        contentView.layer.insertSublayer(endpointLayer, below: titleLabel.layer)
        shapeLayer.isHidden = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        apply(role: .none)
    }

    override func configureAppearance() {
        super.configureAppearance()
        shapeLayer.isHidden = true
        titleLabel.textColor = cellState.contains(.selected) ? .white : .label
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        rangeLayer.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.24).resolvedColor(with: traitCollection).cgColor
        endpointLayer.backgroundColor = UIColor.systemOrange.resolvedColor(with: traitCollection).cgColor
        titleLabel.frame = contentView.bounds
        rangeLayer.frame = CGRect(x: 0, y: contentView.bounds.midY - 20, width: contentView.bounds.width, height: 40)
        let diameter = min(40, min(contentView.bounds.width, contentView.bounds.height) - 6)
        endpointLayer.frame = CGRect(
            x: contentView.bounds.midX - diameter / 2,
            y: contentView.bounds.midY - diameter / 2,
            width: diameter,
            height: diameter
        )
        endpointLayer.cornerRadius = diameter / 2
    }

    func apply(role: RangeCellRole) {
        self.role = role
        rangeLayer.isHidden = role == .none || role == .single
        endpointLayer.isHidden = role == .none || role == .middle
        switch role {
        case .start:
            rangeLayer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
            rangeLayer.cornerRadius = 20
        case .end:
            rangeLayer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
            rangeLayer.cornerRadius = 20
        default:
            rangeLayer.maskedCorners = []
            rangeLayer.cornerRadius = 0
        }
        setNeedsLayout()
    }
}

final class RangePickerViewController: UIViewController, TFYSwiftCalendarDataSource, TFYSwiftCalendarDelegate, DemoSmokeTestable {
    private let calendarView = TFYSwiftCalendar()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let selectionCard = UIView()
    private let startValueLabel = UILabel()
    private let endValueLabel = UILabel()
    private let instructionLabel = UILabel()
    private lazy var clearButton = makeActionButton(
        title: "清除",
        symbol: "xmark",
        style: .gray,
        action: #selector(clearSelection)
    )
    private lazy var nextWeekButton = makeActionButton(
        title: "未来 7 天",
        symbol: "calendar.badge.plus",
        style: .tinted,
        action: #selector(selectNextWeek)
    )
    private var startDate: Date?
    private var endDate: Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "范围选择"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemGroupedBackground

        calendarView.applyDemoDefaults()
        calendarView.dataSource = self
        calendarView.delegate = self
        calendarView.allowsMultipleSelection = true
        calendarView.headerHeight = 52
        calendarView.weekdayHeight = 30
        calendarView.rowHeight = 48
        calendarView.placeholderType = .fillSixRows
        calendarView.today = nil
        calendarView.swipeToChooseGestureRecognizer.isEnabled = true
        calendarView.register(RangePickerCell.self, forCellReuseIdentifier: "range")
        calendarView.backgroundColor = .secondarySystemGroupedBackground
        calendarView.layer.cornerRadius = 20
        calendarView.layer.cornerCurve = .continuous
        calendarView.clipsToBounds = true
        calendarView.sectionInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
        calendarView.appearance.headerTitleFont = .preferredFont(forTextStyle: .headline)
        calendarView.appearance.weekdayFont = .preferredFont(forTextStyle: .caption1)

        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        selectionCard.backgroundColor = .secondarySystemGroupedBackground
        selectionCard.layer.cornerRadius = 20
        selectionCard.layer.cornerCurve = .continuous

        [startValueLabel, endValueLabel].forEach {
            $0.font = .preferredFont(forTextStyle: .headline)
            $0.adjustsFontForContentSizeCategory = true
            $0.maximumContentSizeCategory = .extraExtraExtraLarge
            $0.textColor = .secondaryLabel
            $0.numberOfLines = 2
        }
        startValueLabel.accessibilityLabel = "开始日期"
        endValueLabel.accessibilityLabel = "结束日期"

        instructionLabel.font = .preferredFont(forTextStyle: .footnote)
        instructionLabel.adjustsFontForContentSizeCategory = true
        instructionLabel.maximumContentSizeCategory = .extraExtraExtraLarge
        instructionLabel.textColor = .secondaryLabel
        instructionLabel.textAlignment = .center
        instructionLabel.numberOfLines = 0
        nextWeekButton.tintColor = .systemOrange
        nextWeekButton.accessibilityHint = "选择从今天开始的七天"
        clearButton.accessibilityHint = "移除当前选择"

        let startColumn = makeDateColumn(title: "开始日期", valueLabel: startValueLabel)
        let endColumn = makeDateColumn(title: "结束日期", valueLabel: endValueLabel)
        let arrowView = UIImageView(image: UIImage(systemName: "arrow.right"))
        arrowView.tintColor = .tertiaryLabel
        arrowView.setContentHuggingPriority(.required, for: .horizontal)
        arrowView.accessibilityElementsHidden = true
        let dateRow = UIStackView(arrangedSubviews: [startColumn, arrowView, endColumn])
        dateRow.alignment = .center
        dateRow.spacing = 12
        startColumn.widthAnchor.constraint(equalTo: endColumn.widthAnchor).isActive = true

        let actionRow = UIStackView(arrangedSubviews: [nextWeekButton, clearButton])
        actionRow.axis = .horizontal
        actionRow.spacing = 12
        actionRow.distribution = .fillEqually

        let cardStack = UIStackView(arrangedSubviews: [dateRow, actionRow, instructionLabel])
        cardStack.axis = .vertical
        cardStack.spacing = 16
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        selectionCard.addSubview(cardStack)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        [calendarView, selectionCard].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            calendarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            calendarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            calendarView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            calendarView.heightAnchor.constraint(equalToConstant: 52 + 30 + 6 * 48),

            selectionCard.topAnchor.constraint(equalTo: calendarView.bottomAnchor, constant: 16),
            selectionCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            selectionCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            selectionCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24),

            cardStack.topAnchor.constraint(equalTo: selectionCard.topAnchor, constant: 20),
            cardStack.leadingAnchor.constraint(equalTo: selectionCard.leadingAnchor, constant: 20),
            cardStack.trailingAnchor.constraint(equalTo: selectionCard.trailingAnchor, constant: -20),
            cardStack.bottomAnchor.constraint(equalTo: selectionCard.bottomAnchor, constant: -20),
            nextWeekButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            clearButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        updateRangePresentation()
    }

    func minimumDate(for calendar: TFYSwiftCalendar) -> Date? {
        DemoDate.adding(.year, value: -2)
    }

    func maximumDate(for calendar: TFYSwiftCalendar) -> Date? {
        DemoDate.adding(.month, value: 10)
    }

    func calendar(
        _ calendar: TFYSwiftCalendar,
        cellFor date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) -> TFYSwiftCalendarCell? {
        calendar.dequeueReusableCell(withIdentifier: "range", for: date, at: monthPosition)
    }

    func calendar(_ calendar: TFYSwiftCalendar, contentFor date: Date) -> TFYSwiftCalendarDayContent {
        TFYSwiftCalendarDayContent(title: DemoDate.gregorian.isDateInToday(date) ? "今" : nil)
    }

    func calendar(
        _ calendar: TFYSwiftCalendar,
        shouldSelect date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) -> Bool {
        monthPosition == .current
    }

    func calendar(
        _ calendar: TFYSwiftCalendar,
        didSelect date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) {
        if calendar.swipeToChooseGestureRecognizer.state == .changed {
            if startDate == nil {
                startDate = date
            } else {
                if let endDate { calendar.deselectDate(endDate) }
                self.endDate = date
            }
        } else if let oldEnd = endDate {
            if let startDate { calendar.deselectDate(startDate) }
            calendar.deselectDate(oldEnd)
            startDate = date
            endDate = nil
        } else if startDate == nil {
            startDate = date
        } else {
            endDate = date
        }
        updateRangePresentation()
        if calendar.swipeToChooseGestureRecognizer.state != .changed {
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }

    func calendar(
        _ calendar: TFYSwiftCalendar,
        didDeselect date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) {
        if let startDate, DemoDate.gregorian.isDate(startDate, inSameDayAs: date) { self.startDate = nil }
        if let endDate, DemoDate.gregorian.isDate(endDate, inSameDayAs: date) { self.endDate = nil }
        updateRangePresentation()
    }

    func calendar(_ calendar: TFYSwiftCalendar, willDisplay cell: TFYSwiftCalendarCell, for date: Date) {
        configure(cell: cell, for: date)
    }

    func runSmokeTest() {
        selectNextWeek()
    }

    private func makeDateColumn(title: String, valueLabel: UILabel) -> UIStackView {
        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .caption1)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.maximumContentSizeCategory = .extraExtraExtraLarge
        titleLabel.textColor = .secondaryLabel
        titleLabel.text = title
        let stack = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }

    private func makeActionButton(
        title: String,
        symbol: String,
        style: RangeActionStyle,
        action: Selector
    ) -> UIButton {
        var configuration: UIButton.Configuration
        switch style {
        case .tinted: configuration = .tinted()
        case .gray: configuration = .gray()
        }
        configuration.title = title
        configuration.image = UIImage(systemName: symbol)
        configuration.imagePadding = 6
        configuration.cornerStyle = .large
        configuration.titleLineBreakMode = .byClipping
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            let baseFont = UIFont.systemFont(ofSize: 17, weight: .semibold)
            attributes.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: baseFont, maximumPointSize: 24)
            return attributes
        }
        let button = UIButton(configuration: configuration)
        button.titleLabel?.maximumContentSizeCategory = .extraExtraExtraLarge
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func clearSelection() {
        for date in calendarView.selectedDates {
            calendarView.deselectDate(date)
        }
        startDate = nil
        endDate = nil
        updateRangePresentation()
        UISelectionFeedbackGenerator().selectionChanged()
    }

    @objc private func selectNextWeek() {
        clearSelection()
        let start = DemoDate.day(0)
        let end = DemoDate.day(6)
        calendarView.setCurrentPage(start, animated: true)
        calendarView.selectDate(start, scrollToDate: false)
        calendarView.selectDate(end, scrollToDate: false)
    }

    private func updateRangePresentation() {
        for cell in calendarView.visibleCells {
            guard let date = calendarView.date(for: cell) else { continue }
            configure(cell: cell, for: date)
        }
        startValueLabel.text = startDate.map(formattedDate) ?? "请选择"
        endValueLabel.text = endDate.map(formattedDate) ?? "请选择"
        startValueLabel.accessibilityLabel = startDate.map { "开始日期，\(DemoDate.text($0, format: "yyyy年M月d日 EEEE"))" } ?? "开始日期，未选择"
        endValueLabel.accessibilityLabel = endDate.map { "结束日期，\(DemoDate.text($0, format: "yyyy年M月d日 EEEE"))" } ?? "结束日期，未选择"
        startValueLabel.textColor = startDate == nil ? .secondaryLabel : .label
        endValueLabel.textColor = endDate == nil ? .secondaryLabel : .label
        clearButton.isEnabled = startDate != nil || endDate != nil

        if let startDate, let endDate {
            let lower = min(startDate, endDate)
            let upper = max(startDate, endDate)
            let days = (DemoDate.gregorian.dateComponents([.day], from: lower, to: upper).day ?? 0) + 1
            instructionLabel.text = "已选择 \(days) 天 · 再点日期可重新开始"
            selectionCard.accessibilityLabel = "已选择从 \(DemoDate.text(lower)) 到 \(DemoDate.text(upper))，共 \(days) 天"
        } else if startDate != nil {
            instructionLabel.text = "请选择结束日期，或长按后拖动"
            selectionCard.accessibilityLabel = "已选择开始日期，等待选择结束日期"
        } else {
            instructionLabel.text = "轻点选择起止日期，也可长按后拖动"
            selectionCard.accessibilityLabel = "尚未选择日期"
        }
    }

    private func formattedDate(_ date: Date) -> String {
        "\(DemoDate.text(date, format: "M月d日"))\n\(DemoDate.text(date, format: "EEEE"))"
    }

    private func configure(cell: TFYSwiftCalendarCell, for date: Date) {
        guard let cell = cell as? RangePickerCell else { return }
        guard cell.monthPosition == .current, let startDate else {
            cell.apply(role: .none)
            return
        }
        guard let endDate else {
            cell.apply(role: DemoDate.gregorian.isDate(date, inSameDayAs: startDate) ? .single : .none)
            return
        }
        let lower = min(startDate, endDate)
        let upper = max(startDate, endDate)
        if DemoDate.gregorian.isDate(date, inSameDayAs: lower) {
            cell.apply(role: DemoDate.gregorian.isDate(lower, inSameDayAs: upper) ? .single : .start)
        } else if DemoDate.gregorian.isDate(date, inSameDayAs: upper) {
            cell.apply(role: .end)
        } else if date > lower && date < upper {
            cell.apply(role: .middle)
        } else {
            cell.apply(role: .none)
        }
    }
}

private final class CalendarTagCell: TFYSwiftCalendarCell {
    private let tags = (0..<4).map { _ in UIImageView() }
    private let symbols = ["briefcase.fill", "heart.fill", "figure.run", "cup.and.saucer.fill"]
    private let colors: [UIColor] = [.systemBlue, .systemPink, .systemGreen, .systemOrange]

    override init(frame: CGRect) {
        super.init(frame: frame)
        for tag in tags {
            tag.contentMode = .center
            tag.layer.cornerRadius = 4
            tag.clipsToBounds = true
            contentView.addSubview(tag)
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.frame = CGRect(x: 4, y: 1, width: contentView.bounds.width - 8, height: 20)
        let tagArea = CGRect(x: 4, y: 25, width: contentView.bounds.width - 8, height: max(0, contentView.bounds.height - 29))
        let gap: CGFloat = 2
        let itemWidth = max(0, (tagArea.width - gap) / 2)
        let itemHeight = max(0, (tagArea.height - gap) / 2)
        for index in tags.indices {
            let column = CGFloat(index % 2)
            let row = CGFloat(index / 2)
            tags[index].frame = CGRect(
                x: tagArea.minX + column * (itemWidth + gap),
                y: tagArea.minY + row * (itemHeight + gap),
                width: itemWidth,
                height: itemHeight
            )
        }
        shapeLayer.frame = contentView.bounds
        shapeLayer.path = UIBezierPath(roundedRect: titleLabel.frame, cornerRadius: 4).cgPath
    }

    func configureTags(day: Int) {
        for index in tags.indices {
            let visible = (day + index) % 3 != 0
            tags[index].isHidden = !visible
            tags[index].backgroundColor = colors[index].withAlphaComponent(0.14)
            tags[index].image = DemoSymbol.image(symbols[index], color: colors[index])
        }
    }
}

final class CalendarTagViewController: UIViewController, TFYSwiftCalendarDataSource, TFYSwiftCalendarDelegate {
    private let calendarView = TFYSwiftCalendar()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "自定义标签日期格"
        view.backgroundColor = .systemGroupedBackground

        calendarView.applyDemoDefaults()
        calendarView.dataSource = self
        calendarView.delegate = self
        calendarView.rowHeight = 72
        calendarView.appearance.headerDateFormat = "yyyy年MM月"
        calendarView.appearance.todayColor = .systemOrange
        calendarView.register(CalendarTagCell.self, forCellReuseIdentifier: "tag")
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(calendarView)
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calendarView.heightAnchor.constraint(equalToConstant: calendarView.preferredHeight)
        ])
    }

    func calendar(
        _ calendar: TFYSwiftCalendar,
        cellFor date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) -> TFYSwiftCalendarCell? {
        calendar.dequeueReusableCell(withIdentifier: "tag", for: date, at: monthPosition)
    }

    func calendar(_ calendar: TFYSwiftCalendar, contentFor date: Date) -> TFYSwiftCalendarDayContent {
        TFYSwiftCalendarDayContent(title: calendar.calendar.isDateInToday(date) ? "今" : nil)
    }

    func calendar(_ calendar: TFYSwiftCalendar, willDisplay cell: TFYSwiftCalendarCell, for date: Date) {
        (cell as? CalendarTagCell)?.configureTags(day: calendar.calendar.component(.day, from: date))
    }

    func calendar(
        _ calendar: TFYSwiftCalendar,
        shouldDeselect date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) -> Bool {
        false
    }

    func calendar(
        _ calendar: TFYSwiftCalendar,
        didSelect date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) {
        if monthPosition != .current { calendar.setCurrentPage(date, animated: true) }
    }
}
