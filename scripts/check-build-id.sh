#!/bin/bash

# Script to check Build ID across all containers

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Build ID Verification                    ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}\n"

# Get all running app containers
CONTAINERS=($(docker compose -f docker-compose.prod.yml ps -q app 2>/dev/null))
CONTAINER_COUNT=${#CONTAINERS[@]}

if [ $CONTAINER_COUNT -eq 0 ]; then
    echo -e "${RED}❌ No app containers running!${NC}"
    echo -e "${YELLOW}Start with: docker compose -f docker-compose.prod.yml up -d --scale app=3${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found ${CONTAINER_COUNT} running containers${NC}\n"

# Check build ID from each container
echo -e "${BLUE}Build IDs by Container:${NC}"
echo -e "${BLUE}════════════════════════════════════════════${NC}"

# Collect build IDs
BUILD_ID_LIST=""
for container in "${CONTAINERS[@]}"; do
    SHORT_ID=$(echo $container | cut -c1-12)
    CONTAINER_NAME=$(docker inspect --format='{{.Name}}' $container | sed 's/\///')
    BUILD_ID=$(docker exec $container cat .next/BUILD_ID 2>/dev/null)
    
    if [ -n "$BUILD_ID" ]; then
        echo -e "${GREEN}✓${NC} $CONTAINER_NAME ($SHORT_ID): ${YELLOW}$BUILD_ID${NC}"
        BUILD_ID_LIST="${BUILD_ID_LIST}${BUILD_ID}\n"
    else
        echo -e "${RED}✗${NC} $CONTAINER_NAME ($SHORT_ID): ${RED}No BUILD_ID found${NC}"
    fi
done

echo ""

# Check consistency
UNIQUE_IDS=$(echo -e "$BUILD_ID_LIST" | grep -v '^$' | sort -u | wc -l)
if [ $UNIQUE_IDS -eq 1 ]; then
    CURRENT_BUILD_ID=$(docker exec ${CONTAINERS[0]} cat .next/BUILD_ID 2>/dev/null)
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   Result: ${GREEN}✓ CONSISTENT${CYAN}                      ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo -e "${GREEN}All ${CONTAINER_COUNT} containers use the same build ID:${NC}"
    echo -e "${YELLOW}${CURRENT_BUILD_ID}${NC}\n"
    
    # Extract git hash
    if [[ $CURRENT_BUILD_ID == build-* ]]; then
        GIT_HASH=$(echo $CURRENT_BUILD_ID | sed 's/build-//')
        echo -e "${BLUE}Git Commit:${NC} $GIT_HASH"
        echo -e "${BLUE}Check:${NC} git show $GIT_HASH --oneline -s"
    fi
    echo ""
    echo -e "${GREEN}✅ Production-ready! All containers serving same build.${NC}"
elif [ $UNIQUE_IDS -gt 1 ]; then
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   Result: ${RED}✗ INCONSISTENT${CYAN}                  ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo -e "${RED}⚠ WARNING: Found $UNIQUE_IDS different build IDs!${NC}\n"
    echo -e "${YELLOW}This can cause:${NC}"
    echo -e "  • Version skew between containers"
    echo -e "  • Unexpected behavior"
    echo -e "  • Cache misses"
    echo -e "  • Hard reloads\n"
    
    echo -e "${YELLOW}Fix:${NC}"
    echo -e "  1. Stop all containers: ${BLUE}docker compose -f docker-compose.prod.yml down${NC}"
    echo -e "  2. Remove old images:   ${BLUE}docker rmi nextjs-app:latest${NC}"
    echo -e "  3. Build fresh:         ${BLUE}./scripts/build-production.sh${NC}"
    echo -e "  4. Start:               ${BLUE}docker compose -f docker-compose.prod.yml up -d --scale app=10${NC}"
else
    echo -e "${RED}❌ No valid build IDs found${NC}"
fi

echo ""

