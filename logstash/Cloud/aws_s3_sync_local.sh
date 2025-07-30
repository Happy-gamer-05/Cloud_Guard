#!/bin/bash

# === Configuration ===
BUCKET_NAME="project-s3-bucket-logs-all"
TMP_DIR="/tmp/s3_download_raw"
FINAL_DIR="/home/utkarsh/Desktop/Project/CDAC/Project/logstash/Cloud/s3-logs/data"
LOG_FILE="/home/utkarsh/Desktop/Project/CDAC/Project/logstash/Cloud/last_sync_timestamp.txt"
TIME_STAMP=$(date '+%Y-%m-%d_%H-%M-%S')

mkdir -p "$TMP_DIR"
mkdir -p "$FINAL_DIR"

# === Step 1: Load last sync timestamp or set default ===
if [ -f "$LOG_FILE" ]; then
    LAST_SYNC=$(cat "$LOG_FILE")
else
    LAST_SYNC="1970-01-01T00:00:00Z"  # default if no previous run
fi

echo "[INFO] Last sync time: $LAST_SYNC"

# === Step 2: List new files from S3 ===
aws s3api list-objects-v2 \
  --bucket "$BUCKET_NAME" \
  --query "Contents[?LastModified>\`$LAST_SYNC\`].[Key,LastModified]" \
  --output json > "$TMP_DIR/new_files.json"

# === Step 3: Download and process new files ===
NUM_NEW=$(jq length "$TMP_DIR/new_files.json")
if [ "$NUM_NEW" -eq 0 ]; then
    echo "[INFO] No new files to download."
    exit 0
fi

echo "[INFO] Found $NUM_NEW new file(s). Downloading..."

NEWEST_TIMESTAMP="$LAST_SYNC"

for row in $(jq -c '.[]' "$TMP_DIR/new_files.json"); do
    KEY=$(echo "$row" | jq -r '.[0]')
    MODIFIED=$(echo "$row" | jq -r '.[1]')

    FILE_NAME=$(basename "$KEY")
    LOCAL_PATH="$TMP_DIR/$FILE_NAME"

    aws s3 cp "s3://$BUCKET_NAME/$KEY" "$LOCAL_PATH"

    # Append .json.gz if gzip file without extension
    if file "$LOCAL_PATH" | grep -q "gzip compressed"; then
        mv "$LOCAL_PATH" "$LOCAL_PATH.json.gz"
        LOCAL_PATH="$LOCAL_PATH.json.gz"
        echo "[INFO] Renamed $FILE_NAME to $(basename "$LOCAL_PATH")"
    fi

    # Decompress to final dir
    if [[ "$LOCAL_PATH" == *.json.gz ]]; then
        gunzip -c "$LOCAL_PATH" > "$FINAL_DIR/${FILE_NAME}.json"
        echo "[INFO] Decompressed $FILE_NAME -> $FINAL_DIR/${FILE_NAME}.json"
    fi

    # Update latest timestamp seen
    [[ "$MODIFIED" > "$NEWEST_TIMESTAMP" ]] && NEWEST_TIMESTAMP="$MODIFIED"
done

# === Step 4: Save latest timestamp ===
echo "$NEWEST_TIMESTAMP" > "$LOG_FILE"
echo "[DONE] Sync complete. Latest timestamp updated: $NEWEST_TIMESTAMP"

