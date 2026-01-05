variable "environment" {
  description = "Ambiente de implantação (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "Região AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "s3_bucket_raw" {
  description = "Nome do bucket S3 para armazenar dados brutos"
  type        = string
}

variable "s3_bucket_scripts" {
  description = "Nome do bucket S3 para armazenar scripts e configurações"
  type        = string
}

variable "ec2_key_name" {
  description = "Nome da chave SSH para acesso à instância EC2"
  type        = string
  default     = ""
}
