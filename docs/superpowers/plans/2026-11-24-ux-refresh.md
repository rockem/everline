# UX Refresh: Strip Look, Date Heading and Note Typography

Issue #21. Mockups (light and dark) are attached to the issue. Scope agreed: restyle the existing week strip, add a date
heading above the note, restyle the note text, add an empty-page placeholder, follow the system
appearance. Out of scope for now: the `?` button, the breadcrumb, markdown styling in the editor, a Today button, a
theme toggle.

**Goal:** the app looks like the mockups in light and dark, in Manrope (UI) and IBM Plex Mono (notes), and follows
Apple's guidelines where the mockups are silent: Dynamic Type, contrast, 44 pt targets.

## Concept

View-level changes only, no model or storage changes. The strip gets the mockup's sizes, shapes and colors, and keeps
"selected" and "today" as two independent cues. A new page header sits above the editor: the selected day as a large
title ("November 26"). Header and editor
share a centered, readable column. The editor gets the note typography and shows a placeholder while the page is empty.

## Design

- **Fonts are bundled and registered in code.** Manrope (one variable font, used at Regular, Medium and SemiBold) for
  the UI and IBM Plex Mono Regular for notes, both SIL Open Font License, with their license texts kept next to the
  files in `everline/Fonts/`. A small `Fonts` type registers them at launch with Core Text, the same call on macOS and
  iOS, so no Info.plist keys are needed. If a font is missing the system font is used, so the app never breaks; a test
  pins that they load.
- **Theme tokens.** `Theme` gets the mockup palette as light/dark pairs (sampled from the mockups): background
  `FBFAF8`/`191816`, divider `EFEEEC`/`292524`, selected pill `F5EDE8`/`342721`, secondary text (weekday labels, day
  numbers) `77716C`/`A5A09C`, selected text `9E563C`/`E4A78D`, today text `292524`/`F5F5F5`, note dot
  `AE6447`/`D89679`, title `292524`/`F5F5F5`, placeholder `D6D3D1`/`57534F` (checked against contrast below). The old
  dark pill and `onPill` go away.
- **Strip.** Selected day: tinted pill (about 135 x 72 pt, corner radius about 12 pt, a faint outline in dark) with the
  selected text color on the weekday label and the number. Today: "TODAY" label and a bolder number in the today color,
  whether or not it is selected. Any day whose note has text gets a small accent dot under it (the model answers
  `hasNote(on:)`; VoiceOver hears "has a note"). Other days: secondary text. Identifiers stay (`day-YYYY-MM-DD`,
  `previous-week`, `next-week`).
- **UI fonts follow Dynamic Type.** Sizes are scaled metrics relative to text styles (label about 11 pt, number about
  20 pt semibold, title about 44 pt medium with tight tracking), never fixed. Rows grow with the text size, and arrows
  and days keep at least a 44 pt hit area.
- **Page header.** A `PageHeader` view takes the selected day and the calendar. The title is the day formatted as month
  and day for the user's locale (no caption: the word count and "New page" label were dropped). The header belongs to
  the screen, not the text view, so the model stays free of it.
- **No title bar (macOS).** The window uses the hidden title bar style; the strip is pushed down by a 28 pt band so the
  window buttons never overlap it, and the content ignores the top safe area. iOS is unaffected.
- **Column.** Header and editor share one centered column of about 680 pt maximum width.
- **Note typography.** IBM Plex Mono Regular (400), 16 pt, line height 1.8 (a fixed line height of 1.8 x the size, with
  the text kept visually centered in the line), letter spacing -0.01 em. One `NoteTypography` value holds these numbers
  and both text views (`NSTextView`, `UITextView`) apply it to the text, the typing attributes and the insertion point,
  so new text and loaded text look the same. On iOS the size scales with Dynamic Type (relative to body); macOS has
  none. The 600 weight for bold lines is recorded for the markdown story, not bundled now.
- **Placeholder.** "Write what happened, what mattered, or simply how the day felt..." in the placeholder color, shown
  while the page is empty and gone on the first character. It is drawn by the text view itself (macOS) or a label inside
  it (iOS), so it lines up exactly with the real text and its line height. It is also the editor's accessibility
  placeholder, so VoiceOver reads it.

## Data flow

Nothing new. `ContentView` already observes the model; the header reads `model.selected`, `model.calendar` and
`model.text`, so it updates on typing and on day changes like the strip does. The editor still talks only through its
`text` binding.

## Work order

1. Fonts (files, licenses, registration) and `Theme` tokens.
2. Strip restyle (selected versus today, shapes, scaled sizes, targets).
3. `PageHeader`, with the centered column in `ContentView`.
4. `NoteTypography` applied in both text views.
5. Placeholder in both text views.
6. `CLAUDE.md` and `docs/ARCHITECTURE.md` (views section), license notice.

## Testing

- **Unit:** the fonts load by name.
- **Component (ViewInspector):** the strip shows a dot for days with notes (including the selected day as it gets text);
  the header shows the day title and follows the selected day.
- **Component (hosted `NoteEditor`, macOS):** the text view's font, line height and kerning match `NoteTypography`,
  also for text typed after the page was empty; the placeholder value is exposed while empty and not afterwards.
- **Existing tests:** e2e and component tests keep working through the unchanged accessibility identifiers.
- **By eye:** light and dark, the smallest and a large Dynamic Type size, the 44 pt targets, and the placeholder
  alignment on both platforms (iOS has no automated tests).

## Risks

- Contrast: sampled from the mockups, the placeholder pairs are well under 3:1; the placeholder is darkened or lightened
  to about 3:1 as a compromise, since placeholder text is meant to be faint.
- A fixed 1.8 line height puts the glyphs at the bottom of the line and makes the caret as tall as the whole line. The
  text is centered with `baselineOffset` and the caret cut down to the font height (tested on macOS); the iOS
  equivalent is unverified by eye, and selection rectangles still span the full line.
- Bundled fonts add size and a license obligation (OFL: keep the notice, don't sell the fonts alone).
- A fixed-width column puts the scroll bar at the column edge, not the window edge; revisit with text insets if it
  looks wrong.
