# TFYSwiftCalendarkit

`TFYSwiftCalendarkit` 是一个支持 iOS 15 及以上版本的纯 Swift 日历组件。它保留了 TFY_Calendar 灵活的 UIKit 使用方式，同时以类型安全的 Swift API 替代 Objective-C 运行时消息转发、私有 KVC、非安全指针和固定秒数日期计算。

## 功能特性

- 月视图与周视图
- 水平或垂直分页，以及紧凑的连续垂直滚动
- 可配置每周起始日、语言区域、日历、时区和星期栏样式
- 不显示、首尾补齐和固定六行三种占位模式
- 单选、多选、滑动选择和连续范围选择
- 批量选择、可选的选择数量限制、可见日期查询和相邻月份单元格查询
- 自定义单元格，以及按日期配置内容与样式
- 副标题、顶部副标题、图片、农历文本和事件圆点
- 支持动态字体、VoiceOver 和深色模式
- 提供 UIKit API 和 SwiftUI `UIViewRepresentable` 封装
- 无第三方运行时依赖

## 安装

### Swift Package Manager

在 Xcode 中选择 **File > Add Package Dependencies**，然后输入仓库地址：

```text
https://github.com/13662049573/TFYSwiftCalendarkit.git
```

也可以在 `Package.swift` 中添加：

```swift
.package(url: "https://github.com/13662049573/TFYSwiftCalendarkit.git", from: "1.1.0")
```

随后将 `TFYSwiftCalendarkit` 添加到应用 Target。

### CocoaPods

在 `Podfile` 中添加：

```ruby
pod 'TFYSwiftCalendarkit', '~> 1.1.0'
```

然后执行 `pod install`，并通过生成的 `.xcworkspace` 打开项目。

## UIKit 快速开始

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

实现 `TFYSwiftCalendarDataSource` 以提供日期内容，实现 `TFYSwiftCalendarDelegate` 以处理选择事件和按日期配置样式。所有协议方法都有默认实现，因此只需实现实际需要的方法。

```swift
extension CalendarViewController: TFYSwiftCalendarDataSource {
    func calendar(_ calendar: TFYSwiftCalendar, contentFor date: Date) -> TFYSwiftCalendarDayContent {
        TFYSwiftCalendarDayContent(subtitle: "休", eventColors: [.systemOrange])
    }
}
```

当某个日期需要清晰且独立的边框时，可以使用内置的描边样式工厂。它支持圆形、按比例设置圆角和方形，也可以通过全局外观对象统一设置边框宽度。

```swift
func calendar(_ calendar: TFYSwiftCalendar, styleFor date: Date) -> TFYSwiftCalendarDayStyle? {
    .bordered(
        shape: .rounded(cornerRadiusRatio: 0.35), // 也可使用 .circle 或 .square
        borderColor: .systemIndigo,
        borderWidth: 2,
        selectionFillColor: .systemIndigo
    )
}

calendarView.appearance.borderWidth = 1
calendarView.appearance.selectionBorderWidth = 2
```

如果内容或样式只应显示在日期所属月份，请使用带月份位置的回调。与 `currentPage` 不同，在交互式滑动期间预加载上一页或下一页时，`monthPosition` 仍能保持准确。

```swift
func calendar(
    _ calendar: TFYSwiftCalendar,
    contentFor date: Date,
    at monthPosition: TFYSwiftCalendarMonthPosition
) -> TFYSwiftCalendarDayContent {
    guard monthPosition == .current else { return .init() }
    return .init(subtitle: "提醒")
}

// 仅刷新发生变化的可见日期，不重新加载或创建单元格。
calendarView.reloadDates(changedDates)
```

星期栏支持自定义显示文本、VoiceOver 名称、每日文字与背景颜色、间距、内边距、边框和胶囊圆角背景。数组采用 Foundation 的星期顺序（星期日至星期六），组件会根据 `firstWeekday` 自动重新排列。

```swift
calendarView.appearance.weekdaySymbols = ["日", "一", "二", "三", "四", "五", "六"]
calendarView.appearance.weekdayTextColors = [
    .systemRed, .secondaryLabel, .secondaryLabel, .secondaryLabel,
    .secondaryLabel, .secondaryLabel, .systemRed
]
calendarView.appearance.weekdayLabelCornerRadius = 10
calendarView.appearance.weekdaySpacing = 4
calendarView.appearance.weekdayContentInsets = .init(top: 3, left: 8, bottom: 3, right: 8)

calendarView.appearance.selectionAnimation = .scale // 也可使用 .none
calendarView.appearance.selectionAnimationScale = 0.96
calendarView.appearance.selectionAnimationDuration = 0.16
calendarView.invalidateAppearance()
```

选择连续日期范围：

```swift
calendarView.selectDates(from: startDate, through: endDate)
```

高效选择不连续日期并设置类似预订场景的数量限制：

```swift
calendarView.allowsMultipleSelection = true
calendarView.maximumSelectedDates = 5
calendarView.selectDates(dates, replacingCurrentSelection: true)
```

实现 `calendar(_:didReachMaximumSelectionCount:)` 可以在达到数量上限时显示提示。使用 `selectedDateBounds`、`visibleDates`、`visibleDateRange` 和 `isDateSelected(_:)` 查询当前状态。同一天作为相邻月份占位日期重复出现时，可以使用 `cell(for:at:)` 或 `frame(for:at:)` 精确定位对应位置。

切换月视图与周视图：

```swift
calendarView.setScope(.week, animated: true)

// 可选：允许通过垂直滑动收起或展开月视图与周视图。
calendarView.allowsScopeGesture = true
```

范围切换手势默认关闭，避免垂直滚动意外改变日历范围。如果 Auto Layout 固定了日历高度，请先在 `calendar(_:boundingRectWillChange:animated:)` 中更新高度约束，再启用该手势。

使用带吸顶月份标题的紧凑连续日历：

```swift
calendarView.scrollDirection = .vertical
calendarView.pagingEnabled = false
calendarView.rowHeight = 64
calendarView.continuousSectionHeaderHeight = 44
```

如果高度由 Auto Layout 管理，请通过以下代理方法更新高度约束：

```swift
func calendar(_ calendar: TFYSwiftCalendar, boundingRectWillChange bounds: CGRect, animated: Bool)
```

## SwiftUI 快速开始

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

## 示例与测试

- 打开 `Examples/TFYSwiftCalendarExample/TFYSwiftCalendarExample.xcodeproj` 运行示例应用。菜单包含 11 个完整的 UIKit 和 SwiftUI 示例，涵盖范围选择、EventKit、自定义单元格、月/周切换、连续滚动和按日期配置外观。
- 在 Xcode 中打开仓库目录，可以直接编辑 Swift Package。
- 执行 `xcodebuild -scheme TFYSwiftCalendarkit -destination 'platform=iOS Simulator,name=iPhone 17' test` 运行测试套件。

测试覆盖民用日期边界、夏令时切换、占位日期安全性、批量选择与数量限制、大范围连续滚动、选中区域衔接、无障碍配置、自定义单元格和事件图层复用。连续模式无需实例化所有月份即可计算行布局，内部页面缓存也设置了数量上限。

有关 Objective-C API 对照和行为变化，请参阅 [MIGRATION.md](MIGRATION.md)；有关发布质量检查，请参阅 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 环境要求

- iOS 15+
- Swift 6 / Xcode 16+
- UIKit；SwiftUI 支持为可选能力

## 开源许可

本项目采用 MIT 许可证，详情请参阅 [LICENSE](LICENSE)。
