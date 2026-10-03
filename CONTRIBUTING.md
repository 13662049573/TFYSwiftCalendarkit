# Contributing

TFYSwiftCalendarkit accepts focused changes that preserve source compatibility and civil-date behavior.

## Development checks

1. Build and test the Swift package on an iOS simulator with warnings treated as errors.
2. Build `Examples/TFYSwiftCalendarExample/TFYSwiftCalendarExample.xcodeproj`.
3. Exercise month and week scopes, horizontal paging, continuous vertical scrolling, range selection, Dark Mode, Dynamic Type, and VoiceOver.
4. Run `pod lib lint TFYSwiftCalendarkit.podspec --allow-warnings --test-specs=Tests` when changing CocoaPods sources, resources or metadata.

Discover a simulator with `xcrun simctl list devices available` and substitute its UUID:

```sh
xcodebuild test -scheme TFYSwiftCalendarkit \
  -destination 'platform=iOS Simulator,id=<UUID>' \
  -derivedDataPath /tmp/TFYCalendarChecks \
  SWIFT_TREAT_WARNINGS_AS_ERRORS=YES

xcodebuild build \
  -project Examples/TFYSwiftCalendarExample/TFYSwiftCalendarExample.xcodeproj \
  -scheme TFYSwiftCalendarExample \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
```

Serialize checks against one DerivedData directory. If a failed run leaves a test process alive, finish or terminate that run before starting the next build.

Regression expectations include leap-month identity, era boundaries, runtime layout transitions, RTL offset round trips, selection-limit work bounds, duplicate placeholder state, and SwiftUI binding reconciliation. The Chinese [quality review](Documentation/QUALITY_REVIEW.md) records integration semantics and remaining manual checks.

Date calculations must use `Calendar` operations rather than fixed 86,400-second offsets. New public APIs require documentation and regression coverage. Avoid work proportional to the entire configured date range during scrolling or layout.

## Compatibility

- Minimum deployment target: iOS 16
- Language mode: Swift 6
- Supported UI frameworks: UIKit and SwiftUI

Security issues should be reported according to [SECURITY.md](SECURITY.md), not in a public issue.

## Release preparation

Run `python3 Scripts/validate_release_metadata.py` before committing a release. The script checks Pod/SPM minimum versions, SwiftUI availability, example versions and documentation. CI repeats these checks on main, pull requests, version tags and published GitHub Releases, using an available runner simulator instead of a fixed device/Xcode path.

For tag validation use `python3 Scripts/validate_release_metadata.py --tag 2.0.0`. The Pod source expects the exact numeric version tag. Follow [2.0.0 release instructions](Documentation/RELEASE_2.0.0.md) before publishing to CocoaPods.
