# Everline — MVP 0.1 Goal

## Goal

Ship the smallest native Mac app that the author can **start using every day** for daily notes and meetings. Success
is replacing their current notes tool for a full working week, not feature breadth.

## In Scope

### 1. Main window with two navigation rows

- **Breadcrumb:** Year / Month / Week / Day, always visible at every level; each segment is clickable and opens that
  period's own note.
- **Period strip:** horizontal, adapts to the active level (day: always seven weekdays; week: adjacent weeks; month:
  months; year: adjacent years). The selected period is highlighted and Today is distinguished.
- **Anchor date:** one anchor date provides context, so moving from a yearly note back to a daily note preserves
  position. Week/year boundary cases are handled correctly.

### 2. Independent period notes

- One canonical note per day, week, month and year, each with its own content.
- The app opens on today's **logical** daily note.

### 3. Native Markdown editor

- NSTextView-based. Headings, emphasis, bullet/numbered lists, checkboxes, undo/redo, normal macOS selection and IME
  behavior.
- Content stored as portable text.
- **Autosave**: no save button, no loss across navigation, quit or crash.

### 4. Logical day boundary (setting)

- The user sets when a day starts (e.g. 04:00); writing at 02:30 belongs to the previous day.
- Computed in local time. Changing the setting never moves historical notes; midnight does not move an already-open
  note.

### 5. Meeting scratchpad

- A keyboard shortcut opens a **clean window** showing no journal content (safe for screen sharing).
- The draft autosaves and is recoverable after a crash.
- **Done** appends the Markdown to the logical daily note (optional title heading). **Discard** is explicit and safe.
- Bound to the logical day at the moment it was opened.

### 6. Storage

- Local SQLite via GRDB, stable unique IDs, no silent data loss.

## Out of Scope (Deferred)

Templates, Collections, tags, sections, advanced tasks (beyond checkboxes), search, Quick Capture, AI Insights, custom
ranges, undated notes, sync, iOS/Android/web, subscriptions and billing, plugin system.

## Acceptance Criteria

1. App launches to today's logical daily note.
2. All four breadcrumb levels are visible and clickable from any view; each opens its own note.
3. Strip scale changes with level; the daily strip shows seven weekdays.
4. Typed text persists across navigation, quit and force-quit.
5. The Markdown syntax listed above renders/behaves correctly; undo/redo works.
6. With boundary 04:00, a note created at 02:30 lands on the previous date; changing the setting leaves old notes
   unchanged.
7. Scratchpad opens by shortcut with no journal content visible; Done appends to the right daily note; Discard
   appends nothing; a killed app restores the draft.
8. Correct behavior for weeks crossing months/years.

## Build Order

See [MVP-user-stories.md](MVP-user-stories.md): US-1 (basic app) and US-2 (delivery pipeline) form the walking
skeleton; US-3 to US-14 are small, complete, tested features delivered in order.

## Definition of Done

Author uses it as their only daily-notes and meeting-notes tool for one week without data loss or needing to fall back
to another app. Then decide what hurts most and pick the P1 feature (likely templates or search) from the
[PRD](PRD.md).

## Risks

- Crowded market (NotePlan, Capacities, Bear): mitigate by scoping to personal use first.
- NSTextView Markdown behavior (IME, undo with programmatic edits): build the production editor incrementally with
  tests.
- Week/year boundary bugs: cover with date-edge unit tests early.
- Name availability: confirm before any public release.
