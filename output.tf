output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = aws_lb.app_alb.dns_name
}
