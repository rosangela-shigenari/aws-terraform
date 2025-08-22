variable "project" { 
    type = string 
}
variable "env"     { 
    type = string 
}
variable "aws_region" { 
    type = string 
}
variable "client_cidr" {
  type        = string
  description = "Your current public IP in CIDR to allow temporary RDS access"
}
variable "db_password" { 
    type = string
    description = "Postgres admin password"
}
variable "rds_public_access" { 
    type = bool
    default = true 
}

