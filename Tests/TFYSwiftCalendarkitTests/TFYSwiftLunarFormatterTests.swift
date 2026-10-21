import XCTest
@testable import TFYSwiftCalendarkit

@MainActor
final class TFYSwiftLunarFormatterTests: XCTestCase {
    func testKnownChineseNewYearDate() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let date = calendar.date(from: DateComponents(year: 2024, month: 2, day: 10, hour: 12))!
        let formatter = TFYSwiftLunarFormatter(timeZone: calendar.timeZone)
        XCTAssertEqual(formatter.string(from: date), "正月")
    }
}
