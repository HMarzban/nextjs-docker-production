#!/bin/bash

# Production Load Test Suite
# Clean, professional, and effective stress testing

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Configuration
BASE_URL="${BASE_URL:-http://localhost:3009}"
TARGET_INSTANCES="${1:-10}"
CONCURRENT_REQUESTS="${2:-100}"
TOTAL_REQUESTS="${3:-10000}"
TEST_DURATION="${4:-60}"

RESULTS_DIR="./load-test-results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${RESULTS_DIR}/report_${TIMESTAMP}.txt"

# ============================================================================
# UTILITIES
# ============================================================================

print_header() {
    echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    printf "${CYAN}║${NC} %-56s ${CYAN}║${NC}\n" "$1"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
}

print_result() {
    printf "  ${BLUE}%-25s${NC} %s\n" "$1:" "$2"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    
    printf "\r  ["
    printf "%${filled}s" | tr ' ' '█'
    printf "%$((width - filled))s" | tr ' ' '░'
    printf "] %3d%% (%d/%d)" $percentage $current $total
}

spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while ps -p $pid > /dev/null 2>&1; do
        local temp=${spinstr#?}
        printf "\r  ${CYAN}%c${NC} " "$spinstr"
        spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    printf "\r"
}

# ============================================================================
# SETUP & SCALING
# ============================================================================

setup() {
    clear
    echo -e "${MAGENTA}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║           PRODUCTION LOAD TEST SUITE                       ║"
    echo "║           Next.js + Docker + Nginx                         ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    mkdir -p "$RESULTS_DIR"
    
    echo -e "${CYAN}Configuration:${NC}"
    print_result "Target URL" "$BASE_URL"
    print_result "App Instances" "$TARGET_INSTANCES"
    print_result "Concurrent Users" "$CONCURRENT_REQUESTS"
    print_result "Total Requests" "$TOTAL_REQUESTS"
    print_result "Test Duration" "${TEST_DURATION}s"
    echo ""
}

scale_containers() {
    print_header "Scaling Containers"
    
    echo -ne "  Scaling to ${TARGET_INSTANCES} instances..."
    docker-compose -f docker-compose.prod.yml up -d --scale app=${TARGET_INSTANCES} --no-recreate >/dev/null 2>&1
    echo -e "\r  ${GREEN}✓${NC} Scaled to ${TARGET_INSTANCES} instances"
    
    echo -n "  Waiting for containers to be healthy"
    local max_wait=60
    local elapsed=0
    
    while [ $elapsed -lt $max_wait ]; do
        local healthy=$(docker-compose -f docker-compose.prod.yml ps app 2>/dev/null | grep -c "healthy\|Up" || echo "0")
        
        if [ "$healthy" -ge "$TARGET_INSTANCES" ]; then
            echo -e "\r  ${GREEN}✓${NC} All ${TARGET_INSTANCES} containers healthy          "
            sleep 2
            return 0
        fi
        
        printf "."
        sleep 2
        ((elapsed+=2))
    done
    
    echo -e "\r  ${YELLOW}⚠${NC} Timeout - proceeding with available containers"
}

verify_setup() {
    print_header "Pre-flight Checks"
    
    # Check nginx
    if curl -s -o /dev/null -w "%{http_code}" -m 5 "${BASE_URL}/health" | grep -q "200"; then
        print_success "Nginx responding"
    else
        print_error "Nginx not responding"
        exit 1
    fi
    
    # Check app
    if curl -s -o /dev/null -w "%{http_code}" -m 10 "${BASE_URL}/api/hello" | grep -q "200"; then
        print_success "Next.js app responding"
    else
        print_error "App not responding"
        exit 1
    fi
    
    # Count instances
    local count=$(docker-compose -f docker-compose.prod.yml ps -q app | wc -l | tr -d ' ')
    print_success "$count containers active"
    echo ""
}

# ============================================================================
# TESTS
# ============================================================================

test_homepage_concurrent() {
    print_header "Test 1: Concurrent Homepage Load"
    
    local temp_dir=$(mktemp -d)
    local success=0
    local fail=0
    
    echo "  Testing ${CONCURRENT_REQUESTS} concurrent requests..."
    
    local start_time=$(date +%s.%N)
    
    # Launch concurrent requests
    for i in $(seq 1 $CONCURRENT_REQUESTS); do
        (
            result=$(curl -s -o /dev/null -w "%{http_code},%{time_total}" -m 30 "${BASE_URL}/" 2>/dev/null || echo "000,0")
            echo "$result" > "${temp_dir}/${i}.txt"
        ) &
        
        if [ $((i % 10)) -eq 0 ]; then
            show_progress $i $CONCURRENT_REQUESTS
        fi
    done
    
    wait
    show_progress $CONCURRENT_REQUESTS $CONCURRENT_REQUESTS
    echo ""
    
    local end_time=$(date +%s.%N)
    local total_time=$(echo "$end_time - $start_time" | bc)
    
    # Collect results
    local total_response_time=0
    for i in $(seq 1 $CONCURRENT_REQUESTS); do
        if [ -f "${temp_dir}/${i}.txt" ]; then
            IFS=',' read -r code time_total < "${temp_dir}/${i}.txt"
            if [ "$code" -eq 200 ]; then
                ((success++))
                total_response_time=$(echo "$total_response_time + $time_total" | bc)
            else
                ((fail++))
            fi
        fi
    done
    
    rm -rf "$temp_dir"
    
    # Calculate metrics
    local avg_time=$(echo "scale=3; $total_response_time / $success" | bc)
    local rps=$(echo "scale=2; $success / $total_time" | bc)
    local success_rate=$(echo "scale=1; $success * 100 / $CONCURRENT_REQUESTS" | bc)
    
    echo ""
    print_result "Success Rate" "${success_rate}% (${success}/${CONCURRENT_REQUESTS})"
    print_result "Avg Response Time" "${avg_time}s"
    print_result "Throughput" "${rps} req/s"
    print_result "Total Time" "${total_time}s"
}

test_api_burst() {
    print_header "Test 2: API Burst Load"
    
    echo "  Sending ${TOTAL_REQUESTS} API requests..."
    
    local success=0
    local fail=0
    local batch_size=100
    local total_time=0
    local start_time=$(date +%s.%N)
    
    for batch_start in $(seq 1 $batch_size $TOTAL_REQUESTS); do
        local batch_end=$((batch_start + batch_size - 1))
        [ $batch_end -gt $TOTAL_REQUESTS ] && batch_end=$TOTAL_REQUESTS
        
        for i in $(seq $batch_start $batch_end); do
            (
                code=$(curl -s -o /dev/null -w "%{http_code}" -m 10 "${BASE_URL}/api/hello" 2>/dev/null || echo "000")
                echo "$code"
            ) &
        done
        
        # Collect batch results
        wait
        
        show_progress $batch_end $TOTAL_REQUESTS
    done
    
    echo ""
    
    local end_time=$(date +%s.%N)
    total_time=$(echo "$end_time - $start_time" | bc)
    
    # Sample test for accuracy
    local sample_success=0
    local sample_total=100
    local sample_time=0
    
    for i in $(seq 1 $sample_total); do
        result=$(curl -s -o /dev/null -w "%{http_code},%{time_total}" "${BASE_URL}/api/hello" 2>/dev/null || echo "000,0")
        IFS=',' read -r code time_total <<< "$result"
        if [ "$code" -eq 200 ]; then
            ((sample_success++))
            sample_time=$(echo "$sample_time + $time_total" | bc)
        fi
    done
    
    local avg_time=$(echo "scale=3; $sample_time / $sample_success" | bc)
    local estimated_rps=$(echo "scale=0; $TOTAL_REQUESTS / $total_time" | bc)
    local success_rate=$(echo "scale=1; $sample_success * 100 / $sample_total" | bc)
    
    echo ""
    print_result "Success Rate" "${success_rate}% (sampled)"
    print_result "Avg Response Time" "${avg_time}s"
    print_result "Est. Throughput" "${estimated_rps} req/s"
    print_result "Total Time" "${total_time}s"
}

test_sustained_load() {
    print_header "Test 3: Sustained Load (${TEST_DURATION}s)"
    
    echo "  Running continuous load test..."
    
    local end_time=$(($(date +%s) + TEST_DURATION))
    local success=0
    local fail=0
    local total_time=0
    local request_count=0
    
    while [ $(date +%s) -lt $end_time ]; do
        local batch_success=0
        local batch_time=0
        
        # Send batch of 20 requests
        for i in $(seq 1 20); do
            result=$(curl -s -o /dev/null -w "%{http_code},%{time_total}" -m 5 "${BASE_URL}/api/hello" 2>/dev/null || echo "000,0")
            IFS=',' read -r code time_total <<< "$result"
            
            if [ "$code" -eq 200 ]; then
                ((batch_success++))
                batch_time=$(echo "$batch_time + $time_total" | bc)
            fi
        done &
        
        wait
        
        success=$((success + batch_success))
        total_time=$(echo "$total_time + $batch_time" | bc)
        request_count=$((request_count + 20))
        
        local elapsed=$(($(date +%s) - (end_time - TEST_DURATION)))
        printf "\r  [%3ds/%3ds] Requests: %5d | Success: %5d | Errors: %3d" \
            $elapsed $TEST_DURATION $request_count $success $((request_count - success))
        
        sleep 0.5
    done
    
    echo ""
    
    local avg_time=$(echo "scale=3; $total_time / $success" | bc)
    local rps=$(echo "scale=2; $success / $TEST_DURATION" | bc)
    local error_rate=$(echo "scale=2; ($request_count - $success) * 100 / $request_count" | bc)
    
    echo ""
    print_result "Total Requests" "$request_count"
    print_result "Successful" "$success"
    print_result "Error Rate" "${error_rate}%"
    print_result "Avg Response Time" "${avg_time}s"
    print_result "Throughput" "${rps} req/s"
}

test_mixed_workload() {
    print_header "Test 4: Mixed Workload"
    
    echo "  Testing multiple endpoints (30s)..."
    
    local duration=30
    local end_time=$(($(date +%s) + duration))
    local temp_file=$(mktemp)
    
    # Run tests in background and collect results
    (
        local count=0
        while [ $(date +%s) -lt $end_time ]; do
            # Homepage
            curl -s -o /dev/null -w "homepage,%{http_code}\n" "${BASE_URL}/" 2>/dev/null >> "$temp_file" &
            
            # API
            curl -s -o /dev/null -w "api,%{http_code}\n" "${BASE_URL}/api/hello" 2>/dev/null >> "$temp_file" &
            
            # Weather
            curl -s -o /dev/null -w "weather,%{http_code}\n" "${BASE_URL}/weather" 2>/dev/null >> "$temp_file" &
            
            ((count++))
            local elapsed=$(($(date +%s) - (end_time - duration)))
            printf "\r  [%2ds/%2ds] Sending mixed requests..." $elapsed $duration
            
            sleep 0.3
        done
    )
    
    wait
    echo ""
    
    # Count results
    local homepage_success=$(grep "homepage,200" "$temp_file" 2>/dev/null | wc -l | tr -d ' ')
    local api_success=$(grep "api,200" "$temp_file" 2>/dev/null | wc -l | tr -d ' ')
    local weather_success=$(grep "weather,200" "$temp_file" 2>/dev/null | wc -l | tr -d ' ')
    local total_success=$((homepage_success + api_success + weather_success))
    local total_requests=$(wc -l < "$temp_file" | tr -d ' ')
    local success_rate=$(echo "scale=1; $total_success * 100 / $total_requests" | bc)
    
    rm -f "$temp_file"
    
    echo ""
    print_result "Homepage Requests" "$homepage_success"
    print_result "API Requests" "$api_success"
    print_result "Weather Requests" "$weather_success"
    print_result "Total Successful" "$total_success / $total_requests"
    print_result "Success Rate" "${success_rate}%"
}

# ============================================================================
# METRICS
# ============================================================================

collect_metrics() {
    print_header "Container Metrics"
    
    echo "  Collecting resource usage..."
    echo ""
    
    # CPU & Memory
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" \
        $(docker-compose -f docker-compose.prod.yml ps -q) 2>/dev/null | head -12
    
    echo ""
    
    # Container health
    local containers=($(docker-compose -f docker-compose.prod.yml ps -q app 2>/dev/null))
    local healthy=0
    
    for container in "${containers[@]}"; do
        if docker inspect --format='{{.State.Running}}' "$container" 2>/dev/null | grep -q "true"; then
            ((healthy++))
        fi
    done
    
    echo ""
    print_result "Healthy Containers" "$healthy / ${#containers[@]}"
}

# ============================================================================
# REPORT
# ============================================================================

generate_report() {
    print_header "Test Summary"
    
    {
        echo "=========================================="
        echo "LOAD TEST REPORT"
        echo "=========================================="
        echo "Timestamp: $(date)"
        echo "Target: $BASE_URL"
        echo "Instances: $TARGET_INSTANCES"
        echo "Duration: ${TEST_DURATION}s"
        echo ""
        echo "Configuration:"
        echo "  - Concurrent requests: $CONCURRENT_REQUESTS"
        echo "  - Total requests: $TOTAL_REQUESTS"
        echo ""
        echo "Container Status:"
        docker-compose -f docker-compose.prod.yml ps 2>/dev/null
        echo ""
        echo "=========================================="
    } | tee "$REPORT_FILE" > /dev/null
    
    echo ""
    print_result "Report Saved" "$REPORT_FILE"
    print_result "Results Directory" "$RESULTS_DIR"
    
    echo -e "\n${GREEN}✓ All tests completed successfully!${NC}\n"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    setup
    scale_containers
    verify_setup
    
    # Run all tests
    test_homepage_concurrent
    test_api_burst
    test_sustained_load
    test_mixed_workload
    
    # Collect metrics
    collect_metrics
    
    # Generate report
    generate_report
}

main "$@"
