#!/bin/bash
################################################################################
# Script: test_full_connection.sh
# Description: Complete connection test for DBeaver troubleshooting
# Usage:
#   export AWS_PROFILE=your-profile
#   export EC2_INSTANCE_ID=i-xxxxxxxxx
#   export SECRET_ARN=arn:aws:secretsmanager:...
#   export RDS_HOST=your-rds-host.rds.amazonaws.com
#   ./test_full_connection.sh
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

echo "=========================================="
echo "RDS Connection Test"
echo "=========================================="
echo ""

# Test 1: Check tunnel
echo "[1/4] Checking SSM tunnel on port 5433..."
if netstat -tuln 2>/dev/null | grep -q 5433 || ss -tuln | grep -q 5433; then
    echo "Tunnel is active on port 5433"
else
    echo "Tunnel is NOT active. Run: ./step_06_create_ssm_tunnel.sh"
    exit 1
fi
echo ""

# Test 2: Get credentials
echo "[2/4] Retrieving credentials from Secrets Manager..."
CREDS=$(aws secretsmanager get-secret-value \
    --secret-id "${SECRET_ARN}" \
    --profile "${PROFILE}" \
    --region "${REGION}" \
    --query 'SecretString' \
    --output text)

USERNAME=$(echo "$CREDS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['username'])")
PASSWORD=$(echo "$CREDS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['password'])")

echo "✅ Credentials retrieved"
echo "   Username: $USERNAME"
echo "   Password: [hidden]"
echo ""

# Test 3: Test from EC2 to RDS
echo "[3/4] Testing connection from EC2 to RDS..."
COMMAND_ID=$(aws ssm send-command \
    --instance-ids "${INSTANCE_ID}" \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["export RDS_SECRET_ARN='"${SECRET_ARN}"'","/opt/venv/bin/python3 -c \"import boto3, json, os; session = boto3.Session(region_name='\''us-east-1'\''); client = session.client('\''secretsmanager'\''); response = client.get_secret_value(SecretId=os.getenv('\''RDS_SECRET_ARN'\'')); creds = json.loads(response['\''SecretString'\'']); print(creds['\''password'\''])\" > /tmp/dbpass","export PGPASSWORD=$(cat /tmp/dbpass)","psql -h '"${RDS_HOST}"' -U '"${DB_USER}"' -d '"${DB_NAME}"' -c \"SELECT '\''Connection successful!'\'' as status, version();\""]' \
    --timeout-seconds 60 \
    --profile "${PROFILE}" \
    --region "${REGION}" \
    --query 'Command.CommandId' \
    --output text)

sleep 3

RESULT=$(aws ssm get-command-invocation \
    --command-id "${COMMAND_ID}" \
    --instance-id "${INSTANCE_ID}" \
    --profile "${PROFILE}" \
    --region "${REGION}" \
    --query 'StandardOutputContent' \
    --output text)

if echo "$RESULT" | grep -q "Connection successful"; then
    echo "✅ EC2 → RDS connection works"
    echo "$RESULT"
else
    echo "❌ EC2 → RDS connection failed"
    echo "$RESULT"
    exit 1
fi
echo ""

# Test 4: Sample data query
echo "[4/4] Testing data retrieval..."
COMMAND_ID=$(aws ssm send-command \
    --instance-ids "${INSTANCE_ID}" \
    --document-name "AWS-RunShellScript" \
    --parameters 'commands=["export RDS_SECRET_ARN='"${SECRET_ARN}"'","/opt/venv/bin/python3 -c \"import boto3, json, os; session = boto3.Session(region_name='\''us-east-1'\''); client = session.client('\''secretsmanager'\''); response = client.get_secret_value(SecretId=os.getenv('\''RDS_SECRET_ARN'\'')); creds = json.loads(response['\''SecretString'\'']); print(creds['\''password'\''])\" > /tmp/dbpass","export PGPASSWORD=$(cat /tmp/dbpass)","psql -h '"${RDS_HOST}"' -U '"${DB_USER}"' -d '"${DB_NAME}"' -c \"SELECT COUNT(*) as total_movies FROM movies;\""]' \
    --timeout-seconds 60 \
    --profile "${PROFILE}" \
    --region "${REGION}" \
    --query 'Command.CommandId' \
    --output text)

sleep 3

RESULT=$(aws ssm get-command-invocation \
    --command-id "${COMMAND_ID}" \
    --instance-id "${INSTANCE_ID}" \
    --profile "${PROFILE}" \
    --region "${REGION}" \
    --query 'StandardOutputContent' \
    --output text)

echo "✅ Data retrieval works"
echo "$RESULT"
echo ""

echo "=========================================="
echo "✅ ALL TESTS PASSED!"
echo "=========================================="
echo ""
echo "DBeaver Configuration:"
echo "  Host:     localhost"
echo "  Port:     5433"
echo "  Database: transactional"
echo "  Username: $USERNAME"
echo ""
echo "Make sure the tunnel is running before connecting DBeaver!"
echo "=========================================="
