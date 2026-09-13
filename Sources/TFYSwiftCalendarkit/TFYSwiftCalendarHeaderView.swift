import UIKit

@MainActor
public final class TFYSwiftCalendarHeaderView: UIView {
    public let titleLabel = UILabel()
    public let previousButton = UIButton(type: .system)
    public let nextButton = UIButton(type: .system)

    internal var onPrevious: (() -> Void)?
    internal var onNext: (() -> Void)?

    private let formatter = DateFormatter()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setUpViews()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUpViews()
    }

    private func setUpViews() {
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.maximumContentSizeCategory = .extraExtraExtraLarge
        titleLabel.minimumScaleFactor = 0.7
        titleLabel.adjustsFontSizeToFitWidth = true

        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold)
        previousButton.setImage(UIImage(systemName: "chevron.left", withConfiguration: symbolConfiguration), for: .normal)
        nextButton.setImage(UIImage(systemName: "chevron.right", withConfiguration: symbolConfiguration), for: .normal)
        previousButton.accessibilityLabel = NSLocalizedString("Previous page", comment: "Calendar previous page")
        nextButton.accessibilityLabel = NSLocalizedString("Next page", comment: "Calendar next page")
        previousButton.addTarget(self, action: #selector(previousTapped), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)

        addSubview(titleLabel)
        addSubview(previousButton)
        addSubview(nextButton)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let buttonWidth = min(44, bounds.width * 0.16)
        previousButton.frame = CGRect(x: 0, y: 0, width: buttonWidth, height: bounds.height)
        nextButton.frame = CGRect(x: bounds.width - buttonWidth, y: 0, width: buttonWidth, height: bounds.height)
        titleLabel.frame = CGRect(x: buttonWidth, y: 0, width: bounds.width - buttonWidth * 2, height: bounds.height)
    }

    internal func update(
        date: Date,
        calendar: Calendar,
        locale: Locale,
        appearance: TFYSwiftCalendarAppearance,
        canGoPrevious: Bool,
        canGoNext: Bool
    ) {
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = appearance.headerDateFormat
        var text = formatter.string(from: date)
        if appearance.caseOptions.contains(.headerUppercase) {
            text = text.uppercased(with: locale)
        }
        titleLabel.text = text
        titleLabel.font = appearance.headerTitleFont
        titleLabel.textColor = appearance.headerTitleColor
        previousButton.tintColor = appearance.headerTitleColor
        nextButton.tintColor = appearance.headerTitleColor
        previousButton.isEnabled = canGoPrevious
        nextButton.isEnabled = canGoNext
    }

    @objc private func previousTapped() { onPrevious?() }
    @objc private func nextTapped() { onNext?() }
}
