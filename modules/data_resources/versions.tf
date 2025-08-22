terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.25"
    }
    kafka = {
      source  = "Mongey/kafka"
      version = "~> 0.5.4"
    }
  }
}
