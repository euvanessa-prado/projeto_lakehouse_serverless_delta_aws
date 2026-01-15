#!/usr/bin/env python3
"""
Script para importar CSVs do MovieLens para PostgreSQL local.

Usage:
    python3 "1- import_to_postgres_bd_local.py"
"""
import os

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import Column, MetaData, String, Table, create_engine, text

# Carregar variáveis de ambiente do arquivo .env
load_dotenv()

# Dados de conexão vindos do .env
HOST = os.getenv('DB_HOST')
PORT = int(os.getenv('DB_PORT', 5432))
DATABASE = os.getenv('DB_NAME')
USER = os.getenv('DB_USER')
PASSWORD = os.getenv('DB_PASSWORD')


def validate_env_vars():
    """Valida se todas as variáveis de ambiente foram carregadas."""
    if not all([HOST, PORT, DATABASE, USER, PASSWORD]):
        raise ValueError(
            "Erro: Variáveis de ambiente não configuradas. "
            "Crie o arquivo .env baseado no .env.example"
        )


def get_connection_string():
    """Retorna string de conexão para SQLAlchemy."""
    return f'postgresql://{USER}:{PASSWORD}@{HOST}:{PORT}/{DATABASE}'


def import_csv_to_table(engine, metadata, arquivo, tabela_nome):
    """Importa um arquivo CSV para uma tabela no PostgreSQL."""
    caminho = f'ml-latest-small/{arquivo}'

    print(f"Importando {arquivo}...")

    # Ler CSV
    df = pd.read_csv(caminho)

    # Deletar tabela se existir
    with engine.connect() as conn:
        conn.execute(text(f'DROP TABLE IF EXISTS {tabela_nome}'))
        conn.commit()

    # Criar lista de colunas para SQLAlchemy
    colunas = [Column(col, String) for col in df.columns]

    # Criar tabela usando SQLAlchemy
    tabela = Table(tabela_nome, metadata, *colunas, extend_existing=True)
    tabela.create(engine)

    # Inserir dados usando pandas to_sql
    df.to_sql(tabela_nome, engine, if_exists='append', index=False)

    print(f"{arquivo} importado com sucesso ({len(df)} linhas)\n")


def main():
    """Função principal de importação."""
    validate_env_vars()

    connection_string = get_connection_string()

    print("Conectando ao banco de dados...")
    engine = create_engine(connection_string)
    metadata = MetaData()
    print("Conectado com sucesso\n")

    # Lista de arquivos para importar
    arquivos = [
        ('movies.csv', 'movies'),
        ('ratings.csv', 'ratings'),
        ('tags.csv', 'tags'),
        ('links.csv', 'links')
    ]

    # Importar todos os arquivos
    for arquivo, tabela_nome in arquivos:
        import_csv_to_table(engine, metadata, arquivo, tabela_nome)

    # Fechar conexão
    engine.dispose()
    print("Todos os arquivos foram importados!")


if __name__ == "__main__":
    main()
