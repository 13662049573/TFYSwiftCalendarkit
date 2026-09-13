import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        let menu = DemoMenuViewController()
        let navigationController = UINavigationController(rootViewController: menu)
        var launchedDemo: UIViewController?
        if let argument = ProcessInfo.processInfo.arguments.first(where: { $0.hasPrefix("--demo-index=") }),
           let index = Int(argument.replacingOccurrences(of: "--demo-index=", with: "")),
           let demo = menu.makeDemo(at: index) {
            navigationController.pushViewController(demo, animated: false)
            launchedDemo = demo
        }
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window

        if ProcessInfo.processInfo.arguments.contains("--run-smoke-test"),
           let demo = launchedDemo as? DemoSmokeTestable {
            DispatchQueue.main.async {
                demo.runSmokeTest()
            }
        }
    }
}
