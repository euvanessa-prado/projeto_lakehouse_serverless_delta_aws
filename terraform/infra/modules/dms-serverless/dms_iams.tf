resource "aws_iam_role" "dms_vpc_role" {
  name = "dms-vpc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "dms.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "dms_vpc_role_attachment" {
  role       = aws_iam_role.dms_vpc_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSVPCManagementRole"
}

resource "aws_iam_role" "dms_s3_access" {
  name = "dms-s3-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "dms.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "dms_s3_policy" {
  name        = "dms-s3-parquet-policy"
  description = "Policy for DMS to write to S3 in Parquet format"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:*",
        ],
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_dms_s3_policy" {
  role       = aws_iam_role.dms_s3_access.name
  policy_arn = aws_iam_policy.dms_s3_policy.arn
}

# Política para permitir acesso ao CloudWatch Logs
resource "aws_iam_policy" "dms_cloudwatch_logs_policy" {
  name        = "dms-cloudwatch-logs-policy-${var.project_name}"
  description = "Policy for DMS to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_dms_cloudwatch_logs_policy" {
  role       = aws_iam_role.dms_vpc_role.name
  policy_arn = aws_iam_policy.dms_cloudwatch_logs_policy.arn
}

# Role específica para DMS CloudWatch Logs (nome fixo exigido pela AWS)
resource "aws_iam_role" "dms_cloudwatch_logs_role" {
  name = "dms-cloudwatch-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "dms.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

# Anexar política customizada de CloudWatch Logs à role específica do DMS
resource "aws_iam_role_policy_attachment" "attach_dms_cloudwatch_role_custom" {
  role       = aws_iam_role.dms_cloudwatch_logs_role.name
  policy_arn = aws_iam_policy.dms_cloudwatch_logs_policy.arn
}

# Anexar também a política gerenciada da AWS (para compatibilidade)
resource "aws_iam_role_policy_attachment" "attach_dms_cloudwatch_role_managed" {
  role       = aws_iam_role.dms_cloudwatch_logs_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonDMSCloudWatchLogsRole"
}


# Output da role de CloudWatch Logs
output "dms_cloudwatch_logs_role_arn" {
  value       = aws_iam_role.dms_cloudwatch_logs_role.arn
  description = "ARN da role IAM para DMS CloudWatch Logs"
}

# Role para DMS acessar Secrets Manager
resource "aws_iam_role" "dms_secrets_manager_role" {
  name = "dms-secrets-manager-access-role-${var.project_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "dms.us-east-1.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "dms_secrets_manager_policy" {
  name        = "dms-secrets-manager-policy-${var.project_name}"
  description = "Policy for DMS to access Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Resource = [
          var.rds_secret_arn,
          "arn:aws:secretsmanager:us-east-1:*:secret:${var.project_name}-dms-postgres-creds-v2*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_dms_secrets_manager_policy" {
  role       = aws_iam_role.dms_secrets_manager_role.name
  policy_arn = aws_iam_policy.dms_secrets_manager_policy.arn
}

output "dms_secrets_manager_role_arn" {
  value       = aws_iam_role.dms_secrets_manager_role.arn
  description = "ARN da role IAM para DMS Secrets Manager"
}
