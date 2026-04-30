# Installation Guide for MarkyMarkdown

## Quick Installation

### Option 1: Using the DMG (Easiest)

1. Download `MarkyMarkdown-1.1.0.dmg` from [Releases](https://github.com/abirismyname/markymarkdown/releases)
2. Open the DMG file
3. Drag `MarkyMarkdown.app` to the **Applications** folder
4. Open **Terminal** and run:
   ```bash
   xattr -rd com.apple.quarantine /Applications/MarkyMarkdown.app
   ```
5. Launch MarkyMarkdown from Spotlight or Applications folder

**Why the quarantine removal?**
MarkyMarkdown is signed with a development certificate (not notarized by Apple). When you download it, macOS adds a quarantine flag. The command above removes it so the app launches normally.

---

### Option 2: Using the Install Script

If you prefer, copy this one-liner to Terminal:

```bash
curl -L https://raw.githubusercontent.com/abirismyname/markymarkdown/main/install.sh | bash
```

This script automates the download, installation, and quarantine removal.

---

### Option 3: Building from Source

If you want to build MarkyMarkdown yourself:

1. Clone the repository:
   ```bash
   git clone https://github.com/abirismyname/markymarkdown.git
   cd markymarkdown
   ```

2. Ensure you have Swift 6 and Python 3.10+ installed:
   ```bash
   swift --version
   python3 --version
   ```

3. Build the DMG:
   ```bash
   bash build-dmg.sh
   ```

4. The DMG will be created at `.build/MarkyMarkdown-1.1.0.dmg`

5. Follow **Option 1** to install from the DMG

---

## Troubleshooting

### "MarkyMarkdown.app is damaged and can't be opened"

Run this command:
```bash
xattr -rd com.apple.quarantine /Applications/MarkyMarkdown.app
```

Then try launching again.

### Build fails with "Python 3.10+ required"

Install Python via Homebrew:
```bash
brew install python@3.11
```

Then retry:
```bash
bash build-dmg.sh
```

### Build fails with code signing

If you're building on a different machine without the signing certificate, disable signing:
```bash
ENABLE_CODE_SIGNING=false bash build-dmg.sh
```

Users will still need to remove the quarantine flag in this case.

---

## System Requirements

- **macOS 13.0** or later
- **ARM64** (Apple Silicon) or **Intel** support (currently ARM64 only in distributed DMG)
- **No additional dependencies** — everything is bundled!

---

## What's Bundled

MarkyMarkdown includes:
- **MarkItDown CLI** — Standalone conversion engine
- **Python runtime** — Everything you need, zero user prerequisites
- **File format support:**
  - 📄 PDF, DOCX, PPTX, XLSX
  - 🖼️  PNG, JPG, GIF, WebP
  - 🌐 HTML
  - 🔗 URLs

---

## License

MarkyMarkdown is provided as-is under the MIT License.

For questions or issues, visit [GitHub Issues](https://github.com/abirismyname/markymarkdown/issues).
