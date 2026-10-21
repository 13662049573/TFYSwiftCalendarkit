import UIKit

@MainActor
enum TFYSwiftCalendarTraitRegistration {
    /// Observes interface-style changes using `registerForTraitChanges` on iOS 17+.
    static func registerInterfaceStyleChanges(on view: UIView, handler: @escaping () -> Void) {
        if #available(iOS 17.0, *) {
            view.registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (_: UIView, _: UITraitCollection) in
                handler()
            }
        }
    }

    /// Forwards `traitCollectionDidChange` on iOS 16 only; iOS 17+ uses trait registration above.
    static func handleLegacyInterfaceStyleChange(
        on view: UIView,
        previousTraitCollection: UITraitCollection?,
        handler: () -> Void
    ) {
        if #unavailable(iOS 17.0) {
            if previousTraitCollection?.hasDifferentColorAppearance(comparedTo: view.traitCollection) ?? true {
                handler()
            }
        }
    }
}
