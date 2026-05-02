#!/bin/bash
set -e

# Configuration
APP_NAME="MarkyMarkdown"
VERSION="${APP_VERSION:-1.1.9}"
BUILD_DIR=".build"
APP_BUNDLE_PATH=".build/MarkyMarkdown.app"
DMG_OUTPUT=".build/MarkyMarkdown-${VERSION}.dmg"
DMG_RW_OUTPUT=".build/MarkyMarkdown-${VERSION}-rw.dmg"
EXECUTABLE_PATH="${BUILD_DIR}/release/MarkitdownUI"
MARKITDOWN_STANDALONE_DIR="${BUILD_DIR}/markitdown-standalone"
MARKITDOWN_VENV_DIR="${MARKITDOWN_STANDALONE_DIR}/venv"

# Code Signing Configuration
# Prefer the value injected by CI (via $SIGNING_IDENTITY secret) and fall back to the local default.
SIGNING_IDENTITY="${SIGNING_IDENTITY:-Apple Development: Abir Majumdar (B4994FKL79)}"
# Auto-detect whether the signing certificate is available in the local keychain.
# CI environments (GitHub Actions) do not have the certificate, so signing is skipped gracefully.
if security find-identity -v -p codesigning 2>/dev/null | grep -q "${SIGNING_IDENTITY}"; then
	ENABLE_CODE_SIGNING=true
else
	ENABLE_CODE_SIGNING=false
	echo "⚠️  Signing identity '${SIGNING_IDENTITY}' not found in keychain — code signing will be skipped."
fi

# Sparkle update key — set via CI secret SPARKLE_PUBLIC_ED_KEY.
# Generate once with: .build/artifacts/.../Sparkle.xcframework/.../bin/generate_keys
# See README.md § "Sparkle Update Keys" for full instructions.
SPARKLE_PUBLIC_ED_KEY="${SPARKLE_PUBLIC_ED_KEY:-}"

# Entitlements file required by hardened runtime when Sparkle (a third-party framework) is embedded.
ENTITLEMENTS_PATH="MarkyMarkdown.entitlements"
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

# Normalize Python.framework binary layout so top-level Python points at the canonical, signed runtime binary.
PYTHON_FRAMEWORK_DIR="${APP_BUNDLE_PATH}/Contents/Resources/markitdown/_internal/Python.framework"
if [[ -d "${PYTHON_FRAMEWORK_DIR}" && -f "${PYTHON_FRAMEWORK_DIR}/Python" ]]; then
	if [[ -f "${PYTHON_FRAMEWORK_DIR}/Versions/Current/Python" ]]; then
		rm -f "${PYTHON_FRAMEWORK_DIR}/Python"
		ln -s "Versions/Current/Python" "${PYTHON_FRAMEWORK_DIR}/Python"
	elif [[ -f "${PYTHON_FRAMEWORK_DIR}/Versions/3.11/Python" ]]; then
		rm -f "${PYTHON_FRAMEWORK_DIR}/Python"
		ln -s "Versions/3.11/Python" "${PYTHON_FRAMEWORK_DIR}/Python"
	fi
fi

# Copy app icon
cp "Sources/MarkitdownUI/Resources/AppIcon.icns" "${APP_BUNDLE_PATH}/Contents/Resources/"

# Embed Sparkle.framework
echo "🔗 Embedding Sparkle framework..."
SPARKLE_XCFRAMEWORK=$(find ".build/artifacts" -name "Sparkle.xcframework" -type d 2>/dev/null | head -1)
if [[ -z "${SPARKLE_XCFRAMEWORK}" ]]; then
	echo "❌ Sparkle.xcframework not found in .build/artifacts. Ensure 'swift build' ran successfully."
	exit 1
fi
SPARKLE_MACOS_FRAMEWORK=$(find "${SPARKLE_XCFRAMEWORK}" -name "Sparkle.framework" -maxdepth 2 -type d | head -1)
if [[ -z "${SPARKLE_MACOS_FRAMEWORK}" ]]; then
	echo "❌ Sparkle.framework slice not found inside ${SPARKLE_XCFRAMEWORK}."
	exit 1
fi
mkdir -p "${APP_BUNDLE_PATH}/Contents/Frameworks"
cp -r "${SPARKLE_MACOS_FRAMEWORK}" "${APP_BUNDLE_PATH}/Contents/Frameworks/"
echo "✅ Sparkle.framework embedded"

# Ensure the main binary resolves Sparkle at its bundled location at runtime.
install_name_tool -add_rpath "@executable_path/../Frameworks" \
	"${APP_BUNDLE_PATH}/Contents/MacOS/${APP_NAME}" 2>/dev/null || true
echo "✅ rpath updated for Sparkle"

# Create Info.plist
cat > "${APP_BUNDLE_PATH}/Contents/Info.plist" << EOF
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
	<string>${VERSION}</string>
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
	<key>SUFeedURL</key>
	<string>https://abirismyname.github.io/markymarkdown/appcast.xml</string>
	<key>SUPublicEDKey</key>
	<string>${SPARKLE_PUBLIC_ED_KEY}</string>
</dict>
</plist>
EOF

echo "✅ App bundle created at: ${APP_BUNDLE_PATH}"

# Code Signing
if [[ "${ENABLE_CODE_SIGNING}" == "true" ]]; then
	echo "🔐 Code signing app bundle with '${SIGNING_IDENTITY}'..."

	sign_binary() {
		local target="$1"
		echo "    Signing: ${target}"
		codesign -s "${SIGNING_IDENTITY}" --force --options runtime --timestamp "${target}"
	}
	
	# Verify the signing identity exists and is valid for notarization
	if ! security find-identity -v -p codesigning | grep -q "${SIGNING_IDENTITY}"; then
		echo "⚠️  Signing identity '${SIGNING_IDENTITY}' not found in keychain"
		echo "Available identities:"
		security find-identity -v -p codesigning || true
		echo "Continuing with attempted signing anyway..."
	fi
	
	# Check if using Developer ID (required for notarization) vs Apple Development
	if echo "${SIGNING_IDENTITY}" | grep -q "Apple Development"; then
		echo "⚠️  WARNING: Using 'Apple Development' certificate"
		echo "   For notarization, you need 'Developer ID Application' certificate"
		echo "   This will likely fail notarization!"
	fi
	
	MARKITDOWN_RESOURCES="${APP_BUNDLE_PATH}/Contents/Resources/markitdown"
	SPARKLE_FRAMEWORK_IN_BUNDLE="${APP_BUNDLE_PATH}/Contents/Frameworks/Sparkle.framework"
	DYLIB_COUNT=0
	SO_COUNT=0
	BIN_COUNT=0

	# Sign Sparkle.framework (inner-to-outer: nested XPC services and helpers first)
	if [[ -d "${SPARKLE_FRAMEWORK_IN_BUNDLE}" ]]; then
		echo "  Signing Sparkle framework internals..."

		# Sign XPC service bundles
		find "${SPARKLE_FRAMEWORK_IN_BUNDLE}" -name "*.xpc" -type d | sort -r | while read -r xpc_bundle; do
			echo "    Signing XPC service: ${xpc_bundle}"
			codesign -s "${SIGNING_IDENTITY}" --force --options runtime --timestamp "${xpc_bundle}"
		done

		# Sign other Mach-O executables inside the framework (helpers, etc.)
		find "${SPARKLE_FRAMEWORK_IN_BUNDLE}" -type f -perm -111 \
			! -name "*.xpc" | while read -r bin_file; do
			if file -b "$bin_file" 2>/dev/null | grep -q "Mach-O"; then
				sign_binary "$bin_file"
			fi
		done

		# Sign dylibs inside the framework
		find "${SPARKLE_FRAMEWORK_IN_BUNDLE}" -type f -name "*.dylib" | while read -r dylib; do
			sign_binary "$dylib"
		done

		# Sign the framework bundle itself
		echo "  Signing Sparkle.framework bundle..."
		codesign -s "${SIGNING_IDENTITY}" --force --options runtime --timestamp "${SPARKLE_FRAMEWORK_IN_BUNDLE}"
		echo "  ✓ Sparkle.framework signed"
	fi
	
	# Sign all dylibs and extension modules in the bundled Python runtime
	if [[ -d "${MARKITDOWN_RESOURCES}/_internal" ]]; then
		echo "  Signing Python runtime binaries..."
		
		# Sign executable Mach-O files first (includes _internal/Python and helper binaries).
		BIN_COUNT=$(find "${MARKITDOWN_RESOURCES}/_internal" -type f -perm -111 \
			! -path "*/Python.framework/Python" \
			! -path "*/Python.framework/Versions/Current/Python" \
			| while read -r f; do file -b "$f" | grep -q "Mach-O" && echo "$f"; done | wc -l)
		if [[ $BIN_COUNT -gt 0 ]]; then
			echo "    Signing $BIN_COUNT executable Mach-O files..."
			find "${MARKITDOWN_RESOURCES}/_internal" -type f -perm -111 \
				! -path "*/Python.framework/Python" \
				! -path "*/Python.framework/Versions/Current/Python" \
				| while read -r bin_file; do
				if file -b "$bin_file" | grep -q "Mach-O"; then
					sign_binary "$bin_file"
				fi
			done
		fi
		
		# Sign all .dylib files (shared libraries) 
		DYLIB_COUNT=$(find "${MARKITDOWN_RESOURCES}/_internal" -type f -name "*.dylib" | wc -l)
		if [[ $DYLIB_COUNT -gt 0 ]]; then
			echo "    Signing $DYLIB_COUNT .dylib files..."
			find "${MARKITDOWN_RESOURCES}/_internal" -type f -name "*.dylib" | while read -r dylib; do
				sign_binary "$dylib"
			done
		fi
		
		# Sign all .so files (Python C extension modules)
		SO_COUNT=$(find "${MARKITDOWN_RESOURCES}/_internal" -type f -name "*.so" | wc -l)
		if [[ $SO_COUNT -gt 0 ]]; then
			echo "    Signing $SO_COUNT .so files..."
			find "${MARKITDOWN_RESOURCES}/_internal" -type f -name "*.so" | while read -r so_file; do
				sign_binary "$so_file"
			done
		fi
		
		# Sign Python.framework using the canonical binary path first, then the framework bundle.
		PYTHON_FRAMEWORK_DIR="${MARKITDOWN_RESOURCES}/_internal/Python.framework"
		PYTHON_FRAMEWORK_BIN=""
		if [[ -x "${PYTHON_FRAMEWORK_DIR}/Versions/Current/Python" ]]; then
			PYTHON_FRAMEWORK_BIN="${PYTHON_FRAMEWORK_DIR}/Versions/Current/Python"
		elif [[ -x "${PYTHON_FRAMEWORK_DIR}/Versions/3.11/Python" ]]; then
			PYTHON_FRAMEWORK_BIN="${PYTHON_FRAMEWORK_DIR}/Versions/3.11/Python"
		fi

		if [[ -n "${PYTHON_FRAMEWORK_BIN}" ]]; then
			echo "    Signing Python.framework binary (${PYTHON_FRAMEWORK_BIN})..."
			sign_binary "${PYTHON_FRAMEWORK_BIN}"
		fi

		echo "  ✓ Python runtime binaries signed ($BIN_COUNT executables, $DYLIB_COUNT dylibs, $SO_COUNT .so files)"
	fi
	
	# Sign the bundled MarkItDown CLI binary
	if [[ -f "${MARKITDOWN_RESOURCES}/markitdown" ]]; then
		echo "  Signing MarkItDown CLI binary..."
		sign_binary "${MARKITDOWN_RESOURCES}/markitdown"
		echo "  ✓ MarkItDown binary signed"
	fi
	
	# Sign the Swift executable with entitlements (needed for hardened runtime + Sparkle)
	echo "  Signing Swift executable..."
	codesign -s "${SIGNING_IDENTITY}" --force --options runtime --timestamp \
		--entitlements "${ENTITLEMENTS_PATH}" \
		"${APP_BUNDLE_PATH}/Contents/MacOS/MarkyMarkdown"
	
	# Sign the app bundle container (without --deep) after nested code is already signed.
	echo "  Signing app bundle..."
	codesign -s "${SIGNING_IDENTITY}" --force --options runtime --timestamp "${APP_BUNDLE_PATH}"
	
	# Verify the signatures
	echo "  Verifying signatures..."
	VERIFY_ERRORS=0
	
	if ! codesign --verify --deep --strict --verbose=2 "${APP_BUNDLE_PATH}" 2>&1; then
		echo "⚠️  Main app signature verification failed"
		VERIFY_ERRORS=$((VERIFY_ERRORS + 1))
	fi

	if ! codesign --verify --strict --verbose=2 "${APP_BUNDLE_PATH}/Contents/MacOS/MarkyMarkdown" 2>&1; then
		echo "⚠️  Main executable signature verification failed"
		VERIFY_ERRORS=$((VERIFY_ERRORS + 1))
	fi

	PYTHON_TOP="${MARKITDOWN_RESOURCES}/_internal/Python.framework/Python"
	if [[ -e "${PYTHON_TOP}" ]]; then
		if ! codesign --verify --strict --verbose=2 "${PYTHON_TOP}" 2>&1; then
			echo "⚠️  Python.framework/Python signature verification failed"
			VERIFY_ERRORS=$((VERIFY_ERRORS + 1))
		fi
	fi
	
	# Sample verify a few dylibs
	SAMPLE_DYLIB=$(find "${MARKITDOWN_RESOURCES}/_internal" -type f -name "*.dylib" | head -1)
	if [[ -n "$SAMPLE_DYLIB" ]]; then
		if codesign --verify --strict --verbose=2 "$SAMPLE_DYLIB" 2>&1; then
			echo "✓ Sample dylib verified"
		else
			echo "⚠️  Sample dylib verification failed"
			VERIFY_ERRORS=$((VERIFY_ERRORS + 1))
		fi
	fi

	if spctl -a -t exec -vv "${APP_BUNDLE_PATH}" 2>&1; then
		echo "✓ Gatekeeper assessment passed"
	else
		echo "⚠️  Gatekeeper assessment failed (expected before notarization)"
	fi
	
	if [[ $VERIFY_ERRORS -eq 0 ]]; then
		echo -e "\n✅ All code signatures verified successfully"
	else
		echo -e "\n❌ Signature verification failures detected"
		exit 1
	fi
else
	echo "⚠️  Code signing disabled — app will NOT pass notarization"
fi

# Create DMG
echo "💿 Creating DMG distribution..."

# Create a temporary directory for DMG contents
DMG_TEMP_DIR=".build/dmg_temp"
rm -rf "${DMG_TEMP_DIR}"
mkdir -p "${DMG_TEMP_DIR}"

# Copy app bundle to temp directory without altering symlinks/metadata required by code signatures.
ditto "${APP_BUNDLE_PATH}" "${DMG_TEMP_DIR}/MarkyMarkdown.app"

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
		bless --folder "${DMG_MOUNT_POINT}" || true
	fi

	hdiutil detach "${DMG_MOUNT_POINT}" -quiet
else
	echo "⚠️  Could not find mounted DMG path to set background metadata."
fi

# Convert writable DMG to compressed distribution image.
hdiutil convert "${DMG_RW_OUTPUT}" -format UDZO -o "${DMG_OUTPUT}" -ov

# Sign the final DMG so Gatekeeper trusts it on end-user machines.
if [[ "${ENABLE_CODE_SIGNING}" == "true" ]]; then
	echo "🔐 Signing DMG..."
	codesign -s "${SIGNING_IDENTITY}" --force "${DMG_OUTPUT}" || {
		echo "⚠️  Warning: Could not sign DMG. Distribution is still possible but Gatekeeper may warn users."
	}
	echo "✅ DMG signed successfully"
fi

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
