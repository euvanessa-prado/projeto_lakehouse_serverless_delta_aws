# ============================================
# AWS Glue Crawler for Parquet Data (DMS)
# ============================================

# Glue Database
resource "aws_glue_catalog_database" "this" {
  name        = var.database_name
  description = var.database_description
  
  tags = {
    Name        = var.database_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Source      = "DMS-Parquet"
  }
}

# IAM Role for Glue Crawler
resource "aws_iam_role" "glue_crawler" {
  name = "${var.name_prefix}-glue-crawler-parquet-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.name_prefix}-glue-crawler-parquet-role"
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# IAM Policy for S3 Access
resource "aws_iam_role_policy" "glue_crawler_s3" {
  name = "${var.name_prefix}-glue-crawler-parquet-s3-policy-${var.environment}"
  role = aws_iam_role.glue_crawler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })
}

# Attach AWS Managed Policy for Glue Service
resource "aws_iam_role_policy_attachment" "glue_service" {
  role       = aws_iam_role.glue_crawler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# Glue Crawler
resource "aws_glue_crawler" "this" {
  name          = "${var.name_prefix}-parquet-crawler-${var.environment}"
  role          = aws_iam_role.glue_crawler.arn
  database_name = aws_glue_catalog_database.this.name
  description   = var.crawler_description

  s3_target {
    path = var.s3_target_path
  }

  # Configuração para detectar schema automaticamente
  schema_change_policy {
    delete_behavior = var.delete_behavior
    update_behavior = var.update_behavior
  }

  # Configuração para lidar com partições
  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = {
        AddOrUpdateBehavior = "InheritFromTable"
      }
    }
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
  })

  # Agendamento opcional (use diretamente, não como bloco dinâmico)
  schedule = var.crawler_schedule

  # Prefixo opcional para tabelas
  table_prefix = var.table_prefix

  tags = {
    Name        = "${var.name_prefix}-parquet-crawler"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Source      = "DMS-Parquet"
  }
}
