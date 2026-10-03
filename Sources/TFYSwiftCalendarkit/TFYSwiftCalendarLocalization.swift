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

    static func string(_ key: String, locale: Locale? = nil, comment: String) -> String {
        guard let locale else { return NSLocalizedString(key, bundle: bundle, comment: comment) }
        let preferred = Bundle.preferredLocalizations(from: bundle.localizations, forPreferences: [locale.identifier])
        guard let language = preferred.first,
              let path = bundle.path(forResource: language, ofType: "lproj"),
              let localizedBundle = Bundle(path: path) else {
            return NSLocalizedString(key, bundle: bundle, comment: comment)
        }
        return localizedBundle.localizedString(forKey: key, value: key, table: nil)
    }
}
