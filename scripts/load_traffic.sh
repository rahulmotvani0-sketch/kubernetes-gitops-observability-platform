#!/usr/bin/env bash
# Lightweight HTTP traffic generator to simulate real user load against the sample microservice

TARGET_URL="${1:-http://localhost/api}"
REQUEST_COUNT="${2:-200}"
CONCURRENCY="${3:-5}"

echo "Dispatching $REQUEST_COUNT requests to $TARGET_URL with concurrency $CONCURRENCY..."

for ((i=1; i<=REQUEST_COUNT; i++)); do
  curl -s -o /dev/null -w "%{http_code}\n" "$TARGET_URL" &
  if (( i % CONCURRENCY == 0 )); then
    wait
  fi
done
wait

echo "Load traffic completed."
