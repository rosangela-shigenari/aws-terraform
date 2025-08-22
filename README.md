# Infraestrutura AWS para o Registration Service

Este projeto em **Terraform** provisiona um ambiente completo na AWS para a aplicação **Registration Service**, utilizando ECS Fargate, NLB, PostgreSQL, MSK e API Gateway com VPC Link. Inclui também acesso seguro a segredos via AWS Secrets Manager.  

---

## Visão Geral da Arquitetura

### Rede (Networking)

- **VPC:** VPC customizada com sub-redes públicas e privadas.  
- **Sub-redes Públicas:** `10.0.1.0/24`, `10.0.2.0/24`  
  - RDS PostgreSQL (acessível publicamente)  
  - NAT Gateway  
- **Sub-redes Privadas:** `10.0.11.0/24`, `10.0.12.0/24`  
  - Tarefas do ECS Fargate  
  - NLB interno  
  - Cluster Kafka MSK  

### Computação (Compute)

- **Cluster ECS:** Baseado em Fargate, executando o container `registration-service`.  
- **Repositório ECR:** Armazena imagens de containers.  
- **Definição de Tarefa (Task Definition):** Configurada com variáveis de ambiente seguras e logging no CloudWatch.  

### Balanceamento de Carga

- **NLB (Interno):** Roteia tráfego TCP para tarefas ECS na porta 8080.  

### Camada de API

- **API Gateway:** REST API pública.  
- **Integração:** VPC Link para o NLB interno.  

### Banco de Dados

- **PostgreSQL RDS (público):** Armazena os dados de registro.  
- **Sub-rede:** Pública  
- **Segurança:** Acesso controlado via Security Group (`cidr_blocks = var.client_cidr`).  

### Kafka

- **Cluster MSK:** Privado, com criptografia TLS.  
- **Security Group:** Restringe acesso apenas ao tráfego interno da VPC.  

### Gestão de Segredos

- **AWS Secrets Manager:** Armazena credenciais do banco de dados e do Kafka.  
- Acessível pelas tarefas ECS via IAM roles.  

---

## Módulos e Recursos do Terraform

- **VPC:** `terraform-aws-modules/vpc/aws`  
- **ECS & ECR:** Cluster, Service, Task Definition, IAM roles  
- **API Gateway & VPC Link:** REST API, métodos, integrações, stage  
- **Networking:** Security Groups, NLB, Target Groups, Listeners  
- **Banco de Dados:** Instância PostgreSQL RDS e subnet group  
- **Kafka MSK:** Cluster privado com criptografia em trânsito  
- **Secrets Manager:** Secrets do `registration-service`, truststore do Kafka  
