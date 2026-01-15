#!/bin/bash
################################################################################
# Script: step_05_verify_tables.sh
# Description: Verifies RDS tables were created and populated successfully
# Usage:
#   export AWS_PROFILE=your-profile
#   export EC2_INSTANCE_ID=i-xxxxxxxxx
#   export SECRET_ARN=arn:aws:secretsmanager:...
#   export RDS_HOST=your-rds-host.rds.amazonaws.com
#   ./step_05_verify_tables.sh
################################################################################

set -e

# Configuration via environment variables
readonly PROFILE="${AWS_PROFILE:-default}"
readonly REGION="${AWS_REGION:-us-east-1}"
readonly INSTANCE_ID="${EC2_INSTANCE_ID:?'EC2_INSTANCE_ID environment variable is required'}"
readonly SECRET_ARN="${SECRET_ARN:?'SECRET_ARN environment variable is required'}"
readonly RDS_HOST="${RDS_HOST:?'RDS_HOST environment variable is required'}"
readonly DB_USER="${DB_USER:-datahandsonmds}"
readonly DB_NAME="${DB_NAME:-transactional}"
readonly WAIT_TIME=30

# Main execution
main() {
    echo "[INFO] Verifying tables in RDS database"
    
    local command_id
    command_id=$(aws ssm send-command \
        --instance-ids "${INSTANCE_ID}" \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=["apt-get install -y postgresql-client > /dev/null 2>&1","export RDS_SECRET_ARN='"${SECRET_ARN}"'","/opt/venv/bin/python3 -c \"import boto3, json, os; session = boto3.Session(region_name='\''us-east-1'\''); client = session.client('\''secretsmanager'\''); response = client.get_secret_value(SecretId=os.getenv('\''RDS_SECRET_ARN'\'')); creds = json.loads(response['\''SecretString'\'']); print(creds['\''password'\''])\" > /tmp/dbpass","export PGPASSWORD=$(cat /tmp/dbpass)","echo '\''=== Tables ===\"","psql -h '"${RDS_HOST}"' -U '"${DB_USER}"' -d '"${DB_NAME}"' -c \"\\dt\"","echo '\''\"","echo '\''=== Row Counts ===\"","psql -h '"${RDS_HOST}"' -U '"${DB_USER}"' -d '"${DB_NAME}"' -c \"SELECT '\''ratings'\'' as table_name, COUNT(*) as row_count FROM ratings UNION ALL SELECT '\''tags'\'', COUNT(*) FROM tags UNION ALL SELECT '\''movies'\'', COUNT(*) FROM movies UNION ALL SELECT '\''links'\'', COUNT(*) FROM links ORDER BY table_name;\""]' \
        --timeout-seconds 120 \
        --profile "${PROFILE}" \
        --region "${REGION}" \
        --query 'Command.CommandId' \
        --output text)
    
    echo "[INFO] Command sent. Command ID: ${command_id}"
    echo "[INFO] Waiting ${WAIT_TIME} seconds for execution..."
    sleep "${WAIT_TIME}"
    
    echo ""
    echo "=========================================="
    echo "Verification Results"
    echo "=========================================="
    
    aws ssm get-command-invocation \
        --command-id "${command_id}" \
        --instance-id "${INSTANCE_ID}" \
        --profile "${PROFILE}" \
        --region "${REGION}" \
        --query 'StandardOutputContent' \
        --output text
    
    echo "=========================================="
    echo "[SUCCESS] Verification complete"
}

main "$@"
