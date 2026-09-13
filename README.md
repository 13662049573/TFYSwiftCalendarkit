# TFYSwiftCalendarkit

`TFYSwiftCalendarkit` is a pure Swift calendar library for iOS 15 and later. It keeps the flexible UIKit model of TFY_Calendar while replacing Objective-C runtime forwarding, private KVC access, unsafe pointers, and fixed-second date arithmetic with type-safe Swift APIs.

## Features

- Month and week scopes
- Horizontal and vertical paging
- Configurable first weekday, locale, calendar, and time zone
- None, head/tail, and fixed six-row placeholder modes
- Single, multiple, swipe, and linked-range selection
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
.package(url: "https://github.com/13662049573/TFYSwiftCalendarkit.git", from: "1.0.0")
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

For a contiguous selection:

```swift
calendarView.selectDates(from: startDate, through: endDate)
```

For a scope transition:

```swift
calendarView.setScope(.week, animated: true)
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
        .frame(height: scope == .month ? 293 : 103)
    }
}
```

## Example and tests

- Open `Examples/TFYSwiftCalendarExample/TFYSwiftCalendarExample.xcodeproj` to run the example app.
- Open the repository folder in Xcode to edit the Swift Package.
- Run `xcodebuild -scheme TFYSwiftCalendarkit -destination 'platform=iOS Simulator,name=iPhone 17' test` for the test suite.

See [MIGRATION.md](MIGRATION.md) for Objective-C API mapping and behavior changes.

## Requirements

- iOS 15+
- Swift 6 / Xcode 16+
- UIKit; SwiftUI support is optional

## License

MIT. See [LICENSE](LICENSE).
