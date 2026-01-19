output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "alb_dns_name" {
  description = "ALB DNS 이름"
  value       = aws_lb.main.dns_name
}

output "target_group_arn" {
  description = "Target Group ARN"
  value       = aws_lb_target_group.main.arn
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  value       = try(aws_cloudfront_distribution.main[0].id, null)
}

output "cloudfront_domain_name" {
  description = "CloudFront Domain Name"
  value       = try(aws_cloudfront_distribution.main[0].domain_name, null)
}

output "ec2_instance_id" {
  description = "EC2 Instance ID"
  value       = try(aws_instance.main[0].id, null)
}

output "ec2_instance_private_ip" {
  description = "EC2 Instance Private IP"
  value       = try(aws_instance.main[0].private_ip, null)
}

output "ec2_instance_public_ip" {
  description = "EC2 Instance Public IP (null if in private subnet)"
  value       = try(aws_instance.main[0].public_ip, null)
}

