# Migrating from TFY_Calendar

`TFYSwiftCalendarkit` is a Swift-first replacement rather than a binary-compatible update. The old and new libraries can coexist while screens are migrated.

## Module and type mapping

| Objective-C | Swift |
| --- | --- |
| `TFY_Calendar` | `TFYSwiftCalendar` |
| `TFY_CalendarCell` | `TFYSwiftCalendarCell` |
| `TFY_CalendarAppearance` | `TFYSwiftCalendarAppearance` |
| `TFY_LunarFormatter` | `TFYSwiftLunarFormatter` |
| `TFYCa_CalendarScope` | `TFYSwiftCalendarScope` |
| `TFYCa_CalendarPlaceholderType` | `TFYSwiftCalendarPlaceholderType` |
| `TFYCa_CalendarMonthPosition` | `TFYSwiftCalendarMonthPosition` |
| `TFYCa_CalendarDelegateAppearance` | `TFYSwiftCalendarDelegate.styleFor` |

## Important API changes

- All public symbols begin with `TFYSwift`.
- Optional Objective-C delegate messages became Swift protocol requirements with default implementations.
- Per-day appearance callbacks are consolidated into `TFYSwiftCalendarDayStyle`.
- Titles, subtitles, images, accessibility text, and event colors are consolidated into `TFYSwiftCalendarDayContent`.
- Cell state is a real `OptionSet`; linked range position is a separate enum.
- Invalid selection dates are ignored safely rather than raising an Objective-C exception.
- Reversed date-source bounds are normalized rather than crashing.
- Date arithmetic uses `Calendar`, preserving civil dates across daylight-saving transitions.
- Scope transitions no longer inspect private gesture-recognizer targets or mutate private ivars.

## Incremental adoption

1. Add the Swift package without removing TFY_Calendar.
2. Replace one calendar screen with `TFYSwiftCalendar`.
3. Move content callbacks to `TFYSwiftCalendarDataSource`.
4. Move visual callbacks to the single `styleFor` method.
5. Verify locale, first weekday, minimum/maximum dates, selection, and scope transitions.
6. Remove the old dependency after all screens are migrated.

No bridging header is required by the new library.
