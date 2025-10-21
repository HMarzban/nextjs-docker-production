# Load Testing Guide

Production-grade load testing for scaled Next.js on Docker + Nginx.

## Quick Start

```bash
# 1. Build and start with 10 instances
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d --scale app=10

# 2. Run the load test
./stress-test.sh

# Or use Make
make test-stress
```

## Test Levels

### Light Test (Default)

```bash
./stress-test.sh 10 100 10000 60
# 10 instances, 100 concurrent, 10k total requests, 60s sustained load
```

### Heavy Test

```bash
make test-stress-heavy
# 10 instances, 200 concurrent, 20k requests, 120s sustained load
```

### Extreme Test

```bash
make test-stress-extreme
# 10 instances, 500 concurrent, 50k requests, 300s sustained load
```

## What Gets Tested

### 1. Homepage Concurrent Load

- Tests concurrent requests to `/`
- Measures response time, TTFB, connection time
- Calculates requests/second

### 2. API Burst Load

- Hammers `/api/hello` with thousands of requests
- Tests API endpoint performance under load
- Measures sustained throughput

### 3. Sustained Load Test

- Runs continuous load for specified duration
- Tests stability over time
- Detects memory leaks and degradation

### 4. Mixed Workload

- Simultaneously hits multiple endpoints
- Simulates real-world traffic patterns
- Tests routing efficiency

## Metrics Collected

### Performance

- **Response Time**: Avg, Min, Max latency
- **Throughput**: Requests per second
- **TTFB**: Time to first byte
- **Success Rate**: Percentage of successful requests

### Infrastructure

- **CPU Usage**: Per container
- **Memory Usage**: Per container  
- **Container Health**: Health check status
- **Load Distribution**: How evenly requests are distributed

### Network

- **Connection Time**: Time to establish connection
- **Upstream Connect Time**: Nginx → App connection time
- **Error Rate**: Failed requests percentage

## Understanding Results

### Good Performance (Production-Ready)

```
✓ Success Rate: >99%
✓ Avg Response Time: <100ms for API, <500ms for SSR
✓ RPS: >1000 for 10 instances
✓ Error Rate: <1%
✓ CPU per container: <80%
✓ All containers healthy
```

### Warning Signs

```
⚠ Success Rate: 95-99%
⚠ Avg Response Time: 100-500ms for API
⚠ Error Rate: 1-5%
⚠ CPU >80% sustained
⚠ Some containers unhealthy
```

### Critical Issues

```
✗ Success Rate: <95%
✗ Avg Response Time: >1s
✗ Error Rate: >5%
✗ Requests timing out
✗ Containers crashing
```

## Interpreting Reports

### Sample Output

```
╔══════════════════════════════════════════════════════════╗
║ Test 1: Homepage Concurrent Load                        ║
╚══════════════════════════════════════════════════════════╝

  Total Time:              5.23s
  Successful:              100
  Failed:                  0
  Success Rate:            100.00%
  Avg Response Time:       0.052s
  Avg Connect Time:        0.001s
  Avg TTFB:               0.048s
  Requests/sec:            19.12
```

**What this means:**

- 100 concurrent requests completed in 5.23s
- All successful (100% success rate)
- Average response time of 52ms (excellent)
- Connection overhead is minimal (1ms)
- System handled ~19 req/s for homepage

## Optimization Tips

### If Response Time is High

1. Check nginx buffer sizes
2. Increase upstream keepalive connections
3. Optimize Next.js build (check bundle size)
4. Enable caching for static assets

### If Error Rate is High

1. Check container logs: `docker-compose logs app`
2. Verify health checks are passing
3. Increase proxy timeouts in nginx.conf
4. Check resource limits (CPU/memory)

### If Distribution is Uneven

1. Verify `least_conn` in nginx upstream
2. Check container health (unhealthy ones get no traffic)
3. Ensure Docker DNS resolver is working

## Scaling Guidelines

### Traffic Level → Instance Count

```
Light      (<1k req/min)   → 2-3 instances
Medium     (1k-10k)         → 5-8 instances
Heavy      (10k-50k)        → 10-15 instances
Extreme    (50k-100k)       → 20-30 instances
Enterprise (>100k)          → 50+ instances + multiple regions
```

### Resources per Instance

```yaml
mem_limit: 1G      # Increase if OOM errors
cpus: 2            # Increase for CPU-bound tasks
```

## Advanced Testing

### Test Specific Endpoints

```bash
# Test only API
for i in {1..1000}; do
  curl -s http://localhost:3009/api/hello &
done
wait

# Test upload endpoint
for i in {1..100}; do
  curl -X POST -F "file=@test.txt" http://localhost:3009/api/upload &
done
wait
```

### Monitor During Test

```bash
# Terminal 1: Run test
./stress-test.sh 10 200 20000 120

# Terminal 2: Watch logs
docker-compose -f docker-compose.prod.yml logs -f app

# Terminal 3: Monitor resources
watch -n 1 'docker stats --no-stream'
```

### Check Nginx Connection Pool

```bash
docker-compose exec nginx cat /var/log/nginx/access.log | \
  grep -oE 'uct="[0-9.]+"' | cut -d'"' -f2 | \
  awk '{sum+=$1; count++} END {print "Avg upstream connect:", sum/count "s"}'
```

## Troubleshooting

### Test Hangs

- Check if containers are healthy: `docker-compose ps`
- Verify nginx is responding: `curl http://localhost:3009/health`
- Check network: `docker network inspect nextjs-app-network`

### High Error Rate

- Increase rate limits in nginx.conf
- Check container resource limits
- Verify database connections (if any)

### Memory Leaks

- Run sustained test: `./stress-test.sh 10 50 50000 600`
- Monitor memory: `docker stats`
- Check for growing memory usage over time

## CI/CD Integration

```yaml
# .github/workflows/load-test.yml
name: Load Test
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Build
        run: docker-compose -f docker-compose.prod.yml build
      - name: Start Services
        run: docker-compose -f docker-compose.prod.yml up -d --scale app=5
      - name: Run Load Test
        run: ./stress-test.sh 5 50 5000 30
      - name: Upload Report
        uses: actions/upload-artifact@v2
        with:
          name: load-test-report
          path: load-test-results/
```

## Best Practices

1. **Always warm up**: Run a small test first to warm caches
2. **Test in stages**: Don't jump to max load immediately
3. **Monitor everything**: CPU, memory, network, logs
4. **Save reports**: Keep historical data for comparison
5. **Test regularly**: Run load tests before each deployment
6. **Realistic scenarios**: Test actual user workflows
7. **Resource limits**: Always set CPU/memory limits

## Real-World Scenarios

### E-commerce Site (Black Friday)

```bash
# Simulate 100k users in 5 minutes
./stress-test.sh 20 1000 100000 300
```

### API Service (Steady Load)

```bash
# Continuous moderate load
./stress-test.sh 10 100 0 3600  # 1 hour
```

### News Site (Traffic Spike)

```bash
# Sudden spike, then sustained
./stress-test.sh 15 500 50000 120
```

## Results Directory

Test results are saved in `./load-test-results/`:

```
load-test-results/
├── report_20241021_143022.txt    # Full report
├── report_20241021_150145.txt
└── ...
```

Each report contains:

- Test configuration
- All metrics and statistics
- Container status snapshots
- Resource usage data
- Recommendations

## Next Steps

After running load tests:

1. **Review reports** in `load-test-results/`
2. **Optimize** based on bottlenecks found
3. **Re-test** to verify improvements
4. **Document** your baseline performance
5. **Set up monitoring** in production

## Support

For issues or questions:

- Check container logs: `make prod-logs`
- Run debug script: `./debug-connection.sh`
- Review nginx logs: `docker-compose exec nginx tail /var/log/nginx/error.log`
