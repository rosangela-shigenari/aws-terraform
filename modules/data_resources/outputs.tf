output "rds_endpoint" {
  value = aws_db_instance.postgres_public.address
}

output "rds_db_name" {
  value = aws_db_instance.postgres_public.db_name
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "public_subnets" {
  value = module.vpc.public_subnets
}
