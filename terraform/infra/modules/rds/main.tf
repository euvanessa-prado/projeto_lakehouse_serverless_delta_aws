# RDS will manage the password automatically in Secrets Manager
# No need for random_password or manual secret creation

resource "aws_security_group" "rds_sg" {
  name_prefix = "${var.db_name}-sg"
  vpc_id      = var.vpc_id
  description = "Security group for RDS ${var.db_name}"

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = "Allow ${ingress.value.protocol} on port ${ingress.value.from_port}"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "${var.db_name}-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.db_name}-subnet-group-${var.publicly_accessible ? "public" : "private"}"
  subnet_ids = var.subnet_ids
  
  tags = {
    Name = "${var.db_name}-subnet-group"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "postgres" {
  identifier           = var.db_name
  engine               = "postgres"
  engine_version       = "16.4"
  instance_class       = var.instance_class
  allocated_storage    = var.allocated_storage
  storage_type         = "gp3"
  
  db_name              = var.db_name
  username             = var.username
  
  # Use RDS-managed password in Secrets Manager
  manage_master_user_password   = true
  master_user_secret_kms_key_id = var.kms_key_id  # Optional: use specific KMS key
  
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  publicly_accessible    = var.publicly_accessible
  
  skip_final_snapshot    = true
  backup_retention_period = 0  # Free tier: 0 ou 1 dia apenas
  
  # CloudWatch Logs Export
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  
  tags = {
    Name = var.db_name
  }
  
  depends_on = [aws_cloudwatch_log_group.rds_logs]
}

# CloudWatch Log Group for RDS PostgreSQL logs
resource "aws_cloudwatch_log_group" "rds_logs" {
  name = "/aws/rds/instance/${var.db_name}/postgresql"
  
  tags = {
    Name = "${var.db_name}-postgresql-logs"
  }
}