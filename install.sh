#!/bin/bash
# MarkyMarkdown Installer
# Automates download, installation, and quarantine removal

set -e

APP_NAME="MarkyMarkdown"
REPO="abirismyname/markymarkdown"
RELEASE_API="https://api.github.com/repos/${REPO}/releases/latest"
INSTALL_PATH="/Applications/${APP_NAME}.app"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 MarkyMarkdown Installer${NC}"
echo ""

# Step 1: Fetch latest release info
echo -e "${BLUE}Step 1: Fetching latest release...${NC}"
RELEASE_JSON=$(curl -s "$RELEASE_API")

if echo "$RELEASE_JSON" | grep -q '"message"'; then
	echo -e "${YELLOW}Error: Could not fetch latest release. Exiting.${NC}"
	exit 1
fi

# Extract DMG download URL
DMG_URL=$(echo "$RELEASE_JSON" | grep -o '"browser_download_url":"[^"]*\.dmg"' | head -1 | cut -d'"' -f4)
if [[ -z "$DMG_URL" ]]; then
	echo -e "${YELLOW}Error: No DMG found in latest release. Exiting.${NC}"
	exit 1
fi

VERSION=$(echo "$DMG_URL" | grep -oE 'MarkyMarkdown-[0-9.]+' | sed 's/MarkyMarkdown-//')
DMG_FILE="${HOME}/Downloads/MarkyMarkdown-${VERSION}.dmg"

echo -e "${GREEN}✅ Found version ${VERSION}${NC}"
echo ""

# Step 2: Download DMG
echo -e "${BLUE}Step 2: Downloading MarkyMarkdown-${VERSION}.dmg...${NC}"
if [[ -f "$DMG_FILE" ]]; then
	echo -e "${YELLOW}DMG already exists at ${DMG_FILE}. Skipping download.${NC}"
else
	curl -L -o "$DMG_FILE" "$DMG_URL"
	echo -e "${GREEN}✅ Downloaded to ${DMG_FILE}${NC}"
fi
echo ""

# Step 3: Mount DMG
echo -e "${BLUE}Step 3: Mounting DMG...${NC}"
MOUNT_POINT=$(hdiutil attach "$DMG_FILE" | grep Volumes | awk '{print $NF}')
echo -e "${GREEN}✅ Mounted at ${MOUNT_POINT}${NC}"
echo ""

# Step 4: Copy app to Applications
echo -e "${BLUE}Step 4: Installing to /Applications...${NC}"
if [[ -d "$INSTALL_PATH" ]]; then
	echo -e "${YELLOW}Removing existing installation...${NC}"
	rm -rf "$INSTALL_PATH"
fi

cp -r "${MOUNT_POINT}/MarkyMarkdown.app" "$INSTALL_PATH"
echo -e "${GREEN}✅ Installed to ${INSTALL_PATH}${NC}"
echo ""

# Step 5: Unmount DMG
echo -e "${BLUE}Step 5: Unmounting DMG...${NC}"
hdiutil detach "$MOUNT_POINT" -quiet
echo -e "${GREEN}✅ Unmounted${NC}"
echo ""

# Step 6: Remove quarantine flag
echo -e "${BLUE}Step 6: Removing quarantine attribute...${NC}"
xattr -rd com.apple.quarantine "$INSTALL_PATH"
echo -e "${GREEN}✅ Quarantine removed${NC}"
echo ""

# Step 7: Launch app
echo -e "${BLUE}Step 7: Launching MarkyMarkdown...${NC}"
open "$INSTALL_PATH"
echo -e "${GREEN}✅ Launched${NC}"
echo ""

echo -e "${GREEN}🎉 Installation complete!${NC}"
echo "MarkyMarkdown is now ready to use."
echo ""
echo "💡 Tip: You can also find it in Spotlight (Cmd+Space, then type 'MarkyMarkdown')"
echo ""
