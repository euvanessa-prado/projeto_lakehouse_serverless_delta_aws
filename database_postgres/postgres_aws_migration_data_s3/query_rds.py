#!/usr/bin/env python3
"""
Script: query_rds.py

Executa queries no RDS via SSM tunnel sem necessidade de DBeaver.

Usage:
    export AWS_PROFILE=your-profile
    export AWS_REGION=us-east-1
    export EC2_INSTANCE_ID=i-xxxxxxxxx
    export SECRET_ARN=arn:aws:secretsmanager:...
    export RDS_HOST=your-rds-host.rds.amazonaws.com
    python3 query_rds.py
"""
import json
import os
import time

import boto3

# Configurações via variáveis de ambiente
PROFILE = os.getenv('AWS_PROFILE', 'default')
REGION = os.getenv('AWS_REGION', 'us-east-1')
INSTANCE_ID = os.getenv('EC2_INSTANCE_ID')
SECRET_ARN = os.getenv('SECRET_ARN')
RDS_HOST = os.getenv('RDS_HOST')
DB_NAME = os.getenv('DB_NAME', 'transactional')


def validate_env():
    """Valida variáveis de ambiente obrigatórias."""
    required = ['EC2_INSTANCE_ID', 'SECRET_ARN', 'RDS_HOST']
    missing = [var for var in required if not os.getenv(var)]
    if missing:
        raise ValueError(f"Variáveis obrigatórias não definidas: {missing}")


def get_credentials():
    """Obtém credenciais do RDS do Secrets Manager."""
    session = boto3.Session(profile_name=PROFILE, region_name=REGION)
    client = session.client('secretsmanager')
    response = client.get_secret_value(SecretId=SECRET_ARN)
    creds = json.loads(response['SecretString'])
    return creds['username'], creds['password']


def execute_query(query, description="Query"):
    """Executa query SQL no RDS via SSM."""
    username, password = get_credentials()

    escaped_password = password.replace("'", "'\\''")

    commands = [
        f"export PGPASSWORD='{escaped_password}'",
        f'psql -h {RDS_HOST} -U {username} -d {DB_NAME} -c "{query}"'
    ]

    session = boto3.Session(profile_name=PROFILE, region_name=REGION)
    ssm = session.client('ssm')

    print(f"\n[INFO] Executando: {description}")

    response = ssm.send_command(
        InstanceIds=[INSTANCE_ID],
        DocumentName='AWS-RunShellScript',
        Parameters={'commands': commands},
        TimeoutSeconds=60
    )

    command_id = response['Command']['CommandId']
    time.sleep(3)

    result = ssm.get_command_invocation(
        CommandId=command_id,
        InstanceId=INSTANCE_ID
    )

    if result['Status'] == 'Success':
        print(result['StandardOutputContent'])
    else:
        print(f"[ERROR] {result['StandardErrorContent']}")


def main():
    """Execução principal."""
    validate_env()

    print("=" * 60)
    print("RDS Data Viewer")
    print("=" * 60)

    queries = [
        ("SELECT COUNT(*) as total_movies FROM movies;", "Total Movies"),
        ("SELECT COUNT(*) as total_ratings FROM ratings;", "Total Ratings"),
        ("SELECT COUNT(*) as total_tags FROM tags;", "Total Tags"),
        ("SELECT COUNT(*) as total_links FROM links;", "Total Links"),
        ("SELECT * FROM movies LIMIT 5;", "Sample Movies"),
        ("SELECT * FROM ratings LIMIT 5;", "Sample Ratings"),
    ]

    for query, description in queries:
        execute_query(query, description)
        time.sleep(1)

    print("\n" + "=" * 60)
    print("Done!")
    print("=" * 60)


if __name__ == "__main__":
    main()
