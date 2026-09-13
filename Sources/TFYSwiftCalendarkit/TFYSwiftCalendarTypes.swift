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
