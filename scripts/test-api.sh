#!/usr/bin/env bash
set -euo pipefail
base_url="${BASE_URL:-http://localhost:3009}"
response=$(curl --fail --silent --show-error --max-time 15 "$base_url/api/hello")
printf '%s' "$response" | python3 -c 'import sys,json; d=json.load(sys.stdin); assert d["message"] == "Hello from Next.js"; assert isinstance(d["container"],str); assert d["timestamp"]'
status=$(curl --silent --output /dev/null --write-out '%{http_code}' --max-time 15 -X POST "$base_url/api/hello")
[ "$status" = 405 ] || { echo "Expected POST /api/hello to return 405, got $status" >&2; exit 1; }
status=$(curl --silent --output /dev/null --write-out '%{http_code}' --max-time 15 "$base_url/api/weather?city=")
[ "$status" = 400 ] || { echo "Expected empty city to return 400, got $status" >&2; exit 1; }
echo "API smoke assertions passed"
