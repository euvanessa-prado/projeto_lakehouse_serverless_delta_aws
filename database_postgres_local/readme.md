# Database PostgreSQL - MovieLens Dataset

Este projeto importa o dataset MovieLens para um banco de dados PostgreSQL usando SQLAlchemy.

## 📋 Pré-requisitos

- Docker e Docker Compose
- Python 3.8+
- pip (gerenciador de pacotes Python)

## 🚀 Passo a Passo

### 1. Subir o banco de dados PostgreSQL

```bash
docker compose up -d
```

### 2. Testar a conexão com o banco

```bash
docker exec database_postgres-db-1 psql -U admin -d data_hands_on_postgres_local -c "SELECT version();"
```

### 3. Configurar o ambiente Python

Criar ambiente virtual:
```bash
python3 -m venv venv
source venv/bin/activate  # No Windows: venv\Scripts\activate
```

Instalar dependências:
```bash
pip install -r requirements.txt
```

### 4. Configurar variáveis de ambiente

Copiar o arquivo de exemplo e configurar suas credenciais:
```bash
cp .env.example .env
```

Editar o arquivo `.env` com suas credenciais (se necessário):
```env
DB_HOST=localhost
DB_PORT=5433
DB_NAME=data_hands_on_postgres_local
DB_USER=admin
DB_PASSWORD=postgres123
```

### 5. Importar os dados do MovieLens

```bash
python 1-import_to_postgres.py
```

Este script irá:
- Conectar ao PostgreSQL usando SQLAlchemy
- Criar 4 tabelas (movies, ratings, tags, links)
- Importar todos os dados dos arquivos CSV
- Total: ~124.000 registros

### 6. Verificar se os dados foram importados

```bash
python 2-check_tables.py
```

Este script mostra:
- Lista de todas as tabelas criadas
- Número de registros em cada tabela
- Colunas de cada tabela

## 📊 Estrutura dos Dados

### Tabelas criadas:

- **movies** (9.742 registros)
  - movieId, title, genres

- **ratings** (100.836 registros)
  - userId, movieId, rating, timestamp

- **tags** (3.683 registros)
  - userId, movieId, tag, timestamp

- **links** (9.742 registros)
  - movieId, imdbId, tmdbId

## 🔒 Segurança

- O arquivo `.env` contém credenciais sensíveis e **não deve ser commitado** no Git
- Use o arquivo `.env.example` como template
- O `.gitignore` já está configurado para ignorar arquivos `.env`

## 🛠️ Tecnologias Utilizadas

- **PostgreSQL** - Banco de dados relacional
- **SQLAlchemy** - ORM Python para PostgreSQL
- **Pandas** - Manipulação e leitura de dados CSV
- **Docker** - Containerização do PostgreSQL
- **python-dotenv** - Gerenciamento de variáveis de ambiente

## 📝 Notas

- O dataset MovieLens está localizado em `ml-latest-small/`
- Todas as colunas são criadas como tipo TEXT por padrão
- Os dados são inseridos usando `pandas.to_sql()` para melhor performance