#!/bin/bash
set -e

# Configuration
APP_NAME="MarkyMarkdown"
VERSION="1.1.0"
BUILD_DIR=".build"
APP_BUNDLE_PATH=".build/MarkyMarkdown.app"
DMG_OUTPUT=".build/MarkyMarkdown-${VERSION}.dmg"
DMG_RW_OUTPUT=".build/MarkyMarkdown-${VERSION}-rw.dmg"
EXECUTABLE_PATH="${BUILD_DIR}/release/MarkitdownUI"
MARKITDOWN_STANDALONE_DIR="${BUILD_DIR}/markitdown-standalone"
MARKITDOWN_VENV_DIR="${MARKITDOWN_STANDALONE_DIR}/venv"

# Code Signing Configuration
SIGNING_IDENTITY="Apple Development: Abir Majumdar (B4994FKL79)"
ENABLE_CODE_SIGNING=true
MARKITDOWN_ENTRY_SCRIPT="${MARKITDOWN_STANDALONE_DIR}/markitdown_entry.py"
MARKITDOWN_DIST_BINARY="${MARKITDOWN_STANDALONE_DIR}/dist/markitdown/markitdown"
INSTALLER_BACKGROUND_SRC="installer-background.png"
INSTALLER_BACKGROUND_NAME="installer-background.png"

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
rm -rf "${APP_BUNDLE_PATH}" "${DMG_OUTPUT}" "${DMG_RW_OUTPUT}" "${MARKITDOWN_STANDALONE_DIR}"

# Build a standalone MarkItDown binary so end users do not need Python or pipx.
echo "🐍 Building standalone MarkItDown CLI..."
mkdir -p "${MARKITDOWN_STANDALONE_DIR}"
"${PYTHON_BIN}" -m venv "${MARKITDOWN_VENV_DIR}"
"${MARKITDOWN_VENV_DIR}/bin/python" -m pip install --upgrade pip setuptools wheel
"${MARKITDOWN_VENV_DIR}/bin/python" -m pip install \
	"markitdown[docx,pdf,pptx,xlsx,html,uri] @ git+https://github.com/microsoft/markitdown.git#subdirectory=packages/markitdown" \
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
	<string>1.1.0</string>
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

# Code Signing
if [[ "${ENABLE_CODE_SIGNING}" == "true" ]]; then
	echo "🔐 Code signing app bundle..."
	
	# Sign the bundled MarkItDown CLI binary first
	if [[ -f "${APP_BUNDLE_PATH}/Contents/Resources/markitdown/markitdown" ]]; then
		echo "  Signing MarkItDown CLI binary..."
		codesign -s "${SIGNING_IDENTITY}" --force \
			"${APP_BUNDLE_PATH}/Contents/Resources/markitdown/markitdown" || {
			echo "⚠️  Warning: Could not sign MarkItDown binary. Verify certificate is installed."
		}
	fi
	
	# Sign the entire app bundle with deep signing
	echo "  Signing app bundle (deep)..."
	codesign -s "${SIGNING_IDENTITY}" --deep --force "${APP_BUNDLE_PATH}" || {
		echo "❌ Code signing failed. Verify the certificate is installed:"
		echo "   security find-identity -v -p codesigning"
		exit 1
	}
	
	# Verify the signature
	echo "  Verifying code signature..."
	if codesign -v "${APP_BUNDLE_PATH}" 2>&1; then
		echo "✅ Code signature verified successfully"
		
		# Display signature details
		echo "  Signature details:"
		codesign -d -r - "${APP_BUNDLE_PATH}" 2>&1 | head -3
	else
		echo "⚠️  Code signature verification failed. The app may not launch properly."
	fi
else
	echo "⚠️  Code signing disabled (ENABLE_CODE_SIGNING not set)"
fi

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

if [[ ! -f "${INSTALLER_BACKGROUND_SRC}" ]]; then
	echo "❌ ${INSTALLER_BACKGROUND_SRC} not found. Place the 700x440 PNG in the repo root and re-run."
	exit 1
fi
cp "${INSTALLER_BACKGROUND_SRC}" "${DMG_TEMP_DIR}/.background/${INSTALLER_BACKGROUND_NAME}"

# Make the mounted DMG volume use the same icon as the app.
cp "Sources/MarkitdownUI/Resources/AppIcon.icns" "${DMG_TEMP_DIR}/.VolumeIcon.icns"
if command -v SetFile >/dev/null 2>&1; then
	SetFile -a C "${DMG_TEMP_DIR}"
	SetFile -a V "${DMG_TEMP_DIR}/.VolumeIcon.icns"
else
	echo "⚠️  SetFile not found; DMG custom volume icon may not be applied on this machine."
fi


# Create a writable DMG first so Finder metadata (background + icon layout) can be set.
DMG_VOLUME_NAME="MarkyMarkdown ${VERSION}"
hdiutil create \
	-volname "${DMG_VOLUME_NAME}" \
	-srcfolder "${DMG_TEMP_DIR}" \
	-ov \
	-format UDRW \
	"${DMG_RW_OUTPUT}"

ATTACH_OUTPUT="$(hdiutil attach -readwrite -noverify -noautoopen "${DMG_RW_OUTPUT}")"
DMG_MOUNT_POINT="$(echo "${ATTACH_OUTPUT}" | awk 'match($0,/\/Volumes\/.*/) { print substr($0, RSTART); exit }')"

if [[ -n "${DMG_MOUNT_POINT}" && -d "${DMG_MOUNT_POINT}" ]]; then
	if command -v SetFile >/dev/null 2>&1; then
		SetFile -a C "${DMG_MOUNT_POINT}" || true
		SetFile -a V "${DMG_MOUNT_POINT}/.VolumeIcon.icns" || true
	fi

	if [[ -f "${DMG_MOUNT_POINT}/.background/${INSTALLER_BACKGROUND_NAME}" ]]; then
		if ! osascript <<EOF
tell application "Finder"
	tell disk "${DMG_VOLUME_NAME}"
		open
		set current view of container window to icon view
		set toolbar visible of container window to false
		set statusbar visible of container window to false
		-- Window bounds sized exactly to the 700x440 installer-background.png.
		-- Formula: {left, top, left+700, top+440} = {120, 120, 820, 560}
		set the bounds of container window to {120, 120, 820, 560}
		set viewOptions to the icon view options of container window
		set arrangement of viewOptions to not arranged
		set icon size of viewOptions to 96
		set text size of viewOptions to 13
		set background picture of viewOptions to file ".background:${INSTALLER_BACKGROUND_NAME}"
		-- Icon positions are Finder icon-center coordinates within the 700x440 canvas.
		-- App icon centred in the left drop zone; Applications alias in the right drop zone.
		set position of item "${APP_NAME}.app" of container window to {200, 260}
		set position of item "Applications" of container window to {500, 260}
		close
		open
		update without registering applications
		delay 1
	end tell
end tell
EOF
		then
			echo "⚠️  Finder metadata step timed out; continuing DMG build without persisted window layout/background settings."
		fi
	fi

	if command -v bless >/dev/null 2>&1; then
		bless --folder "${DMG_MOUNT_POINT}" --openfolder "${DMG_MOUNT_POINT}" || true
	fi

	hdiutil detach "${DMG_MOUNT_POINT}" -quiet
else
	echo "⚠️  Could not find mounted DMG path to set background metadata."
fi

# Convert writable DMG to compressed distribution image.
hdiutil convert "${DMG_RW_OUTPUT}" -format UDZO -o "${DMG_OUTPUT}" -ov

# Clean up temp directory
rm -rf "${DMG_TEMP_DIR}"
rm -f "${DMG_RW_OUTPUT}"

echo "✅ DMG created successfully: ${DMG_OUTPUT}"
echo ""
echo "📊 Build Summary:"
echo "  App Bundle: ${APP_BUNDLE_PATH}"
echo "  DMG Distribution: ${DMG_OUTPUT}"
echo "  Version: ${VERSION}"
echo ""
echo "🚀 To distribute, share: ${DMG_OUTPUT}"
echo "📖 Users can drag MarkyMarkdown.app to Applications folder from the DMG"
