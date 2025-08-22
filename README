# AWS Infrastructure for Registration Service

This Terraform project provisions a full AWS environment for a **Registration Service** application using ECS Fargate, NLB, PostgreSQL, MSK, and API Gateway with VPC Link. It includes secure access to secrets via AWS Secrets Manager.

---

## Architecture Overview

### Networking

- **VPC:** Custom VPC with public and private subnets.
- **Public Subnets:** `10.0.1.0/24`, `10.0.2.0/24`  
  - RDS PostgreSQL (publicly accessible)  
  - NAT Gateway
- **Private Subnets:** `10.0.11.0/24`, `10.0.12.0/24`  
  - ECS Fargate tasks  
  - Internal NLB  
  - Kafka MSK cluster  

### Compute

- **ECS Cluster:** Fargate-based, running the `registration-service` container.  
- **ECR Repository:** Stores container images.  
- **Task Definition:** Configured with environment secrets and logging to CloudWatch.  

### Load Balancing

- **NLB (Internal):** Routes TCP traffic to ECS tasks on port 8080.  

### API Layer

- **API Gateway:** Public REST API.  
- **Integration:** VPC Link to internal NLB.  

### Database

- **PostgreSQL RDS (public):** Stores registration data.  
- **Subnet:** Public  
- **Security:** Access controlled via security group (`cidr_blocks = var.client_cidr`).  

### Kafka

- **MSK Cluster:** Private, TLS encrypted.  
- **Security Group:** Restricts access to VPC internal traffic only.  

### Secrets Management

- **AWS Secrets Manager:** Stores database and Kafka credentials.  
- Accessible by ECS tasks using IAM roles.  

---

## Terraform Modules & Resources

- **VPC:** `terraform-aws-modules/vpc/aws`  
- **ECS & ECR:** Cluster, Service, Task Definition, IAM roles  
- **API Gateway & VPC Link:** REST API, methods, integrations, stage  
- **Networking:** Security Groups, NLB, Target Groups, Listeners  
- **Database:** PostgreSQL RDS instance and subnet group  
- **Kafka MSK:** Private cluster with encryption in transit  
- **Secrets Manager:** `registration-service` secrets, Kafka truststore  
