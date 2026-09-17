#!/usr/bin/env bash
# Pure threshold check, also sourced by the fixture test.
check_load_threshold() {
    local label=$1 successes=$2 total=$3 average=$4
    awk -v successes="$successes" -v total="$total" -v average="$average" \
        -v max_error="${MAX_ERROR_RATE:-1}" -v max_average="${MAX_AVG_RESPONSE_SECONDS:-2}" '
        BEGIN {
            if (total !~ /^[0-9]+$/ || successes !~ /^[0-9]+$/ || total == 0 || successes > total) exit 1
            if (max_error !~ /^[0-9]+([.][0-9]+)?$/ || max_error > 100) exit 1
            if (max_average !~ /^[0-9]+([.][0-9]+)?$/ || max_average <= 0) exit 1
            if ((total - successes) * 100 / total > max_error) exit 1
            if (average != "skip" && (average !~ /^[0-9]*[.]?[0-9]+$/ || average > max_average)) exit 1
        }' || { echo "FAIL: $label exceeds thresholds or has no valid samples" >&2; return 1; }
}
