output "rds_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "rds_reader_endpoint" {
  value = aws_db_instance.postgres.endpoint
  description = "Endpoint do RDS Postgres (mesmo que o writer)"
}

output "rds_secret_arn" {
  value       = length(aws_db_instance.postgres.master_user_secret) > 0 ? aws_db_instance.postgres.master_user_secret[0].secret_arn : null
  description = "ARN do secret gerenciado pelo RDS no AWS Secrets Manager"
}

output "rds_secret_name" {
  value       = length(aws_db_instance.postgres.master_user_secret) > 0 ? split(":", aws_db_instance.postgres.master_user_secret[0].secret_arn)[6] : null
  description = "Nome do secret gerenciado pelo RDS no AWS Secrets Manager"
}

output "rds_security_group_id" {
  value = aws_security_group.rds_sg.id
}

output "rds_subnet_group_name" {
  value = aws_db_subnet_group.rds_subnet_group.name
}

output "rds_username" {
  description = "Usuário mestre do banco RDS"
  value       = var.username
}

output "rds_address" {
  description = "Endereço do RDS (host)"
  value       = aws_db_instance.postgres.address
}

output "rds_port" {
  description = "Porta do RDS"
  value       = aws_db_instance.postgres.port
}

output "rds_db_name" {
  description = "Nome do banco de dados"
  value       = aws_db_instance.postgres.db_name
}
