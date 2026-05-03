# MarkyMarkdown

A native macOS menu bar application that provides a joyful, delightful interface for converting documents to Markdown using [MarkItDown](https://github.com/microsoft/markitdown).

## System Requirements

- **macOS**: 13.0 or later
- **Architecture**: Apple Silicon (arm64)
- **Dependencies**: None - MarkItDown CLI is bundled with the app

> **Note**: The current build is optimized for Apple Silicon Macs (M1, M2, M3, M4, etc.). No separate Python or MarkItDown installation is required.

## Features

- **🎉 Menu Bar Integration**: Persistent menu bar item with drag-and-drop support
- **✨ Celebratory Messages**: 14 randomized success messages celebrate every conversion
- **🎊 Milestone Tracking**: Special achievements unlocked at 10, 50, and 100 conversions
- **🤔 Playful Error Guidance**: Context-aware, encouraging messages when issues occur
- **💾 Smart File Handling**: Markdown files generated in the same folder with automatic collision handling
- **🔥 Zero Prerequisites**: Bundled MarkItDown CLI with complete Python 3.11 runtime—nothing to install
- **⚙️ Preferences**: Customize CLI path and output options (embed assets as data URLs)
- **📁 File Picker Fallback**: Use "Convert File…" menu option for convenient file selection

## Installation

**📖 For detailed installation instructions, see [INSTALL.md](INSTALL.md)**

### Quick Start (From DMG)

1. Download the latest `MarkyMarkdown-*.dmg` file from [Releases](https://github.com/abirismyname/markymarkdown/releases)
2. Open the DMG file
3. Drag the `MarkyMarkdown` app to the `Applications` folder
4. In **Terminal**, run:
   ```bash
   xattr -rd com.apple.quarantine /Applications/MarkyMarkdown.app
   ```
5. Launch the app from Applications or Spotlight (⌘+Space, type "MarkyMarkdown")

The app will appear as a menu bar item and remain running in the background. No configuration needed!

> **Note**: The quarantine removal step above is only needed for builds signed with an *Apple Development* certificate.

### From Source

```bash
# Clone or navigate to the repository
cd /path/to/markymarkdown

# Build the DMG
./build-dmg.sh

# The DMG will be created at: .build/MarkyMarkdown-1.0.0.dmg
```

## Usage

### Via Drop Window

1. Click the MarkyMarkdown menu bar icon and select "Open Drop Window"
2. Drag a file onto the drop zone
3. The Markdown file will be created next to the original
4. Click "Reveal" to open in Finder

### Via Menu Bar Drag-and-Drop

1. Drag a file directly onto the MarkyMarkdown menu bar icon
2. Conversion happens automatically
3. Status icon updates to show success/failure

### Via File Picker

1. Click the MarkyMarkdown menu bar icon
2. Select "Convert File…"
3. Choose a file to convert
4. Markdown file is created in the same folder

## Preferences

Click the menu bar icon and select "Preferences…" to customize:

- **MarkItDown CLI Path**: Override the bundled CLI with your own (if needed)
- **Embed assets as data URLs (self-contained output)**: When enabled, images/assets remain embedded as `data:` URLs so the output works offline and in a single file. This can significantly increase output size and may be blocked by some security policies.

## Automatic Updates

MarkyMarkdown uses **[Sparkle](https://sparkle-project.org)** to deliver updates automatically so you're always running the latest version.

### How it works

1. On launch (and periodically in the background) the app silently checks the [appcast feed](https://abirismyname.github.io/markymarkdown/appcast.xml) for a newer version.
2. When an update is found a native macOS dialog asks whether to install it now or later.
3. Sparkle downloads the new DMG, verifies its **EdDSA signature**, and relaunches the app—no manual steps required.

You can also trigger a check yourself at any time: click the menu bar icon and choose **"Check for Updates…"**.

Every DMG published in GitHub Releases is signed with a private EdDSA key; the matching public key is embedded in the app bundle (`SUPublicEDKey` in `Info.plist`). If the signature does not verify Sparkle refuses to install the update, protecting you from tampered downloads.

### Sparkle Update Keys (for maintainers)

Before publishing a release that delivers updates you must generate a key pair once and configure it in CI.

**1. Generate the key pair**

```bash
# Build the app once so Sparkle's CLI tools are extracted into .build/artifacts/
swift build --configuration release

# Locate Sparkle's generate_keys tool
SPARKLE_BIN=$(find .build/artifacts -name "generate_keys" 2>/dev/null | head -1)

# Generate a new Ed25519 key pair; the tool prints the public key and stores
# the private key in macOS Keychain under the account "ed25519".
"${SPARKLE_BIN}"
```

The tool prints a line like:

```
Public Key (SUPublicEDKey):  <base64-encoded public key>
```

**2. Add the public key to Info.plist**

Set the `SPARKLE_PUBLIC_ED_KEY` environment variable (or repository secret) to the base64 public key printed above. The `build-dmg.sh` script reads this variable and writes it into `Info.plist` at build time:

```bash
export SPARKLE_PUBLIC_ED_KEY="<your base64 public key>"
./build-dmg.sh
```

In GitHub Actions add it as a repository secret named `SPARKLE_PUBLIC_ED_KEY`.

**3. Store the private key for CI**

Export the private key from Keychain and store it as the `SPARKLE_ED_PRIVATE_KEY` secret:

```bash
# Find the Sparkle sign_update tool
SPARKLE_BIN=$(find .build/artifacts -name "sign_update" 2>/dev/null | head -1)

# Export the private key (reads from Keychain, prints base64 to stdout)
"${SPARKLE_BIN}" --export-private-key
```

Add the printed value as a repository secret named `SPARKLE_ED_PRIVATE_KEY`.

**4. Required CI secrets summary**

| Secret | Purpose |
|---|---|
| `SPARKLE_PUBLIC_ED_KEY` | Embedded in `Info.plist`; verifies update signatures at runtime |
| `SPARKLE_ED_PRIVATE_KEY` | Signs the DMG; used by the `update-appcast` workflow job |

Once both secrets are set, every `v*` tag push will build the DMG, sign it, update `docs/appcast.xml`, and push the updated feed automatically.

### Releasing a new version

> **TL;DR:** push a version tag. Everything else is automatic.

```bash
git tag v1.2.0
git push --tags
```

That single command triggers three sequential CI jobs in `release.yml`:

| CI job | What it does |
|---|---|
| `build-and-notarize` | Builds the signed + notarized DMG |
| `create-release` | Creates a GitHub Release and attaches the DMG |
| `update-appcast` | Signs the DMG with the EdDSA key, appends a new entry to `docs/appcast.xml`, commits & pushes it to `main` |

**Sparkle does not poll the GitHub Releases page.** It fetches the [appcast feed](https://abirismyname.github.io/markymarkdown/appcast.xml) — an RSS-style XML file hosted via GitHub Pages. The appcast entry contains the DMG download URL (which does point at the GitHub Release asset), the new version number, the byte size, and an EdDSA signature. When users' copies of MarkyMarkdown next check for updates (on launch or via "Check for Updates…"), they read this feed, compare the version, and Sparkle handles downloading, verifying, and installing the update automatically.

If `SPARKLE_ED_PRIVATE_KEY` is not configured the `update-appcast` job skips with a warning and no update will be delivered to existing users even though the GitHub Release exists. Set the secret before tagging if you want in-app updates.

## Milestone Celebrations

Every conversion counts! Unlock special achievements:

- **10 conversions**: 🎊 "10 files converted! You're on fire! 🔥"
- **50 conversions**: 🏆 "50 conversions! You're a Markdown master! 👑"
- **100 conversions**: 👏 "100 files! You deserve a medal! 🥇"

Your conversion count persists across sessions—keep converting to unlock achievements!

## Supported File Formats

MarkItDown supports converting the following file formats to Markdown:

- PDF
- DOCX (Word)
- PPTX (PowerPoint)
- HTML
- Images (JPG, PNG, GIF)
- And more

For the full list of supported formats, see [MarkItDown documentation](https://github.com/microsoft/markitdown).

## Project Structure

```
markymarkdown/
├── Sources/MarkitdownUI/
│   ├── AppMain.swift                    # App entry point
│   ├── AppDelegate.swift                # Application lifecycle
│   ├── Controllers/
│   │   ├── DropWindowController.swift   # Main window controller
│   │   ├── PreferencesWindowController.swift
│   │   └── StatusBarController.swift    # Menu bar integration
│   ├── Models/
│   │   ├── AppSettingsStore.swift       # Preferences persistence
│   │   └── ConversionState.swift        # UI state management
│   ├── Services/
│   │   └── MarkitdownConversionService.swift  # CLI invocation
│   ├── ViewModels/
│   │   └── ConversionManager.swift      # Conversion workflow
│   ├── Views/
│   │   ├── DropZoneView.swift           # Main drop UI
│   │   └── PreferencesView.swift        # Settings UI
│   └── Resources/
│       └── markitdown                   # Bundled CLI binary
├── Package.swift                        # Swift Package manifest
├── build-dmg.sh                         # DMG creation script
└── README.md                            # This file
```

## Building & Development

### Development Build

```bash
# Build the Swift package
swift build

# Run from source
swift run MarkitdownUI
```

### Testing

```bash
# Run the test suite
swift test
```

### Release Build (DMG)

```bash
# Create a distributable DMG (includes bundled CLI)
./build-dmg.sh

# Output will be at: .build/MarkyMarkdown-1.0.0.dmg
```

## Continuous Integration

This repository uses GitHub Actions for automated building, testing, and releasing:

- **Build Workflow** (`.github/workflows/build.yml`): Compiles the app on every push to main
- **Test Workflow** (`.github/workflows/test.yml`): Runs Swift tests on every PR
- **Release Workflow** (`.github/workflows/release.yml`): Creates releases and uploads DMG when version tags are pushed; imports a signing certificate and optionally notarizes the DMG

All workflows run on macOS 15 with Apple Silicon support.

## Code Signing & Notarization

The release workflow supports signing and notarizing the DMG automatically. Both steps are optional—if the required secrets are absent the workflow skips them gracefully and still produces an unsigned DMG.

### Required secrets (code signing)

Add these in **GitHub → Settings → Secrets and variables → Actions**:

| Secret | Description |
|---|---|
| `MACOS_CERTIFICATE` | Base64-encoded `.p12` certificate + private key exported from Keychain Access |
| `MACOS_CERTIFICATE_PWD` | Password you set when exporting the `.p12` |
| `MACOS_KEYCHAIN_PWD` | Any strong random string—used only for the ephemeral CI keychain |
| `SIGNING_IDENTITY` | Full identity string, e.g. `Apple Development: Abir Majumdar (B4994FKL79)` |

To create `MACOS_CERTIFICATE`:

1. Open **Keychain Access** → My Certificates
2. Right-click your Apple Development certificate → **Export** → `.p12` format
3. Base64-encode the file:
   ```bash
   base64 -i ~/path/to/cert.p12 | pbcopy   # copies to clipboard
   ```
4. Paste the result as the `MACOS_CERTIFICATE` secret value

### How signing works in CI

When a `v*` tag is pushed, `release.yml`:

1. **Import signing certificate** — decodes `MACOS_CERTIFICATE` into a short-lived keychain, imports the certificate, and configures `codesign` to access the private key without a UI prompt
2. **Build DMG** — runs `build-dmg.sh` with `SIGNING_IDENTITY` injected; the script signs the `.app` bundle and the final `.dmg`
3. **Notarize DMG** — submits the signed DMG to Apple's notary service (see below)

The ephemeral keychain is created fresh every run and is discarded when the runner terminates.

### Optional secrets (notarization)

Notarization removes the Gatekeeper warning that appears when users open the app on a new Mac. It requires a **Developer ID Application** certificate (paid Apple Developer Program membership).

| Secret | Description |
|---|---|
| `NOTARIZATION_APPLE_ID` | Your Apple ID email address |
| `NOTARIZATION_TEAM_ID` | Your 10-character Apple Developer Team ID, e.g. `B4994FKL79` |
| `NOTARIZATION_PWD` | App-specific password generated at [appleid.apple.com](https://appleid.apple.com) → Sign-In and Security → App-Specific Passwords |

When all three secrets are present, the workflow uses `xcrun notarytool` to submit the DMG and `xcrun stapler` to attach the notarization ticket before uploading the release asset.

> **Note:** If only an *Apple Development* certificate is available (not *Developer ID Application*), users who download the DMG still need to remove the quarantine attribute manually—see the Installation step above.

## Architecture

The app uses a clean MVVM architecture:

- **AppDelegate**: Manages app lifecycle, window controllers, and state
- **ConversionManager**: Orchestrates file conversion workflow
- **MarkitdownConversionService**: Handles CLI invocation and output path generation
- **AppSettingsStore**: Manages persistent user preferences
- **StatusBarController**: Manages menu bar item and drag-and-drop
- **DropZoneView**: Main UI for drag-and-drop and status feedback
- **PreferencesView**: Settings UI for CLI path and options

## Requirements

- macOS 13.0 or later
- No external dependencies (MarkItDown CLI is bundled)

## License

MarkyMarkdown is released under the [MIT License](LICENSE).

This app bundles [MarkItDown](https://github.com/microsoft/markitdown) by Microsoft Corporation, also released under the MIT License. See [ACKNOWLEDGEMENTS.md](ACKNOWLEDGEMENTS.md) for the full copyright notice.

## Troubleshooting

### App Won't Launch

- Ensure the app is in your Applications folder
- Try moving it to Applications: `mv ~/Downloads/MarkItDown.app /Applications/`
- Check System Preferences > Security & Privacy if prompted

### Files Not Converting

1. Open Preferences (⌘+, in menu bar menu)
2. Verify "CLI path is valid" shows in green
3. If bundled version shows, try a test file
4. If custom path is set, verify the CLI binary exists and is executable

### Permission Denied on First Use

macOS may prompt for permission the first time the app runs. Grant "Open" permission if prompted.

## Support

For issues with MarkItDown CLI itself, see [MarkItDown GitHub](https://github.com/microsoft/markitdown).

For issues with this UI, check the app's preferences and verify the MarkItDown CLI path is valid.

---

**Version**: 1.1.1  
**Built**: Swift 5.9+ with SwiftUI and AppKit  
**Target**: macOS 13.0+
