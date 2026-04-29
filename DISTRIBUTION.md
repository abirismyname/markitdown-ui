# Distribution Guide

This guide explains how to distribute the MarkItDown app to users.

## For End Users

### Installation

1. **Download the DMG**: Get the latest `MarkItDown-*.dmg` file
2. **Open the DMG**: Double-click to mount
3. **Install the App**: Drag `MarkItDown` to the `Applications` folder
4. **Eject the DMG**: Right-click the mounted volume and select "Eject"
5. **Launch the App**: 
   - Open Applications folder and click MarkItDown, OR
   - Use Spotlight search (⌘+Space) and type "MarkItDown"

### First Launch

- The app appears as a document icon in the menu bar (top-right)
- A drop window will open automatically
- The app will remain running in the background
- To see the menu, click the menu bar icon

### Getting Help

- Use the "Preferences…" option (⌘+,) to verify the MarkItDown CLI is found
- Try the "Convert File…" option if drag-and-drop doesn't work
- All file conversions output to the same folder as the source file with `.md` extension

## For Developers / Distributors

### Building the DMG

```bash
# Clone the repository
git clone https://github.com/yourusername/markymarkdown.git
cd markymarkdown

# Build the DMG (includes bundled MarkItDown CLI)
./build-dmg.sh

# Output file: .build/MarkItDown-1.0.0.dmg
```

### What's Included in the DMG

- `MarkItDown.app` - The complete macOS application
  - Bundled MarkItDown CLI binary (no installation needed)
  - All required resources and settings
- `Applications` folder shortcut (for easy installation)

### Release Process

1. Build the DMG: `./build-dmg.sh`
2. Test the app on a fresh macOS system (if possible)
3. Upload `.build/MarkItDown-*.dmg` to your release page
4. Update version number in `build-dmg.sh` and `Package.swift` for future releases

### Customization

#### Update Version Number

Edit `build-dmg.sh`:
```bash
VERSION="1.1.0"  # Change this line
```

#### Include Custom MarkItDown

Replace `Sources/MarkitdownUI/Resources/markitdown` with your own compiled binary:
```bash
# Download or build a newer MarkItDown
# Then replace the bundled version
cp /path/to/your/markitdown Sources/MarkitdownUI/Resources/markitdown
chmod +x Sources/MarkitdownUI/Resources/markitdown

# Rebuild
./build-dmg.sh
```

#### Codesign and Notarize (for App Store distribution)

If you plan to distribute on the App Store or need code signing:

```bash
# Sign the app bundle
codesign --deep --force --verify --verbose --sign "Developer ID Application" \
    .build/MarkItDown.app

# For App Store, you'll also need notarization
# See Apple's documentation on app notarization
```

### System Requirements

- **macOS Version**: 13.0 or later
- **Architecture**: Apple Silicon (arm64) - M1, M2, M3, M4, and newer
- **Bundled Dependencies**: None - all required software is included in the app
- **Additional Installation Required**: None - no Python, pip, or system tools needed

**Note**: This build is specifically compiled for Apple Silicon Macs. Users with Intel-based Macs will not be able to run this version. A separate build would be needed for Intel compatibility.

### File Sizes

- MarkItDown.app: ~5-8 MB (with bundled MarkItDown)
- MarkItDown-*.dmg: ~110 KB (compressed)

## Troubleshooting Distribution Issues

### App won't launch after installation

1. Verify the app is in `/Applications` folder
2. Check System Preferences > Security & Privacy
3. If blocked, click "Open" button next to the security warning
4. Try launching via Terminal: `/Applications/MarkItDown.app/Contents/MacOS/MarkItDown`

### MarkItDown binary not found

1. Open Preferences in the app (menu bar icon → Preferences)
2. Verify "CLI path is valid" appears in green
3. If it shows "Using bundled MarkItDown", the binary is included and working
4. If custom path shows, verify it points to a valid markitdown executable

### File conversion fails

1. Check that the file format is supported by MarkItDown
2. Verify you have read/write permissions in the folder containing the file
3. Try a simple test file (PDF or DOCX)
4. Check Preferences to ensure CLI validation passes

## Reporting Issues

If users encounter issues:

1. Check the Preferences to verify MarkItDown is found
2. Try converting a simple test file
3. Note the exact error message
4. Check if the issue is with MarkItDown CLI or the UI

## Further Development

- See [README.md](README.md) for project structure
- See [Package.swift](Package.swift) for dependencies and build configuration
- File issues and feature requests on GitHub

---

**Last Updated**: April 2026  
**Current Version**: 1.0.0
