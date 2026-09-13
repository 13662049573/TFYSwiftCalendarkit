import UIKit

@MainActor
public final class TFYSwiftCalendarWeekdayView: UIView {
    public private(set) var weekdayLabels: [UILabel] = []
    private let stackView = UIStackView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpViews()
    }

    private func setUpViews() {
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        addSubview(stackView)

        weekdayLabels = (0..<7).map { _ in
            let label = UILabel()
            label.textAlignment = .center
            label.adjustsFontForContentSizeCategory = true
            label.minimumScaleFactor = 0.7
            label.adjustsFontSizeToFitWidth = true
            stackView.addArrangedSubview(label)
            return label
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        stackView.frame = bounds
    }

    internal func update(calendar: Calendar, locale: Locale, appearance: TFYSwiftCalendarAppearance) {
        var formatter = calendar
        formatter.locale = locale
        let symbols = formatter.shortStandaloneWeekdaySymbols
        guard symbols.count == 7 else { return }

        let first = max(1, min(7, calendar.firstWeekday)) - 1
        let ordered = Array(symbols[first...]) + Array(symbols[..<first])
        for (label, original) in zip(weekdayLabels, ordered) {
            var text = original
            if appearance.caseOptions.contains(.weekdaySingleCharacter) {
                text = text.first.map(String.init) ?? text
            }
            if appearance.caseOptions.contains(.weekdayUppercase) {
                text = text.uppercased(with: locale)
            }
            label.text = text
            label.font = appearance.weekdayFont
            label.textColor = appearance.weekdayTextColor
            label.accessibilityLabel = original
        }
    }
}
