import UIKit

@MainActor
public final class TFYSwiftCalendarWeekdayView: UIView {
    public private(set) var weekdayLabels: [UILabel] = []
    public let stackView = UIStackView()
    private weak var appliedAppearance: TFYSwiftCalendarAppearance?

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
        appliedAppearance = appearance
        var formatter = calendar
        formatter.locale = locale
        let localizedAccessibilitySymbols = formatter.shortStandaloneWeekdaySymbols
        let localizedDisplaySymbols = appearance.caseOptions.contains(.weekdaySingleCharacter)
            ? formatter.veryShortStandaloneWeekdaySymbols
            : localizedAccessibilitySymbols
        let accessibilitySymbols = validated(appearance.weekdayAccessibilitySymbols)
            ?? localizedAccessibilitySymbols
        let displaySymbols = validated(appearance.weekdaySymbols)
            ?? localizedDisplaySymbols
        guard accessibilitySymbols.count == 7, displaySymbols.count == 7 else { return }

        backgroundColor = appearance.weekdayBackgroundColor
        stackView.spacing = max(0, appearance.weekdaySpacing)
        stackView.layoutMargins = appearance.weekdayContentInsets
        stackView.isLayoutMarginsRelativeArrangement = true

        let textColors = validated(appearance.weekdayTextColors)
        let backgroundColors = validated(appearance.weekdayLabelBackgroundColors)
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
            label.textColor = textColors?[index] ?? appearance.weekdayTextColor
            label.backgroundColor = backgroundColors?[index] ?? appearance.weekdayLabelBackgroundColor
            label.layer.cornerRadius = max(0, appearance.weekdayLabelCornerRadius)
            label.layer.cornerCurve = .continuous
            label.layer.borderWidth = max(0, appearance.weekdayLabelBorderWidth)
            label.layer.borderColor = appearance.weekdayLabelBorderColor
                .resolvedColor(with: traitCollection)
                .cgColor
            label.clipsToBounds = appearance.weekdayLabelCornerRadius > 0
            label.accessibilityLabel = original
        }
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) ?? true,
              let appearance = appliedAppearance else { return }
        for label in weekdayLabels where label.layer.borderWidth > 0 {
            label.layer.borderColor = appearance.weekdayLabelBorderColor
                .resolvedColor(with: traitCollection)
                .cgColor
        }
    }

    private func validated<T>(_ values: [T]?) -> [T]? {
        guard let values, values.count == 7 else { return nil }
        return values
    }
}
