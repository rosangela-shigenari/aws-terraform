module "data_resources" {
  source = "./modules/data_resources"
  project = var.project
  env     = var.env
  aws_region = var.aws_region
  client_cidr = var.client_cidr
  db_password = var.db_password
  rds_public_access = var.rds_public_access
}

module "deploy_resources" {
  source = "./modules/deploy_resources"
  project = var.project
  env     = var.env
  aws_region = var.aws_region
  vpc_id     = module.data_resources.vpc_id
  private_subnets = module.data_resources.private_subnets
  ecs_container_image = var.ecs_container_image
  image_tag = var.image_tag
}

module "gateway_resources" {
  source = "./modules/gateway_resources"
  project = var.project
  env     = var.env
  aws_region = var.aws_region
  nlb_arn = module.deploy_resources.nlb_arn
  nlb_dns = module.deploy_resources.nlb_dns
}

