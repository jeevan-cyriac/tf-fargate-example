variable "application_name" {
  type        = string
  default     = "cloud-custodian"
  description = "Name of the application"
}

variable "subnets" {
  type        = list(string)
  description = "List of subnets to deploy the ECS"
}

variable "env" {
  type        = string
  description = "Environment"
}

variable "vpc_id" {
  type        = string
  description = "FinOps VPC ID where the lambda and rds are deployed"
}

variable "cron_expression" {
  type    = string
  default = "cron(10 06 * * ? *)"
}

variable "container_image_name" {
  type    = string
  default = "cloud-custodian-runner"
}

variable "container_version" {
  type    = string
  default = "latest"
}

variable "airbrake_api_key" {
  type        = string
  description = "Airbrake API key for the airbrake project"
}

variable "airbrake_project_id" {
  type        = string
  description = "Airbrake Project id for the airbrake project"
}

variable "rds_cluster" {
  type    = string
  default = "cloudservices"
}

variable "rds_db_reporting" {
  type    = string
  default = "reporting"
}

variable "rds_db_operational" {
  type    = string
  default = "cloud_services"
}

variable "rds_table_c7n" {
  type        = string
  default     = "cloud_custodian_history"
  description = "Name of Cloud Custodian history resources table"
}

variable "rds_table_c7n_non_compl_resources" {
  type        = string
  default     = "cloud_custodian_nc_resources"
  description = "Name of Cloud Custodian non-compliant resources table"
}

variable "rds_table_aws_cam" {
  type        = string
  default     = "aws_cam"
  description = "Name of AWS cam RDS table"
}

variable "rds_username_reporter" {
  type        = string
  default     = "c7n-reporter"
  description = "Name of mysql user for updating the RDS table"
}

variable "ecs_cpu_size" {
  type        = number
  default     = 2048
  description = "Runner ECS task CPU size"
}

variable "ecs_memory_size" {
  type        = number
  default     = 4096
  description = "Runner ECS task memory size"
}

variable "lambda_arn_waive_nc_resources" {
  type        = string
  description = "ARN of cs-portal-cloud-custodian-waivered Lambda function"
}
