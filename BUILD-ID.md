# Build ID for Horizontal Scaling

## Why Build IDs Matter

When running **multiple containers** (horizontal scaling), all instances must serve the **exact same build** to prevent version skew issues.

### Problems Without Consistent Build IDs

❌ **Version Skew** - Different containers serve different builds  
❌ **Cache Misses** - Inconsistent caching behavior  
❌ **Hard Reloads** - Users experience full page reloads instead of smooth transitions  
❌ **State Loss** - Component state lost during navigation  
❌ **Debugging Nightmares** - Hard to reproduce bugs  

### What We Implemented

✅ **Consistent Build IDs** - Same build across all containers  
✅ **Git Hash Based** - Uses git commit hash for versioning  
✅ **Timestamp Fallback** - Works without git repository  
✅ **Automated** - Build script handles everything  

## How It Works

### 1. Next.js Configuration

```javascript
// next.config.mjs
generateBuildId: async () => {
  return process.env.BUILD_ID || process.env.GIT_HASH || 'production-build';
}
```

This ensures Next.js uses a consistent build ID that you control.

### 2. Dockerfile

```dockerfile
# Accept build args
ARG BUILD_ID
ARG GIT_HASH

# Pass to Next.js during build
ENV BUILD_ID=${BUILD_ID} \
    GIT_HASH=${GIT_HASH}
```

The build ID is baked into the image at build time.

### 3. Docker Compose

```yaml
args:
  - BUILD_ID=${BUILD_ID:-production-build}
  - GIT_HASH=${GIT_HASH:-latest}
```

Allows passing build ID from environment or uses defaults.

### 4. Build Script

```bash
./build-production.sh
```

Automatically:
- Detects git hash (if available)
- Generates consistent build ID
- Exports to environment
- Builds the image

## Usage

### Recommended: Use Build Script

```bash
# Build with automatic git hash
./build-production.sh

# Or use Make
make prod-build
```

### Manual Build (Advanced)

```bash
# With git hash
BUILD_ID="build-$(git rev-parse --short HEAD)" \
GIT_HASH="$(git rev-parse --short HEAD)" \
docker-compose -f docker-compose.prod.yml build

# With custom build ID
BUILD_ID="production-v1.2.3" \
GIT_HASH="v1.2.3" \
docker-compose -f docker-compose.prod.yml build
```

### In CI/CD

```yaml
# GitHub Actions example
- name: Build with Build ID
  run: |
    export BUILD_ID="build-${GITHUB_SHA::7}"
    export GIT_HASH="${GITHUB_SHA::7}"
    docker-compose -f docker-compose.prod.yml build
```

## Verification

### Check Build ID in Running Container

```bash
# Method 1: Check environment
docker-compose -f docker-compose.prod.yml exec app env | grep BUILD_ID

# Method 2: Check Next.js build manifest
docker-compose -f docker-compose.prod.yml exec app cat .next/BUILD_ID
```

### Verify All Containers Use Same Build

```bash
# Get build IDs from all containers
for container in $(docker-compose -f docker-compose.prod.yml ps -q app); do
  docker exec $container cat .next/BUILD_ID
done
```

All should show the **same build ID**.

## Best Practices

### 1. Always Use Build Script in Production

```bash
./build-production.sh
```

This ensures consistency and proper versioning.

### 2. Tag Images with Build ID

```bash
# After building
docker tag nextjs-app:latest nextjs-app:build-abc123
```

Allows rollback to specific builds.

### 3. Never Rebuild Between Environments

```bash
# ❌ BAD: Rebuilding in each environment
# staging
docker-compose build && docker-compose up

# production  
docker-compose build && docker-compose up

# ✅ GOOD: Build once, deploy everywhere
# CI/CD
./build-production.sh
docker push registry.example.com/nextjs-app:build-abc123

# staging
docker pull registry.example.com/nextjs-app:build-abc123
docker-compose up

# production
docker pull registry.example.com/nextjs-app:build-abc123
docker-compose up
```

### 4. Include Build ID in Monitoring

```bash
# Add to your monitoring/logging
BUILD_ID=$(docker-compose exec app cat .next/BUILD_ID)
echo "Deployed Build ID: $BUILD_ID"
```

## Troubleshooting

### Issue: Different Build IDs Across Containers

**Cause:** Built separately or without consistent BUILD_ID

**Solution:**
```bash
# Stop everything
docker-compose -f docker-compose.prod.yml down

# Remove old images
docker rmi nextjs-app:latest

# Build fresh
./build-production.sh

# Start all containers
docker-compose -f docker-compose.prod.yml up -d --scale app=10
```

### Issue: Build ID Not Being Used

**Check 1: Verify next.config.mjs has generateBuildId**
```bash
grep -A 3 "generateBuildId" next.config.mjs
```

**Check 2: Verify Dockerfile has ARG**
```bash
grep -A 2 "ARG BUILD_ID" Dockerfile.bun
```

**Check 3: Verify it's being passed**
```bash
grep "BUILD_ID" docker-compose.prod.yml
```

### Issue: Git Hash Not Found

This is fine! The script falls back to timestamp:
```bash
BUILD_ID="build-20241021_143022"
```

## Related Documentation

- [Next.js Self-Hosting Guide](https://nextjs.org/docs/pages/guides/self-hosting#build-cache)
- [DOCKER.md](./DOCKER.md) - Docker deployment guide
- [SCALE-TEST.md](./SCALE-TEST.md) - Horizontal scaling guide
- [TESTING-QUICKSTART.md](./TESTING-QUICKSTART.md) - Load testing

## Summary

✅ **Implemented** - `generateBuildId` in next.config.mjs  
✅ **Automated** - `build-production.sh` handles everything  
✅ **Git-Based** - Uses git commit hash for versioning  
✅ **Fallback** - Timestamp-based if no git  
✅ **Make Commands** - `make prod-build`, `make prod-rebuild`  
✅ **CI/CD Ready** - Works in automated pipelines  

Your setup now follows Next.js production best practices for horizontally scaled deployments! 🚀

