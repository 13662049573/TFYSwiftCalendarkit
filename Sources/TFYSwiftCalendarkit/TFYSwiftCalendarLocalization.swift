import Foundation

internal enum TFYSwiftCalendarLocalization {
    private final class BundleToken {}

    static let bundle: Bundle = {
        #if SWIFT_PACKAGE
        return .module
        #else
        let containingBundle = Bundle(for: BundleToken.self)
        for candidate in [Bundle.main, containingBundle] {
            if let resourceURL = candidate.url(
                forResource: "TFYSwiftCalendarkit_Resources",
                withExtension: "bundle"
            ), let resourceBundle = Bundle(url: resourceURL) {
                return resourceBundle
            }
        }
        return containingBundle
        #endif
    }()

    static func string(_ key: String, comment: String) -> String {
        NSLocalizedString(key, bundle: bundle, comment: comment)
    }
}
