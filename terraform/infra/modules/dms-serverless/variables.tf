variable "project_name" {
  type = string
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "rds_endpoint" {
  type = string
  description = "Writer endpoint do RDS PostgreSQL (com porta)"
}

variable "rds_reader_endpoint" {
  type = string
  description = "Reader endpoint do RDS PostgreSQL"
  default = ""  # Será usado o endpoint principal se não for fornecido
}

variable "rds_address" {
  type = string
  description = "Endereço do RDS PostgreSQL (sem porta)"
}

variable "rds_port" {
  type    = number
  default = 5432
}

variable "rds_username" {
  type = string
}

variable "rds_secret_arn" {
  type        = string
  description = "ARN do secret no AWS Secrets Manager contendo a senha do RDS"
  sensitive   = true
}

variable "rds_db_name" {
  type = string
}

variable "s3_bucket_name" {
  type = string
}

variable "dms_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "enable_ssl" {
  type    = bool
  default = false
  description = "Habilitar conexão SSL com o RDS PostgreSQL"
}

variable "log_retention_days" {
  description = "Número de dias para reter os logs do CloudWatch"
  type        = number
  default     = 14
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"
}
