#!/bin/bash

# One-command full test suite for production deployment
# Usage: ./run-full-test.sh [instances] [concurrent] [total_requests] [duration]

set -euo pipefail

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

INSTANCES="${1:-10}"
CONCURRENT="${2:-200}"
TOTAL="${3:-20000}"
DURATION="${4:-120}"

echo -e "${CYAN}"
cat << "EOF"
╔════════════════════════════════════════════════════════════╗
║                                                            ║
║     FULL PRODUCTION TEST SUITE                             ║
║     Build → Deploy → Scale → Load Test → Report           ║
║                                                            ║
╚════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}\n"

# Step 1: Build
echo -e "${YELLOW}[1/6] Building production image with consistent build ID...${NC}"
./scripts/build-production.sh > /dev/null 2>&1 || {
    echo -e "${RED}Build failed!${NC}"
    exit 1
}
echo -e "${GREEN}✓ Build complete${NC}\n"

# Step 2: Start services
echo -e "${YELLOW}[2/6] Starting services...${NC}"
docker-compose -f docker-compose.prod.yml up -d 2>&1 | tail -3
echo -e "${GREEN}✓ Services started${NC}\n"

# Step 3: Scale
echo -e "${YELLOW}[3/6] Scaling to ${INSTANCES} instances...${NC}"
docker-compose -f docker-compose.prod.yml up -d --scale app=${INSTANCES} --no-recreate 2>&1 | tail -3

# Wait for health
echo -n "  Waiting for containers to be healthy"
for i in {1..30}; do
    healthy=$(docker-compose -f docker-compose.prod.yml ps app 2>/dev/null | grep -c "healthy\|Up" || echo "0")
    if [ "$healthy" -ge "$INSTANCES" ]; then
        echo -e "\n${GREEN}✓ All ${INSTANCES} instances healthy${NC}\n"
        break
    fi
    echo -n "."
    sleep 2
done

# Step 4: Quick health check
echo -e "${YELLOW}[4/6] Running health checks...${NC}"
if curl -sf http://localhost:3009/health > /dev/null; then
    echo -e "${GREEN}✓ Nginx: OK${NC}"
else
    echo -e "${RED}✗ Nginx: FAIL${NC}"
    exit 1
fi

if curl -sf http://localhost:3009/api/hello > /dev/null; then
    echo -e "${GREEN}✓ App API: OK${NC}"
else
    echo -e "${RED}✗ App API: FAIL${NC}"
    exit 1
fi
echo ""

# Step 5: Run load tests
echo -e "${YELLOW}[5/6] Running load tests...${NC}"
echo -e "  Instances: ${INSTANCES}"
echo -e "  Concurrent: ${CONCURRENT}"
echo -e "  Total Requests: ${TOTAL}"
echo -e "  Duration: ${DURATION}s"
echo ""

./scripts/stress-test.sh ${INSTANCES} ${CONCURRENT} ${TOTAL} ${DURATION}

# Step 6: Show summary
echo -e "\n${YELLOW}[6/6] Final System Status${NC}"
echo -e "${CYAN}════════════════════════════════════════════${NC}"

docker-compose -f docker-compose.prod.yml ps

echo -e "\n${CYAN}Resource Usage:${NC}"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" \
    $(docker-compose -f docker-compose.prod.yml ps -q) | head -15

echo -e "\n${GREEN}════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Full test suite completed!${NC}"
echo -e "${GREEN}════════════════════════════════════════════${NC}\n"

echo -e "Reports available in: ${CYAN}./load-test-results/${NC}"
echo -e "Latest report: ${CYAN}$(ls -t ./load-test-results/report_*.txt 2>/dev/null | head -1)${NC}\n"

echo -e "${YELLOW}Next commands:${NC}"
echo -e "  View logs:     ${CYAN}docker-compose -f docker-compose.prod.yml logs -f${NC}"
echo -e "  Stop services: ${CYAN}docker-compose -f docker-compose.prod.yml down${NC}"
echo -e "  Rebuild:       ${CYAN}docker-compose -f docker-compose.prod.yml build --no-cache${NC}"
echo ""

