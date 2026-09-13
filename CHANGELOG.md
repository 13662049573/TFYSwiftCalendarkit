# Changelog

## 1.1.0

- Added batch selection, maximum-selection limits, selected/visible date queries, and explicit adjacent-month cell/frame lookup.
- Reworked continuous vertical layout to calculate rows without constructing every page, use binary section lookup, keep sticky headers correct while scrolling, and support right-to-left layout.
- Bounded the page cache and reused event indicator layers to reduce memory churn in large date ranges.
- Removed cascading calendar-configuration reloads and preserved selections when locale, time zone, or calendar settings change.
- Prevented SwiftUI binding feedback during view updates and replaced quadratic selection synchronization with one batched update.
- Improved Dynamic Type, VoiceOver state descriptions, disabled-date traits, reduced-motion behavior, 44-point header controls, and dynamic-color layer updates.
- Added packaged English and Simplified Chinese accessibility strings for Swift Package Manager and CocoaPods.
- Expanded regression coverage and added automated package/example build checks.
- Added configurable normal/selected border widths and a reusable circular-border day-style factory.
- Refined the per-date appearance demo with true circular outlines, cleaner content separation, and an adaptive style legend.

## 1.0.0

- Reimplemented the calendar in pure Swift 6.
- Added month/week scopes and horizontal/vertical paging.
- Added safe single, multiple, swipe, and linked-range selection.
- Added per-day content, styling, images, subtitles, lunar formatting, and event dots.
- Added Dynamic Type, VoiceOver, Dark Mode, UIKit, and SwiftUI support.
- Added Swift Package Manager, CocoaPods metadata, regression tests, and a standalone app with 11 complete demos.
- Covered custom-cell boundary placeholders safely and corrected localized single-character weekday symbols.
- Refined detail navigation and range-selection UI with adaptive cards, quick actions, Dark Mode, and dense-calendar Dynamic Type limits.
- Added compact non-paging vertical layout with optional sticky month section headers.
- Corrected range endpoint joins and pixel-aligned adjacent day cells to remove translucent selection seams.
- Redesigned the custom-tag demo with compact day indicators, circular selection, a responsive card layout, and selected-day details.
- Removed Objective-C runtime forwarding, private KVC, unsafe pointer layouts, and fixed-second day arithmetic.
