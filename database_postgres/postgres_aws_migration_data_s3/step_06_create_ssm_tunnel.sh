#!/bin/bash
################################################################################
# Script: step_06_create_ssm_tunnel.sh
# Description: Creates SSM port forwarding tunnel to RDS via EC2 bastion
# Usage:
#   export AWS_PROFILE=your-profile
#   export EC2_INSTANCE_ID=i-xxxxxxxxx
#   export SECRET_ARN=arn:aws:secretsmanager:...
#   export RDS_HOST=your-rds-host.rds.amazonaws.com
#   ./step_06_create_ssm_tunnel.sh
################################################################################

set -e

# Configuration via environment variables
readonly PROFILE="${AWS_PROFILE:-default}"
readonly REGION="${AWS_REGION:-us-east-1}"
readonly INSTANCE_ID="${EC2_INSTANCE_ID:?'EC2_INSTANCE_ID environment variable is required'}"
readonly RDS_HOST="${RDS_HOST:?'RDS_HOST environment variable is required'}"
readonly RDS_PORT="${RDS_PORT:-5432}"
readonly LOCAL_PORT="${LOCAL_PORT:-5433}"
readonly SECRET_ARN="${SECRET_ARN:?'SECRET_ARN environment variable is required'}"

# Get database credentials
get_db_password() {
    echo "[INFO] Retrieving database credentials from Secrets Manager..."
    
    aws secretsmanager get-secret-value \
        --secret-id "${SECRET_ARN}" \
        --profile "${PROFILE}" \
        --region "${REGION}" \
        --query 'SecretString' \
        --output text | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['password'])"
}

# Main execution
main() {
    echo "=========================================="
    echo "SSM Port Forwarding Tunnel Setup"
    echo "=========================================="
    echo ""
    echo "[INFO] Configuration:"
    echo "  EC2 Instance: ${INSTANCE_ID}"
    echo "  RDS Endpoint: ${RDS_HOST}:${RDS_PORT}"
    echo "  Local Port:   localhost:${LOCAL_PORT}"
    echo ""
    
    local db_password
    db_password=$(get_db_password)
    
    echo "[SUCCESS] Credentials retrieved"
    echo ""
    echo "=========================================="
    echo "Connection Details"
    echo "=========================================="
    echo "Host:     localhost"
    echo "Port:     ${LOCAL_PORT}"
    echo "Database: transactional"
    echo "Username: datahandsonmds"
    echo "Password: [retrieved from Secrets Manager]"
    echo ""
    echo "=========================================="
    echo "[INFO] Starting SSM tunnel..."
    echo "[INFO] Press Ctrl+C to stop the tunnel"
    echo "=========================================="
    echo ""
    
    aws ssm start-session \
        --target "${INSTANCE_ID}" \
        --document-name AWS-StartPortForwardingSessionToRemoteHost \
        --parameters "{\"host\":[\"${RDS_HOST}\"],\"portNumber\":[\"${RDS_PORT}\"],\"localPortNumber\":[\"${LOCAL_PORT}\"]}" \
        --profile "${PROFILE}" \
        --region "${REGION}"
}

main "$@"
