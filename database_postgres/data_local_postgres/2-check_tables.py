#!/usr/bin/env python3
"""
Script para verificar tabelas no PostgreSQL local.

Usage:
    python3 2-check_tables.py
"""
import os

from dotenv import load_dotenv
from sqlalchemy import create_engine, inspect, text

# Carregar variáveis de ambiente
load_dotenv()

# Dados de conexão
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
            "Crie o arquivo .env"
        )


def get_connection_string():
    """Retorna string de conexão para SQLAlchemy."""
    return f'postgresql://{USER}:{PASSWORD}@{HOST}:{PORT}/{DATABASE}'


def print_table_info(engine, inspector, table):
    """Imprime informações de uma tabela."""
    print(f"✅ Tabela: {table}")

    # Contar registros
    with engine.connect() as conn:
        result = conn.execute(text(f"SELECT COUNT(*) FROM {table}"))
        count = result.scalar()
        print(f"   └─ Registros: {count:,}")

    # Mostrar colunas
    columns = inspector.get_columns(table)
    column_names = ', '.join([col['name'] for col in columns])
    print(f"   └─ Colunas: {column_names}")
    print()


def main():
    """Função principal de verificação."""
    validate_env_vars()

    connection_string = get_connection_string()

    print("Conectando ao banco de dados...")
    engine = create_engine(connection_string)

    # Verificar tabelas
    inspector = inspect(engine)
    tables = inspector.get_table_names()

    print(f"\n{'=' * 60}")
    print(f"TABELAS NO BANCO DE DADOS: {DATABASE}")
    print(f"{'=' * 60}\n")

    if not tables:
        print("Nenhuma tabela encontrada!")
    else:
        for table in tables:
            print_table_info(engine, inspector, table)

    print(f"{'=' * 60}")
    print(f"Total de tabelas: {len(tables)}")
    print(f"{'=' * 60}")

    engine.dispose()


if __name__ == "__main__":
    main()
