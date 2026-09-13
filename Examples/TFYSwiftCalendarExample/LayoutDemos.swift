import TFYSwiftCalendarkit
import UIKit

final class ButtonsViewController: UIViewController {
    private let calendarView = TFYSwiftCalendar()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "上一个 / 下一个"
        view.backgroundColor = .systemGroupedBackground

        calendarView.applyDemoDefaults()
        calendarView.appearance.headerDateFormat = "yyyy MMMM"
        calendarView.calendarHeaderView.previousButton.isHidden = true
        calendarView.calendarHeaderView.nextButton.isHidden = true

        let previousButton = makePageButton(title: "上一个月", symbol: "chevron.left", action: #selector(showPrevious))
        let nextButton = makePageButton(title: "下一个月", symbol: "chevron.right", action: #selector(showNext))
        let buttonBar = UIStackView(arrangedSubviews: [previousButton, UIView(), nextButton])
        buttonBar.alignment = .center

        [calendarView, buttonBar].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        NSLayoutConstraint.activate([
            buttonBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            buttonBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            buttonBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            buttonBar.heightAnchor.constraint(equalToConstant: 44),
            calendarView.topAnchor.constraint(equalTo: buttonBar.topAnchor),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calendarView.heightAnchor.constraint(equalToConstant: calendarView.preferredHeight)
        ])
        view.bringSubviewToFront(buttonBar)
    }

    private func makePageButton(title: String, symbol: String, action: Selector) -> UIButton {
        var configuration = UIButton.Configuration.plain()
        configuration.title = title
        configuration.image = UIImage(systemName: symbol)
        configuration.imagePadding = 4
        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func showPrevious() {
        calendarView.setCurrentPage(DemoDate.adding(.month, value: -1, to: calendarView.currentPage), animated: true)
    }

    @objc private func showNext() {
        calendarView.setCurrentPage(DemoDate.adding(.month, value: 1, to: calendarView.currentPage), animated: true)
    }
}

final class HidePlaceholderViewController: UIViewController, TFYSwiftCalendarDataSource, TFYSwiftCalendarDelegate {
    private let calendarView = TFYSwiftCalendar()
    private let footer = UIStackView()
    private let eventLabel = UILabel()
    private var calendarHeightConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "隐藏占位日期"
        view.backgroundColor = .systemGroupedBackground

        calendarView.applyDemoDefaults()
        calendarView.dataSource = self
        calendarView.delegate = self
        calendarView.placeholderType = .none
        calendarView.adjustsBoundingRectWhenChangingMonths = true
        calendarView.scrollDirection = .vertical
        calendarView.appearance.separatorStyle = .rows
        calendarView.calendarHeaderView.backgroundColor = .secondarySystemGroupedBackground
        calendarView.appearance.weekdayTextColor = .secondaryLabel

        eventLabel.font = .preferredFont(forTextStyle: .subheadline)
        eventLabel.adjustsFontForContentSizeCategory = true
        eventLabel.text = "🐈  Hey Daily Event  🐈"
        let previous = compactButton(title: "上一个", action: #selector(showPrevious))
        let next = compactButton(title: "下一个", action: #selector(showNext))
        footer.axis = .horizontal
        footer.alignment = .center
        footer.spacing = 8
        footer.addArrangedSubview(eventLabel)
        footer.addArrangedSubview(previous)
        footer.addArrangedSubview(next)

        [calendarView, footer].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        calendarHeightConstraint = calendarView.heightAnchor.constraint(equalToConstant: calendarView.preferredHeight)
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calendarHeightConstraint,
            footer.topAnchor.constraint(equalTo: calendarView.bottomAnchor, constant: 8),
            footer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            footer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            footer.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    func minimumDate(for calendar: TFYSwiftCalendar) -> Date? { DemoDate.adding(.year, value: -4) }
    func maximumDate(for calendar: TFYSwiftCalendar) -> Date? { DemoDate.adding(.year, value: 4) }

    func calendar(_ calendar: TFYSwiftCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        calendarHeightConstraint.constant = bounds.height
        let changes = { self.view.layoutIfNeeded() }
        animated ? UIView.animate(withDuration: 0.3, animations: changes) : changes()
    }

    private func compactButton(title: String, action: Selector) -> UIButton {
        var configuration = UIButton.Configuration.bordered()
        configuration.title = title
        configuration.buttonSize = .small
        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func showPrevious() {
        calendarView.setCurrentPage(DemoDate.adding(.month, value: -1, to: calendarView.currentPage), animated: true)
    }

    @objc private func showNext() {
        calendarView.setCurrentPage(DemoDate.adding(.month, value: 1, to: calendarView.currentPage), animated: true)
    }
}

final class LoadViewExampleViewController: UIViewController, TFYSwiftCalendarDataSource, TFYSwiftCalendarDelegate {
    private weak var calendarView: TFYSwiftCalendar?
    private var calendarHeightConstraint: NSLayoutConstraint?

    override func loadView() {
        let rootView = UIView(frame: UIScreen.main.bounds)
        rootView.backgroundColor = .systemGroupedBackground
        view = rootView

        let calendar = TFYSwiftCalendar()
        calendar.applyDemoDefaults()
        calendar.dataSource = self
        calendar.delegate = self
        calendar.scrollDirection = .vertical
        calendar.backgroundColor = .systemBackground
        calendar.translatesAutoresizingMaskIntoConstraints = false
        rootView.addSubview(calendar)
        let height = calendar.heightAnchor.constraint(equalToConstant: calendar.preferredHeight)
        NSLayoutConstraint.activate([
            calendar.topAnchor.constraint(equalTo: rootView.safeAreaLayoutGuide.topAnchor),
            calendar.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
            calendar.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
            height
        ])
        calendarView = calendar
        calendarHeightConstraint = height
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "loadView 创建"
    }

    func minimumDate(for calendar: TFYSwiftCalendar) -> Date? { DemoDate.adding(.year, value: -7) }
    func maximumDate(for calendar: TFYSwiftCalendar) -> Date? { DemoDate.adding(.year, value: 7) }

    func calendar(_ calendar: TFYSwiftCalendar, contentFor date: Date) -> TFYSwiftCalendarDayContent {
        let day = calendar.calendar.component(.day, from: date)
        guard [11, 13, 15, 17].contains(day) else { return TFYSwiftCalendarDayContent() }
        let symbol = day.isMultiple(of: 2) ? "pawprint.fill" : "cat.fill"
        let image = DemoSymbol.image(symbol, color: day.isMultiple(of: 3) ? .systemPurple : .systemTeal)
        return TFYSwiftCalendarDayContent(image: image, topImage: image, accessibilityHint: "包含上下图片")
    }

    func calendar(_ calendar: TFYSwiftCalendar, styleFor date: Date) -> TFYSwiftCalendarDayStyle? {
        guard [11, 13, 15, 17].contains(calendar.calendar.component(.day, from: date)) else { return nil }
        var style = TFYSwiftCalendarDayStyle()
        style.topImageOffset = CGPoint(x: 0, y: -4)
        style.imageOffset = CGPoint(x: 0, y: 3)
        return style
    }

    func calendar(_ calendar: TFYSwiftCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        calendarHeightConstraint?.constant = bounds.height
    }

    func calendar(
        _ calendar: TFYSwiftCalendar,
        didSelect date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) {
        if monthPosition != .current { calendar.setCurrentPage(date, animated: true) }
    }
}

final class ScopeExampleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIGestureRecognizerDelegate, TFYSwiftCalendarDelegate {
    private let calendarView = TFYSwiftCalendar()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var calendarHeightConstraint: NSLayoutConstraint!
    private var scopeGesture: UIPanGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "月/周联动"
        view.backgroundColor = .systemBackground

        calendarView.applyDemoDefaults()
        calendarView.delegate = self
        calendarView.placeholderType = .none
        calendarView.appearance.titleFont = .systemFont(ofSize: 12)
        calendarView.appearance.todayColor = .systemRed
        calendarView.appearance.selectionColor = .systemBlue
        calendarView.appearance.weekdayTextColor = .systemGreen
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "scope")

        [calendarView, tableView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        calendarHeightConstraint = calendarView.heightAnchor.constraint(equalToConstant: calendarView.preferredHeight)
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            calendarHeightConstraint,
            tableView.topAnchor.constraint(equalTo: calendarView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let gesture = UIPanGestureRecognizer(target: calendarView, action: #selector(TFYSwiftCalendar.handleScopeGesture(_:)))
        gesture.delegate = self
        gesture.minimumNumberOfTouches = 1
        gesture.maximumNumberOfTouches = 2
        view.addGestureRecognizer(gesture)
        tableView.panGestureRecognizer.require(toFail: gesture)
        scopeGesture = gesture

        calendarView.setScope(.week, animated: false)
        calendarView.selectDate(Date(), scrollToDate: true)
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === scopeGesture, let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let isAtTop = tableView.contentOffset.y <= -tableView.adjustedContentInset.top
        guard isAtTop else { return false }
        let velocity = pan.velocity(in: view)
        return calendarView.scope == .month ? velocity.y < 0 : velocity.y > 0
    }

    func calendar(_ calendar: TFYSwiftCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        calendarHeightConstraint.constant = bounds.height
        let changes = { self.view.layoutIfNeeded() }
        animated ? UIView.animate(withDuration: 0.3, animations: changes) : changes()
    }

    func calendar(
        _ calendar: TFYSwiftCalendar,
        didSelect date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) {
        if monthPosition != .current { calendar.setCurrentPage(date, animated: true) }
    }

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? 2 : 20
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "scope", for: indexPath)
        var configuration = cell.defaultContentConfiguration()
        configuration.text = indexPath.section == 0
            ? (indexPath.row == 0 ? "切换到月视图" : "切换到周视图")
            : "日程列表 \(indexPath.row + 1)"
        cell.contentConfiguration = configuration
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.section == 0 else { return }
        calendarView.setScope(indexPath.row == 0 ? .month : .week, animated: true)
    }
}
