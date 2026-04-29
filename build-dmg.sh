#!/bin/bash
set -e

# Configuration
APP_NAME="MarkyMarkdown"
VERSION="1.0.0"
BUILD_DIR=".build"
APP_BUNDLE_PATH=".build/MarkyMarkdown.app"
DMG_OUTPUT=".build/MarkyMarkdown-${VERSION}.dmg"
EXECUTABLE_PATH="${BUILD_DIR}/release/MarkitdownUI"
MARKITDOWN_STANDALONE_DIR="${BUILD_DIR}/markitdown-standalone"
MARKITDOWN_VENV_DIR="${MARKITDOWN_STANDALONE_DIR}/venv"
MARKITDOWN_ENTRY_SCRIPT="${MARKITDOWN_STANDALONE_DIR}/markitdown_entry.py"
MARKITDOWN_DIST_BINARY="${MARKITDOWN_STANDALONE_DIR}/dist/markitdown/markitdown"

if command -v python3.12 >/dev/null 2>&1; then
	PYTHON_BIN="$(command -v python3.12)"
elif command -v python3.11 >/dev/null 2>&1; then
	PYTHON_BIN="$(command -v python3.11)"
elif command -v python3.10 >/dev/null 2>&1; then
	PYTHON_BIN="$(command -v python3.10)"
else
	echo "❌ Python 3.10+ is required to build the bundled MarkItDown CLI."
	echo "   Install one (e.g. 'brew install python@3.11') and re-run ./build-dmg.sh"
	exit 1
fi

echo "📦 Building MarkyMarkdown macOS app..."

# Clean previous builds
rm -rf "${APP_BUNDLE_PATH}" "${DMG_OUTPUT}" "${MARKITDOWN_STANDALONE_DIR}"

# Build a standalone MarkItDown binary so end users do not need Python or pipx.
echo "🐍 Building standalone MarkItDown CLI..."
mkdir -p "${MARKITDOWN_STANDALONE_DIR}"
"${PYTHON_BIN}" -m venv "${MARKITDOWN_VENV_DIR}"
"${MARKITDOWN_VENV_DIR}/bin/python" -m pip install --upgrade pip setuptools wheel
"${MARKITDOWN_VENV_DIR}/bin/python" -m pip install \
	"markitdown[docx,pdf,pptx,xlsx] @ git+https://github.com/microsoft/markitdown.git#subdirectory=packages/markitdown" \
	pyinstaller

cat > "${MARKITDOWN_ENTRY_SCRIPT}" << 'EOF'
from markitdown.__main__ import main

if __name__ == "__main__":
	raise SystemExit(main())
EOF

"${MARKITDOWN_VENV_DIR}/bin/python" -m PyInstaller \
	--clean \
	--noconfirm \
	--onedir \
	--collect-all markitdown \
	--collect-all magika \
	--hidden-import markitdown \
	--hidden-import markitdown.__main__ \
	--hidden-import markitdown._markitdown \
	--hidden-import markitdown.cli \
	--hidden-import magika \
	--hidden-import PIL \
	--hidden-import pypdfium2 \
	--distpath "${MARKITDOWN_STANDALONE_DIR}/dist" \
	--workpath "${MARKITDOWN_STANDALONE_DIR}/build" \
	--specpath "${MARKITDOWN_STANDALONE_DIR}" \
	--name markitdown \
	"${MARKITDOWN_ENTRY_SCRIPT}"

if [[ ! -x "${MARKITDOWN_DIST_BINARY}" ]]; then
	echo "❌ Failed to build standalone MarkItDown binary"
	exit 1
fi

# Build the executable in release mode
echo "🔨 Building Swift package (release)..."
swift build --configuration release

# Create app bundle structure
echo "📁 Creating app bundle structure..."
mkdir -p "${APP_BUNDLE_PATH}/Contents/MacOS"
mkdir -p "${APP_BUNDLE_PATH}/Contents/Resources"

# Copy executable
cp "${EXECUTABLE_PATH}" "${APP_BUNDLE_PATH}/Contents/MacOS/${APP_NAME}"

# Copy bundled standalone markitdown directory (includes _internal Python runtime)
cp -r "${MARKITDOWN_STANDALONE_DIR}/dist/markitdown" "${APP_BUNDLE_PATH}/Contents/Resources/"
chmod +x "${APP_BUNDLE_PATH}/Contents/Resources/markitdown/markitdown"

# Copy app icon
cp "Sources/MarkitdownUI/Resources/AppIcon.icns" "${APP_BUNDLE_PATH}/Contents/Resources/"

# Create Info.plist
cat > "${APP_BUNDLE_PATH}/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleExecutable</key>
	<string>MarkyMarkdown</string>
	<key>CFBundleIdentifier</key>
	<string>com.markymarkdown.app</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>MarkyMarkdown</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.0.0</string>
	<key>CFBundleVersion</key>
	<string>1</string>
	<key>CFBundleIconFile</key>
	<string>AppIcon</string>
	<key>LSMinimumSystemVersion</key>
	<string>13.0</string>
	<key>LSUIElement</key>
	<true/>
	<key>NSHighResolutionCapable</key>
	<true/>
	<key>NSHumanReadableCopyright</key>
	<string>Copyright © 2026. All rights reserved.</string>
	<key>NSRequiresIPhoneOS</key>
	<false/>
</dict>
</plist>
EOF

echo "✅ App bundle created at: ${APP_BUNDLE_PATH}"

# Create DMG
echo "💿 Creating DMG distribution..."

# Create a temporary directory for DMG contents
DMG_TEMP_DIR=".build/dmg_temp"
rm -rf "${DMG_TEMP_DIR}"
mkdir -p "${DMG_TEMP_DIR}"

# Copy app bundle to temp directory
cp -r "${APP_BUNDLE_PATH}" "${DMG_TEMP_DIR}/"

# Create a symlink to Applications folder for easy installation
ln -s /Applications "${DMG_TEMP_DIR}/Applications"

# Create a background image directory (optional, creates DMG with background)
mkdir -p "${DMG_TEMP_DIR}/.background"

# Make the mounted DMG volume use the same icon as the app.
cp "Sources/MarkitdownUI/Resources/AppIcon.icns" "${DMG_TEMP_DIR}/.VolumeIcon.icns"
if command -v SetFile >/dev/null 2>&1; then
	SetFile -a C "${DMG_TEMP_DIR}"
	SetFile -a V "${DMG_TEMP_DIR}/.VolumeIcon.icns"
else
	echo "⚠️  SetFile not found; DMG custom volume icon may not be applied on this machine."
fi

# Create DMG using hdiutil
hdiutil create \
	-volname "MarkyMarkdown ${VERSION}" \
    -srcfolder "${DMG_TEMP_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_OUTPUT}"

# Clean up temp directory
rm -rf "${DMG_TEMP_DIR}"

echo "✅ DMG created successfully: ${DMG_OUTPUT}"
echo ""
echo "📊 Build Summary:"
echo "  App Bundle: ${APP_BUNDLE_PATH}"
echo "  DMG Distribution: ${DMG_OUTPUT}"
echo "  Version: ${VERSION}"
echo ""
echo "🚀 To distribute, share: ${DMG_OUTPUT}"
echo "📖 Users can drag MarkyMarkdown.app to Applications folder from the DMG"
