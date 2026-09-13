# TFYSwiftCalendarkit

`TFYSwiftCalendarkit` is a pure Swift calendar library for iOS 15 and later. It keeps the flexible UIKit model of TFY_Calendar while replacing Objective-C runtime forwarding, private KVC access, unsafe pointers, and fixed-second date arithmetic with type-safe Swift APIs.

## Features

- Month and week scopes
- Horizontal/vertical paging and compact continuous vertical scrolling
- Configurable first weekday, locale, calendar, time zone, and weekday-bar styling
- None, head/tail, and fixed six-row placeholder modes
- Single, multiple, swipe, and linked-range selection
- Batched selection, optional selection limits, visible-date queries, and adjacent-month cell lookup
- Custom cells and per-day content/styles
- Subtitles, top subtitles, images, lunar labels, and event dots
- Dynamic Type, VoiceOver labels, and Dark Mode colors
- UIKit API plus a SwiftUI `UIViewRepresentable`
- No third-party runtime dependencies

## Installation

### Swift Package Manager

In Xcode, select **File > Add Package Dependencies**, then use the repository URL after publishing this folder:

```text
https://github.com/13662049573/TFYSwiftCalendarkit.git
```

Or add it to `Package.swift`:

```swift
.package(url: "https://github.com/13662049573/TFYSwiftCalendarkit.git", from: "1.1.0")
```

Then add `TFYSwiftCalendarkit` to the app target.

## UIKit quick start

```swift
import TFYSwiftCalendarkit
import UIKit

final class CalendarViewController: UIViewController {
    private let calendarView = TFYSwiftCalendar()

    override func viewDidLoad() {
        super.viewDidLoad()
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        calendarView.locale = Locale(identifier: "zh_CN")
        calendarView.firstWeekday = 2
        calendarView.allowsMultipleSelection = true
        calendarView.swipeToChooseGestureRecognizer.isEnabled = true
        view.addSubview(calendarView)

        NSLayoutConstraint.activate([
            calendarView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            calendarView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            calendarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            calendarView.heightAnchor.constraint(equalToConstant: calendarView.preferredHeight)
        ])
    }
}
```

Implement `TFYSwiftCalendarDataSource` to provide day content and `TFYSwiftCalendarDelegate` for selection and per-day style. Every protocol method has a default implementation, so only implement what is needed.

```swift
extension CalendarViewController: TFYSwiftCalendarDataSource {
    func calendar(_ calendar: TFYSwiftCalendar, contentFor date: Date) -> TFYSwiftCalendarDayContent {
        TFYSwiftCalendarDayContent(subtitle: "休", eventColors: [.systemOrange])
    }
}
```

Use the built-in circular-outline factory when an individual date needs a clear,
independent border. Border widths can also be configured globally through the appearance object.

```swift
func calendar(_ calendar: TFYSwiftCalendar, styleFor date: Date) -> TFYSwiftCalendarDayStyle? {
    .circularBorder(
        borderColor: .systemIndigo,
        borderWidth: 2,
        selectionFillColor: .systemIndigo
    )
}

calendarView.appearance.borderWidth = 1
calendarView.appearance.selectionBorderWidth = 2
```

The weekday bar supports custom symbols, VoiceOver names, per-day text/background colors,
spacing, insets, borders, and rounded pill backgrounds. Arrays use Foundation weekday order
(Sunday through Saturday) and are reordered automatically for `firstWeekday`.

```swift
calendarView.appearance.weekdaySymbols = ["日", "一", "二", "三", "四", "五", "六"]
calendarView.appearance.weekdayTextColors = [
    .systemRed, .secondaryLabel, .secondaryLabel, .secondaryLabel,
    .secondaryLabel, .secondaryLabel, .systemRed
]
calendarView.appearance.weekdayLabelCornerRadius = 10
calendarView.appearance.weekdaySpacing = 4
calendarView.appearance.weekdayContentInsets = .init(top: 3, left: 8, bottom: 3, right: 8)

calendarView.appearance.selectionAnimation = .scale // or .none
calendarView.appearance.selectionAnimationScale = 0.96
calendarView.appearance.selectionAnimationDuration = 0.16
calendarView.invalidateAppearance()
```

For a contiguous selection:

```swift
calendarView.selectDates(from: startDate, through: endDate)
```

For efficient non-contiguous selection and a booking-style limit:

```swift
calendarView.allowsMultipleSelection = true
calendarView.maximumSelectedDates = 5
calendarView.selectDates(dates, replacingCurrentSelection: true)
```

Implement `calendar(_:didReachMaximumSelectionCount:)` to show a limit message. Use
`selectedDateBounds`, `visibleDates`, `visibleDateRange`, and `isDateSelected(_:)` for state queries.
When the same day appears as an adjacent-month placeholder, use `cell(for:at:)` or `frame(for:at:)`
to address that exact occurrence.

For a scope transition:

```swift
calendarView.setScope(.week, animated: true)
```

For a compact continuous calendar with sticky month headers:

```swift
calendarView.scrollDirection = .vertical
calendarView.pagingEnabled = false
calendarView.rowHeight = 64
calendarView.continuousSectionHeaderHeight = 44
```

When Auto Layout controls the height, update its height constraint from:

```swift
func calendar(_ calendar: TFYSwiftCalendar, boundingRectWillChange bounds: CGRect, animated: Bool)
```

## SwiftUI quick start

```swift
import SwiftUI
import TFYSwiftCalendarkit

struct ContentView: View {
    @State private var selectedDates: [Date] = []
    @State private var scope: TFYSwiftCalendarScope = .month

    var body: some View {
        TFYSwiftCalendarView(selectedDates: $selectedDates, scope: $scope) { date in
            TFYSwiftCalendarDayContent()
        } configure: { calendar in
            calendar.locale = Locale(identifier: "zh_CN")
            calendar.allowsMultipleSelection = true
        }
        .frame(height: scope == .month ? 297 : 107)
    }
}
```

## Example and tests

- Open `Examples/TFYSwiftCalendarExample/TFYSwiftCalendarExample.xcodeproj` to run the example app. Its menu contains 11 complete UIKit and SwiftUI demonstrations, including range selection, EventKit, custom cells, month/week transitions, continuous scrolling, and per-date appearance.
- Open the repository folder in Xcode to edit the Swift Package.
- Run `xcodebuild -scheme TFYSwiftCalendarkit -destination 'platform=iOS Simulator,name=iPhone 17' test` for the test suite.

The test suite covers civil-date boundaries, daylight-saving transitions, placeholder safety,
selection batching and limits, large continuous ranges, layout joins, accessibility configuration,
custom cells, and event-layer reuse. Continuous mode computes row geometry without materializing
every month and the internal page cache is bounded.

See [MIGRATION.md](MIGRATION.md) for Objective-C API mapping and behavior changes, and
[CONTRIBUTING.md](CONTRIBUTING.md) for release-quality checks.

## Requirements

- iOS 15+
- Swift 6 / Xcode 16+
- UIKit; SwiftUI support is optional

## License

MIT. See [LICENSE](LICENSE).
