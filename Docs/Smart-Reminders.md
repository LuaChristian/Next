# Smart Reminders (V2-M7)

Optional, entirely local daily invitations to begin a focus session.
Default **OFF**. Never streaks, guilt, urgency, or personalized task names in the banner.

## Identifiers

| Kind | Identifier | Owner |
|---|---|---|
| Daily reminder | `next.reminder.daily` | `DailyReminderCoordinator` |
| Focus completion (M4) | `next.focus.completion` | `FocusNotificationCoordinator` |

Changing reminder preferences cancels **only** `next.reminder.daily`.

## Scheduling

- Public `UserNotifications` APIs only.
- One pending request with identifier `next.reminder.daily`.
- Calendar trigger (local year/month/day/hour/minute/second), **non-repeating**.
- On enable, time change, or app becoming active: cancel that identifier, then schedule the next fire.
- Next fire:
  - If a `FocusSession` has `completedAt` today → tomorrow at the chosen clock time.
  - Else if today’s clock time is still ahead → today.
  - Else → tomorrow.
- A completed focus session counts even when the user answered **NOT YET** (task unfinished). Task completion is irrelevant.

## Smart suppression (honest limits)

**Reliable when the app becomes active** before the next fire: reconcile inspects SwiftData `FocusSession.completedAt` and skips today’s reminder if the user already focused.

**Not guaranteed** if the user focuses, leaves the app, and never returns before the previously scheduled fire: iOS may still deliver that one-shot notification. Next does not add background modes or polling solely to promise perfect suppression.

## Permission

Authorization is requested only when the user turns Reminders **On**. If delivery is not possible (denied / unavailable), the preference stays **Off** and Settings guidance is shown. Provisional and authorized both allow scheduling.

## Navigation

Tapping a reminder opens Next normally and prefers the Home tab unless a focus session is already on screen.
