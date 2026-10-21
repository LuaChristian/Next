# V3-M10 — Settings Navigation & Organization

**Status:** Ready for PM review (uncommitted)  
**Date:** 2026-10-21  
**Devices:** iPhone 16 / iPhone 16e Simulator  
**Base:** `4220d41` — V3-M9 living garden (confirmed committed before start)

## 1. Implementation summary

Settings is now a section-based navigation hub. History, Appearance, Reminders, and About each open a dedicated page. Existing appearance persistence, reminder scheduling, and History behavior are reused without duplication. No SwiftData schema changes.

## 2. Navigation architecture

```
TabView → NavigationStack → SettingsView (hub)
                              ├─ History → HistoryView (existing)
                              ├─ Appearance → AppearanceSettingsView
                              ├─ Reminders → RemindersSettingsView
                              └─ About → AboutNextView
```

- Single `NavigationStack` on the Settings tab (no nested stacks).
- Typed `SettingsDestination` + `navigationDestination(for:)`.
- Back returns to the hub; tab bar remains stable.
- Appearance / reminder changes apply immediately via existing preferences.

## 3. Files changed

| File | Role |
| --- | --- |
| `Next/SettingsView.swift` | Hub only |
| `Next/SettingsDestination.swift` | **New** — destinations + `AppVersionInfo` |
| `Next/SettingsRow.swift` | **New** — editorial nav row |
| `Next/AppearanceSettingsView.swift` | **New** — dedicated Appearance page |
| `Next/RemindersSettingsView.swift` | **New** — dedicated Reminders page |
| `Next/AboutNextView.swift` | **New** — About + version/build |
| `NextTests/NextTests.swift` | `SettingsNavigationTests`; fern default assertion |
| `NextUITests/NextUITests.swift` | Hub navigation helpers + visual review; M9 Settings paths updated |
| `Review/V3-M10-Settings-Navigation/` | Screenshots + REPORT |

## 4. Targeted test results

**Unit — PASS**

- `SettingsNavigationTests` (2)  
- `AppearancePreferenceTests` (6)

**UI — PASS**

- `testSettingsNavigationHubOpensEachDestination`  
- `testSettingsNavigationVisualReview` (shots 01–08)  
- `testSettingsNavigationSmallScreenReview` (shot 09)  
- `testM9TabsSettingsHistoryAndHomeHeader`  
- `testM9AppearanceSwitchesImmediatelyAndPersists`  
- `testM9ReminderToggleStillWorksFromSettings`

## 5. Screenshots

| # | File |
| --- | --- |
| 01 | `01 Settings navigation hub — light mode.png` |
| 02 | `02 Appearance settings.png` |
| 03 | `03 Reminders settings.png` |
| 04 | `04 History opened from Settings.png` |
| 05 | `05 About Next.png` |
| 06 | `06 Settings navigation hub — dark mode.png` |
| 07 | `07 A dedicated settings page — dark mode.png` |
| 08 | `08 Settings with large Dynamic Type.png` |
| 09 | `09 Settings on a smaller device.png` |

## 6. Risks / limitations

- Older visual-review tests that still reference a removed Home `appearanceButton` / preferences sheet were not rewritten (outside this milestone’s Settings hub path).  
- About shows marketing version/build only — no privacy policy or support URLs (by design).  
- Reminder notification permission still depends on system prompts / UITest auth overrides.

**Do not commit or push until PM approval.**
