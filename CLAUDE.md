# MarkyMarkdown — Claude Instructions

> Read by Claude Code when working in this repository.

## Project at a Glance

Native macOS menu bar app (Swift 6 / AppKit+SwiftUI) that converts files to Markdown via a bundled MarkItDown CLI. Zero prerequisites for end users — the Python runtime is bundled via PyInstaller.

- **User-facing name:** MarkyMarkdown
- **Swift package name:** MarkitdownUI  
- **Bundle ID:** `com.markymarkdown.app`
- **Repo:** `abirismyname/markymarkdown`
- **Platform:** macOS 13+ · arm64

---

## Non-Negotiable Workflow Rules

1. **Never commit directly to `main`.** Branch protection is enabled.
2. Create a branch → commit → push → `gh pr create`.
3. Branch naming: `feat/`, `fix/`, `chore/` prefixes.

```bash
git checkout -b feat/short-description
# work...
git push -u origin feat/short-description
gh pr create --title "..." --body "..."
```

---

## Build & Test

```bash
swift build --configuration debug    # fast iteration
swift build --configuration release  # before PRs touching core logic
swift test --verbose                 # must pass before merging
bash build-dmg.sh                    # full DMG (slow, only for releases)
```

---

## Architecture Rules

- **Swift 6 strict concurrency** — never introduce data races. UI updates and shared state require `@MainActor`.
- **AppKit-first** — the app is `LSUIElement` (menu-bar only). Don't add Dock presence.
- **SwiftUI views** are hosted via `NSHostingController` inside AppKit windows.
- **No new dependencies** without discussion — the bundled CLI is intentionally self-contained.

---

## File Output Convention

`original.pdf` → `original.pdf.md` (same directory).  
Collisions → `original.pdf (1).md`, `original.pdf (2).md`, …

---

## UserDefaults Keys

| Key | Type | Purpose |
|-----|------|---------|
| `settings.cliPath` | String | Path to MarkItDown executable |
| `settings.keepDataURIs` | Bool | Passes `--keep-data-uris` to CLI |
| `settings.colorScheme` | String | UI color scheme (`auto`/`light`/`dark`) |
| `com.markitdown.conversionCount` | Int | Milestone celebration counter |

---

## GitHub Actions

All three workflows (`build`, `test`, `release`) use:
- Runner: `macos-15`
- `actions/checkout@v5`, `actions/cache@v5`, `softprops/action-gh-release@v2`

Do **not** downgrade action versions.

---

## UX / Joy Conventions

The app has intentional delight features — maintain them:
- Randomised celebration messages on success (`celebrationMessages` array in `DropZoneView.swift`)
- Milestone alerts at 10 / 50 / 100 conversions (`checkMilestone()` in `ConversionManager.swift`)
- Playful, context-aware error messages (`playfulErrorMessage(_:)` in `DropZoneView.swift`)
- Fun VoiceOver descriptions on menu bar icon state changes (`StatusBarController.swift`)

---

## Bundled CLI

The MarkItDown binary lives at `Sources/MarkitdownUI/Resources/markitdown/`.  
At runtime: `Bundle.main.resourcePath + "/markitdown/markitdown"`.  
Built via `build-dmg.sh` using PyInstaller `--onedir --collect-all magika`.  
Do **not** replace with a wrapper script — the full `_internal/` Python runtime must be present.

---

## Releasing

```bash
git tag v1.x.0
git push --tags   # triggers release.yml → builds DMG → creates GitHub Release
```
