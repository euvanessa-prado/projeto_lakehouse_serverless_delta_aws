#!/bin/bash
################################################################################
# Script: step_02_upload_csvs_to_s3.sh
# Description: Uploads MovieLens CSV files to S3 bucket
# Usage:
#   export AWS_PROFILE=your-profile
#   export S3_BUCKET=your-bucket-name
#   ./step_02_upload_csvs_to_s3.sh
################################################################################

set -e

# Configuration via environment variables
readonly PROFILE="${AWS_PROFILE:-default}"
readonly BUCKET_NAME="${S3_BUCKET:?'S3_BUCKET environment variable is required'}"
readonly S3_PREFIX="${S3_PREFIX:-movielens-source-data}"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CSV_DIR="${SCRIPT_DIR}/../ml-latest-small"

# File list
readonly FILES=("ratings" "tags" "movies" "links")

# Upload function
upload_file() {
    local file_name=$1
    echo "[INFO] Uploading ${file_name}.csv..."
    
    aws s3 cp "${CSV_DIR}/${file_name}.csv" \
        "s3://${BUCKET_NAME}/${S3_PREFIX}/${file_name}.csv" \
        --profile "${PROFILE}"
}

# Main execution
main() {
    echo "[INFO] Starting upload to s3://${BUCKET_NAME}/${S3_PREFIX}/"
    
    for file in "${FILES[@]}"; do
        upload_file "$file"
    done
    
    echo "[SUCCESS] All files uploaded successfully"
}

main "$@"
