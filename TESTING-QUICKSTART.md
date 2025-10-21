# Load Testing Quickstart

**TL;DR**: Test your scaled Next.js deployment with 10 instances handling heavy traffic.

## 🚀 One-Command Test

```bash
./run-full-test.sh
```

This will:

1. Build production image
2. Deploy with 10 instances
3. Run comprehensive load tests
4. Generate detailed reports

## 📊 Test Levels

### Quick Test (2 minutes)

```bash
make test-stress
# 10 instances, 100 concurrent, 10k requests, 60s
```

### Heavy Test (4 minutes)

```bash
make test-stress-heavy
# 10 instances, 200 concurrent, 20k requests, 120s
```

### Extreme Test (10 minutes)

```bash
make test-stress-extreme
# 10 instances, 500 concurrent, 50k requests, 300s
```

## 🎯 What You Get

### Performance Metrics

- **Throughput**: Requests per second
- **Latency**: Response time, TTFB, connect time
- **Success Rate**: % of successful requests
- **Error Rate**: % of failed requests

### Infrastructure Metrics

- CPU & Memory usage per container
- Container health status
- Load distribution across instances
- Network connection pooling efficiency

### 4 Test Scenarios

1. **Homepage Concurrent Load** - Concurrent users hitting homepage
2. **API Burst Load** - Thousands of API requests
3. **Sustained Load** - Continuous traffic over time
4. **Mixed Workload** - Multiple endpoints simultaneously

## 📈 Expected Results (10 Instances)

### ✅ Good Performance

```
Success Rate:       >99%
Avg Response:       <100ms (API), <500ms (SSR)
Throughput:         >1000 req/s
Error Rate:         <1%
CPU per container:  <80%
```

### ⚠️ Warning Signs

```
Success Rate:       95-99%
Avg Response:       100-500ms (API)
Error Rate:         1-5%
CPU:                >80% sustained
```

### ❌ Critical Issues

```
Success Rate:       <95%
Avg Response:       >1s
Error Rate:         >5%
Containers:         Crashing
```

## 🛠️ Manual Testing

### Test Specific Endpoints

```bash
# API only
for i in {1..1000}; do curl -s http://localhost:3009/api/hello & done; wait

# Homepage only
ab -n 10000 -c 100 http://localhost:3009/

# With monitoring
watch -n 1 'docker stats --no-stream'
```

### Custom Parameters

```bash
# ./stress-test.sh [instances] [concurrent] [total] [duration]
./stress-test.sh 15 300 30000 180
```

## 📁 Output

Results saved to `./load-test-results/`:

```
load-test-results/
├── report_20241021_143022.txt    # Detailed text report
├── report_20241021_150145.txt
└── report.html                    # Visual HTML report
```

### Generate HTML Report

```bash
./generate-report.sh
open ./load-test-results/report.html
```

## 🔍 Monitoring During Test

### Terminal 1: Run Test

```bash
./stress-test.sh 10 200 20000 120
```

### Terminal 2: Watch Logs

```bash
docker-compose -f docker-compose.prod.yml logs -f app
```

### Terminal 3: Monitor Resources

```bash
watch -n 1 'docker stats --no-stream'
```

### Terminal 4: Nginx Stats

```bash
watch -n 2 'curl -s http://localhost:3009/nginx_status'
```

## 🐛 Troubleshooting

### Test Fails Immediately

```bash
# Check services are up
docker-compose -f docker-compose.prod.yml ps

# Check logs
docker-compose -f docker-compose.prod.yml logs

# Run debug
./debug-connection.sh
```

### High Error Rate

```bash
# Check container health
docker-compose -f docker-compose.prod.yml ps

# Increase timeouts in nginx.conf
proxy_read_timeout 120s;

# Check resource limits
docker stats
```

### Uneven Distribution

```bash
# Verify load balancer config
docker-compose -f docker-compose.prod.yml exec nginx cat /etc/nginx/nginx.conf | grep -A 5 "upstream"

# Check DNS resolver
docker-compose -f docker-compose.prod.yml exec nginx nslookup app
```

## 📊 All Available Tests

```bash
make test-health              # Basic health check
make test-balancing           # Load balancing test
make test-distribution        # Container distribution test
make test-debug               # Connection debugging
make test-stress              # Standard load test
make test-stress-heavy        # Heavy load test
make test-stress-extreme      # Extreme load test
make test-all                 # Run all basic tests
```

## 🎓 Understanding Results

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
  Requests/sec:            19.12
```

**What this means:**

- 100 concurrent requests completed in 5.23 seconds
- Zero failures (excellent)
- Average response time is 52ms (great for SSR)
- System can handle ~19 homepage requests/second per burst

### Interpreting Throughput

For **10 instances**:

- `>1000 req/s` = Excellent
- `500-1000 req/s` = Good
- `100-500 req/s` = Fair (check bottlenecks)
- `<100 req/s` = Poor (investigate)

### CPU & Memory

Each container (1G RAM, 2 CPUs):

- `<50% CPU` = Healthy
- `50-80% CPU` = Normal under load
- `>80% CPU` = Consider adding instances
- `Memory >800MB` = Possible leak, investigate

## 🚦 CI/CD Integration

```yaml
# .github/workflows/load-test.yml
- name: Run Load Test
  run: |
    docker-compose -f docker-compose.prod.yml up -d --scale app=5
    ./stress-test.sh 5 100 10000 60
    
- name: Upload Report
  uses: actions/upload-artifact@v2
  with:
    name: load-test-report
    path: load-test-results/
```

## 🎯 Scaling Guidelines

Based on traffic:

```
1k-10k req/min    → 5-8 instances
10k-50k req/min   → 10-15 instances
50k-100k req/min  → 20-30 instances
>100k req/min     → 50+ instances + CDN
```

## 📚 Full Documentation

- `LOAD-TEST.md` - Complete testing guide
- `NGINX-COMPARISON.md` - Nginx optimization details
- `SCALE-TEST.md` - Scaling documentation
- `TEST.md` - General testing info

## 🎉 Quick Wins

### Before Production

1. ✅ Run `./run-full-test.sh`
2. ✅ Verify >99% success rate
3. ✅ Check all containers healthy
4. ✅ Review HTML report
5. ✅ Save baseline metrics

### Optimization Tips

- Enable gzip (already in nginx.conf)
- Use keepalive connections (already configured)
- Set proper cache headers (check nginx.conf)
- Monitor and adjust resource limits
- Scale horizontally before vertically

## 💡 Pro Tips

1. **Warm up first**: Run small test before heavy load
2. **Test regularly**: Before each deployment
3. **Save reports**: Compare with previous runs
4. **Monitor in production**: Use real metrics
5. **Test realistic scenarios**: Match actual user behavior

## 🆘 Getting Help

```bash
# View all make targets
make help

# Check documentation
ls *.md

# Debug connection
./debug-connection.sh

# View logs
docker-compose -f docker-compose.prod.yml logs -f
```

---

**Ready to test?**

```bash
./run-full-test.sh
```

Then check `./load-test-results/` for your reports! 🚀
