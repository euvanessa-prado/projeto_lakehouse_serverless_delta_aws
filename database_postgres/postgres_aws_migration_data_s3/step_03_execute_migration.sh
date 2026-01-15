#!/bin/bash
################################################################################
# Script: step_03_execute_migration.sh
# Description: Executes Python migration script on EC2 via SSM Run Command
# Usage:
#   export AWS_PROFILE=your-profile
#   export EC2_INSTANCE_ID=i-xxxxxxxxx
#   export SECRET_ARN=arn:aws:secretsmanager:...
#   export RDS_HOST=your-rds-host.rds.amazonaws.com
#   export S3_BUCKET=your-bucket-name
#   ./step_03_execute_migration.sh
################################################################################

set -e

# Configuration via environment variables
readonly PROFILE="${AWS_PROFILE:-default}"
readonly REGION="${AWS_REGION:-us-east-1}"
readonly INSTANCE_ID="${EC2_INSTANCE_ID:?'EC2_INSTANCE_ID environment variable is required'}"
readonly SECRET_ARN="${SECRET_ARN:?'SECRET_ARN environment variable is required'}"
readonly RDS_HOST="${RDS_HOST:?'RDS_HOST environment variable is required'}"
readonly S3_BUCKET="${S3_BUCKET:?'S3_BUCKET environment variable is required'}"

# Main execution
main() {
    echo "[INFO] Sending migration command to EC2 instance ${INSTANCE_ID}"
    
    local command_id
    command_id=$(aws ssm send-command \
        --instance-ids "${INSTANCE_ID}" \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=["cat > /tmp/insert_data.py << '\''EOF'\''
import pandas as pd
from sqlalchemy import create_engine
import boto3
import json
import os

AWS_REGION = os.getenv('\''AWS_REGION'\'', '\''us-east-1'\'')
session = boto3.Session(region_name=AWS_REGION)

def get_db_credentials(secret_arn):
    client = session.client('\''secretsmanager'\'')
    response = client.get_secret_value(SecretId=secret_arn)
    return json.loads(response['\''SecretString'\''])

SECRET_ARN = os.getenv('\''RDS_SECRET_ARN'\'')
creds = get_db_credentials(SECRET_ARN)

DB_USER = creds['\''username'\'']
DB_PASSWORD = creds['\''password'\'']
DB_HOST = os.getenv('\''RDS_HOST'\'')
DB_PORT = 5432
DB_NAME = '\''transactional'\''

engine = create_engine(f\"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}\")

S3_BUCKET = os.getenv('\''S3_BUCKET'\'')
S3_PATH = \"movielens-source-data\"
s3_client = session.client('\''s3'\'')

csv_files = [\"ratings\", \"tags\", \"movies\", \"links\"]

for csv_name in csv_files:
    print(f\"Processing {csv_name}...\")
    file_key = f\"{S3_PATH}/{csv_name}.csv\"
    obj = s3_client.get_object(Bucket=S3_BUCKET, Key=file_key)
    df = pd.read_csv(obj['\''Body'\''])
    df.to_sql(csv_name, engine, if_exists=\"replace\", index=False)
    print(f\"Table {csv_name} created successfully!\")

print(\"All tables created successfully!\")
EOF","export RDS_SECRET_ARN='"${SECRET_ARN}"'","export RDS_HOST='"${RDS_HOST}"'","export S3_BUCKET='"${S3_BUCKET}"'","python3 /tmp/insert_data.py 2>&1"]' \
        --timeout-seconds 600 \
        --profile "${PROFILE}" \
        --region "${REGION}" \
        --query 'Command.CommandId' \
        --output text)
    
    echo "[SUCCESS] Command sent successfully"
    echo "[INFO] Command ID: ${command_id}"
    echo ""
    echo "Next step:"
    echo "  ./step_04_check_execution_result.sh ${command_id}"
}

main "$@"
