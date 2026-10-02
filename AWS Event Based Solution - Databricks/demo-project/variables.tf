variable "aws_region" {
  type        = string
  description = "Target AWS region"
  default     = "eu-west-1"
}

variable "primary_bucket_name" {
  type        = string
  description = "Name of the first S3 bucket (must be globally unique)"
}

variable "secondary_bucket_name" {
  type        = string
  description = "Name of the second S3 bucket (must be globally unique)"
}

variable "databricks_host" {
  type        = string
  description = "Databricks Workspace URL without https://"
}

variable "databricks_token" {
  type        = string
  description = "Databricks Personal Access Token"
  sensitive   = true
}

variable "databricks_user_email" {
  type        = string
  description = "Databricks user account email for file paths"
}