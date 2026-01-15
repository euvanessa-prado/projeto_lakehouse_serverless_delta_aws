#!/usr/bin/env python3
"""
Script para fazer upload dos CSVs do MovieLens para o S3.

Usage:
    export S3_BUCKET=your-bucket-name
    python3 upload_csvs_to_s3.py
"""
import os
from pathlib import Path

import boto3

# Configurações via variáveis de ambiente
S3_BUCKET = os.getenv('S3_BUCKET')
S3_PREFIX = os.getenv('S3_PREFIX', 'movielens-source-data')
CSV_DIR = "ml-latest-small"
REGION = os.getenv('AWS_REGION', 'us-east-1')

FILES = ["movies.csv", "ratings.csv", "tags.csv", "links.csv"]


def validate_env():
    """Valida variáveis de ambiente obrigatórias."""
    if not S3_BUCKET:
        raise ValueError("Variável S3_BUCKET não definida")


def upload_files():
    """Faz upload dos arquivos CSV para o S3."""
    validate_env()

    s3_client = boto3.client('s3', region_name=REGION)

    print("=== Upload dos CSVs do MovieLens para o S3 ===")
    print(f"Bucket: {S3_BUCKET}")
    print(f"Prefix: {S3_PREFIX}")
    print()

    for file in FILES:
        local_path = Path(CSV_DIR) / file
        s3_key = f"{S3_PREFIX}/{file}"

        if not local_path.exists():
            print(f"❌ Arquivo não encontrado: {local_path}")
            continue

        print(f"Uploading {file}...")
        try:
            s3_client.upload_file(str(local_path), S3_BUCKET, s3_key)
            print(f"✅ {file} uploaded successfully")
        except Exception as e:
            print(f"❌ Erro ao fazer upload de {file}: {e}")

    print()
    print("✅ Upload concluído!")
    print(f"Arquivos disponíveis em: s3://{S3_BUCKET}/{S3_PREFIX}/")


if __name__ == "__main__":
    upload_files()
