# MarkyMarkdown — Agent Instructions

## Project Overview

**MarkyMarkdown** is a native macOS menu bar application that wraps the [MarkItDown](https://github.com/microsoft/markitdown) CLI as a zero-prerequisite drag-and-drop converter. Users drag files onto the menu bar icon or the drop window; the app converts them to Markdown in-place.

- **App name (user-facing):** MarkyMarkdown
- **Swift package name:** MarkitdownUI
- **Bundle ID:** `com.markymarkdown.app`
- **Repo:** `abirismyname/markymarkdown`
- **Minimum macOS:** 13.0 (arm64)
- **Swift version:** 6.0 (strict concurrency)

---

## Repository Layout

```
markitdown-ui/
├── Sources/MarkitdownUI/
│   ├── AppDelegate.swift
│   ├── AppMain.swift
│   ├── Controllers/
│   │   ├── DropWindowController.swift     # NSWindow wrapping DropZoneView
│   │   └── StatusBarController.swift      # Menu bar item + drag overlay
│   ├── Models/
│   │   └── ConversionState.swift          # .idle / .converting / .success / .failure
│   ├── Services/
│   │   └── MarkitdownConversionService.swift  # Process runner for CLI
│   ├── ViewModels/
│   │   ├── AppSettingsStore.swift         # UserDefaults-backed settings
│   │   └── ConversionManager.swift        # Orchestration + milestone tracking
│   ├── Views/
│   │   ├── DropZoneView.swift             # Main drag-drop UI
│   │   └── PreferencesView.swift
│   └── Resources/
│       ├── AppIcon.icns
│       └── markitdown/                    # Bundled PyInstaller CLI (arm64)
├── Tests/MarkitdownUITests/
├── .github/workflows/
│   ├── build.yml    # Triggered on push + PR to main
│   ├── test.yml     # Triggered on push + PR to main
│   └── release.yml  # Triggered on version tags (v*)
├── build-dmg.sh     # End-to-end DMG builder (PyInstaller + Swift release)
├── Package.swift
└── LICENSE          # MIT
```

---

## Build & Test Commands

```bash
# Debug build
swift build --configuration debug

# Release build
swift build --configuration release

# Run tests
swift test --verbose

# Full distributable DMG (requires Python 3.10+, ~10 min first run)
bash build-dmg.sh
```

The DMG lands at `.build/MarkyMarkdown-1.0.0.dmg` (~88 MB).

---

## Key Conventions

### Git Workflow
- **Never push directly to `main`** — branch protection is enabled.
- Always create a feature branch, push, and open a PR.
- Suggested naming: `feat/`, `fix/`, `chore/` prefixes.

```bash
git checkout -b feat/your-feature
# ... make changes ...
git push -u origin feat/your-feature
gh pr create
```

### Swift
- Swift 6 strict concurrency — all shared state must be `@MainActor` or `Sendable`.
- AppKit + SwiftUI mixed — `NSHostingController` bridges SwiftUI views into AppKit windows.
- `LSUIElement = true` in Info.plist — app is menu-bar-only with no Dock icon.

### Output File Naming
- Output is placed in the **same directory** as the source file.
- Naming: `original.pdf` → `original.pdf.md`
- Collision handling: appends ` (1)`, ` (2)`, etc. before `.md`.

### Bundled CLI
- Standalone MarkItDown binary lives at `Sources/MarkitdownUI/Resources/markitdown/`.
- Built with PyInstaller `--onedir` + `--collect-all magika`.
- Auto-detected at runtime via `Bundle.main.resourcePath + "/markitdown/markitdown"`.

### UserDefaults Keys
| Key | Purpose |
|-----|---------|
| `settings.cliPath` | Path to MarkItDown executable |
| `settings.keepDataURIs` | Toggle `--keep-data-uris` flag |
| `com.markitdown.conversionCount` | Persistent milestone counter |

### Joy / UX Features
- 14 randomised celebratory success messages (emoji-rich).
- Milestone achievements at 10 / 50 / 100 conversions.
- Context-aware playful error messages via `playfulErrorMessage(_:)`.
- Fun VoiceOver accessibility descriptions on the menu bar icon.

---

## GitHub Actions

All workflows use `macos-15` runners with `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true`.

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `build.yml` | push + PR → main | Compiles debug + release, verifies binary |
| `test.yml` | push + PR → main | `swift test --verbose` |
| `release.yml` | push tag `v*` | Builds DMG, creates GitHub Release |

To publish a release:
```bash
git tag v1.1.0
git push --tags
```

---

## DMG Build Notes

`build-dmg.sh` detects Python (tries 3.12 → 3.11 → 3.10) and:
1. Creates a venv in `.build/markitdown-standalone/venv`
2. Installs MarkItDown with extras `[docx,pdf,pptx,xlsx]`
3. Runs PyInstaller with `--collect-all magika`
4. Runs `swift build --configuration release`
5. Assembles `.app` bundle with Info.plist + bundled CLI
6. Creates UDZO-compressed DMG with custom volume icon
