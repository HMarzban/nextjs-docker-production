#!/bin/bash

# Build production image with consistent build ID
# Prevents version skew across horizontally scaled containers

set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${CYAN}Building Next.js production image...${NC}\n"

# Try to get git hash, fallback to timestamp
if command -v git &> /dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
    GIT_HASH=$(git rev-parse --short HEAD)
    BUILD_ID="build-${GIT_HASH}"
    echo -e "${GREEN}✓ Using git hash: ${GIT_HASH}${NC}"
else
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BUILD_ID="build-${TIMESTAMP}"
    GIT_HASH="no-git"
    echo -e "${YELLOW}⚠ No git repository, using timestamp: ${TIMESTAMP}${NC}"
fi

echo -e "${CYAN}Build ID: ${BUILD_ID}${NC}\n"

# Export for docker-compose
export BUILD_ID
export GIT_HASH

# Build
echo -e "${CYAN}Running docker-compose build...${NC}\n"
docker-compose -f docker-compose.prod.yml build

echo -e "\n${GREEN}✓ Build complete!${NC}"
echo -e "${GREEN}  Build ID: ${BUILD_ID}${NC}"
echo -e "${GREEN}  Git Hash: ${GIT_HASH}${NC}\n"

echo -e "${CYAN}Next steps:${NC}"
echo -e "  Start: ${YELLOW}docker-compose -f docker-compose.prod.yml up -d --scale app=10${NC}"
echo -e "  Test:  ${YELLOW}./stress-test.sh${NC}"
echo ""

