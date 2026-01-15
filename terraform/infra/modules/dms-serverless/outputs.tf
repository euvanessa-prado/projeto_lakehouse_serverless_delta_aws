# Outputs do módulo DMS Serverless

output "dms_security_group_id" {
  value       = aws_security_group.dms_sg.id
  description = "ID do Security Group do DMS"
}

output "dms_replication_config_arn" {
  value       = aws_dms_replication_config.this.arn
  description = "ARN da configuração de replicação DMS Serverless"
}

output "dms_source_endpoint_arn" {
  value       = aws_dms_endpoint.postgres_source.endpoint_arn
  description = "ARN do endpoint source (PostgreSQL)"
}

output "dms_target_endpoint_arn" {
  value       = aws_dms_s3_endpoint.s3_target.endpoint_arn
  description = "ARN do endpoint target (S3)"
}
