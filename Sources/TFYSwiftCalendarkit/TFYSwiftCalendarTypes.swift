import Foundation
import UIKit

public enum TFYSwiftCalendarScope: Int, CaseIterable, Sendable {
    case month
    case week
}

public enum TFYSwiftCalendarScrollDirection: Int, CaseIterable, Sendable {
    case vertical
    case horizontal
}

public enum TFYSwiftCalendarPlaceholderType: Int, CaseIterable, Sendable {
    case none
    case fillHeadTail
    case fillSixRows
}

public enum TFYSwiftCalendarMonthPosition: Int, CaseIterable, Sendable {
    case previous
    case current
    case next
    case notFound
}

public enum TFYSwiftCalendarSelectionPosition: Int, CaseIterable, Sendable {
    case none
    case single
    case left
    case middle
    case right
}

public enum TFYSwiftCalendarFillType: Int, CaseIterable, Sendable {
    case separate
    case linked
}

/// Defines the geometry used by an independently filled or outlined day.
///
/// The rounded value is expressed as a ratio from `0` (square) to `1` (circle).
/// Values outside that range are clamped when the style is created.
/// 定义单个日期填充或描边区域的形状。圆角值使用 `0...1` 的比例，超出范围时会自动截断。
public enum TFYSwiftCalendarDayShape: Sendable, Equatable {
    /// 圆形。
    case circle
    /// 自定义圆角，`0` 等同方形，`1` 等同圆形。
    case rounded(cornerRadiusRatio: CGFloat)
    /// 直角方形。
    case square

    fileprivate var cornerRadiusRatio: CGFloat {
        switch self {
        case .circle:
            return 1
        case let .rounded(cornerRadiusRatio):
            return min(1, max(0, cornerRadiusRatio))
        case .square:
            return 0
        }
    }
}

public enum TFYSwiftCalendarSelectionAnimation: Int, CaseIterable, Sendable {
    case none
    case scale
}

public enum TFYSwiftCalendarSeparatorStyle: Int, CaseIterable, Sendable {
    case none
    case rows
}

public enum TFYSwiftCalendarHeaderOrder: Int, CaseIterable, Sendable {
    case monthAboveYear
    case yearAboveMonth
}

public struct TFYSwiftCalendarCaseOptions: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let headerUppercase = Self(rawValue: 1 << 0)
    public static let weekdayUppercase = Self(rawValue: 1 << 1)
    public static let weekdaySingleCharacter = Self(rawValue: 1 << 2)
}

public struct TFYSwiftCalendarCellState: OptionSet, Sendable {
    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let selected = Self(rawValue: 1 << 0)
    public static let placeholder = Self(rawValue: 1 << 1)
    public static let disabled = Self(rawValue: 1 << 2)
    public static let today = Self(rawValue: 1 << 3)
    public static let weekend = Self(rawValue: 1 << 4)
}

public enum TFYSwiftCalendarDefaults {
    public static let headerHeight: CGFloat = 44
    public static let weekdayHeight: CGFloat = 25
    public static let rowHeight: CGFloat = 38
    public static let maximumNumberOfEvents = 3
    public static let animationDuration: TimeInterval = 0.3
}

public struct TFYSwiftCalendarDayContent {
    public var title: String?
    public var subtitle: String?
    public var topSubtitle: String?
    public var image: UIImage?
    public var topImage: UIImage?
    public var eventColors: [UIColor]
    public var accessibilityLabel: String?
    public var accessibilityHint: String?

    public init(
        title: String? = nil,
        subtitle: String? = nil,
        topSubtitle: String? = nil,
        image: UIImage? = nil,
        topImage: UIImage? = nil,
        eventColors: [UIColor] = [],
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.topSubtitle = topSubtitle
        self.image = image
        self.topImage = topImage
        self.eventColors = eventColors
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
    }
}

public struct TFYSwiftCalendarDayStyle {
    public var fillColor: UIColor?
    public var selectionFillColor: UIColor?
    public var titleColor: UIColor?
    public var selectionTitleColor: UIColor?
    public var subtitleColor: UIColor?
    public var selectionSubtitleColor: UIColor?
    public var topSubtitleColor: UIColor?
    public var selectionTopSubtitleColor: UIColor?
    public var borderColor: UIColor?
    public var selectionBorderColor: UIColor?
    public var borderWidth: CGFloat?
    public var selectionBorderWidth: CGFloat?
    public var eventColors: [UIColor]?
    public var selectionEventColors: [UIColor]?
    public var titleOffset: CGPoint?
    public var subtitleOffset: CGPoint?
    public var topSubtitleOffset: CGPoint?
    public var imageOffset: CGPoint?
    public var topImageOffset: CGPoint?
    public var eventOffset: CGPoint?
    public var borderRadius: CGFloat?
    public var fillType: TFYSwiftCalendarFillType?
    public var selectionPosition: TFYSwiftCalendarSelectionPosition?

    public init() {}

    /// Creates an independently filled day style with a configurable outline shape.
    /// 创建具有独立填充和可配置描边形状的日期样式。
    /// - Parameters:
    ///   - shape: 日期外形，可选择圆形、自定义圆角或方形。
    ///   - borderColor: 普通状态的描边颜色。
    ///   - borderWidth: 描边宽度；负数会按 `0` 处理。
    ///   - fillColor: 普通状态的填充颜色。
    ///   - selectionFillColor: 选中状态填充颜色；为 `nil` 时使用日历全局选中颜色。
    ///   - selectionBorderColor: 选中状态描边颜色；为 `nil` 时沿用 `borderColor`。
    public static func bordered(
        shape: TFYSwiftCalendarDayShape = .circle,
        borderColor: UIColor,
        borderWidth: CGFloat = 2,
        fillColor: UIColor = .clear,
        selectionFillColor: UIColor? = nil,
        selectionBorderColor: UIColor? = nil
    ) -> Self {
        var style = Self()
        style.fillType = .separate
        style.borderRadius = shape.cornerRadiusRatio
        style.fillColor = fillColor
        style.selectionFillColor = selectionFillColor
        style.borderColor = borderColor
        style.selectionBorderColor = selectionBorderColor ?? borderColor
        style.borderWidth = max(0, borderWidth)
        style.selectionBorderWidth = max(0, borderWidth)
        return style
    }

    /// Creates a separate, fully rounded date style with a visible outline.
    ///
    /// The selected state keeps the same outline width and uses the calendar's
    /// selection fill unless `selectionFillColor` is supplied.
    /// 创建带独立圆形描边的日期样式；未指定选中填充色时使用日历全局选中颜色。
    public static func circularBorder(
        borderColor: UIColor,
        borderWidth: CGFloat = 2,
        fillColor: UIColor = .clear,
        selectionFillColor: UIColor? = nil,
        selectionBorderColor: UIColor? = nil
    ) -> Self {
        bordered(
            shape: .circle,
            borderColor: borderColor,
            borderWidth: borderWidth,
            fillColor: fillColor,
            selectionFillColor: selectionFillColor,
            selectionBorderColor: selectionBorderColor
        )
    }

    /// Creates a separate square date style with a visible outline.
    /// 创建带独立方形描边的日期样式。
    public static func squareBorder(
        borderColor: UIColor,
        borderWidth: CGFloat = 2,
        fillColor: UIColor = .clear,
        selectionFillColor: UIColor? = nil,
        selectionBorderColor: UIColor? = nil
    ) -> Self {
        bordered(
            shape: .square,
            borderColor: borderColor,
            borderWidth: borderWidth,
            fillColor: fillColor,
            selectionFillColor: selectionFillColor,
            selectionBorderColor: selectionBorderColor
        )
    }
}

internal struct TFYSwiftCalendarDayKey: Hashable, Comparable {
    let era: Int
    let year: Int
    let month: Int
    let day: Int

    init(date: Date, calendar: Calendar) {
        let components = calendar.dateComponents([.era, .year, .month, .day], from: date)
        era = components.era ?? 1
        year = components.year ?? 1
        month = components.month ?? 1
        day = components.day ?? 1
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.era, lhs.year, lhs.month, lhs.day) < (rhs.era, rhs.year, rhs.month, rhs.day)
    }
}

internal struct TFYSwiftCalendarGridItem {
    let date: Date?
    let monthPosition: TFYSwiftCalendarMonthPosition
}
