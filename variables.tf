###########################################
# Root variables.tf
###########################################

# General project info
variable "project" {
  type    = string
  default = "registration"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

# Your current public IP in CIDR to allow temporary RDS access
variable "client_cidr" {
  type        = string
  description = "Your current public IP in CIDR for temporary RDS access"
  default     = "0.0.0.0/0"
}

# RDS/Postgres
variable "db_password" {
  type        = string
  description = "postgres"
  default     = "Password1234567"   
}

variable "rds_public_access" {
  type    = bool
  default = true
}

# ECS Fargate
variable "ecs_container_image" {
  type        = string
  description = "Docker image URI for ECS task"
  default     = "public.ecr.aws/nginx/nginx:latest"
}
variable "image_tag" {
  type    = string
  default = "latest"
}
