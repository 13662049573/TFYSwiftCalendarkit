# Changelog

## 2.0.0

- **Breaking compatibility:** raised the minimum deployment target from iOS 15 to iOS 16 across SPM, CocoaPods, SwiftUI and the example app.

- Fixed leap-month date identity and ordering; kept the default range in Gregorian civil years across calendar identifiers.
- Preserved focused/selected days through month/week changes and page alignment through runtime layout changes.
- Sanitized invalid geometry, protected invalid item lookups, and included insets/sticky headers in preferred height.
- Made SwiftUI obey selection configuration, defer binding reconciliation, and cancel stale updates on replacement/dismantle.
- Added calendarSelectionDidChange for final selections, including range and selection-limit pruning.
- Streamed range candidates with early selection-limit termination and cached page counts/continuous row metrics.
- Unified RTL page offsets and columns; mirrored navigation controls and linked-range ends.
- Synchronized all visible copies of selected dates, disconnected links into hidden placeholders, and restored navigation for repeated selections.
- Localized accessibility states and day numbers according to the component locale; refreshed visible sticky-header appearance.
- Fixed midnight/last-day EventKit boundaries, cleared demo event data when permission is denied, and kept its permission bridge compatible with Swift 6 isolation checking on older SDKs.
- Fixed lunar/event toggle flashes in the DIY and full-screen demos with in-place content refresh; coalesced event requests and cached successful empty results.
- Added 21 regression tests and a Chinese quality/risk review with explicit integration contracts.

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
- Removed selection and scope-transition flashes by updating visible cells in place and eliminating opacity-based scope animation.
- Added custom weekday symbols, accessibility names, per-day colors/backgrounds, spacing, insets, borders, and pill corners.
- Deferred weekday spacing and inset layout until a valid size is available, preventing zero-width Auto Layout conflicts.
- Reserved independent date, subtitle, and centered event-dot slots to prevent event markers from drifting or overlapping text.
- Made vertical month/week scope gestures opt-in and hardened the DIY demo's animated height transition.
- Redesigned the complete overview demo with adaptive cards, a styled month/week control, clearer selection summaries, and uncluttered placeholders.
- Added circle, proportional rounded-corner, and square per-date border shapes with an interactive appearance demo.
- Added position-aware content/style callbacks so adjacent-page preloading cannot hide labels or styles during swipes.
- Reconfigured visible dates in place after page changes and cleared recycled-cell animations to prevent paging and reuse flashes.

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
