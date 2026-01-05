import os
from sqlalchemy import create_engine, text, inspect
from dotenv import load_dotenv

# Carregar variáveis de ambiente
load_dotenv()

# Dados de conexão
host = os.getenv('DB_HOST')
port = int(os.getenv('DB_PORT'))
database = os.getenv('DB_NAME')
user = os.getenv('DB_USER')
password = os.getenv('DB_PASSWORD')

# Validar variáveis
if not all([host, port, database, user, password]):
    raise ValueError("Erro: Variáveis de ambiente não configuradas. Crie o arquivo .env")

# Criar connection string
connection_string = f'postgresql://{user}:{password}@{host}:{port}/{database}'

# Conectar
print("Conectando ao banco de dados...")
engine = create_engine(connection_string)

# Verificar tabelas
inspector = inspect(engine)
tables = inspector.get_table_names()

print(f"\n{'='*60}")
print(f"TABELAS NO BANCO DE DADOS: {database}")
print(f"{'='*60}\n")

if not tables:
    print("Nenhuma tabela encontrada!")
else:
    for table in tables:
        print(f"✅ Tabela: {table}")
        
        # Contar registros
        with engine.connect() as conn:
            result = conn.execute(text(f"SELECT COUNT(*) FROM {table}"))
            count = result.scalar()
            print(f"   └─ Registros: {count:,}")
        
        # Mostrar colunas
        columns = inspector.get_columns(table)
        print(f"   └─ Colunas: {', '.join([col['name'] for col in columns])}")
        print()

print(f"{'='*60}")
print(f"Total de tabelas: {len(tables)}")
print(f"{'='*60}")

engine.dispose()
