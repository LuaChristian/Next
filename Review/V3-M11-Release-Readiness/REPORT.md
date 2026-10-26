# V3-M11 — Release Readiness & Quality Assurance

**Status:** Ready for final PM review (uncommitted)  
**Date:** 2026-10-26  
**Devices:** iPhone 16 Simulator (iOS 18.6)  
**Organization base:** approved folder layout (App / Core / Models / Features / Resources)  
**Do not reorganize further.**

---

## 1. Executive recommendation

**Conditional go for TestFlight / internal release**, with the following caveats:

1. **Unit suite: 308/308 PASS** after fixing two stale botanical assertions.  
2. **UI suite: 78/79 PASS** on the final full run after isolation + stale-path fixes; the single failure (`testM1MultiAreaPlantEditAndScopeFiltering`) was a **stale Living Garden assertion** and **PASS** when re-run after a one-line test update.  
3. Product behavior audits (SwiftData relationships, recovery, Settings hub, Release seeding) look sound.  
4. Remaining risk is **DEBUG UITest isolation** (focus-recovery UserDefaults) — mitigated in this milestone — and occasional simulator AX flakiness under load.

**Ship blockers found in product code:** none for the audited surface.  
**Ship blockers found in tests:** resolved (stale assertions + recovery cleanup).

---

## 2. Exact test results

### Unit — `NextTests`

| Run | Result |
| --- | --- |
| Full suite (after stale botanical fixes) | **308 passed / 0 failed** |
| Final confirmation (post recovery cleanup) | **308 passed / 0 failed** |

Initial full-suite failures (before fixes):

| Test | Classification | Resolution |
| --- | --- | --- |
| `PlantIdentityTests.rendererSignatureIsDeterministic` | **B. Stale test** | Updated for V3-M8 fern remapping of legacy variants |
| `OnboardingTests.completionPersistsGoalsWithoutTasks` | **B. Stale test** | Expects default fern species (M8), not distinct silhouette variants |

### UI — `NextUITests` (+ LaunchTests)

| Run | Result |
| --- | --- |
| First full suite (pre-fixes) | **20 passed / 59 failed** |
| Journey subset (10 tests) after recovery cleanup | **10/10 PASS** |
| Final full suite | **78 passed / 1 failed** (`testM1MultiArea…`) |
| `testM1MultiAreaPlantEditAndScopeFiltering` re-run after fix | **PASS** |

Root cause of the mass first-run failures:

| Cause | Class | Notes |
| --- | --- | --- |
| Leftover `FocusRecoveryStore` snapshots full-screening Focus during later UITests | **A. Product defect (DEBUG isolation)** + **C. Environment** | Settings/Home/Garden unreachable; AX hierarchy showed `focusSettings` |
| Tests still tapping removed Home `appearanceButton` / History tab | **B. Stale test** | Updated to Settings hub destinations |
| Living Garden no longer shows area chips on cells | **B. Stale test** | M1 assertion moved to Goal Detail |
| Intermittent `kAXErrorCannotComplete` on tab/button `.tap()` | **C. Environment** | Mitigated with coordinate tab helpers |

---

## 3. Fixes applied this phase

| Change | Why |
| --- | --- |
| `@MainActor` + convenience init on `FocusView` (no `.shared` default arg) | Clears Swift 6 concurrency warning on `FocusNotificationCoordinator.shared` |
| `FocusRecoveryLaunch`: clear recovery store for UITest launches that do **not** pass `UITEST_FOCUS_RECOVERY` | Prevents cross-test Focus fullScreenCover leakage |
| Unit test updates for fern signature / onboarding defaults | Align with approved V3-M8 behavior |
| UITest helpers: Settings hub / History / Appearance / Reminders paths; coordinate tab taps | Replace stale Home-sheet / History-tab flows |
| `testM1MultiArea…` area-label assertion | Areas verified on Goal Detail (Living Garden cells omit them) |

**Not changed:** SwiftData schema, growth thresholds, RecommendationEngine, folder organization.

---

## 4. Swift 6 concurrency (`FocusView`)

**Finding:** Warning was **future compatibility**, not a live correctness bug.

- Cause: default-argument evaluation of `FocusNotificationCoordinator.shared` is nonisolated; the property is `@MainActor`.
- Runtime today: Focus UI is always constructed on the main actor in practice.
- Fix: MainActor-isolated convenience init that resolves `.shared` in-body; injectable init unchanged for tests.
- **Release build:** no remaining `FocusView` concurrency warnings observed.

---

## 5. Audits

### SwiftData / migration

| Check | Result |
| --- | --- |
| Schema | `Goal`, `GoalTask`, `FocusSession` only — unchanged |
| Goal → tasks | `.cascade` |
| Goal → sessions | `.nullify` (history preserved on goal delete) |
| Task → sessions | `.nullify` |
| `experienceID` idempotent commit | Present |
| Areas migration | `migrateGoalAreasIfNeeded` lightweight backfill |
| Cross-version fixture | `CrossVersionMigrationTests` still present / green in unit suite |
| plantVariantRaw | Non-destructive; unknown → fern |

### Focus timing / background / notifications

| Check | Result |
| --- | --- |
| Simple + Pomodoro mode switch banking | Covered by unit + Pomodoro UI tests |
| Notification cancel clears completion **and** segment IDs | Verified in `FocusNotification` |
| Reminder IDs isolated from focus completion | Unit `ReleaseCandidateTests` / SmartReminders |
| Keep-screen-awake preference | UI test PASS |
| Session recovery fixtures | Visual review PASS; non-recovery UITests now clear leftovers |

### Settings

| Check | Result |
| --- | --- |
| Hub rows → History / Appearance / Reminders / About | PASS |
| Appearance persistence across relaunch | PASS |
| Reminders enable + denied guidance | PASS |
| About version/build (`1.0` / `1`) | PASS (bundle metadata) |

### Production / Release configuration

| Check | Result |
| --- | --- |
| UITest seeds / in-memory stores | `#if DEBUG` only |
| Fern showcase / plant comparison routes | `#if DEBUG` only |
| Launch overrides (appearance, reminder, recovery fixtures) | DEBUG bodies |
| Marketing version / build | `1.0` / `1` |
| Asset catalog | `Next/Resources/Assets.xcassets` (AppIcon, AccentColor) |
| Entitlements file | None (local notifications via standard UN API) |
| Generated Info.plist | Orientations + scene generation; no privacy URL inventions |

### Accessibility / Dynamic Type / dark / small screen

Covered by existing visual-review UITests that passed in the final suite (Garden large DT, History large DT, Settings large DT, Living Garden small screen, Settings small screen, dark appearance captures).

---

## 6. Failure classification summary

| ID | Item | Class | Status |
| --- | --- | --- | --- |
| 1 | Botanical signature / onboarding plantVariant unit expects | B | Fixed |
| 2 | Home `appearanceButton` / History-tab UITests | B | Fixed |
| 3 | Garden cell area-label assertion (M1) | B | Fixed |
| 4 | Stale Focus recovery snapshots poisoning UITests | A (DEBUG isolation) | Fixed |
| 5 | Simulator AX `scrollToVisible` flakiness | C | Mitigated (coordinate tabs); residual risk |
| 6 | FocusView Swift 6 warning | Future compat | Fixed |

**Unresolved (D):** None blocking. Residual AX flakiness under long suites remains an environment risk.

---

## 7. Complete user journey (verified)

Exercised via targeted + final UI suite:

1. Create goal / tasks / multi-area → PASS (M1 after fix)  
2. Recommendations + scope → PASS  
3. Simple Focus finish-early → Garden + History → PASS  
4. Pomodoro optional / presets → PASS  
5. Persistence across process termination → PASS  
6. Settings appearance / reminders / hub → PASS  
7. Session recovery (explicit fixture) → PASS  

---

## 8. Remaining risks

1. **Long UI suites** can still hit intermittent AX failures if the simulator is stressed — prefer serialized runs and recovery cleanup (now automatic for UITests).  
2. **No dedicated Privacy Info / App Store privacy nutrition labels** yet — not introduced here (out of scope).  
3. **Placeholder botanical art** remains intentional until a later artwork pass.  
4. Organization renames remain **uncommitted** alongside this QA work — commit when PM approves both org + readiness.

---

## 9. Files touched this readiness phase

| File | Role |
| --- | --- |
| `Next/Features/Focus/FocusView.swift` | Swift 6 MainActor init fix |
| `Next/Features/Focus/FocusRecoveryLaunch.swift` | Clear recovery for non-recovery UITests |
| `NextTests/NextTests.swift` | Stale botanical / onboarding asserts |
| `NextUITests/NextUITests.swift` | Settings hub paths, tab helpers, M1 area assert |
| `Review/V3-M11-Release-Readiness/REPORT.md` | This report |

Folder organization from the prior phase remains as approved (still uncommitted in the working tree).

---

## 10. PM ask

Approve:

1. Release-readiness findings and recommendation above  
2. The small DEBUG isolation + test/concurrency fixes  
3. Whether to commit **organization + readiness** together or separately  

**Do not commit or push until PM approval.**
