output "database_name" {
  description = "Name of the Glue database"
  value       = aws_glue_catalog_database.this.name
}

output "database_arn" {
  description = "ARN of the Glue database"
  value       = aws_glue_catalog_database.this.arn
}

output "crawler_name" {
  description = "Name of the Glue crawler"
  value       = aws_glue_crawler.this.name
}

output "crawler_arn" {
  description = "ARN of the Glue crawler"
  value       = aws_glue_crawler.this.arn
}

output "crawler_role_arn" {
  description = "ARN of the IAM role used by the crawler"
  value       = aws_iam_role.glue_crawler.arn
}
