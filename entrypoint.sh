#!/bin/bash

set -e

NGINX_PID=""
API_SERVER_PID=""
CURRENT_SYNC_PID=""

start_nginx() {
    nginx -g 'daemon off;' &
    NGINX_PID=$!
}

start_api_server() {
    python3 /app/scripts/aws_s3_sync_compress.py api-server &
    API_SERVER_PID=$!
}

run_s3_sync_bg() {
    if [ ! -z "$CURRENT_SYNC_PID" ] && kill -0 $CURRENT_SYNC_PID 2>/dev/null; then
        return 1
    fi
    (cd /app/scripts && python3 aws_s3_sync_compress.py) &
    CURRENT_SYNC_PID=$!
    return 0
}

cleanup() {
    kill -TERM $NGINX_PID 2>/dev/null || true
    kill -TERM $API_SERVER_PID 2>/dev/null || true
    kill -TERM $CURRENT_SYNC_PID 2>/dev/null || true
    exit 0
}

trap cleanup SIGTERM SIGINT

echo '{"status": "starting", "files_synced": 0, "files_compressed": 0, "timestamp": "'$(date -Iseconds)'"}' > /app/output/status.json

start_nginx
start_api_server
sleep 2

if [ "$AUTO_RUN_SYNC" != "false" ]; then
    (cd /app/scripts && python3 aws_s3_sync_compress.py)
fi

while true; do
    if ! kill -0 $NGINX_PID 2>/dev/null; then
        start_nginx
    fi
    
    if [ -f "/tmp/trigger_sync" ]; then
        rm -f /tmp/trigger_sync
        run_s3_sync_bg
    fi
    
    if [ ! -z "$CURRENT_SYNC_PID" ] && ! kill -0 $CURRENT_SYNC_PID 2>/dev/null; then
        CURRENT_SYNC_PID=""
    fi
    
    sleep 5
done