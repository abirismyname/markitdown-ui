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
- **⚙️ Preferences**: Customize CLI path and output options (keep data URIs)
- **📁 File Picker Fallback**: Use "Convert File…" menu option for convenient file selection

## Installation

### From DMG (Recommended)

1. Download the latest `MarkyMarkdown-*.dmg` file from [Releases](https://github.com/abirismyname/markitdown-ui/releases)
2. Open the DMG file
3. Drag the `MarkyMarkdown` app to the `Applications` folder
4. Eject the DMG
5. Launch the app from Applications or Spotlight (⌘+Space, type "MarkyMarkdown")

The app will appear as a menu bar item and remain running in the background. No configuration needed!

### From Source

```bash
# Clone or navigate to the repository
cd /path/to/markitdown-ui

# Build the DMG
./build-dmg.sh

# The DMG will be created at: .build/MarkItDown-1.0.0.dmg
```

## Usage

### Via Drop Window

1. Click the MarkItDown menu bar icon and select "Open Drop Window"
2. Drag a file onto the drop zone
3. The Markdown file will be created next to the original
4. Click "Reveal" to open in Finder

### Via Menu Bar Drag-and-Drop

1. Drag a file directly onto the MarkItDown menu bar icon
2. Conversion happens automatically
3. Status icon updates to show success/failure

### Via File Picker

1. Click the MarkItDown menu bar icon
2. Select "Convert File…"
3. Choose a file to convert
4. Markdown file is created in the same folder

## Preferences

Click the menu bar icon and select "Preferences…" to customize:

- **MarkItDown CLI Path**: Override the bundled CLI with your own (if needed)
- **Keep Data URIs**: Preserve embedded images in output (rather than stripping them)

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
markitdown-ui/
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
- **Release Workflow** (`.github/workflows/release.yml`): Creates releases and uploads DMG when version tags are pushed

All workflows run on macOS 14+ with Apple Silicon support.

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

This project is provided as-is. See individual component licenses for more information.

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

**Version**: 1.0.0  
**Built**: Swift 5.9+ with SwiftUI and AppKit  
**Target**: macOS 13.0+
