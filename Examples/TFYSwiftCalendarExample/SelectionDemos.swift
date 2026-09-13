import TFYSwiftCalendarkit
import UIKit

private enum RangeCellRole {
    case none
    case start
    case middle
    case end
    case single
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
    private let statusLabel = UILabel()
    private var startDate: Date?
    private var endDate: Date?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "范围选择"
        view.backgroundColor = .systemBackground

        calendarView.applyDemoDefaults()
        calendarView.dataSource = self
        calendarView.delegate = self
        calendarView.pagingEnabled = false
        calendarView.allowsMultipleSelection = true
        calendarView.rowHeight = 60
        calendarView.weekdayHeight = 0
        calendarView.placeholderType = .fillHeadTail
        calendarView.today = nil
        calendarView.swipeToChooseGestureRecognizer.isEnabled = true
        calendarView.register(RangePickerCell.self, forCellReuseIdentifier: "range")

        statusLabel.font = .preferredFont(forTextStyle: .footnote)
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.text = "选择起点和终点，或长按后滑动"

        [calendarView, statusLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calendarView.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -8),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            statusLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            statusLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        ])
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
        let start = DemoDate.adding(.day, value: 1)
        let end = DemoDate.adding(.day, value: 5)
        calendarView.selectDate(start, scrollToDate: false)
        calendarView.selectDate(end, scrollToDate: false)
    }

    private func updateRangePresentation() {
        for cell in calendarView.visibleCells {
            guard let date = calendarView.date(for: cell) else { continue }
            configure(cell: cell, for: date)
        }
        let start = startDate.map { DemoDate.text($0) } ?? "—"
        let end = endDate.map { DemoDate.text($0) } ?? "—"
        statusLabel.text = "起点：\(start)    终点：\(end)"
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
