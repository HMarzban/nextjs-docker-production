#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Next.js Connection Debugger              ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}\n"

BASE_URL="http://localhost:3009"

# 1. Check if nginx is listening
echo -e "${YELLOW}[1/8] Checking nginx port binding...${NC}"
NGINX_PORT=$(docker-compose -f docker-compose.prod.yml ps nginx | grep "3009" | wc -l)
if [ $NGINX_PORT -gt 0 ]; then
    echo -e "${GREEN}✓ Nginx is bound to port 3009${NC}"
    netstat -an | grep 3009 || ss -tln | grep 3009
else
    echo -e "${RED}✗ Nginx NOT bound to port 3009${NC}"
fi
echo ""

# 2. Test nginx directly
echo -e "${YELLOW}[2/8] Testing nginx health endpoint...${NC}"
HEALTH_CODE=$(curl -s -o /dev/null -w "%{http_code}" -m 5 ${BASE_URL}/health)
echo -e "  HTTP Status: $HEALTH_CODE"
if [ "$HEALTH_CODE" -eq 200 ]; then
    echo -e "${GREEN}✓ Nginx responding to /health${NC}"
else
    echo -e "${RED}✗ Nginx health check failed${NC}"
fi
echo ""

# 3. Test Next.js API endpoint (lightweight)
echo -e "${YELLOW}[3/8] Testing Next.js API endpoint...${NC}"
API_CODE=$(curl -s -o /dev/null -w "%{http_code}" -m 10 ${BASE_URL}/api/hello)
echo -e "  HTTP Status: $API_CODE"
if [ "$API_CODE" -eq 200 ]; then
    echo -e "${GREEN}✓ Next.js API responding${NC}"
    curl -s ${BASE_URL}/api/hello | jq '.' 2>/dev/null || curl -s ${BASE_URL}/api/hello
else
    echo -e "${RED}✗ Next.js API not responding${NC}"
fi
echo ""

# 4. Test homepage with verbose output
echo -e "${YELLOW}[4/8] Testing homepage with details...${NC}"
echo -e "  Running: curl -v -m 30 ${BASE_URL}/ 2>&1 | head -30\n"

HOMEPAGE_OUTPUT=$(curl -v -m 30 ${BASE_URL}/ 2>&1 | head -40)
echo "$HOMEPAGE_OUTPUT"

HTTP_CODE=$(echo "$HOMEPAGE_OUTPUT" | grep "< HTTP" | awk '{print $3}')
echo -e "\n  ${BLUE}HTTP Response Code: ${HTTP_CODE:-NONE}${NC}"

if echo "$HOMEPAGE_OUTPUT" | grep -q "Connection timed out"; then
    echo -e "${RED}✗ CONNECTION TIMEOUT - Next.js not responding!${NC}"
elif echo "$HOMEPAGE_OUTPUT" | grep -q "200 OK"; then
    echo -e "${GREEN}✓ Got 200 OK but page may be loading forever${NC}"
else
    echo -e "${YELLOW}⚠ Unexpected response${NC}"
fi
echo ""

# 5. Check app container logs for errors
echo -e "${YELLOW}[5/8] Checking app container logs (last 30 lines)...${NC}"
echo -e "${CYAN}────────────────────────────────────────────${NC}"
docker-compose -f docker-compose.prod.yml logs --tail=30 app | grep -v "Attention:" | tail -20
echo -e "${CYAN}────────────────────────────────────────────${NC}\n"

# 6. Check nginx logs
echo -e "${YELLOW}[6/8] Checking nginx error logs...${NC}"
echo -e "${CYAN}────────────────────────────────────────────${NC}"
docker-compose -f docker-compose.prod.yml logs --tail=20 nginx | grep -i "error\|warn\|timeout" || echo "  No errors found in nginx logs"
echo -e "${CYAN}────────────────────────────────────────────${NC}\n"

# 7. Check if Next.js is actually building/serving properly
echo -e "${YELLOW}[7/8] Testing direct container access (bypassing nginx)...${NC}"
APP_CONTAINER=$(docker-compose -f docker-compose.prod.yml ps -q app | head -1)
if [ -n "$APP_CONTAINER" ]; then
    echo "  Trying to access app container directly on port 3000..."
    DIRECT_CODE=$(docker exec $APP_CONTAINER wget -q -O- --timeout=5 http://localhost:3000/api/hello 2>&1)
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ App container responds directly${NC}"
        echo "$DIRECT_CODE" | head -5
    else
        echo -e "${RED}✗ App container NOT responding on port 3000${NC}"
        echo "  This means Next.js isn't starting properly!"
    fi
else
    echo -e "${RED}✗ No app container found${NC}"
fi
echo ""

# 8. Check for common issues
echo -e "${YELLOW}[8/8] Checking for common issues...${NC}"

# Check if standalone build exists
STANDALONE_CHECK=$(docker-compose -f docker-compose.prod.yml exec -T app ls -la /app/server.js 2>&1)
if echo "$STANDALONE_CHECK" | grep -q "server.js"; then
    echo -e "${GREEN}✓ server.js exists in container${NC}"
else
    echo -e "${RED}✗ server.js NOT FOUND - standalone build failed!${NC}"
fi

# Check Next.js config
echo -e "\n${CYAN}╔════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Diagnosis & Solutions                    ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}\n"

# Analyze results
if [ "$API_CODE" -eq 200 ] && [ "$HTTP_CODE" != "200" ]; then
    echo -e "${RED}ISSUE FOUND:${NC} API works but homepage doesn't load\n"
    echo -e "${YELLOW}Possible causes:${NC}"
    echo "  1. Missing 'output: standalone' in next.config.js"
    echo "  2. Build didn't include homepage properly"
    echo "  3. Static files not copied correctly"
    echo "  4. CSP/CORS blocking resources"
    echo ""
    echo -e "${GREEN}Solutions:${NC}"
    echo "  → Check next.config.mjs has: output: 'standalone'"
    echo "  → Rebuild: docker-compose -f docker-compose.prod.yml build --no-cache"
    echo "  → Check browser console for errors (F12)"
    
elif [ "$API_CODE" -ne 200 ]; then
    echo -e "${RED}ISSUE FOUND:${NC} Next.js not responding at all\n"
    echo -e "${YELLOW}Possible causes:${NC}"
    echo "  1. Next.js server crashed on startup"
    echo "  2. Port 3000 not exposed properly"
    echo "  3. server.js missing (build failed)"
    echo ""
    echo -e "${GREEN}Solutions:${NC}"
    echo "  → Check logs: docker-compose -f docker-compose.prod.yml logs app"
    echo "  → Verify build: docker-compose -f docker-compose.prod.yml exec app ls -la /app"
    echo "  → Rebuild from scratch: docker-compose -f docker-compose.prod.yml build --no-cache"
    
else
    echo -e "${YELLOW}Complex issue - page starts loading but never finishes${NC}\n"
    echo -e "${YELLOW}Possible causes:${NC}"
    echo "  1. Next.js trying to load resources that timeout"
    echo "  2. WebSocket connection hanging"
    echo "  3. Infinite loading state in React"
    echo "  4. Missing static files (CSS/JS)"
    echo ""
    echo -e "${GREEN}Solutions:${NC}"
    echo "  → Open browser DevTools (F12) and check:"
    echo "     • Console tab for errors"
    echo "     • Network tab for failed/pending requests"
    echo "  → Check if /_next/static files are loading"
fi

echo ""
echo -e "${CYAN}Quick commands to try:${NC}"
echo "  # Watch live logs"
echo "  docker-compose -f docker-compose.prod.yml logs -f app"
echo ""
echo "  # Check browser console"
echo "  # Press F12 → Console tab"
echo ""
echo "  # Test specific resources"
echo "  curl -I ${BASE_URL}/_next/static/"
echo ""
echo "  # Rebuild everything"
echo "  docker-compose -f docker-compose.prod.yml down && docker-compose -f docker-compose.prod.yml build --no-cache && docker-compose -f docker-compose.prod.yml up -d --scale app=3"
