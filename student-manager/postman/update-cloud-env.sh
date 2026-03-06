#!/bin/bash

# =============================================================================
# Update Cloud Postman Environment from BTP VCAP_SERVICES
# =============================================================================
# 
# This script extracts XSUAA credentials from Cloud Foundry environment
# and updates the Cloud.postman_environment.json file.
#
# Usage:
#   ./update-cloud-env.sh [app-name]
#
# Example:
#   ./update-cloud-env.sh student-manager-srv
#
# Requirements:
#   - CF CLI installed and logged in
#   - jq installed (brew install jq)
#   - Application deployed to Cloud Foundry
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default app name
DEFAULT_APP_NAME="student-manager-srv"
APP_NAME="${1:-$DEFAULT_APP_NAME}"

# Output file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/Cloud.postman_environment.json"

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Update Cloud Postman Environment${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo -e "${RED}Error: jq is not installed${NC}"
    echo "Install with: brew install jq"
    exit 1
fi

# Check if cf is installed
if ! command -v cf &> /dev/null; then
    echo -e "${RED}Error: CF CLI is not installed${NC}"
    exit 1
fi

# Check if logged in to CF
if ! cf target &> /dev/null; then
    echo -e "${RED}Error: Not logged in to Cloud Foundry${NC}"
    echo "Run: cf login"
    exit 1
fi

echo -e "App name: ${GREEN}$APP_NAME${NC}"
echo ""

# Get app URL
echo -e "${YELLOW}Getting application URL...${NC}"
APP_URL=$(cf app "$APP_NAME" | grep "routes:" | awk '{print $2}')

if [ -z "$APP_URL" ]; then
    echo -e "${RED}Error: Could not get app URL${NC}"
    exit 1
fi

# Add https:// prefix if not present
if [[ ! "$APP_URL" =~ ^https?:// ]]; then
    APP_URL="https://$APP_URL"
fi

echo -e "App URL: ${GREEN}$APP_URL${NC}"

# Get VCAP_SERVICES
echo -e "${YELLOW}Getting VCAP_SERVICES...${NC}"
VCAP_SERVICES=$(cf env "$APP_NAME" | sed -n '/VCAP_SERVICES/,/^$/p' | tail -n +2)

# Try to extract XSUAA credentials
# First, try to get the full JSON
FULL_ENV=$(cf env "$APP_NAME" --output json 2>/dev/null || echo "")

if [ -n "$FULL_ENV" ] && [ "$FULL_ENV" != "" ]; then
    # CF CLI v8+ supports --output json
    XSUAA_URL=$(echo "$FULL_ENV" | jq -r '.SystemEnvJson.VCAP_SERVICES.xsuaa[0].credentials.url // empty' 2>/dev/null)
    CLIENT_ID=$(echo "$FULL_ENV" | jq -r '.SystemEnvJson.VCAP_SERVICES.xsuaa[0].credentials.clientid // empty' 2>/dev/null)
    CLIENT_SECRET=$(echo "$FULL_ENV" | jq -r '.SystemEnvJson.VCAP_SERVICES.xsuaa[0].credentials.clientsecret // empty' 2>/dev/null)
fi

# If that didn't work, parse the text output
if [ -z "$XSUAA_URL" ] || [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ]; then
    echo -e "${YELLOW}Parsing VCAP_SERVICES from text output...${NC}"
    
    # Get raw environment and extract JSON
    RAW_ENV=$(cf env "$APP_NAME" 2>/dev/null)
    
    # Extract the JSON block after "VCAP_SERVICES:" 
    VCAP_JSON=$(echo "$RAW_ENV" | awk '/^VCAP_SERVICES:/{flag=1; next} flag && /^[A-Z_]+:/{flag=0} flag' | tr -d '\n')
    
    if [ -n "$VCAP_JSON" ]; then
        XSUAA_URL=$(echo "$VCAP_JSON" | jq -r '.xsuaa[0].credentials.url // empty' 2>/dev/null)
        CLIENT_ID=$(echo "$VCAP_JSON" | jq -r '.xsuaa[0].credentials.clientid // empty' 2>/dev/null)
        CLIENT_SECRET=$(echo "$VCAP_JSON" | jq -r '.xsuaa[0].credentials.clientsecret // empty' 2>/dev/null)
    fi
fi

# Check if we got the credentials
if [ -z "$XSUAA_URL" ] || [ -z "$CLIENT_ID" ] || [ -z "$CLIENT_SECRET" ]; then
    echo -e "${RED}Error: Could not extract XSUAA credentials${NC}"
    echo ""
    echo "Please manually extract credentials from:"
    echo "  cf env $APP_NAME"
    echo ""
    echo "Look for VCAP_SERVICES -> xsuaa -> credentials and copy:"
    echo "  - url -> xsuaaUrl"
    echo "  - clientid -> clientId"
    echo "  - clientsecret -> clientSecret"
    exit 1
fi

echo -e "XSUAA URL: ${GREEN}$XSUAA_URL${NC}"
echo -e "Client ID: ${GREEN}$CLIENT_ID${NC}"
echo -e "Client Secret: ${GREEN}[extracted]${NC}"
echo ""

# Update the Postman environment file
echo -e "${YELLOW}Updating $ENV_FILE...${NC}"

if [ ! -f "$ENV_FILE" ]; then
    echo -e "${RED}Error: Environment file not found: $ENV_FILE${NC}"
    exit 1
fi

# Create updated JSON
jq --arg baseUrl "$APP_URL" \
   --arg xsuaaUrl "$XSUAA_URL" \
   --arg clientId "$CLIENT_ID" \
   --arg clientSecret "$CLIENT_SECRET" \
   '(.values[] | select(.key == "baseUrl") | .value) = $baseUrl |
    (.values[] | select(.key == "xsuaaUrl") | .value) = $xsuaaUrl |
    (.values[] | select(.key == "clientId") | .value) = $clientId |
    (.values[] | select(.key == "clientSecret") | .value) = $clientSecret' \
   "$ENV_FILE" > "$ENV_FILE.tmp" && mv "$ENV_FILE.tmp" "$ENV_FILE"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}✓ Cloud environment updated successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Updated values:"
echo -e "  baseUrl:      ${GREEN}$APP_URL${NC}"
echo -e "  xsuaaUrl:     ${GREEN}$XSUAA_URL${NC}"
echo -e "  clientId:     ${GREEN}$CLIENT_ID${NC}"
echo -e "  clientSecret: ${GREEN}[set]${NC}"
echo ""
echo "Next steps:"
echo "  1. Import/refresh the Cloud environment in Postman"
echo "  2. Run 'Get OAuth2 Token' request to authenticate"
echo "  3. Test the API endpoints"