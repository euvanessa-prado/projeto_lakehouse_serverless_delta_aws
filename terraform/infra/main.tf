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



###############################################################################
#########            DMS SERVERLESS                               #############
###############################################################################
module "dms" {
  source = "./modules/dms-serverless"

  project_name               = "data-handson-mds"
  rds_endpoint               = module.rds.rds_endpoint
  rds_reader_endpoint        = module.rds.rds_reader_endpoint
  rds_address                = module.rds.rds_address  # Host sem porta
  rds_port                   = 5432
  rds_username               = module.rds.rds_username
  rds_secret_arn             = module.rds.rds_secret_arn
  rds_db_name                = "transactional"
  s3_bucket_name             = var.s3_bucket_raw
  dms_subnet_ids             = module.vpc_public.private_subnet_ids
  
  enable_ssl                 = false

  vpc_id = module.vpc_public.vpc_id
}

# Regra de ingress para permitir DMS conectar no RDS
resource "aws_security_group_rule" "rds_allow_dms" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = module.dms.dms_security_group_id
  security_group_id        = module.rds.rds_security_group_id
  description              = "Allow DMS Serverless to connect to RDS PostgreSQL"
}



# ##############################################################################
# ########             INSTANCIAS EC2                              #############
# ##############################################################################
# module "ec2_instance" {
#   source             = "./modules/ec2"
#   ami_id             = "ami-04b4f1a9cf54c11d0"
#   instance_type      = "t3.small"
#   subnet_id          = module.vpc_public.public_subnet_ids[0]
#   vpc_id             = module.vpc_public.vpc_id
#   key_name           = ""
#   associate_public_ip = true
#   instance_name      = "data-handson-mds-ec2-${var.environment}"
#   enable_ssm         = true
#   root_volume_size   = 30
  
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



##############################################################################
########            GLUE JOBS                                   #############
##############################################################################
module "glue_jobs_etl" {
  source = "./modules/glue-job"

  project_name      = "data-handson-mds-deltalake-raw-curated"
  environment       = var.environment
  region            = var.region
  s3_bucket_scripts = var.s3_bucket_scripts
  s3_bucket_data    = var.s3_bucket_raw
  scripts_local_path = "scripts/glue_etl"
  
  job_scripts = {
    "datahandson-mds-raw-staged-deltalake" = "datahandson-mds-raw-staged-deltalake.py",
    "datahandson-mds-staged-curated-deltalake-user-tags" = "datahandson-mds-staged-curated-deltalake-user-tags.py",
    "datahandson-mds-staged-curated-deltalake-movie-ratings" = "datahandson-mds-staged-curated-deltalake-movie-ratings.py"
  }
  
  worker_type       = "G.1X"
  number_of_workers = 3
  timeout           = 60
  max_retries       = 1
  max_concurrent_runs = 4  # Permite 4 execuções paralelas do mesmo job
  
  additional_python_modules = "delta-spark==3.2.1"
  
  additional_arguments = {
    "--enable-glue-datacatalog" = "true"
    "--conf"                    = "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension --conf spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog --conf spark.delta.logStore.class=org.apache.spark.sql.delta.storage.S3SingleDriverLogStore"
    "--datalake-formats"        = "delta"
  }
}





###############################################################################
#########            GLUE CRAWLER DELTA LAKE - CURATED           #############
###############################################################################
module "glue_crawler_delta" {
  source = "./modules/glue-crawler-delta"

  name_prefix    = "data-handson-mds"
  environment    = var.environment
  database_name  = "datahandson_mds_movielens_deltalake"
  
  delta_tables = [
    # Apenas CURATED (Gold Layer) - Dados prontos para consumo
    "s3://${var.s3_bucket_curated}/movielens_delta_glue/movie_ratings/",
    "s3://${var.s3_bucket_curated}/movielens_delta_glue/user_tags/"
  ]

  # Opcional: configurar um agendamento para o crawler
  # crawler_schedule = "cron(0 12 * * ? *)"  # Executa diariamente ao meio-dia
  
  # Opcional: prefixo para as tabelas criadas pelo crawler
  # table_prefix   = "curated_"
  
}

###############################################################################
#########            GLUE CRAWLER PARQUET (DMS)                   #############
###############################################################################
module "glue_crawler_parquet_dms" {
  source = "./modules/glue-crawler-parquet"

  name_prefix    = "data-handson-mds"
  environment    = var.environment
  database_name  = "movielens_dms_parquet"
  s3_bucket_name = var.s3_bucket_raw
  s3_target_path = "s3://${var.s3_bucket_raw}/movielens_rds_dms_serverless_dev/"
  
  database_description = "MovieLens data from RDS via DMS (Parquet format)"
  crawler_description  = "Crawler for MovieLens Parquet data from DMS replication"
  
  # Opcional: agendar crawler para rodar automaticamente
  # crawler_schedule = "cron(0 2 * * ? *)"  # Executa diariamente às 2h da manhã
  
  # Opcional: adicionar prefixo às tabelas
  # table_prefix = "dms_"
  
  # Comportamento quando schema muda
  delete_behavior = "LOG"
  update_behavior = "UPDATE_IN_DATABASE"
}




module "glue_jobs_dq" {
  source = "./modules/glue-job"

  project_name      = "data-handson-mds-curated-dq"
  environment       = var.environment
  region            = var.region
  s3_bucket_scripts = var.s3_bucket_scripts
  s3_bucket_data    = var.s3_bucket_raw
  scripts_local_path = "scripts/glue_etl"
  
  job_scripts = {
    "datahandson-mds-deltalake-data-quality" = "datahandson-mds-deltalake-data-quality.py"
  }
  
  worker_type       = "G.1X"
  number_of_workers = 3
  timeout           = 60
  max_retries       = 1
  
  additional_python_modules = "great_expectations[spark]==0.16.5,delta-spark==3.2.1"
  
  additional_arguments = {
    "--enable-glue-datacatalog" = "true"
    "--conf"                    = "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension --conf spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog --conf spark.delta.logStore.class=org.apache.spark.sql.delta.storage.S3SingleDriverLogStore"
    "--datalake-formats"        = "delta"
  }
}

###############################################################################
#########            STEP FUNCTIONS                               #############
###############################################################################
module "step_functions" {
  source = "./modules/step-functions"

  project_name = "data-handson-mds"
  environment  = var.environment
  region       = var.region
  
  # Definições das máquinas de estado
  state_machines = {
    "datahandson-mds-movielens-glue-etl" = {
      definition_file = "datahandson-mds-movielens-glue-etl.json"
      type            = "STANDARD"
    }
  }
  
  # Permissões adicionais para o Step Functions
  additional_iam_statements = [
    {
      Effect = "Allow"
      Action = [
        "glue:StartJobRun",
        "glue:GetJobRun",
        "glue:GetJobRuns",
        "glue:BatchStopJobRun"
      ]
      Resource = "*"
    }
  ]
  
  # Anexar políticas gerenciadas
  attach_glue_policy = true
  
  # Configurações de logging
  log_retention_days = 30
  include_execution_data = true
  logging_level = "ALL"
}

