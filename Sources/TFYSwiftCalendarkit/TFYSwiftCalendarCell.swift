import UIKit

@MainActor
open class TFYSwiftCalendarCell: UICollectionViewCell {
    public let titleLabel = UILabel()
    public let subtitleLabel = UILabel()
    public let topSubtitleLabel = UILabel()
    public let imageView = UIImageView()
    public let topImageView = UIImageView()
    public let eventIndicator = TFYSwiftCalendarEventIndicator()
    public let shapeLayer = CAShapeLayer()

    public private(set) var representedDate: Date?
    public private(set) var monthPosition: TFYSwiftCalendarMonthPosition = .notFound
    public private(set) var cellState: TFYSwiftCalendarCellState = []
    public private(set) var selectionPosition: TFYSwiftCalendarSelectionPosition = .none

    private let rowSeparatorLayer = CALayer()
    private var appliedStyle = TFYSwiftCalendarDayStyle()
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
        isAccessibilityElement = true
        accessibilityTraits = .button
        contentView.layer.insertSublayer(shapeLayer, at: 0)
        contentView.layer.addSublayer(rowSeparatorLayer)

        [titleLabel, subtitleLabel, topSubtitleLabel].forEach {
            $0.textAlignment = .center
            $0.adjustsFontForContentSizeCategory = true
            $0.maximumContentSizeCategory = .extraExtraLarge
            $0.minimumScaleFactor = 0.65
            $0.adjustsFontSizeToFitWidth = true
            contentView.addSubview($0)
        }

        [imageView, topImageView].forEach {
            $0.contentMode = .scaleAspectFit
            $0.clipsToBounds = true
            contentView.addSubview($0)
        }

        contentView.addSubview(eventIndicator)
        clipsToBounds = false
        contentView.clipsToBounds = false
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
        representedDate = nil
        monthPosition = .notFound
        cellState = []
        selectionPosition = .none
        titleLabel.text = nil
        subtitleLabel.text = nil
        topSubtitleLabel.text = nil
        imageView.image = nil
        topImageView.image = nil
        eventIndicator.colors = []
        accessibilityLabel = nil
        accessibilityValue = nil
        accessibilityHint = nil
        transform = .identity
        alpha = 1
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        let bounds = contentView.bounds
        let centerY = bounds.midY
        let titleHeight = min(24, bounds.height * 0.42)
        let side = min(bounds.width, bounds.height) - 4
        let shapeRect = CGRect(
            x: bounds.midX - side / 2,
            y: bounds.midY - side / 2,
            width: side,
            height: side
        )

        shapeLayer.frame = bounds
        shapeLayer.path = selectionPath(in: shapeRect).cgPath

        titleLabel.frame = CGRect(x: 3, y: centerY - titleHeight / 2, width: bounds.width - 6, height: titleHeight)
            .offsetBy(dx: (appliedStyle.titleOffset?.x ?? appliedAppearance?.titleOffset.x ?? 0) + (appliedAppearance?.horizontalTitleInset ?? 0),
                      dy: appliedStyle.titleOffset?.y ?? appliedAppearance?.titleOffset.y ?? 0)

        let auxiliaryHeight = min(15, bounds.height * 0.22)
        topSubtitleLabel.frame = CGRect(x: 2, y: 1, width: bounds.width - 4, height: auxiliaryHeight)
            .offsetBy(dx: appliedStyle.topSubtitleOffset?.x ?? appliedAppearance?.topSubtitleOffset.x ?? 0,
                      dy: appliedStyle.topSubtitleOffset?.y ?? appliedAppearance?.topSubtitleOffset.y ?? 0)
        subtitleLabel.frame = CGRect(x: 2, y: bounds.height - auxiliaryHeight - 2, width: bounds.width - 4, height: auxiliaryHeight)
            .offsetBy(dx: appliedStyle.subtitleOffset?.x ?? appliedAppearance?.subtitleOffset.x ?? 0,
                      dy: appliedStyle.subtitleOffset?.y ?? appliedAppearance?.subtitleOffset.y ?? 0)

        let imageSide = min(14, auxiliaryHeight)
        topImageView.frame = CGRect(x: bounds.midX - imageSide / 2, y: 1, width: imageSide, height: imageSide)
            .offsetBy(dx: appliedStyle.topImageOffset?.x ?? appliedAppearance?.topImageOffset.x ?? 0,
                      dy: appliedStyle.topImageOffset?.y ?? appliedAppearance?.topImageOffset.y ?? 0)
        imageView.frame = CGRect(x: bounds.midX - imageSide / 2, y: bounds.height - imageSide - 2, width: imageSide, height: imageSide)
            .offsetBy(dx: appliedStyle.imageOffset?.x ?? appliedAppearance?.imageOffset.x ?? 0,
                      dy: appliedStyle.imageOffset?.y ?? appliedAppearance?.imageOffset.y ?? 0)
        eventIndicator.frame = CGRect(x: 2, y: bounds.height - 9, width: bounds.width - 4, height: 7)
            .offsetBy(dx: appliedStyle.eventOffset?.x ?? appliedAppearance?.eventOffset.x ?? 0,
                      dy: appliedStyle.eventOffset?.y ?? appliedAppearance?.eventOffset.y ?? 0)

        rowSeparatorLayer.frame = CGRect(x: 0, y: bounds.height - 0.5, width: bounds.width, height: 0.5)
    }

    open func configureAppearance() {
        guard let appearance = appliedAppearance else { return }
        let selected = cellState.contains(.selected)
        titleLabel.font = appearance.titleFont
        subtitleLabel.font = appearance.subtitleFont
        topSubtitleLabel.font = appearance.topSubtitleFont

        titleLabel.textColor = selected
            ? (appliedStyle.selectionTitleColor ?? appearance.titleColor(for: cellState))
            : (appliedStyle.titleColor ?? appearance.titleColor(for: cellState))
        subtitleLabel.textColor = selected
            ? (appliedStyle.selectionSubtitleColor ?? appearance.subtitleColor(for: cellState))
            : (appliedStyle.subtitleColor ?? appearance.subtitleColor(for: cellState))
        topSubtitleLabel.textColor = selected
            ? (appliedStyle.selectionTopSubtitleColor ?? appearance.topSubtitleSelectionColor)
            : (appliedStyle.topSubtitleColor ?? appearance.topSubtitleDefaultColor)

        let fill = selected
            ? (appliedStyle.selectionFillColor ?? appearance.fillColor(for: cellState))
            : (appliedStyle.fillColor ?? appearance.fillColor(for: cellState))
        let border = selected
            ? (appliedStyle.selectionBorderColor ?? appearance.borderColor(for: cellState))
            : (appliedStyle.borderColor ?? appearance.borderColor(for: cellState))
        let borderWidth = selected
            ? (appliedStyle.selectionBorderWidth ?? appearance.selectionBorderWidth)
            : (appliedStyle.borderWidth ?? appearance.borderWidth)
        shapeLayer.fillColor = fill.resolvedColor(with: traitCollection).cgColor
        shapeLayer.strokeColor = border.resolvedColor(with: traitCollection).cgColor
        shapeLayer.lineWidth = max(0, borderWidth)
        rowSeparatorLayer.backgroundColor = appearance.separatorColor.resolvedColor(with: traitCollection).cgColor
        rowSeparatorLayer.isHidden = appearance.separatorStyle == .none

        let customEvents = selected ? appliedStyle.selectionEventColors : appliedStyle.eventColors
        if let customEvents {
            eventIndicator.colors = customEvents
        }
        eventIndicator.fallbackColor = selected ? appearance.eventSelectionColor : appearance.eventDefaultColor
        setNeedsLayout()
    }

    internal func apply(
        date: Date,
        monthPosition: TFYSwiftCalendarMonthPosition,
        state: TFYSwiftCalendarCellState,
        selectionPosition: TFYSwiftCalendarSelectionPosition,
        content: TFYSwiftCalendarDayContent,
        style: TFYSwiftCalendarDayStyle,
        appearance: TFYSwiftCalendarAppearance,
        defaultTitle: String,
        defaultAccessibilityLabel: String
    ) {
        representedDate = date
        self.monthPosition = monthPosition
        cellState = state
        self.selectionPosition = selectionPosition
        appliedStyle = style
        appliedAppearance = appearance

        titleLabel.text = content.title ?? defaultTitle
        subtitleLabel.text = content.subtitle
        topSubtitleLabel.text = content.topSubtitle
        imageView.image = content.image
        topImageView.image = content.topImage
        eventIndicator.colors = Array(content.eventColors.prefix(TFYSwiftCalendarDefaults.maximumNumberOfEvents))
        let descriptiveText = [defaultAccessibilityLabel, content.topSubtitle, content.subtitle]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        accessibilityLabel = content.accessibilityLabel ?? descriptiveText
        accessibilityHint = content.accessibilityHint
        var traits: UIAccessibilityTraits = .button
        if state.contains(.selected) { traits.insert(.selected) }
        if state.contains(.disabled) { traits.insert(.notEnabled) }
        accessibilityTraits = traits
        var values: [String] = []
        if state.contains(.today) {
            values.append(TFYSwiftCalendarLocalization.string("Today", comment: "Calendar cell accessibility value"))
        }
        if state.contains(.selected) {
            values.append(TFYSwiftCalendarLocalization.string("Selected", comment: "Calendar cell accessibility value"))
        }
        if state.contains(.disabled) {
            values.append(TFYSwiftCalendarLocalization.string("Unavailable", comment: "Calendar cell accessibility value"))
        }
        if !content.eventColors.isEmpty {
            let format = TFYSwiftCalendarLocalization.string(
                "%ld events",
                comment: "Calendar cell accessibility event count"
            )
            values.append(String.localizedStringWithFormat(format, content.eventColors.count))
        }
        accessibilityValue = values.isEmpty ? nil : values.joined(separator: ", ")
        configureAppearance()
    }

    internal func animateSelection() {
        guard !UIAccessibility.isReduceMotionEnabled else {
            transform = .identity
            return
        }
        transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
        UIView.animate(
            withDuration: 0.22,
            delay: 0,
            usingSpringWithDamping: 0.65,
            initialSpringVelocity: 0.3,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) {
            self.transform = .identity
        }
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) ?? true {
            configureAppearance()
        }
    }

    private func selectionPath(in baseRect: CGRect) -> UIBezierPath {
        guard let appearance = appliedAppearance else { return UIBezierPath(rect: baseRect) }
        let radiusFactor = max(0, min(1, appliedStyle.borderRadius ?? appearance.borderRadius))
        let fillType = appliedStyle.fillType ?? appearance.fillType
        guard fillType == .linked, selectionPosition != .none else {
            return UIBezierPath(roundedRect: baseRect, cornerRadius: min(baseRect.width, baseRect.height) * 0.5 * radiusFactor)
        }

        let linkedRect = CGRect(x: 0, y: baseRect.minY, width: bounds.width, height: baseRect.height)
        let radius = linkedRect.height * 0.5 * radiusFactor
        switch selectionPosition {
        case .single:
            return UIBezierPath(roundedRect: baseRect, cornerRadius: radius)
        case .left:
            return UIBezierPath(
                roundedRect: linkedRect,
                byRoundingCorners: [.topLeft, .bottomLeft],
                cornerRadii: CGSize(width: radius, height: radius)
            )
        case .middle:
            return UIBezierPath(rect: linkedRect)
        case .right:
            return UIBezierPath(
                roundedRect: linkedRect,
                byRoundingCorners: [.topRight, .bottomRight],
                cornerRadii: CGSize(width: radius, height: radius)
            )
        case .none:
            return UIBezierPath(roundedRect: baseRect, cornerRadius: radius)
        }
    }
}

@MainActor
public final class TFYSwiftCalendarBlankCell: UICollectionViewCell {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = false
        backgroundColor = .clear
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        isAccessibilityElement = false
        backgroundColor = .clear
    }
}
