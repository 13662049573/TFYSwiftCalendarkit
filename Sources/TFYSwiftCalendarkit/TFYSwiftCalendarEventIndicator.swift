import UIKit

@MainActor
public final class TFYSwiftCalendarEventIndicator: UIView {
    public var colors: [UIColor] = [] {
        didSet { setNeedsLayout() }
    }

    public var fallbackColor: UIColor = .systemBlue {
        didSet { setNeedsLayout() }
    }

    public var maximumVisibleEvents = TFYSwiftCalendarDefaults.maximumNumberOfEvents {
        didSet { setNeedsLayout() }
    }

    private var eventLayers: [CAShapeLayer] = []

    public override class var layerClass: AnyClass { CALayer.self }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        isAccessibilityElement = false
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        isUserInteractionEnabled = false
        backgroundColor = .clear
        isAccessibilityElement = false
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        updateLayers()
    }

    private func updateLayers() {
        let visibleColors = Array(colors.prefix(max(0, maximumVisibleEvents)))
        while eventLayers.count > visibleColors.count {
            eventLayers.removeLast().removeFromSuperlayer()
        }
        while eventLayers.count < visibleColors.count {
            let dot = CAShapeLayer()
            layer.addSublayer(dot)
            eventLayers.append(dot)
        }
        guard !visibleColors.isEmpty else { return }

        let dotDiameter = min(5, max(2, bounds.height))
        let spacing: CGFloat = 3
        let totalWidth = CGFloat(visibleColors.count) * dotDiameter + CGFloat(visibleColors.count - 1) * spacing
        var x = (bounds.width - totalWidth) / 2
        let y = (bounds.height - dotDiameter) / 2

        for (index, color) in visibleColors.enumerated() {
            let dot = eventLayers[index]
            dot.frame = CGRect(x: x, y: y, width: dotDiameter, height: dotDiameter)
            dot.path = UIBezierPath(ovalIn: dot.bounds).cgPath
            dot.fillColor = color.resolvedColor(with: traitCollection).cgColor
            x += dotDiameter + spacing
        }
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) ?? true {
            setNeedsLayout()
        }
    }
}
