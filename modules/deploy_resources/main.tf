###########################################
# ECS Fargate module with ECR
###########################################

# CloudWatch log group for ECS
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/registration-service"
  retention_in_days = 14
}

# ECS Cluster
resource "aws_ecs_cluster" "this" {
  name = "${var.project}-${var.env}-cluster"
}

# IAM: ECS task execution role
data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}


resource "aws_iam_role" "ecs_execution" {
  name               = "${var.project}-${var.env}-ecs-execution"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_execution_attach" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM: ECS task role
resource "aws_iam_role" "ecs_task" {
  name               = "${var.project}-${var.env}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
}

###########################################
# ECR Repository (stores container images)
###########################################
resource "aws_ecr_repository" "app_repo" {
  name                 = "${var.project}-${var.env}-repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

###########################################
# Networking: Security Groups
###########################################
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project}-${var.env}-ecs-sg"
  description = "Allow HTTP from NLB to ECS tasks"
  vpc_id      = var.vpc_id

  ingress {
    description     = "HTTP from NLB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.nlb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group placeholder for LB reference
resource "aws_security_group" "nlb" {
  name   = "${var.project}-${var.env}-nlb-sg"
  vpc_id = var.vpc_id
}

###########################################
# NLB (Private)
###########################################
resource "aws_lb" "nlb" {
  name               = "${var.project}-${var.env}-nlb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.private_subnets
}

# NLB Target Group
resource "aws_lb_target_group" "tg" {
  name        = "${var.project}-${var.env}-tg"
  port        = 8080
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    port                = "8080"
    protocol            = "TCP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}


# NLB Listener
resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 8080
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}



###########################################
# ECS Task Definition (with ECR image)
###########################################
data "aws_ecr_image" "registration_service" {
  repository_name = aws_ecr_repository.app_repo.name
  most_recent     = true
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.project}-${var.env}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name         = "registration-service"
      image        = "${aws_ecr_repository.app_repo.repository_url}@${data.aws_ecr_image.registration_service.image_digest}"
      essential    = true
      portMappings = [{ containerPort = 8080, hostPort = 8080, protocol = "tcp" }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      },
      secrets = [
        {
          name      = "SPRING_DATASOURCE_URL"
          valueFrom = "${aws_secretsmanager_secret.registration_service.arn}:spring.datasource.url::"
        },
        {
          name      = "SPRING_DATASOURCE_USERNAME"
          valueFrom = "${aws_secretsmanager_secret.registration_service.arn}:spring.datasource.username::"
        },
        {
          name      = "SPRING_DATASOURCE_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.registration_service.arn}:spring.datasource.password::"
        },
        {
          name      = "SPRING_KAFKA_BOOTSTRAP_SERVERS"
          valueFrom = "${aws_secretsmanager_secret.registration_service.arn}:spring.kafka.bootstrap-servers::"
        },
        {
          name      = "SPRING_KAFKA_PROPERTIES_SECURITY_PROTOCOL"
          valueFrom = "${aws_secretsmanager_secret.registration_service.arn}:spring.kafka.properties.security.protocol::"
        },
        {
          name      = "SPRING_KAFKA_PROPERTIES_SSL_TRUSTSTORE_LOCATION"
          valueFrom = "${aws_secretsmanager_secret.registration_service.arn}:spring.kafka.properties.ssl.truststore.location::"
        },
        {
          name      = "SPRING_KAFKA_PROPERTIES_SSL_TRUSTSTORE_PASSWORD"
          valueFrom = "${aws_secretsmanager_secret.registration_service.arn}:spring.kafka.properties.ssl.truststore.password::"
        },
        {
          name      = "KAFKA_TRUSTSTORE_B64"
          valueFrom = aws_secretsmanager_secret.kafka_truststore.arn
        }
      ]

    }
  ])
}

###########################################
# ECS Service
###########################################
resource "aws_ecs_service" "app" {
  name            = "${var.project}-${var.env}-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "registration-service"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.nlb_listener]
}

###########################################
# Secrets manager
###########################################

resource "aws_secretsmanager_secret" "registration_service" {
  name        = "registration-service-secrets"
  description = "Secrets for ECS"
}

resource "aws_secretsmanager_secret" "kafka_truststore" {
  name        = "msk-truststore"
  description = "Truststore for MSK"
}

resource "aws_iam_role_policy" "ecs_task_secrets_policy" {
  name = "ecs-task-secrets-access"
  role = aws_iam_role.ecs_task.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.registration_service.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_execution_secrets_policy" {
  name = "ecs-execution-secrets-access"
  role = aws_iam_role.ecs_execution.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [
          aws_secretsmanager_secret.kafka_truststore.arn
        ]
      }
    ]
  })
}


