import TFYSwiftCalendarkit
import UIKit

final class CalendarDemoViewController: UIViewController {
    private let calendarView = TFYSwiftCalendar()
    private let scopeControl = UISegmentedControl(items: ["月", "周"])
    private let selectionLabel = UILabel()
    private let lunarFormatter = TFYSwiftLunarFormatter(timeZone: TimeZone(identifier: "Asia/Shanghai")!)
    private var calendarHeightConstraint: NSLayoutConstraint!

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

        scopeControl.selectedSegmentIndex = 0
        scopeControl.addTarget(self, action: #selector(scopeChanged), for: .valueChanged)
        selectionLabel.font = .preferredFont(forTextStyle: .body)
        selectionLabel.adjustsFontForContentSizeCategory = true
        selectionLabel.textAlignment = .center
        selectionLabel.numberOfLines = 0
        selectionLabel.text = "点击日期，或长按滑动连续选择"

        calendarView.dataSource = self
        calendarView.delegate = self
        calendarView.locale = Locale(identifier: "zh_CN")
        calendarView.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        calendarView.firstWeekday = 2
        calendarView.allowsMultipleSelection = true
        calendarView.swipeToChooseGestureRecognizer.isEnabled = true
        calendarView.appearance.headerDateFormat = "yyyy年 M月"
        calendarView.appearance.caseOptions = [.weekdaySingleCharacter]
        calendarView.appearance.selectionColor = .systemIndigo
        calendarView.appearance.todaySelectionColor = .systemIndigo
        calendarView.appearance.fillType = .linked
        calendarView.layer.cornerRadius = 16

        [scopeControl, calendarView, selectionLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        calendarHeightConstraint = calendarView.heightAnchor.constraint(equalToConstant: calendarView.preferredHeight)
        NSLayoutConstraint.activate([
            scopeControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            scopeControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scopeControl.widthAnchor.constraint(equalToConstant: 180),

            calendarView.topAnchor.constraint(equalTo: scopeControl.bottomAnchor, constant: 16),
            calendarView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            calendarView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            calendarHeightConstraint,

            selectionLabel.topAnchor.constraint(equalTo: calendarView.bottomAnchor, constant: 24),
            selectionLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            selectionLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20)
        ])
    }

    @objc private func scopeChanged() {
        calendarView.setScope(scopeControl.selectedSegmentIndex == 0 ? .month : .week, animated: true)
    }

    @objc private func showToday() {
        calendarView.setCurrentPage(Date(), animated: true)
        calendarView.selectDate(Date())
    }

    private func updateSelectionLabel() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "yyyy-MM-dd"
        let values = calendarView.selectedDates.map(formatter.string(from:))
        selectionLabel.text = values.isEmpty ? "尚未选择日期" : "已选择：\n" + values.joined(separator: "、")
    }
}

extension CalendarDemoViewController: TFYSwiftCalendarDataSource {
    func minimumDate(for calendar: TFYSwiftCalendar) -> Date? {
        Calendar.current.date(byAdding: .year, value: -5, to: Date())
    }

    func maximumDate(for calendar: TFYSwiftCalendar) -> Date? {
        Calendar.current.date(byAdding: .year, value: 5, to: Date())
    }

    func calendar(_ calendar: TFYSwiftCalendar, contentFor date: Date) -> TFYSwiftCalendarDayContent {
        let day = calendar.calendar.component(.day, from: date)
        return TFYSwiftCalendarDayContent(
            subtitle: lunarFormatter.string(from: date),
            eventColors: day % 5 == 0 ? [.systemOrange, .systemPink] : []
        )
    }
}

extension CalendarDemoViewController: TFYSwiftCalendarDelegate {
    func calendar(
        _ calendar: TFYSwiftCalendar,
        didSelect date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) {
        updateSelectionLabel()
    }

    func calendar(
        _ calendar: TFYSwiftCalendar,
        didDeselect date: Date,
        at monthPosition: TFYSwiftCalendarMonthPosition
    ) {
        updateSelectionLabel()
    }

    func calendar(_ calendar: TFYSwiftCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        calendarHeightConstraint.constant = bounds.height
        scopeControl.selectedSegmentIndex = calendar.scope == .month ? 0 : 1
        let changes = { self.view.layoutIfNeeded() }
        animated ? UIView.animate(withDuration: 0.3, animations: changes) : changes()
    }

    func calendar(_ calendar: TFYSwiftCalendar, styleFor date: Date) -> TFYSwiftCalendarDayStyle? {
        guard calendar.calendar.isDateInWeekend(date) else { return nil }
        var style = TFYSwiftCalendarDayStyle()
        style.titleColor = .systemRed
        return style
    }
}
