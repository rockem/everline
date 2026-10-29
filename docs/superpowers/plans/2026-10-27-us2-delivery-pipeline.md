# US-2 Delivery Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Lint, build, test, CI and a tag-driven GitHub Release in place around the US-1 app.

**Architecture:** Shell scripts in `scripts/` are the single entry point for build, test, lint and package; local
runs and GitHub Actions call the same scripts. CI and release are two workflows over those scripts.

**Tech Stack:** xcodebuild, SwiftLint, markdownlint-cli2, GitHub Actions, GitHub Releases.

**Spec:** GitHub issue [#2](https://github.com/rockem/everline/issues/2) (US-2) and `docs/MVP-user-stories.md`.
Depends on the US-1 plan, `2026-10-27-us1-basic-app.md`: it consumes `Everline.app` and the UI tests.

## Global Constraints

- Distribution: GitHub Releases only; ad-hoc signed builds; no notarization, no App Store.
- Versioning: semver from git tags `vMAJOR.MINOR.PATCH`; first release `0.0.1`; build number is the CI run number.
- Compiler warnings are errors in Debug and Release builds.
- Markdown files wrap at 120 columns and pass `.markdownlint.json`.
- Local runs and CI use the same scripts, never duplicated command lines.

## Review Focus

- A failing test or lint violation: the scripts must exit non-zero so CI goes red. Owned by Tasks 1 and 2.
- A tag with a malformed version (`v1.2`, `vfoo`): the release workflow must not publish. Owned by Task 4.
- Scripts run from a different working directory: they must still work. Owned by Task 1.
- UI tests on a CI runner without Accessibility permission: must fail loudly, not hang. Owned by Task 3.
- Release re-run for an existing tag: must fail clearly, not overwrite the published asset. Owned by Task 4.

---

## File Structure

- `scripts/build.sh`, `scripts/test.sh`, `scripts/lint.sh`, `scripts/package.sh`: build, test, lint, package.
- `.swiftlint.yml`: lint config.
- `.github/workflows/ci.yml`, `.github/workflows/release.yml`: CI and release.

## Task 1: One-command build and test

**Files:**

- Create: `scripts/build.sh`, `scripts/test.sh`

**Interfaces:**

- Produces: `scripts/build.sh [Debug|Release]` and `scripts/test.sh`, both exiting non-zero on failure, both
  runnable from any directory. CI (Task 3) calls these.

- [ ] **Step 1: Write the failing check**

  Run `scripts/test.sh`. Expected: "No such file or directory".

- [ ] **Step 2: Implement the scripts**

  `#!/usr/bin/env bash` with `set -euo pipefail`, `cd` to the repo root, then `xcodebuild` on
  `everline.xcodeproj`, scheme `everline`, destination `platform=macOS`. `build.sh` takes the configuration
  (default Debug) and passes `SWIFT_TREAT_WARNINGS_AS_ERRORS=YES GCC_TREAT_WARNINGS_AS_ERRORS=YES`. `test.sh` runs
  `xcodebuild test` with the same warning flags. Both `chmod +x`.

- [ ] **Step 3: Verify success path**

  Run: `scripts/build.sh Debug && scripts/build.sh Release && scripts/test.sh; echo $?`
  Expected: `0`.

- [ ] **Step 4: Verify failure path**

  Temporarily change an assertion in `testTypingShowsTextInNote` to a wrong value and run `scripts/test.sh; echo $?`.
  Expected: non-zero. Revert the change.

- [ ] **Step 5: Commit**

  ```bash
  git add scripts && git commit -m "build: add build and test scripts"
  ```

## Task 2: Lint code and docs

**Files:**

- Create: `.swiftlint.yml`, `scripts/lint.sh`

**Interfaces:**

- Consumes: `.markdownlint.json` (exists).
- Produces: `scripts/lint.sh`, exiting non-zero on any SwiftLint or markdownlint violation.

- [ ] **Step 1: Install SwiftLint**

  Run: `brew install swiftlint`. Expected: `swiftlint version` prints a version.

- [ ] **Step 2: Write `.swiftlint.yml`**

  Included paths `everline` and `everlineUITests`; keep default rules, `line_length: 120` to match the markdown
  limit. No custom rules yet.

- [ ] **Step 3: Write the failing check**

  Run `scripts/lint.sh`. Expected: "No such file or directory".

- [ ] **Step 4: Implement `scripts/lint.sh`**

  Same bash preamble as Task 1. Runs `swiftlint --strict`, then `npx --yes markdownlint-cli2@0.24.0 "**/*.md"
  "#node_modules"`. With `set -e`, either failing fails the script.

- [ ] **Step 5: Verify both paths**

  Expected: `scripts/lint.sh` exits 0 on the current tree. Then add `var x = 1;` (trailing semicolon, unused) to
  `NoteEditor.swift`: expect non-zero; revert. Add a 130-character line to `docs/MVP.md`: expect non-zero; revert.
  Fix any violations SwiftLint finds in the US-1 code.

- [ ] **Step 6: Commit**

  ```bash
  git add .swiftlint.yml scripts/lint.sh && git commit -m "build: add swiftlint and lint script"
  ```

## Task 3: CI workflow

**Files:**

- Create: `.github/workflows/ci.yml`

**Interfaces:**

- Consumes: `scripts/lint.sh`, `scripts/build.sh`, `scripts/test.sh`.

- [ ] **Step 1: Write `ci.yml`**

  Triggers: `push` to `main` and `pull_request`. One job on a macOS runner whose Xcode version supports the
  project's `objectVersion = 90` (check which `macos-*` image ships a matching Xcode; select it explicitly with
  `sudo xcode-select`). Steps: checkout, `brew install swiftlint`, `scripts/lint.sh`, `scripts/build.sh Debug`,
  `scripts/build.sh Release`, `scripts/test.sh`.

- [ ] **Step 2: Push the branch and open a pull request**

  Expected: the check runs. UI tests on a runner may need Accessibility permission; if the e2e tests fail only in CI
  with an automation-permission error, fix it in the workflow (grant via TCC database before the test step) and
  record the fix in a comment in `ci.yml`.

- [ ] **Step 3: Verify red path**

  Push a commit with a deliberately failing assertion; expected: the check goes red. Revert and confirm green.

- [ ] **Step 4: Commit**

  ```bash
  git add .github && git commit -m "ci: lint, build and test on every push and pull request"
  ```

## Task 4: Tag-driven release

**Files:**

- Create: `scripts/package.sh`, `.github/workflows/release.yml`

**Interfaces:**

- Produces: `scripts/package.sh <version> <build>` creating `dist/Everline-<version>.zip` containing `Everline.app`.

- [ ] **Step 1: Write the failing check**

  Run `scripts/package.sh 0.0.1 1`. Expected: "No such file or directory".

- [ ] **Step 2: Implement `scripts/package.sh`**

  Same preamble. Validates `<version>` against `^[0-9]+\.[0-9]+\.[0-9]+$` (exit 1 otherwise). Runs Release
  `xcodebuild` with `MARKETING_VERSION=<version>`, `CURRENT_PROJECT_VERSION=<build>`, `CODE_SIGN_IDENTITY=-`,
  `CODE_SIGNING_REQUIRED=NO`, a local `-derivedDataPath build`, then
  `ditto -c -k --keepParent <app> dist/Everline-<version>.zip`.

- [ ] **Step 3: Verify locally**

  Run: `scripts/package.sh 0.0.1 99 && unzip -p dist/Everline-0.0.1.zip 'Everline.app/Contents/Info.plist' | plutil
  -p - | grep -E 'ShortVersion|BundleVersion'`
  Expected: `0.0.1` and `99`. Also run `scripts/package.sh 1.2 1`: expect non-zero.

- [ ] **Step 4: Implement `release.yml`**

  Trigger: push of tags matching `v[0-9]+.[0-9]+.[0-9]+`. Job: same runner and Xcode selection as `ci.yml`, run
  lint, build and test first, then `scripts/package.sh "${GITHUB_REF_NAME#v}" "$GITHUB_RUN_NUMBER"`, then
  `gh release create "$GITHUB_REF_NAME" dist/*.zip --generate-notes` with a note that the build is unsigned.
  Needs `permissions: contents: write`. Malformed tags such as `v1.2` do not match the filter, so no release is made.

- [ ] **Step 5: Publish `v0.0.1`**

  After the pull request merges, tag `main` with `v0.0.1` and push the tag (outward-facing, so confirm with the
  user first). Expected: release workflow green; the GitHub Release has `Everline-0.0.1.zip`; downloading and
  opening the app shows the editable note.

- [ ] **Step 6: Commit**

  ```bash
  git add scripts/package.sh .github && git commit -m "ci: publish GitHub Release on version tag"
  ```
