#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== MarkyMarkdown Local Notarization Test ===${NC}\n"

# Check for required credentials
if [[ -z "$NOTARIZATION_APPLE_ID" ]]; then
    echo -e "${YELLOW}⚠️  NOTARIZATION_APPLE_ID not set${NC}"
    read -p "Enter Apple ID for notarization: " NOTARIZATION_APPLE_ID
fi

if [[ -z "$NOTARIZATION_TEAM_ID" ]]; then
    echo -e "${YELLOW}⚠️  NOTARIZATION_TEAM_ID not set${NC}"
    read -p "Enter Team ID for notarization: " NOTARIZATION_TEAM_ID
fi

if [[ -z "$NOTARIZATION_PWD" ]]; then
    echo -e "${YELLOW}⚠️  NOTARIZATION_PWD not set${NC}"
    read -sp "Enter app-specific password for notarization: " NOTARIZATION_PWD
    echo ""
fi

# Check for signing identity
if [[ -z "$SIGNING_IDENTITY" ]]; then
    echo -e "${YELLOW}⚠️  SIGNING_IDENTITY not set${NC}"
    echo "Available identities:"
    security find-identity -v -p codesigning | grep -v "iPhone" || true
    read -p "Enter signing identity (or press Enter to skip signing): " SIGNING_IDENTITY
fi

export NOTARIZATION_APPLE_ID
export NOTARIZATION_TEAM_ID
export NOTARIZATION_PWD
export SIGNING_IDENTITY

# Step 1: Build the DMG
echo -e "\n${BLUE}Step 1: Building DMG...${NC}"
if bash build-dmg.sh; then
    echo -e "${GREEN}✅ DMG built successfully${NC}"
else
    echo -e "${RED}❌ DMG build failed${NC}"
    exit 1
fi

# Step 2: Find the newest DMG from this build output folder
echo -e "\n${BLUE}Step 2: Locating DMG...${NC}"
DMG_PATH=$(ls -t .build/MarkyMarkdown-*.dmg 2>/dev/null | grep -v -- '-rw\.dmg$' | head -1)

if [[ -z "${DMG_PATH}" || ! -f "${DMG_PATH}" ]]; then
    echo -e "${RED}❌ DMG not found in .build/${NC}"
    exit 1
fi

DMG_SIZE=$(du -h "${DMG_PATH}" | cut -f1)
echo -e "${GREEN}✅ Found: ${DMG_PATH} (${DMG_SIZE})${NC}"

# Step 3: Submit for notarization
echo -e "\n${BLUE}Step 3: Submitting for notarization...${NC}"
echo "  Apple ID: $NOTARIZATION_APPLE_ID"
echo "  Team ID: $NOTARIZATION_TEAM_ID"
echo "  File: $DMG_PATH"
echo ""

set +e
NOTARIZE_OUTPUT=$(xcrun notarytool submit "${DMG_PATH}" \
    --apple-id "$NOTARIZATION_APPLE_ID" \
    --team-id "$NOTARIZATION_TEAM_ID" \
    --password "$NOTARIZATION_PWD" \
    --wait 2>&1)
NOTARIZE_EXIT_CODE=$?
set -e

echo "$NOTARIZE_OUTPUT"

# Step 4: Check notarization result
echo -e "\n${BLUE}Step 4: Checking notarization status...${NC}"

if [[ ${NOTARIZE_EXIT_CODE} -ne 0 ]]; then
    echo -e "${RED}❌ notarytool submit failed (exit ${NOTARIZE_EXIT_CODE})${NC}"
    exit 1
fi

if echo "$NOTARIZE_OUTPUT" | grep -q "status: Accepted"; then
    echo -e "${GREEN}✅ Notarization ACCEPTED${NC}"
    
    # Extract submission ID
    SUBMISSION_ID=$(echo "$NOTARIZE_OUTPUT" | grep "id:" | head -1 | awk '{print $NF}')
    echo "  Submission ID: $SUBMISSION_ID"
    
    # Step 5: Staple the ticket
    echo -e "\n${BLUE}Step 5: Stapling notarization ticket...${NC}"
    if xcrun stapler staple "${DMG_PATH}"; then
        echo -e "${GREEN}✅ Notarization ticket stapled${NC}"
    else
        echo -e "${YELLOW}⚠️  Could not staple ticket (non-critical)${NC}"
    fi
    
    echo -e "\n${GREEN}🎉 SUCCESS - Your app is notarized and ready for distribution!${NC}"
    exit 0
else
    echo -e "${RED}❌ Notarization REJECTED${NC}"
    
    # Extract submission ID for log fetch
    SUBMISSION_ID=$(echo "$NOTARIZE_OUTPUT" | awk '/  id:/{print $2; exit}')
    
    if [[ -n "${SUBMISSION_ID}" ]]; then
        echo -e "\n${BLUE}Step 5: Fetching notarization log (ID: ${SUBMISSION_ID})...${NC}"
        
        LOG_OUTPUT=$(xcrun notarytool log "${SUBMISSION_ID}" \
            --apple-id "$NOTARIZATION_APPLE_ID" \
            --team-id "$NOTARIZATION_TEAM_ID" \
            --password "$NOTARIZATION_PWD" 2>&1)
        
        echo "$LOG_OUTPUT"
        
        # Count and display first errors
        ERROR_COUNT=$(echo "$LOG_OUTPUT" | grep -c '"severity":"error"' || true)
        echo -e "\n${RED}Total errors: ${ERROR_COUNT}${NC}"
        
        # Show first few error messages
        echo -e "\n${YELLOW}First 10 errors:${NC}"
        echo "$LOG_OUTPUT" | grep '"message"' | head -10
    fi
    
    exit 1
fi
