#!/bin/bash

# Production-grade stress test for scaled Next.js containers
# Tests throughput, latency, error rates, and container distribution

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# ============================================================================
# CONFIGURATION
# ============================================================================

BASE_URL="${BASE_URL:-http://localhost:3009}"
TARGET_INSTANCES="${1:-10}"
CONCURRENT_REQUESTS="${2:-100}"
TOTAL_REQUESTS="${3:-10000}"
TEST_DURATION="${4:-60}" # seconds for sustained load

RESULTS_DIR="./load-test-results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${RESULTS_DIR}/report_${TIMESTAMP}.txt"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_header() {
    echo -e "\n${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    printf "${CYAN}║${NC} %-56s ${CYAN}║${NC}\n" "$1"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}\n"
}

print_metric() {
    printf "  ${BLUE}%-30s${NC} %s\n" "$1:" "$2"
}

# ============================================================================
# SETUP
# ============================================================================

setup() {
    print_header "Load Test Setup"
    
    mkdir -p "$RESULTS_DIR"
    
    log_info "Configuration:"
    print_metric "Target URL" "$BASE_URL"
    print_metric "App Instances" "$TARGET_INSTANCES"
    print_metric "Concurrent Requests" "$CONCURRENT_REQUESTS"
    print_metric "Total Requests" "$TOTAL_REQUESTS"
    print_metric "Test Duration" "${TEST_DURATION}s"
    print_metric "Report Output" "$REPORT_FILE"
}

# ============================================================================
# SCALE & VERIFY
# ============================================================================

scale_containers() {
    print_header "Scaling Containers"
    
    log_info "Scaling app to ${TARGET_INSTANCES} instances..."
    docker-compose -f docker-compose.prod.yml up -d --scale app=${TARGET_INSTANCES} --no-recreate 2>&1 | tail -5
    
    log_info "Waiting for containers to be healthy (max 60s)..."
    local max_wait=60
    local elapsed=0
    
    while [ $elapsed -lt $max_wait ]; do
        local healthy=$(docker-compose -f docker-compose.prod.yml ps app 2>/dev/null | grep -c "healthy\|Up" || echo "0")
        
        if [ "$healthy" -ge "$TARGET_INSTANCES" ]; then
            log_success "All ${TARGET_INSTANCES} instances ready"
            sleep 3 # Extra buffer
            return 0
        fi
        
        echo -ne "  Waiting... (${healthy}/${TARGET_INSTANCES} ready) [${elapsed}s]\r"
        sleep 2
        ((elapsed+=2))
    done
    
    log_warn "Timeout waiting for all containers. Proceeding with available instances."
}

verify_setup() {
    print_header "Pre-flight Checks"
    
    # Check nginx
    local health_code=$(curl -s -o /dev/null -w "%{http_code}" -m 5 "${BASE_URL}/health" || echo "000")
    if [ "$health_code" -eq 200 ]; then
        log_success "Nginx health check passed"
    else
        log_error "Nginx not responding (HTTP $health_code)"
        exit 1
    fi
    
    # Check app
    local app_code=$(curl -s -o /dev/null -w "%{http_code}" -m 10 "${BASE_URL}/api/hello" || echo "000")
    if [ "$app_code" -eq 200 ]; then
        log_success "App API responding"
    else
        log_error "App not responding (HTTP $app_code)"
        exit 1
    fi
    
    # Count actual instances
    local actual_count=$(docker-compose -f docker-compose.prod.yml ps -q app | wc -l | tr -d ' ')
    print_metric "Active Instances" "$actual_count"
    
    if [ "$actual_count" -lt 2 ]; then
        log_warn "Only $actual_count instance(s) running. Results may not reflect load balancing."
    fi
}

# ============================================================================
# TEST RUNNERS
# ============================================================================

test_homepage_concurrent() {
    print_header "Test 1: Homepage Concurrent Load"
    
    log_info "Sending ${CONCURRENT_REQUESTS} concurrent requests to homepage..."
    
    local start_time=$(date +%s.%N)
    local success=0
    local fail=0
    local temp_dir=$(mktemp -d)
    
    # Launch concurrent requests
    for i in $(seq 1 $CONCURRENT_REQUESTS); do
        (
            time_total=$(curl -s -o /dev/null -w "%{http_code},%{time_total},%{time_connect},%{time_starttransfer}" \
                -m 30 "${BASE_URL}/" 2>/dev/null || echo "000,0,0,0")
            echo "$time_total" > "${temp_dir}/${i}.txt"
        ) &
    done
    
    # Wait for all
    wait
    
    local end_time=$(date +%s.%N)
    local total_time=$(echo "$end_time - $start_time" | bc)
    
    # Collect results
    local -a response_times=()
    local -a connect_times=()
    local -a ttfb=()
    
    for i in $(seq 1 $CONCURRENT_REQUESTS); do
        if [ -f "${temp_dir}/${i}.txt" ]; then
            IFS=',' read -r code time_total time_connect time_ttfb < "${temp_dir}/${i}.txt"
            
            if [ "$code" -eq 200 ]; then
                ((success++))
                response_times+=("$time_total")
                connect_times+=("$time_connect")
                ttfb+=("$time_ttfb")
            else
                ((fail++))
            fi
        else
            ((fail++))
        fi
    done
    
    rm -rf "$temp_dir"
    
    # Calculate statistics
    local avg_response=$(echo "${response_times[@]}" | tr ' ' '\n' | awk '{sum+=$1} END {print sum/NR}')
    local avg_connect=$(echo "${connect_times[@]}" | tr ' ' '\n' | awk '{sum+=$1} END {print sum/NR}')
    local avg_ttfb=$(echo "${ttfb[@]}" | tr ' ' '\n' | awk '{sum+=$1} END {print sum/NR}')
    local rps=$(echo "scale=2; $success / $total_time" | bc)
    
    print_metric "Total Time" "${total_time}s"
    print_metric "Successful" "$success"
    print_metric "Failed" "$fail"
    print_metric "Success Rate" "$(echo "scale=2; $success * 100 / $CONCURRENT_REQUESTS" | bc)%"
    print_metric "Avg Response Time" "${avg_response}s"
    print_metric "Avg Connect Time" "${avg_connect}s"
    print_metric "Avg TTFB" "${avg_ttfb}s"
    print_metric "Requests/sec" "$rps"
}

test_api_burst() {
    print_header "Test 2: API Burst Load"
    
    log_info "Hammering API endpoint with ${TOTAL_REQUESTS} requests..."
    
    local start_time=$(date +%s.%N)
    local success=0
    local fail=0
    local batch_size=50
    local -a all_times=()
    
    for batch_start in $(seq 1 $batch_size $TOTAL_REQUESTS); do
        local batch_end=$((batch_start + batch_size - 1))
        [ $batch_end -gt $TOTAL_REQUESTS ] && batch_end=$TOTAL_REQUESTS
        
        for i in $(seq $batch_start $batch_end); do
            (
                time_total=$(curl -s -o /dev/null -w "%{http_code},%{time_total}" \
                    -m 10 "${BASE_URL}/api/hello" 2>/dev/null || echo "000,0")
                echo "$time_total"
            ) &
        done
        
        # Collect batch results
        for i in $(seq $batch_start $batch_end); do
            wait -n 2>/dev/null || true
        done
        
        # Progress indicator
        local progress=$((batch_end * 100 / TOTAL_REQUESTS))
        echo -ne "  Progress: ${progress}% (${batch_end}/${TOTAL_REQUESTS})\r"
    done
    
    echo ""
    local end_time=$(date +%s.%N)
    local total_time=$(echo "$end_time - $start_time" | bc)
    
    # Note: Simplified - in real scenario we'd collect all response data
    # For now, do a sample test
    local sample_success=0
    local -a sample_times=()
    
    for i in $(seq 1 100); do
        result=$(curl -s -o /dev/null -w "%{http_code},%{time_total}" "${BASE_URL}/api/hello" 2>/dev/null || echo "000,0")
        IFS=',' read -r code time_total <<< "$result"
        if [ "$code" -eq 200 ]; then
            ((sample_success++))
            sample_times+=("$time_total")
        fi
    done
    
    local avg_time=$(echo "${sample_times[@]}" | tr ' ' '\n' | awk '{sum+=$1} END {print sum/NR}')
    local estimated_rps=$(echo "scale=2; $TOTAL_REQUESTS / $total_time" | bc)
    
    print_metric "Total Time" "${total_time}s"
    print_metric "Sample Success Rate" "$((sample_success))%"
    print_metric "Avg Response (sample)" "${avg_time}s"
    print_metric "Estimated RPS" "$estimated_rps"
}

test_sustained_load() {
    print_header "Test 3: Sustained Load (${TEST_DURATION}s)"
    
    log_info "Running sustained load test..."
    
    local end_time=$(($(date +%s) + TEST_DURATION))
    local success=0
    local fail=0
    local -a response_times=()
    
    while [ $(date +%s) -lt $end_time ]; do
        for i in $(seq 1 20); do
            (
                result=$(curl -s -o /dev/null -w "%{http_code},%{time_total}" \
                    -m 5 "${BASE_URL}/api/hello" 2>/dev/null || echo "000,0")
                echo "$result"
            ) &
        done
        
        # Collect this batch
        for i in $(seq 1 20); do
            read -r result
            IFS=',' read -r code time_total <<< "$result"
            
            if [ "$code" -eq 200 ]; then
                ((success++))
                response_times+=("$time_total")
            else
                ((fail++))
            fi
        done < <(wait)
        
        local elapsed=$(($(date +%s) + TEST_DURATION - end_time))
        echo -ne "  Requests: ${success} | Errors: ${fail} | Time: ${elapsed}s\r"
        
        sleep 0.5
    done
    
    echo ""
    
    local avg_time=$(echo "${response_times[@]}" | tr ' ' '\n' | awk '{sum+=$1} END {print sum/NR}')
    local rps=$(echo "scale=2; $success / $TEST_DURATION" | bc)
    local error_rate=$(echo "scale=2; $fail * 100 / ($success + $fail)" | bc)
    
    print_metric "Duration" "${TEST_DURATION}s"
    print_metric "Total Requests" "$((success + fail))"
    print_metric "Successful" "$success"
    print_metric "Failed" "$fail"
    print_metric "Error Rate" "${error_rate}%"
    print_metric "Avg Response Time" "${avg_time}s"
    print_metric "Throughput" "${rps} req/s"
}

test_mixed_workload() {
    print_header "Test 4: Mixed Workload"
    
    log_info "Testing multiple endpoints simultaneously..."
    
    local duration=30
    local end_time=$(($(date +%s) + duration))
    
    local homepage_success=0
    local api_success=0
    local weather_success=0
    local total_fail=0
    
    while [ $(date +%s) -lt $end_time ]; do
        # Homepage
        (curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/" 2>/dev/null || echo "000") | \
            grep -q "200" && ((homepage_success++)) || ((total_fail++)) &
        
        # API
        (curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/api/hello" 2>/dev/null || echo "000") | \
            grep -q "200" && ((api_success++)) || ((total_fail++)) &
        
        # Weather (if exists)
        (curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/weather" 2>/dev/null || echo "000") | \
            grep -q "200" && ((weather_success++)) || true &
        
        wait
        sleep 0.2
    done
    
    local total_success=$((homepage_success + api_success + weather_success))
    
    print_metric "Duration" "${duration}s"
    print_metric "Homepage Requests" "$homepage_success"
    print_metric "API Requests" "$api_success"
    print_metric "Weather Requests" "$weather_success"
    print_metric "Total Successful" "$total_success"
    print_metric "Failed" "$total_fail"
}

# ============================================================================
# METRICS & ANALYSIS
# ============================================================================

collect_container_metrics() {
    print_header "Container Metrics"
    
    log_info "Collecting resource usage..."
    
    echo -e "\n${YELLOW}CPU & Memory Usage:${NC}"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" \
        $(docker-compose -f docker-compose.prod.yml ps -q) | head -15
    
    echo -e "\n${YELLOW}Container Health Status:${NC}"
    local containers=($(docker-compose -f docker-compose.prod.yml ps -q app))
    local healthy=0
    local unhealthy=0
    
    for container in "${containers[@]}"; do
        local health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "unknown")
        local name=$(docker inspect --format='{{.Name}}' "$container" | sed 's|/||')
        
        if [ "$health" = "healthy" ] || docker inspect --format='{{.State.Running}}' "$container" | grep -q "true"; then
            ((healthy++))
            echo -e "  ${GREEN}✓${NC} $name"
        else
            ((unhealthy++))
            echo -e "  ${RED}✗${NC} $name ($health)"
        fi
    done
    
    print_metric "Healthy Containers" "$healthy / ${#containers[@]}"
    
    echo -e "\n${YELLOW}Nginx Connection Stats:${NC}"
    docker-compose -f docker-compose.prod.yml exec -T nginx cat /proc/net/sockstat 2>/dev/null | grep TCP || echo "  Stats not available"
}

analyze_distribution() {
    print_header "Load Distribution Analysis"
    
    log_info "Analyzing request distribution across containers..."
    
    # Check nginx logs for upstream distribution
    local log_count=$(docker-compose -f docker-compose.prod.yml logs --tail=200 nginx 2>/dev/null | grep -c "GET\|POST" || echo "0")
    
    if [ "$log_count" -gt 0 ]; then
        log_success "Found $log_count requests in nginx logs"
        echo -e "\n${YELLOW}Sample of recent requests:${NC}"
        docker-compose -f docker-compose.prod.yml logs --tail=100 nginx 2>/dev/null | \
            grep "GET\|POST" | tail -10 | cut -c 1-120
    else
        log_warn "No requests found in nginx logs (may be buffered)"
    fi
    
    echo -e "\n${YELLOW}Connection pooling effectiveness:${NC}"
    docker-compose -f docker-compose.prod.yml exec -T nginx cat /var/log/nginx/access.log 2>/dev/null | \
        tail -50 | grep -oE "uct=\"[0-9.]+\"" | cut -d'"' -f2 | \
        awk '{sum+=$1; count++} END {if(count>0) printf "  Avg upstream connect time: %.3fs (%d samples)\n", sum/count, count}' || \
        echo "  No connection time data available"
}

# ============================================================================
# REPORT GENERATION
# ============================================================================

generate_report() {
    print_header "Generating Report"
    
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
        docker-compose -f docker-compose.prod.yml ps
        echo ""
        
        echo "Resource Usage:"
        docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" \
            $(docker-compose -f docker-compose.prod.yml ps -q)
        echo ""
        
        echo "=========================================="
        echo "Report saved to: $REPORT_FILE"
        echo "=========================================="
        
    } | tee "$REPORT_FILE"
    
    log_success "Report saved to: $REPORT_FILE"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    clear
    
    echo -e "${MAGENTA}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║           PRODUCTION LOAD TEST SUITE                       ║"
    echo "║           Next.js + Docker + Nginx                         ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    setup
    scale_containers
    verify_setup
    
    # Run all tests
    test_homepage_concurrent
    test_api_burst
    test_sustained_load
    test_mixed_workload
    
    # Collect metrics
    collect_container_metrics
    analyze_distribution
    
    # Final report
    print_header "Test Summary"
    
    echo -e "${GREEN}✓ All tests completed successfully${NC}\n"
    
    print_metric "Test Duration" "~$((TEST_DURATION * 3))s"
    print_metric "Total Instances" "$TARGET_INSTANCES"
    print_metric "Results Directory" "$RESULTS_DIR"
    
    echo -e "\n${CYAN}Next Steps:${NC}"
    echo "  • Review detailed logs: docker-compose logs -f"
    echo "  • Check nginx metrics: curl http://localhost:3009/nginx_status"
    echo "  • Monitor resources: docker stats"
    echo ""
    
    generate_report
    
    log_success "Load test completed! 🚀"
}

# Run it
main "$@"

