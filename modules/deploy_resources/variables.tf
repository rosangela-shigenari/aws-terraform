variable "project" { 
    type = string 
}
variable "env"     { 
    type = string
}
variable "aws_region" { 
    type = string 
}
variable "vpc_id" { 
    type = string 
}
variable "private_subnets" { 
    type = list(string) 
}
variable "ecs_container_image" {
  type        = string
  description = "Docker image URI for ECS task"
}
variable "image_tag" {
  description = "Git SHA for Docker image"
  type        = string
}

