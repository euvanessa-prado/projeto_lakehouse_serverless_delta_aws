#!/bin/bash
################################################################################
# Script: step_04_check_execution_result.sh
# Description: Checks SSM command execution status and output
# Usage: ./step_04_check_execution_result.sh <COMMAND_ID>
# Parameters:
#   COMMAND_ID - The command ID returned from step_03
################################################################################

set -e

# Configuration
readonly PROFILE="projeto-lakehouse-serverless"
readonly REGION="us-east-1"
readonly INSTANCE_ID="i-003d2d73d6c25c754"
readonly WAIT_TIME=60

# Validate input
if [ -z "$1" ]; then
    echo "[ERROR] Missing required parameter"
    echo "Usage: $0 <COMMAND_ID>"
    echo "Example: $0 f48fe438-1fa3-48aa-8e7c-690a8763656c"
    exit 1
fi

readonly COMMAND_ID="$1"

# Main execution
main() {
    echo "[INFO] Checking execution status for command: ${COMMAND_ID}"
    echo "[INFO] Waiting ${WAIT_TIME} seconds for execution to complete..."
    sleep "${WAIT_TIME}"
    
    echo ""
    echo "=========================================="
    echo "Execution Result"
    echo "=========================================="
    
    aws ssm get-command-invocation \
        --command-id "${COMMAND_ID}" \
        --instance-id "${INSTANCE_ID}" \
        --profile "${PROFILE}" \
        --region "${REGION}" \
        --query '{Status:Status,Output:StandardOutputContent,Error:StandardErrorContent}' \
        --output json
    
    echo ""
    echo "=========================================="
    echo "[INFO] If status is 'Success', proceed to:"
    echo "  ./step_05_verify_tables.sh"
}

main "$@"
