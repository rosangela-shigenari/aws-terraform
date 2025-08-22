###########################################
# VPC
###########################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.21"

  name = "${var.project}-${var.env}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Project = var.project, Env = var.env }
}

# Security group for RDS
resource "aws_security_group" "rds_public" {
  name        = "${var.project}-${var.env}-rds-sg-public"
  description = "RDS public access"
  vpc_id      = module.vpc.vpc_id

  # Allow access for my IP
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.client_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = var.project
    Env     = var.env
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "postgres_public" {
  name       = "${var.project}-${var.env}-dbsubnet-public"
  subnet_ids = module.vpc.public_subnets
  tags = {
    Project = var.project
    Env     = var.env
  }
}

# RDS PostgreSQL
resource "aws_db_instance" "postgres_public" {
  identifier              = "${var.project}-${var.env}-pg-public"
  engine                  = "postgres"
  engine_version          = "11.22-rds.20240418"
  instance_class          = "db.t3.micro"
  allocated_storage       = 20
  db_subnet_group_name    = aws_db_subnet_group.postgres_public.name
  vpc_security_group_ids  = [aws_security_group.rds_public.id]
  username                = "pgadmin"
  password                = var.db_password
  db_name                 = "registrationdb"
  publicly_accessible     = true
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 1
  multi_az                = false
  storage_encrypted       = true

  tags = {
    Project = var.project
    Env     = var.env
  }
}

# Create table 
resource "null_resource" "create_registration_table" {
  depends_on = [aws_db_instance.postgres_public]

  provisioner "local-exec" {
    command = <<EOT
      PGPASSWORD="${var.db_password}" psql \
        -h ${aws_db_instance.postgres_public.address} \
        -U pgadmin \
        -d registrationdb -c "
        CREATE TABLE IF NOT EXISTS registration (
          id SERIAL PRIMARY KEY,
          first_name VARCHAR(100) NOT NULL,
          last_name VARCHAR(100) NOT NULL,
          age CHAR(3) NOT NULL,
          country_code CHAR(2) NOT NULL,
          email VARCHAR(150) NOT NULL UNIQUE,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );"
    EOT
  }
}

###########################################
# Security Group for MSK (private access)
###########################################
resource "aws_security_group" "msk" {
  name        = "${var.project}-${var.env}-msk-sg"
  description = "MSK private access"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 9094
    to_port     = 9094
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"] # only allow VPC internal traffic
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = var.project
    Env     = var.env
  }
}

###########################################
# Kafka MSK Cluster (private, TLS)
###########################################
resource "aws_msk_cluster" "kafka" {
  cluster_name           = "${var.project}-${var.env}-msk"
  kafka_version          = "3.6.0"
  number_of_broker_nodes = 2

  broker_node_group_info {
    instance_type   = "kafka.m5.large"
    client_subnets  = module.vpc.private_subnets 
    security_groups = [aws_security_group.msk.id]
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS"
      in_cluster    = true
    }
  }

  tags = {
    Project = var.project
    Env     = var.env
  }
}