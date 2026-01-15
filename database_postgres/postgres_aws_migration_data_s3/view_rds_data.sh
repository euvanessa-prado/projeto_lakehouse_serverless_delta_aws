#!/bin/bash
################################################################################
# Script: view_rds_data.sh
# Description: View RDS data without DBeaver or Python dependencies
# Usage:
#   export AWS_PROFILE=your-profile
#   export EC2_INSTANCE_ID=i-xxxxxxxxx
#   export SECRET_ARN=arn:aws:secretsmanager:...
#   export RDS_HOST=your-rds-host.rds.amazonaws.com
#   ./view_rds_data.sh
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

# Function to execute query
execute_query() {
    local query="$1"
    local description="$2"
    
    echo ""
    echo "=========================================="
    echo "${description}"
    echo "=========================================="
    
    local command_id
    command_id=$(aws ssm send-command \
        --instance-ids "${INSTANCE_ID}" \
        --document-name "AWS-RunShellScript" \
        --parameters 'commands=["export RDS_SECRET_ARN='"${SECRET_ARN}"'","/opt/venv/bin/python3 -c \"import boto3, json, os; session = boto3.Session(region_name='\''us-east-1'\''); client = session.client('\''secretsmanager'\''); response = client.get_secret_value(SecretId=os.getenv('\''RDS_SECRET_ARN'\'')); creds = json.loads(response['\''SecretString'\'']); print(creds['\''password'\''])\" > /tmp/dbpass","export PGPASSWORD=$(cat /tmp/dbpass)","psql -h '"${RDS_HOST}"' -U '"${DB_USER}"' -d '"${DB_NAME}"' -c \"'"${query}"'\""]' \
        --timeout-seconds 60 \
        --profile "${PROFILE}" \
        --region "${REGION}" \
        --query 'Command.CommandId' \
        --output text)
    
    sleep 3
    
    aws ssm get-command-invocation \
        --command-id "${command_id}" \
        --instance-id "${INSTANCE_ID}" \
        --profile "${PROFILE}" \
        --region "${REGION}" \
        --query 'StandardOutputContent' \
        --output text
}

# Main execution
main() {
    echo "=========================================="
    echo "RDS Data Viewer"
    echo "=========================================="
    
    execute_query "SELECT 'movies' as table_name, COUNT(*) as row_count FROM movies UNION ALL SELECT 'ratings', COUNT(*) FROM ratings UNION ALL SELECT 'tags', COUNT(*) FROM tags UNION ALL SELECT 'links', COUNT(*) FROM links ORDER BY table_name;" "Table Row Counts"
    
    execute_query "SELECT * FROM movies LIMIT 10;" "Sample Movies (First 10)"
    
    execute_query "SELECT * FROM ratings LIMIT 10;" "Sample Ratings (First 10)"
    
    execute_query "SELECT m.title, COUNT(r.rating) as num_ratings, ROUND(AVG(r.rating)::numeric, 2) as avg_rating FROM movies m JOIN ratings r ON m.movieid = r.movieid GROUP BY m.movieid, m.title HAVING COUNT(r.rating) >= 50 ORDER BY avg_rating DESC LIMIT 10;" "Top 10 Rated Movies (min 50 ratings)"
    
    echo ""
    echo "=========================================="
    echo "Done!"
    echo "=========================================="
}

main "$@"
