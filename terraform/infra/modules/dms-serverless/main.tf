# Buscar senha do RDS no Secrets Manager
data "aws_secretsmanager_secret_version" "rds_password" {
  secret_id = var.rds_secret_arn
}

locals {
  rds_credentials = jsondecode(data.aws_secretsmanager_secret_version.rds_password.secret_string)
  rds_password    = local.rds_credentials.password
}

resource "aws_security_group" "dms_sg" {
  name        = "${var.project_name}-dms-security-group"
  description = "Security Group for DMS serverless replication"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_dms_replication_subnet_group" "this" {
  replication_subnet_group_id          = "${var.project_name}-dms-subnet-group"
  subnet_ids                           = var.dms_subnet_ids
  replication_subnet_group_description = "DMS subnet group"
}

# DMS Serverless Replication Configuration
resource "aws_dms_replication_config" "this" {
  replication_config_identifier = "${var.project_name}-dms-serverless"
  source_endpoint_arn           = aws_dms_endpoint.postgres_source.endpoint_arn
  target_endpoint_arn           = aws_dms_s3_endpoint.s3_target.endpoint_arn
  replication_type              = "full-load"
  start_replication             = false  # NÃO iniciar automaticamente
  
  # Configuração simplificada para evitar problemas com TimestampColumnName
  replication_settings = jsonencode({
    "BeforeImageSettings": {
      "EnableBeforeImage": false,
      "ColumnFilter": "pk-only",
      "FieldName": "before-image"
    },
    "FullLoadSettings": {
      "TargetTablePrepMode": "DROP_AND_CREATE",
      "MaxFullLoadSubTasks": 8,
      "CommitRate": 10000
    },
    "Logging": {
      "EnableLogging": true,
      "LogLevel": "INFO"
    },
    "ControlTablesSettings": {
      "ControlSchema": "",
      "HistoryTimeslotInMinutes": 5,
      "HistoryTableEnabled": false,
      "StatusTableEnabled": true
    }
  })

  table_mappings = jsonencode({
    "rules": [
      {
        "rule-type": "selection",
        "rule-id": "1",
        "rule-name": "1",
        "object-locator": {
          "schema-name": "public",
          "table-name": "%"
        },
        "rule-action": "include"
      }
    ]
  })

  compute_config {
    replication_subnet_group_id = aws_dms_replication_subnet_group.this.replication_subnet_group_id
    vpc_security_group_ids      = [aws_security_group.dms_sg.id]
    max_capacity_units          = 8
    min_capacity_units          = 2
  }

  depends_on = [
    aws_iam_role_policy_attachment.attach_dms_cloudwatch_role_custom,
    aws_iam_role_policy_attachment.attach_dms_cloudwatch_role_managed,
    aws_iam_role_policy_attachment.attach_dms_cloudwatch_logs_policy
  ]

  lifecycle {
    ignore_changes = [
      replication_settings,
      table_mappings,
      start_replication
    ]
  }
}

resource "aws_dms_endpoint" "postgres_source" {
  endpoint_id                     = "${var.project_name}-postgres-source"
  endpoint_type                   = "source"
  engine_name                     = "postgres"
  database_name                   = var.rds_db_name
  secrets_manager_arn             = aws_secretsmanager_secret.dms_postgres_credentials.arn
  secrets_manager_access_role_arn = aws_iam_role.dms_secrets_manager_role.arn
  
  ssl_mode                        = var.enable_ssl ? "require" : "none"

  depends_on = [
    aws_iam_role_policy_attachment.attach_dms_secrets_manager_policy,
    aws_secretsmanager_secret_version.dms_postgres_credentials
  ]
}

# Secret customizado para DMS com todas as informações necessárias
resource "aws_secretsmanager_secret" "dms_postgres_credentials" {
  name                    = "${var.project_name}-dms-postgres-creds-v2"
  description             = "Credentials for DMS to connect to PostgreSQL RDS"
  recovery_window_in_days = 0  # Força deleção imediata sem período de recuperação
}

resource "aws_secretsmanager_secret_version" "dms_postgres_credentials" {
  secret_id = aws_secretsmanager_secret.dms_postgres_credentials.id
  secret_string = jsonencode({
    username = var.rds_username
    password = local.rds_password
    host     = var.rds_address
    port     = var.rds_port
  })
}


resource "aws_dms_s3_endpoint" "s3_target" {
  endpoint_id             = "${var.project_name}-s3-target"
  endpoint_type           = "target"
  bucket_name             = var.s3_bucket_name
  bucket_folder           = "movielens_rds_dms_serverless_dev/"
  compression_type        = "GZIP"
  data_format             = "parquet"
  parquet_version         = "parquet-1-0"
  service_access_role_arn = aws_iam_role.dms_s3_access.arn
  timestamp_column_name   = "dms_timestamp_col"
}

