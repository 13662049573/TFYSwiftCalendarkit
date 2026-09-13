import Foundation

@MainActor
public final class TFYSwiftLunarFormatter {
    private var chineseCalendar: Calendar
    private let monthNames = ["正月", "二月", "三月", "四月", "五月", "六月", "七月", "八月", "九月", "十月", "冬月", "腊月"]
    private let dayNames = [
        "初一", "初二", "初三", "初四", "初五", "初六", "初七", "初八", "初九", "初十",
        "十一", "十二", "十三", "十四", "十五", "十六", "十七", "十八", "十九", "二十",
        "廿一", "廿二", "廿三", "廿四", "廿五", "廿六", "廿七", "廿八", "廿九", "三十"
    ]

    public init(timeZone: TimeZone = .current) {
        var calendar = Calendar(identifier: .chinese)
        calendar.locale = Locale(identifier: "zh_Hans_CN")
        calendar.timeZone = timeZone
        chineseCalendar = calendar
    }

    public var timeZone: TimeZone {
        get { chineseCalendar.timeZone }
        set { chineseCalendar.timeZone = newValue }
    }

    public func string(from date: Date) -> String {
        let components = chineseCalendar.dateComponents([.month, .day], from: date)
        guard let day = components.day, day > 0, day <= dayNames.count else { return "" }
        if day == 1, let month = components.month, month > 0, month <= monthNames.count {
            return (components.isLeapMonth == true ? "闰" : "") + monthNames[month - 1]
        }
        return dayNames[day - 1]
    }
}
