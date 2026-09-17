# Interpreting the load tests

Run from the root on Linux with Bash 4+, curl, bc, Docker and Compose v2+:

```sh
MAX_ERROR_RATE=1 MAX_AVG_RESPONSE_SECONDS=2 bash scripts/stress-test.sh 2 20 100 10
bash scripts/test-load-thresholds.sh
```

Arguments are replicas, homepage concurrency, API request count and sustained-load
seconds. The mixed workload runs for 30 seconds. Reports go to `load-test-results/`.
A run fails if any workload exceeds the error threshold, has no valid samples, or
if a measured mean latency exceeds the configured limit (tests 1–3). Mixed workload
latency is not measured. Passing these checks is not production certification.

The Nginx configuration intentionally limits API requests to 20 requests/second per
IP, with a burst allowance. Aggressive single-host load will hit that policy and
should fail strict availability thresholds. Report these rejections; do not hide
them by describing the run as successful or silently disabling rate limiting.

Record the git commit, OS/architecture, CPU/RAM, Docker/Bun versions, replica count,
request mix, rate-limit policy, concurrency, duration, external API availability,
errors and the full report when sharing results. The current shell tool launches
curl processes: its timings include the client and network overhead, and its mean
latency is not a percentile distribution. Use a dedicated load generator for p50,
p95 and p99 measurements. No throughput target is a measured benchmark result.
