output "alb_dns_name" {
  value       = aws_lb.app_alb.dns_name
  description = "DNS name of the Application Load Balancer"
}

output "ec2_instance_id" {
  value       = aws_instance.app_instance.id
  description = "ID of the EC2 instance"
}