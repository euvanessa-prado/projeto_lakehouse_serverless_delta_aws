output "instance_id" {
  description = "ID of the created EC2 instance"
  value       = aws_instance.this.id
}

output "public_ip" {
  description = "Public IP of the created EC2 instance"
  value       = aws_instance.this.public_ip
}

output "private_ip" {
  description = "Private IP of the created EC2 instance"
  value       = aws_instance.this.private_ip
}

output "security_group_id" {
  description = "ID of the created Security Group"
  value       = aws_security_group.this.id
}

output "iam_role_arn" {
  description = "ARN of the IAM role (if SSM is enabled)"
  value       = var.enable_ssm ? aws_iam_role.ssm_role[0].arn : null
}
