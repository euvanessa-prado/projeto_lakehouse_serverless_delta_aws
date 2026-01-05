# Requirements Document

## Introduction

Migração do script de importação de dados MovieLens de psycopg2 para SQLAlchemy, mantendo a funcionalidade existente de importar arquivos CSV (movies, ratings, tags, links) para um banco de dados PostgreSQL.

## Glossary

- **Import_Script**: O script Python que realiza a importação dos dados CSV para PostgreSQL
- **SQLAlchemy**: Biblioteca ORM (Object-Relational Mapping) para Python
- **MovieLens_Dataset**: Conjunto de dados contendo informações sobre filmes, avaliações, tags e links
- **Database_Connection**: Conexão com o banco de dados PostgreSQL

## Requirements

### Requirement 1: Database Connection Management

**User Story:** Como desenvolvedor, eu quero gerenciar conexões ao banco de dados usando SQLAlchemy, para que eu possa ter melhor controle de recursos e usar padrões modernos de ORM.

#### Acceptance Criteria

1. THE Import_Script SHALL use SQLAlchemy Engine for database connections
2. THE Import_Script SHALL use connection parameters (host, port, database, user, password) to create the connection string
3. WHEN the script completes or encounters an error, THE Import_Script SHALL properly close database connections
4. THE Import_Script SHALL provide clear feedback about connection status

### Requirement 2: Table Creation and Management

**User Story:** Como desenvolvedor, eu quero criar tabelas dinamicamente baseadas nos arquivos CSV, para que o schema seja gerado automaticamente.

#### Acceptance Criteria

1. WHEN processing a CSV file, THE Import_Script SHALL drop the existing table if it exists
2. WHEN creating tables, THE Import_Script SHALL define all columns as TEXT type
3. THE Import_Script SHALL create tables using SQLAlchemy's table creation methods
4. THE Import_Script SHALL handle table names matching the CSV file names (movies, ratings, tags, links)

### Requirement 3: Data Import from CSV Files

**User Story:** Como desenvolvedor, eu quero importar dados de múltiplos arquivos CSV para o PostgreSQL, para que todos os dados do MovieLens sejam carregados no banco.

#### Acceptance Criteria

1. THE Import_Script SHALL process four CSV files: movies.csv, ratings.csv, tags.csv, and links.csv
2. WHEN reading CSV files, THE Import_Script SHALL use pandas to parse the data
3. WHEN inserting data, THE Import_Script SHALL insert all rows from each CSV file into the corresponding table
4. THE Import_Script SHALL process files sequentially in a defined order
5. WHEN each file is processed, THE Import_Script SHALL display progress information including filename and row count

### Requirement 4: Error Handling and Feedback

**User Story:** Como desenvolvedor, eu quero receber feedback claro sobre o processo de importação, para que eu possa identificar problemas rapidamente.

#### Acceptance Criteria

1. WHEN starting the import process, THE Import_Script SHALL display a connection status message
2. WHEN processing each file, THE Import_Script SHALL display the current file being imported
3. WHEN completing each file import, THE Import_Script SHALL display the number of rows imported
4. WHEN all imports complete successfully, THE Import_Script SHALL display a completion message
5. IF an error occurs, THEN THE Import_Script SHALL display a meaningful error message

### Requirement 5: Code Quality and Maintainability

**User Story:** Como desenvolvedor, eu quero código limpo e bem estruturado, para que seja fácil de manter e estender no futuro.

#### Acceptance Criteria

1. THE Import_Script SHALL use SQLAlchemy best practices for ORM operations
2. THE Import_Script SHALL maintain the same functional behavior as the original psycopg2 version
3. THE Import_Script SHALL use appropriate SQLAlchemy methods for bulk inserts
4. THE Import_Script SHALL organize code in a clear and readable manner
