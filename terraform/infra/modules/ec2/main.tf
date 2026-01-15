# IAM Role for SSM
resource "aws_iam_role" "ssm_role" {
  count = var.enable_ssm ? 1 : 0
  name  = "${var.instance_name}-ssm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Attach SSM Managed Policy
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.ssm_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach S3 Read Policy
resource "aws_iam_role_policy_attachment" "s3_policy" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.ssm_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# Attach Secrets Manager Read Policy
resource "aws_iam_role_policy_attachment" "secrets_policy" {
  count      = var.enable_ssm ? 1 : 0
  role       = aws_iam_role.ssm_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

# Instance Profile
resource "aws_iam_instance_profile" "ssm_profile" {
  count = var.enable_ssm ? 1 : 0
  name  = "${var.instance_name}-ssm-profile"
  role  = aws_iam_role.ssm_role[0].name
}

# Security Group
resource "aws_security_group" "this" {
  name        = "${var.instance_name}-sg"
  description = "Security Group for ${var.instance_name}"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.instance_name}-sg"
  }
}

# EC2 Instance
resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  key_name                    = var.key_name != "" ? var.key_name : null
  associate_public_ip_address = var.associate_public_ip
  user_data                   = var.user_data != "" ? var.user_data : null
  user_data_replace_on_change = true
  iam_instance_profile        = var.enable_ssm ? aws_iam_instance_profile.ssm_profile[0].name : null

  vpc_security_group_ids = [aws_security_group.this.id]

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = {
    Name = var.instance_name
  }

  depends_on = [aws_security_group.this]
}
