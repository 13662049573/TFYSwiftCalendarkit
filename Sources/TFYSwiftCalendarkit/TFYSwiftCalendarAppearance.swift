import UIKit

@MainActor
public final class TFYSwiftCalendarAppearance {
    public var titleFont = UIFont.preferredFont(forTextStyle: .body)
    public var subtitleFont = UIFont.preferredFont(forTextStyle: .caption2)
    public var topSubtitleFont = UIFont.preferredFont(forTextStyle: .caption2)
    public var weekdayFont = UIFont.preferredFont(forTextStyle: .caption1)
    public var headerTitleFont = UIFont.preferredFont(forTextStyle: .headline)

    public var titleOffset = CGPoint.zero
    public var subtitleOffset = CGPoint.zero
    public var topSubtitleOffset = CGPoint.zero
    public var eventOffset = CGPoint.zero
    public var imageOffset = CGPoint.zero
    public var topImageOffset = CGPoint.zero

    public var eventDefaultColor = UIColor.systemBlue.withAlphaComponent(0.75)
    public var eventSelectionColor = UIColor.white
    public var weekdayTextColor = UIColor.secondaryLabel
    public var headerTitleColor = UIColor.label
    public var headerDateFormat = "yyyy MMMM"

    public var titleDefaultColor = UIColor.label
    public var titleSelectionColor = UIColor.white
    public var titleTodayColor = UIColor.systemRed
    public var titlePlaceholderColor = UIColor.tertiaryLabel
    public var titleWeekendColor = UIColor.systemRed
    public var titleDisabledColor = UIColor.quaternaryLabel

    public var subtitleDefaultColor = UIColor.secondaryLabel
    public var subtitleSelectionColor = UIColor.white
    public var subtitleTodayColor = UIColor.systemRed
    public var subtitlePlaceholderColor = UIColor.tertiaryLabel
    public var subtitleWeekendColor = UIColor.secondaryLabel

    public var topSubtitleDefaultColor = UIColor.secondaryLabel
    public var topSubtitleSelectionColor = UIColor.white

    public var selectionColor = UIColor.systemBlue
    public var todayColor = UIColor.clear
    public var todaySelectionColor = UIColor.systemBlue
    public var borderDefaultColor = UIColor.clear
    public var borderSelectionColor = UIColor.clear
    public var borderWidth: CGFloat = 1
    public var selectionBorderWidth: CGFloat = 1
    public var separatorColor = UIColor.separator.withAlphaComponent(0.45)

    /// `0` is a rectangle and `1` is the largest possible corner radius.
    public var borderRadius: CGFloat = 1
    public var horizontalTitleInset: CGFloat = 0
    public var fillType: TFYSwiftCalendarFillType = .separate
    public var separatorStyle: TFYSwiftCalendarSeparatorStyle = .none
    public var caseOptions: TFYSwiftCalendarCaseOptions = []
    public var headerOrder: TFYSwiftCalendarHeaderOrder = .monthAboveYear

    public init() {}

    public func titleColor(for state: TFYSwiftCalendarCellState) -> UIColor {
        if state.contains(.selected) { return titleSelectionColor }
        if state.contains(.disabled) { return titleDisabledColor }
        if state.contains(.placeholder) { return titlePlaceholderColor }
        if state.contains(.today) { return titleTodayColor }
        if state.contains(.weekend) { return titleWeekendColor }
        return titleDefaultColor
    }

    public func subtitleColor(for state: TFYSwiftCalendarCellState) -> UIColor {
        if state.contains(.selected) { return subtitleSelectionColor }
        if state.contains(.placeholder) { return subtitlePlaceholderColor }
        if state.contains(.today) { return subtitleTodayColor }
        if state.contains(.weekend) { return subtitleWeekendColor }
        return subtitleDefaultColor
    }

    public func fillColor(for state: TFYSwiftCalendarCellState) -> UIColor {
        if state.contains([.today, .selected]) { return todaySelectionColor }
        if state.contains(.selected) { return selectionColor }
        if state.contains(.today) { return todayColor }
        return .clear
    }

    public func borderColor(for state: TFYSwiftCalendarCellState) -> UIColor {
        state.contains(.selected) ? borderSelectionColor : borderDefaultColor
    }
}
