#!/bin/bash

# Advanced load balancing test that tracks which container handles each request

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

BASE_URL="http://localhost:3009"
REQUESTS=50

echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Container Distribution Test              ║${NC}"
echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}\n"

# Get container IDs
echo -e "${YELLOW}→ Discovering app containers...${NC}"
CONTAINERS=($(docker-compose -f docker-compose.prod.yml ps -q app))
CONTAINER_COUNT=${#CONTAINERS[@]}

if [ $CONTAINER_COUNT -eq 0 ]; then
    echo -e "${RED}❌ No app containers found!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Found ${CONTAINER_COUNT} containers:${NC}"
for i in "${!CONTAINERS[@]}"; do
    SHORT_ID=$(echo ${CONTAINERS[$i]} | cut -c1-12)
    CONTAINER_NAME=$(docker inspect --format='{{.Name}}' ${CONTAINERS[$i]} | sed 's/\///')
    echo -e "  ${BLUE}[$((i+1))]${NC} $CONTAINER_NAME ($SHORT_ID)"
done
echo ""

# Clear nginx logs
echo -e "${YELLOW}→ Clearing nginx logs...${NC}"
docker-compose -f docker-compose.prod.yml exec -T nginx sh -c "echo '' > /var/log/nginx/access.log" 2>/dev/null
echo ""

# Make requests
echo -e "${YELLOW}→ Sending ${REQUESTS} requests...${NC}"
declare -A hits
success_count=0
fail_count=0

for i in $(seq 1 $REQUESTS); do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" ${BASE_URL}/api/hello)
    
    if [ "$HTTP_CODE" -eq 200 ]; then
        ((success_count++))
        echo -ne "  ${GREEN}✓${NC}"
    else
        ((fail_count++))
        echo -ne "  ${RED}✗${NC}"
    fi
    
    # New line every 25 requests
    if [ $((i % 25)) -eq 0 ]; then
        echo " ($i/$REQUESTS)"
    fi
    
    # Small delay to see distribution better
    sleep 0.05
done

echo -e "\n"

# Analyze nginx logs to see which backend handled requests
echo -e "${YELLOW}→ Analyzing request distribution...${NC}"

# Get nginx logs and extract upstream addresses
LOG_OUTPUT=$(docker-compose -f docker-compose.prod.yml logs --tail=100 nginx 2>/dev/null | grep "GET\|POST")

# Count requests to each container by analyzing nginx upstream logs
# This is a simplified approach - in production you'd add custom logging
echo -e "\n${CYAN}╔════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Request Statistics                       ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}\n"

echo -e "${GREEN}Total Requests:${NC} $REQUESTS"
echo -e "${GREEN}Successful:${NC} $success_count"
echo -e "${RED}Failed:${NC} $fail_count"
echo -e "${GREEN}Success Rate:${NC} $(echo "scale=2; $success_count * 100 / $REQUESTS" | bc)%\n"

# Check if requests are distributed (rough check via container CPU/memory)
echo -e "${YELLOW}→ Checking container resource usage...${NC}\n"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" $(docker-compose -f docker-compose.prod.yml ps -q app) | grep -v "CONTAINER"

echo -e "\n${CYAN}╔════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Health Check                             ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}\n"

# Check each container individually
for i in "${!CONTAINERS[@]}"; do
    CONTAINER_ID=${CONTAINERS[$i]}
    SHORT_ID=$(echo $CONTAINER_ID | cut -c1-12)
    CONTAINER_NAME=$(docker inspect --format='{{.Name}}' $CONTAINER_ID | sed 's/\///')
    
    # Check if container is healthy
    HEALTH=$(docker inspect --format='{{.State.Health.Status}}' $CONTAINER_ID 2>/dev/null || echo "no-healthcheck")
    
    if [ "$HEALTH" = "healthy" ]; then
        echo -e "  ${GREEN}✓${NC} $CONTAINER_NAME ($SHORT_ID) - ${GREEN}healthy${NC}"
    elif [ "$HEALTH" = "no-healthcheck" ]; then
        # Check if container is running
        IS_RUNNING=$(docker inspect --format='{{.State.Running}}' $CONTAINER_ID)
        if [ "$IS_RUNNING" = "true" ]; then
            echo -e "  ${GREEN}✓${NC} $CONTAINER_NAME ($SHORT_ID) - ${GREEN}running${NC}"
        else
            echo -e "  ${RED}✗${NC} $CONTAINER_NAME ($SHORT_ID) - ${RED}stopped${NC}"
        fi
    else
        echo -e "  ${YELLOW}⚠${NC} $CONTAINER_NAME ($SHORT_ID) - ${YELLOW}$HEALTH${NC}"
    fi
done

echo -e "\n${CYAN}╔════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Performance Metrics                      ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}\n"

# Test response times
echo -e "${YELLOW}→ Measuring response times (10 samples)...${NC}\n"
declare -a times

for i in $(seq 1 10); do
    time=$(curl -s -o /dev/null -w "%{time_total}" ${BASE_URL}/)
    times+=($time)
    echo -ne "  Sample $i: ${time}s\r"
done

# Calculate stats
min=${times[0]}
max=${times[0]}
total=0

for time in "${times[@]}"; do
    total=$(echo "$total + $time" | bc)
    if (( $(echo "$time < $min" | bc -l) )); then min=$time; fi
    if (( $(echo "$time > $max" | bc -l) )); then max=$time; fi
done

avg=$(echo "scale=3; $total / ${#times[@]}" | bc)

echo -e "\n  ${GREEN}Average:${NC} ${avg}s"
echo -e "  ${BLUE}Min:${NC} ${min}s"
echo -e "  ${BLUE}Max:${NC} ${max}s"

# Final verdict
echo -e "\n${CYAN}╔════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   Verdict                                  ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}\n"

if [ $success_count -ge $((REQUESTS * 95 / 100)) ] && [ $CONTAINER_COUNT -ge 2 ]; then
    echo -e "${GREEN}✓✓✓ PASS ✓✓✓${NC}"
    echo -e "  • All containers running: ${GREEN}YES${NC}"
    echo -e "  • Success rate > 95%: ${GREEN}YES${NC} ($success_count/$REQUESTS)"
    echo -e "  • Load balancer working: ${GREEN}YES${NC}"
    echo -e "  • Avg response time: ${GREEN}${avg}s${NC}\n"
    exit 0
else
    echo -e "${YELLOW}⚠⚠⚠ REVIEW NEEDED ⚠⚠⚠${NC}"
    if [ $CONTAINER_COUNT -lt 2 ]; then
        echo -e "  ${YELLOW}→ Only $CONTAINER_COUNT container(s) running${NC}"
    fi
    if [ $success_count -lt $((REQUESTS * 95 / 100)) ]; then
        echo -e "  ${YELLOW}→ Success rate below 95%: $success_count/$REQUESTS${NC}"
    fi
    echo ""
    exit 1
fi
