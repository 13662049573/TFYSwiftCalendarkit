# Contributing

TFYSwiftCalendarkit accepts focused changes that preserve source compatibility and civil-date behavior.

## Development checks

1. Build and test the Swift package on an iOS simulator with warnings treated as errors.
2. Build `Examples/TFYSwiftCalendarExample/TFYSwiftCalendarExample.xcodeproj`.
3. Exercise month and week scopes, horizontal paging, continuous vertical scrolling, range selection, Dark Mode, Dynamic Type, and VoiceOver.
4. Run `pod lib lint TFYSwiftCalendarkit.podspec --allow-warnings` when changing CocoaPods metadata.

Date calculations must use `Calendar` operations rather than fixed 86,400-second offsets. New public APIs require documentation and regression coverage. Avoid work proportional to the entire configured date range during scrolling or layout.

## Compatibility

- Minimum deployment target: iOS 15
- Language mode: Swift 6
- Supported UI frameworks: UIKit and SwiftUI

Security issues should be reported according to [SECURITY.md](SECURITY.md), not in a public issue.
