import UIKit

@MainActor
private struct DemoDescriptor {
    let title: String
    let detail: String
    let makeViewController: @MainActor () -> UIViewController
}

final class DemoMenuViewController: UITableViewController {
    private lazy var demos: [DemoDescriptor] = [
        DemoDescriptor(title: "完整功能总览", detail: "月/周、农历、事件点、连续多选", makeViewController: CalendarDemoViewController.init),
        DemoDescriptor(title: "范围选择", detail: "起点、终点、滑动选择与区间着色", makeViewController: RangePickerViewController.init),
        DemoDescriptor(title: "DIY 日历", detail: "农历、系统日历事件、自定义主题", makeViewController: DIYExampleViewController.init),
        DemoDescriptor(title: "上一个 / 下一个", detail: "外部按钮控制日历翻页", makeViewController: ButtonsViewController.init),
        DemoDescriptor(title: "隐藏占位日期", detail: "自适应高度、垂直滚动与行分隔线", makeViewController: HidePlaceholderViewController.init),
        DemoDescriptor(title: "逐日期外观", detail: "颜色、边框、圆角、图片、上下副标题", makeViewController: DelegateAppearanceViewController.init),
        DemoDescriptor(title: "全屏日历", detail: "无分页连续滚动、系统事件与农历", makeViewController: FullScreenExampleViewController.init),
        DemoDescriptor(title: "loadView 创建", detail: "纯代码生命周期与上下图片", makeViewController: LoadViewExampleViewController.init),
        DemoDescriptor(title: "月/周联动", detail: "日历高度变化、手势与列表联动", makeViewController: ScopeExampleViewController.init),
        DemoDescriptor(title: "自定义标签日期格", detail: "紧凑标签、分类图例与日期详情", makeViewController: CalendarTagViewController.init),
        DemoDescriptor(title: "SwiftUI 封装", detail: "UIViewRepresentable、Binding 与状态同步", makeViewController: makeSwiftUIDemo)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "TFYSwiftCalendarkit"
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "demo")
        tableView.rowHeight = 68
        tableView.accessibilityIdentifier = "demo.menu"
    }

    var demoCount: Int { demos.count }

    func makeDemo(at index: Int) -> UIViewController? {
        guard demos.indices.contains(index) else { return nil }
        let viewController = demos[index].makeViewController()
        viewController.navigationItem.largeTitleDisplayMode = .never
        return viewController
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        demos.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "demo", for: indexPath)
        let demo = demos[indexPath.row]
        var configuration = cell.defaultContentConfiguration()
        configuration.text = demo.title
        configuration.secondaryText = demo.detail
        configuration.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = configuration
        cell.accessoryType = .disclosureIndicator
        cell.accessibilityIdentifier = "demo.row.\(indexPath.row)"
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let viewController = makeDemo(at: indexPath.row) else { return }
        navigationController?.pushViewController(viewController, animated: true)
    }
}
