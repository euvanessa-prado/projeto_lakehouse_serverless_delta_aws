#terraform apply -var-file=envs/develop.tfvars
#terraform init -backend-config="backends/develop.hcl"

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

###############################################################################
#########             VPC E SUBNETS                               #############
###############################################################################
module "vpc_public" {
  source                = "./modules/vpc"
  project_name          = "data-handson-mds"
  vpc_name              = "data-handson-mds-vpc-${var.environment}"
  vpc_cidr              = "10.0.0.0/16"
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs  = ["10.0.3.0/24", "10.0.4.0/24"]
  availability_zones    = ["us-east-1a", "us-east-1b"]
}



###############################################################################
#########             RDS - POSTGRES                              #############
###############################################################################
module "rds" {
  source = "./modules/rds"

  db_name              = "transactional"
  username             = "datahandsonmds"
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "16.4"
  instance_class       = "db.t3.micro"
  publicly_accessible  = false
  vpc_id               = module.vpc_public.vpc_id
  subnet_ids           = module.vpc_public.private_subnet_ids

  ingress_rules = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/16"]
    }
  ]
}



# ###############################################################################
# #########            DMS SERVERLESS                               #############
# ###############################################################################
# module "dms" {
#   source = "./modules/dms-serverless"

#   project_name               = "data-handson-mds"
#   rds_endpoint               = module.rds.rds_endpoint
#   rds_reader_endpoint        = module.rds.rds_reader_endpoint
#   rds_port                   = 5432
#   rds_username               = module.rds.rds_username
#   rds_password               = module.rds.rds_password
#   rds_db_name                = "transactional"
#   s3_bucket_name             = var.s3_bucket_raw
#   dms_subnet_ids             = module.vpc_public.public_subnet_ids
  
#   enable_ssl                 = false

#   vpc_id = module.vpc_public.vpc_id
# }



# ##############################################################################
# ########             INSTANCIAS EC2                              #############
# ##############################################################################
# module "ec2_instance" {
#   source             = "./modules/ec2"
#   ami_id             = "ami-04b4f1a9cf54c11d0"
#   instance_type      = "t3a.2xlarge"
#   subnet_id          = module.vpc_public.public_subnet_ids[0]
#   vpc_id             = module.vpc_public.vpc_id
#   key_name           = "conta-aws-mds"
#   associate_public_ip = true
#   instance_name      = "data-handson-mds-ec2-${var.environment}"
#   enable_ssm         = true  # Habilita SSM para túneis
#   root_volume_size   = 500
  
#   user_data = templatefile("${path.module}/scripts/bootstrap/ec2_bootstrap.sh", {})

#   ingress_rules = [
#     {
#       from_port   = 22
#       to_port     = 22
#       protocol    = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#     },
#     {
#       from_port   = 80
#       to_port     = 80
#       protocol    = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#     },
#     {
#       from_port   = 443
#       to_port     = 443
#       protocol    = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#     },
#     {
#       from_port   = 5432
#       to_port     = 5432
#       protocol    = "tcp"
#       cidr_blocks = ["10.0.0.0/16"]  # Permite conexão do Postgres dentro da VPC
#     }
#   ]
# }