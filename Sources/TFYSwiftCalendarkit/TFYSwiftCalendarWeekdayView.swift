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
            label.maximumContentSizeCategory = .extraExtraLarge
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
        let accessibilitySymbols = formatter.shortStandaloneWeekdaySymbols
        let displaySymbols = appearance.caseOptions.contains(.weekdaySingleCharacter)
            ? formatter.veryShortStandaloneWeekdaySymbols
            : accessibilitySymbols
        guard accessibilitySymbols.count == 7, displaySymbols.count == 7 else { return }

        let first = max(1, min(7, calendar.firstWeekday)) - 1
        let orderedIndices = Array(first..<7) + Array(0..<first)
        for (label, index) in zip(weekdayLabels, orderedIndices) {
            let original = accessibilitySymbols[index]
            var text = displaySymbols[index]
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
