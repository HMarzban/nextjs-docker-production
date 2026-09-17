#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/load-thresholds.sh"
check_load_threshold success 100 100 0.1
check_load_threshold boundary 99 100 2
check_load_threshold mixed 100 100 skip
for fixture in "errors 98 100 0.1" "empty 0 0 0" "slow 100 100 2.1" "missing 100 100 N/A" "invalid 101 100 0.1"; do
    if check_load_threshold $fixture 2>/dev/null; then
        echo "Expected threshold rejection: $fixture" >&2; exit 1
    fi
done
if MAX_ERROR_RATE=bogus check_load_threshold invalid 100 100 0.1 2>/dev/null; then exit 1; fi
if MAX_AVG_RESPONSE_SECONDS=0 check_load_threshold invalid 100 100 0.1 2>/dev/null; then exit 1; fi
echo "Load threshold fixtures passed"

# The full runner must propagate failed acceptance checks after writing a report.
(
    source "$(dirname "$0")/stress-test.sh"
    setup() { :; }; scale_containers() { :; }; verify_setup() { :; }
    sleep() { :; }; collect_metrics() { :; }
    test_homepage_concurrent() { TEST1_RESULTS=([success]=100 [total]=100 [avg_time]=0.1s); }
    test_api_burst() { TEST2_RESULTS=([success]=100 [total]=100 [avg_time]=0.1s); }
    test_sustained_load() { TEST3_RESULTS=([success]=100 [total]=100 [avg_time]=0.1s); }
    test_mixed_workload() { TEST4_RESULTS=([success]=0 [requests]=100); }
    generate_report() { [ "$THRESHOLD_STATUS" = FAIL ]; }
    if main; then echo "Runner hid a failing workload" >&2; exit 1; fi
)
echo "Load runner failure-exit fixture passed"
