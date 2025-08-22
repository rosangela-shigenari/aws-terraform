output "ecs_cluster_name" { 
    value = aws_ecs_cluster.this.name 
}
output "ecs_service_name" { 
    value = aws_ecs_service.app.name 
}
output "nlb_arn" { 
    value = aws_lb.nlb.arn 
}
output "nlb_dns_name" { 
    value = aws_lb.nlb.dns_name 
}
output "nlb_dns" {
  value       = aws_lb.nlb.dns_name
  description = "DNS name of the Network Load Balancer"
}

