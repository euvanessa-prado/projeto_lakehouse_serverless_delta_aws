import pandas as pd
from sqlalchemy import create_engine, Table, Column, String, MetaData, text
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

# Carregar variáveis de ambiente do arquivo .env
load_dotenv()

# Dados de conexão vindos do .env
host = os.getenv('DB_HOST')
port = int(os.getenv('DB_PORT'))
database = os.getenv('DB_NAME')
user = os.getenv('DB_USER')
password = os.getenv('DB_PASSWORD')

# Validar que todas as variáveis foram carregadas
if not all([host, port, database, user, password]):
    raise ValueError("Erro: Variáveis de ambiente não configuradas. Crie o arquivo .env baseado no .env.example")

# Criar connection string para SQLAlchemy
connection_string = f'postgresql://{user}:{password}@{host}:{port}/{database}'

# Conectar ao banco usando SQLAlchemy
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

# Importar todos os arquivos em um loop
for arquivo, tabela_nome in arquivos:
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
    
    # Inserir dados usando pandas to_sql (mais eficiente com SQLAlchemy)
    df.to_sql(tabela_nome, engine, if_exists='append', index=False)
    
    print(f"{arquivo} importado com sucesso ({len(df)} linhas)\n")

# Fechar conexão
engine.dispose()
print("Todos os arquivos foram importados!")
