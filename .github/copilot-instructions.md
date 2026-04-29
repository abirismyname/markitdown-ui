---
applyTo: "**"
---

# MarkyMarkdown — GitHub Copilot Instructions

## Project Identity

- **App name (user-facing):** MarkyMarkdown
- **Swift package name:** MarkitdownUI
- **Bundle ID:** `com.markymarkdown.app`
- **Repository:** `abirismyname/markymarkdown`
- **Platform:** macOS 13+ · arm64 · Swift 6

Native macOS menu bar application. Converts files to Markdown via a bundled MarkItDown CLI (PyInstaller, zero user prerequisites).

---

## Git Workflow

Branch protection is enabled on `main`. **All changes go through PRs.**

```bash
git checkout -b feat/short-description   # or fix/ or chore/
git push -u origin feat/short-description
gh pr create
```

Never suggest committing directly to `main`.

---

## Build Commands

```bash
swift build --configuration debug     # development
swift build --configuration release   # pre-merge validation
swift test --verbose                  # tests must pass
bash build-dmg.sh                     # distributable DMG (releases only)
```

---

## Code Conventions

### Swift
- **Swift 6 strict concurrency.** All mutable shared state must be `@MainActor` or `Sendable`. Never introduce sendability warnings.
- Mixed AppKit + SwiftUI. SwiftUI views are embedded via `NSHostingController`.
- App runs as `LSUIElement` (menu-bar only, no Dock icon). Do not add `NSApplication.shared.setActivationPolicy(.regular)` calls.

### Output Files
- Written to the **same directory** as input.
- Naming: `input.pdf` → `input.pdf.md`
- Collision suffix: `input.pdf (1).md`, `input.pdf (2).md`, …

### UserDefaults
Use only these established keys — do not invent new ones without updating `AppSettingsStore.swift`:
- `settings.cliPath`
- `settings.keepDataURIs`
- `com.markitdown.conversionCount`

---

## Source Layout

```
Sources/MarkitdownUI/
  Controllers/   — AppKit controllers (StatusBar, DropWindow, Preferences)
  Models/        — ConversionState enum
  Services/      — MarkitdownConversionService (Process runner)
  ViewModels/    — ConversionManager, AppSettingsStore
  Views/         — SwiftUI views (DropZoneView, PreferencesView)
  Resources/     — AppIcon.icns, bundled markitdown/ CLI directory
```

---

## GitHub Actions

All workflows must keep:
- `runs-on: macos-15`
- `env: FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true`
- `actions/checkout@v4`, `actions/cache@v4`
- `softprops/action-gh-release@v2` (release workflow only)

`build.yml` and `test.yml` trigger on both `push` and `pull_request` to `main`.  
`release.yml` triggers on `v*` tags only.

---

## UX Delight — Preserve These

The app has intentional joy features. Do not remove or flatten them:
- `celebrationMessages` array in `DropZoneView.swift` — randomised emoji success messages
- `checkMilestone()` in `ConversionManager.swift` — 10 / 50 / 100 conversion achievements
- `playfulErrorMessage(_:)` in `DropZoneView.swift` — context-aware friendly error text
- VoiceOver descriptions in `StatusBarController.swift` — fun accessibility strings per state

---

## Bundled CLI

Path: `Sources/MarkitdownUI/Resources/markitdown/markitdown`  
Runtime lookup: `Bundle.main.resourcePath + "/markitdown/markitdown"`  
Built by `build-dmg.sh` with PyInstaller `--onedir --collect-all magika`.  
The `_internal/` directory (Python runtime + magika models) must ship alongside the binary.
