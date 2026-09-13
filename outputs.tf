output "alb_dns_name" {
  description = "Load balancer public URL"
  value       = aws_lb.alb.dns_name
}