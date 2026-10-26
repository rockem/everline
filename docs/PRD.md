# Everline — Product Requirements Document (High Level)

Status: Draft v0.1
Working name: Everline (formerly "Daybook", which is taken; availability still needs trademark/App Store review)
Source: ChatGPT conversation archive (`everline_conversation_archive.pdf`)

## 1. Summary

Everline is a **native macOS, date-first notebook**. Every note belongs to a period of time (day, week, month, year,
and later custom ranges). Users write in an uncluttered editor and move through time with a persistent breadcrumb and
a horizontal period strip. Over time it grows into a programmable system: user-defined templates, indexed Collections
for recurring subjects (e.g. a 1:1 history), native tasks, search, and source-linked Insights.

## 2. Problem and Positioning

People who work in daily notes and meetings want a fast, calm place to write that is organised by *when* things
happened, without the overhead of an object database or a task manager.

- Closest competitor: **NotePlan** (time-first). Others: Capacities (object-first), Tana, Logseq, Reflect, Bear.
- Everline should **not** try to out-feature them. Differentiators:
  1. Truly native Mac feel (SwiftUI + AppKit/TextKit); the reason Tauri and Flutter were rejected.
  2. Persistent Year/Month/Week/Day breadcrumb with an independent note per period.
  3. A private meeting scratchpad that merges into the daily note (safe for screen sharing).
  4. Configurable "logical day" boundary (writing at 02:30 still belongs to yesterday).
  5. Later: user-defined inline notation (templates), section-level Collections, source-linked Insights.
- Honest framing: first a useful personal Mac notebook, then a possible product. Validate by testing real workflows
  against NotePlan and Capacities.

## 3. Target User

Knowledge workers and developers on Mac who keep daily notes, run many meetings and recurring 1:1s, and want
keyboard-driven, minimal-overhead writing. The first user is the author.

## 4. Product Principles

1. **Date-first.** Time is the primary organising axis; undated notes are secondary.
2. **Native and fast.** Must feel like a Mac app; editor quality comes before breadth.
3. **Editor-first, minimal chrome.** Navigation supports writing, never dominates it.
4. **User-defined, not hard-coded.** "Meeting", "decision", etc. are templates, not built-in block types. Tasks are
   the one deliberate built-in exception.
5. **Local-first, no silent data loss.** Reliable autosave and recovery; portable content format.
6. **Stay small.** Not a full task manager, not a knowledge graph.

## 5. Feature Areas

### MVP

- **Time navigation:** always-visible Year / Month / Week / Day breadcrumb, each segment clickable. The horizontal
  strip adapts to the level: seven weekdays (day), adjacent weeks, months, years. One anchor date preserves context.
- **Period notes:** one independent canonical note per day, week, month and year. Opens on today's logical day.
- **Editor:** native NSTextView editor, basic Markdown (headings, emphasis, lists, checkboxes), undo/redo, IME
  support, autosave.
- **Logical day:** user-set start-of-day (e.g. 04:00); historical notes never move when it changes.
- **Meeting scratchpad:** a shortcut opens a clean window with no journal content visible. The draft autosaves;
  **Done** appends to the logical daily note (optional title heading); **Discard** is explicit.

### P1

- **Templates:** user-configurable trigger rules (e.g. `/=` gives a bold meeting line plus a `#meeting` tag).
  Definitions are separate from instances; editing a template does not rewrite history.
- **Sections and tags:** stable section IDs, block metadata, tags.
- **Search:** full text, plus tag and date filters.
- **Quick Capture:** a global shortcut opens a popup that appends a line to today's note (Enter submits,
  Shift+Enter inserts a newline, Esc dismisses).

### P2

- **Collections:** index complete sections across dates without duplication (e.g. "1:1 – Alex": latest entry, full
  history).
- **Tasks:** built-in capability with stable identity, completion state and optional dates, created by templates;
  lightweight aggregation.
- **Custom ranges:** named, overlapping date-range notes in a Ranges view; surfaced when overlapping the selected day.
- **Undated notes:** reference notes using the same editor, search and templates; may join Collections.

### Later

- **Insights (AI):** extract action items, decisions, mood, progress, blockers, people and open loops. Insights are
  source-linked, reviewable and distinct from facts, and aggregate by period. Explicit templates take precedence over
  inference.
- **Sync, iOS, Android, Web:** sync API and portable document schema designed early; implemented later.

## 6. Technical Approach

- **macOS:** SwiftUI shell, AppKit NSTextView/TextKit editor, Swift domain logic.
- **Storage:** local SQLite via GRDB; stable unique IDs; portable text content for now.
- **Future platforms:** SwiftUI/UIKit for iOS; Expo/React Native for Android and React Native Web for browser; shared
  document contracts and a later sync API. UI code is not shared with Apple platforms.
- **Editor strategy:** no throwaway spike; build the production NSTextView editor incrementally.
- **Development process:** spec-driven with Claude Code: concise `CLAUDE.md`, versioned PRD, short architecture
  decisions, small feature specs, vertical slices, deterministic tests, human review.

## 7. Business Model

Open core: a public, genuinely usable basic Swift core; a private official commercial app built on it, published as
**one app** with free features and a Pro subscription unlocking premium capabilities. No third-party plugin platform
(and App Store code-loading limits make downloadable plugins impractical). Candidate premium features: templates,
Collections, tasks, AI Insights, sync. License choice (Apache 2.0 vs MPL 2.0) and the free/paid split are open.

## 8. Privacy and Data

Local by default. Data exportable in a portable format. Any AI processing must be opt-in and transparent about what
leaves the device (to be specified before Insights).

## 9. Success Criteria

- Author replaces their current daily-notes tool with Everline for daily work and meetings.
- No data loss across crashes, restarts and navigation.
- Navigation across year/month/week/day feels instant and never loses context.
- Later: a user can find the last 1:1 with a person in seconds.

## 10. Open Questions

1. Final name and availability (Everline vs alternatives; trademark, App Store, domain).
2. Week definition: week start day, and weeks that cross month/year boundaries.
3. Exact free vs Pro feature split and pricing.
4. Open-source license and what lives in the public core.
5. Portable content format beyond plain Markdown text (needed for templates, sections, Collections).
6. Whether undated notes and custom ranges belong in P2 or earlier.
7. Differentiation validation against NotePlan and Capacities.
