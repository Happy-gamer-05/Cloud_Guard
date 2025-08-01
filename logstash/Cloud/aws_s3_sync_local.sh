#!/bin/bash

# =========================================================================
# === Script: aws_s3_sync_local.sh                                      ===
# === Description: Syncs S3 log files, decompresses them, and cleans up ===
# =========================================================================

# === Configuration ===
BUCKET_NAME="project-s3-bucket-logs-all"
FINAL_DIR="/home/utkarsh/Desktop/Project/CDAC/Project/logstash/Cloud/s3-logs/data"
SINCEDB_FILE="/home/utkarsh/Desktop/Project/CDAC/Project/logstash/Cloud/sincedb/s3_logs_sincedb"

# Create directories if they don't exist
mkdir -p "$FINAL_DIR"
mkdir -p "$(dirname "$SINCEDB_FILE")"

echo "[INFO] Starting S3 log sync and cleanup script."

# === Step 1: Cleanup old log files, directory structure, and sincedb file ===
echo "--------------------------------------------------------"
echo "[INFO] Cleaning up old log files from previous runs..."

# Delete original S3 log files from the nested directories
find "$FINAL_DIR" -type f -name "PUT-S3-Project-nginx-log-1-*" -delete

# Delete the empty directory structure left behind
find "$FINAL_DIR" -type d -empty -delete

# Delete the decompressed .json files from the root data directory
rm -f "$FINAL_DIR"/PUT-S3-Project-nginx-log-1-*.json

# Delete the sincedb file to ensure a fresh start for Logstash
rm -f "$SINCEDB_FILE"

echo "[INFO] Cleanup complete."
echo "--------------------------------------------------------"


# === Step 2: Sync new files from S3 to the local directory ===
echo "[INFO] Syncing new files from S3..."
aws s3 sync s3://"$BUCKET_NAME" "$FINAL_DIR"

echo "[INFO] Sync from S3 complete."
echo "--------------------------------------------------------"

# === Step 3: Decompress the gzipped files and set permissions ===
echo "[INFO] Decompressing new gzipped files and setting permissions..."

# Find all files recursively that are gzip compressed
find "$FINAL_DIR" -type f -exec sh -c '
    file_path="$1"
    if file "$file_path" | grep -q "gzip compressed"; then
        echo "[INFO] Decompressing $(basename "$file_path")..."
        gunzip -c "$file_path" > "$file_path.json"
        chmod 644 "$file_path.json"
        rm "$file_path"
    fi
' sh {} \;

echo "[INFO] Decompression and permission setting complete."
echo "--------------------------------------------------------"

echo "[DONE] Script finished successfully."
