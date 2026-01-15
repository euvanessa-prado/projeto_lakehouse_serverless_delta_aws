#!/bin/bash
################################################################################
# Script: step_01_create_s3_bucket.sh
# Description: Creates S3 bucket for CSV data storage
# Usage: 
#   export AWS_PROFILE=your-profile
#   export S3_BUCKET=your-bucket-name
#   ./step_01_create_s3_bucket.sh
################################################################################

set -e

# Configuration via environment variables
readonly PROFILE="${AWS_PROFILE:-default}"
readonly REGION="${AWS_REGION:-us-east-1}"
readonly BUCKET_NAME="${S3_BUCKET:?'S3_BUCKET environment variable is required'}"

# Main execution
main() {
    echo "[INFO] Creating S3 bucket: ${BUCKET_NAME}"
    
    if aws s3 mb "s3://${BUCKET_NAME}" \
        --profile "${PROFILE}" \
        --region "${REGION}" 2>&1; then
        echo "[SUCCESS] Bucket created successfully"
    else
        echo "[WARNING] Bucket already exists or creation failed"
    fi
}

main "$@"
