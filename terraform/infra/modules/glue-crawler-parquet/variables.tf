variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "database_name" {
  description = "Name of the Glue database to create"
  type        = string
}

variable "database_description" {
  description = "Description of the Glue database"
  type        = string
  default     = "Database for Parquet data from DMS replication"
}

variable "s3_bucket_name" {
  description = "Name of the S3 bucket containing the data"
  type        = string
}

variable "s3_target_path" {
  description = "S3 path to crawl (e.g., s3://bucket/path/)"
  type        = string
}

variable "crawler_description" {
  description = "Description of the Glue crawler"
  type        = string
  default     = "Crawler for Parquet data from DMS replication"
}

variable "crawler_schedule" {
  description = "Cron expression for crawler schedule (optional)"
  type        = string
  default     = null
}

variable "table_prefix" {
  description = "Prefix to add to table names (optional)"
  type        = string
  default     = ""
}

variable "delete_behavior" {
  description = "Behavior when a table is deleted from the source"
  type        = string
  default     = "LOG"
  
  validation {
    condition     = contains(["LOG", "DELETE_FROM_DATABASE", "DEPRECATE_IN_DATABASE"], var.delete_behavior)
    error_message = "delete_behavior must be one of: LOG, DELETE_FROM_DATABASE, DEPRECATE_IN_DATABASE"
  }
}

variable "update_behavior" {
  description = "Behavior when a table schema changes"
  type        = string
  default     = "UPDATE_IN_DATABASE"
  
  validation {
    condition     = contains(["LOG", "UPDATE_IN_DATABASE"], var.update_behavior)
    error_message = "update_behavior must be one of: LOG, UPDATE_IN_DATABASE"
  }
}
